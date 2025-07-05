#!/bin/bash

# ──────────────────────────────────────────────────────
# Image/Video Upscaling Script (1 to 16 passes)
# Zenity GUI + Real-ESRGAN NCNN Vulkan
# Includes: detailed steps, progress bar + % + message, EXIF copy, timer, framerate,
# isolated directories, clean console logs, CLI or GUI mode
# ──────────────────────────────────────────────────────

export GTK_THEME="Adwaita:dark"
export GDK_SCALE=1
export GDK_DPI_SCALE=1

# Load .env variables
if [ -f ".env" ]; then
  export $(grep -v "^#" .env | xargs)
fi

# Create working directories
mkdir -p "$WORKDIR" "$FRAMES_DIR" "$UPSCALED_DIR"
cd "$WORKDIR" || exit 1

# ─── GUI OR CLI MODE ───────────────────────────────────
if [[ "$1" == "--mode=gui" ]]; then
  gui_mode=true
  shift
else
  gui_mode=false
fi

# ─── CLI MODE ──────────────────────────────────────────
if [[ "$gui_mode" != "true" ]]; then
  if [[ $# -lt 4 ]]; then
    echo "Usage CLI : $0 input_file output_file model passes"
    echo "Available models : realesrgan-x4plus, realesr-animevideov3-x4, auto"
    echo "Valid passes : 1, 2, 4, 8, 16"
    exit 1
  fi

  input="${INPUT_DIR}/$1"
  output_file="${OUTPUT_DIR}/$2"
  model="$3"
  passes="$4"

  if [[ "$model" == "auto" ]]; then
    model_flag=""
    suffix_model="auto"
  else
    model_flag="-n $model"
    suffix_model=$(echo "$model" | sed 's/^realesr[-]*//; s/realesrgan[-]*//; s/[-_]*$//')
  fi

  scale_factor="x$((passes * 4))"
  filename=$(basename "$input")
  name="${filename%.*}"
  ext="${filename##*.}"
  ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

  start_time=$(date +%s)

  if [[ "$ext_lower" =~ ^(mp4|mov|mkv|webm)$ ]]; then output_ext="mp4"; else output_ext="png"; fi

  if [[ "$ext_lower" =~ ^(png|jpg|jpeg|webp)$ ]]; then
    echo "[INFO] Upscaling image..."
    tmp_out=$(mktemp --suffix=".${output_ext}" --tmpdir="$WORKDIR")
    if ! "$REALESRGAN_BIN" -i "$input" -o "$tmp_out" $model_flag; then
      echo "Error: image upscaling failed." >&2
      exit 1
    fi
    command -v exiftool >/dev/null && exiftool -overwrite_original -TagsFromFile "$input" "$tmp_out"
    mv "$tmp_out" "$output_file"
  else
    echo "[INFO] Extracting frames..."
    ffmpeg -i "$input" "$FRAMES_DIR/frame_%06d.png" -hide_banner -loglevel error

    total=$(find "$FRAMES_DIR" -maxdepth 1 -name '*.png' | wc -l)
    if [ "$total" -eq 0 ]; then echo "❌ No frames extracted."; exit 1; fi

    echo "[INFO] Detecting framerate..."
    fps=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate \
      -of default=nw=1:nk=1 "$input")
    if [[ "$fps" == */* ]]; then num=${fps%%/*}; den=${fps##*/}; fps=$(awk -v n="$num" -v d="$den" 'BEGIN{ if(d>0) printf "%.2f",n/d; else print "30" }'); fi
    fps=${fps:-30}

    echo "[INFO] Upscaling video in $passes passes..."
    count=0
    for frame in "$FRAMES_DIR"/*.png; do
      tmp_frame="$frame"
      for ((p=1; p<=passes; p++)); do
        out="$UPSCALED_DIR/$(basename "$frame")_p${p}.png"
        "$REALESRGAN_BIN" -i "$tmp_frame" -o "$out" $model_flag
        tmp_frame="$out"
      done
      mv "$tmp_frame" "$UPSCALED_DIR/$(basename "$frame")"
      count=$((count+1))
      echo "[Progress] $count/$total"
    done

    echo "[INFO] Compiling video..."
    ffmpeg -y -framerate "$fps" -i "$UPSCALED_DIR/frame_%06d.png" -i "$input" \
      -map 0:v -map 1:a? -c:v libx264 -pix_fmt yuv420p -c:a copy "$output_file" -loglevel error
  fi

  end_time=$(date +%s)
  duration=$((end_time - start_time))
  if [ "$duration" -gt 3600 ]; then duration_fmt="$((duration/3600))h $(((duration%3600)/60))m $((duration%60))s";
  elif [ "$duration" -gt 60 ]; then duration_fmt="$((duration/60))m $((duration%60))s";
  else duration_fmt="${duration}s"; fi

  mkdir -p "$(dirname "$HISTORY_LOG")"
  echo "$(date '+%Y-%m-%d %H:%M:%S') | $input | $model | $scale_factor | ${duration_fmt} | $output_file" >> "$HISTORY_LOG"

  echo "✅ Upscaling complete in $duration_fmt"
  echo "📁 Output file: $output_file"

  exit 0
fi

# ─── GUI MODE (zenity) ─────────────────────────────────

input=$(zenity --file-selection --title="Choose an image or video file") || exit 1

output_file=$(zenity --file-selection --save --confirm-overwrite --title="Save as...") || exit 1

model=$(zenity --list --title="Select a model" \
  --radiolist \
  --column="Select" --column="Model" \
  TRUE "realesrgan-x4plus" FALSE "realesr-animevideov3-x4" FALSE "auto") || exit 1

passes=$(zenity --list --title="Number of passes" \
  --radiolist \
  --column="Select" --column="Passes" \
  TRUE 1 FALSE 2 FALSE 4 FALSE 8 FALSE 16) || exit 1

zenity --info --text="Preparing files..."

exec "$0" "$input" "$output_file" "$model" "$passes"
