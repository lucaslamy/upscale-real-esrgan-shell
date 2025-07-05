# 🔺 upscale-real-esrgan-shell : Multi-Pass Image & Video Upscaler (CLI + GUI)

This project provides a powerful and flexible **Bash-based upscaling tool** for both **images and videos**, using **[Real-ESRGAN NCNN Vulkan](w)**. It supports **1 to 16 upscaling passes**, **metadata preservation**, and comes with a minimal **Zenity-based GUI** and a clean CLI mode.

---

## ✨ Features

- 🖼️ Supports both images (`.png`, `.jpg`, etc.) and videos (`.mp4`, `.mkv`, etc.)
- 🔁 Multi-pass upscaling (1 to 16 passes)
- 🧠 Smart model selector (`auto`, `realesrgan-x4plus`, `animevideov3-x4`)
- ⏱️ Timer with duration logging
- 🎞️ Video frame extraction and reassembly
- 🔊 Audio track preserved in output video
- 🗂️ Isolated working directories (`/tmp`)
- 📝 Clean console output + persistent history log
- 📸 Copies EXIF metadata (if `exiftool` is available)
- 🧑‍💻 Dual mode: CLI **and** Zenity-based GUI
- 📦 Zero dependency outside standard Linux utils + Real-ESRGAN binary

---

## 🧰 Requirements

- Linux system with:
  - `bash`, `ffmpeg`, `ffprobe`, `zenity`
  - Optional: `exiftool` for metadata copying
- [Real-ESRGAN NCNN Vulkan](w) binary

> Set the path to your `realesrgan-ncnn-vulkan` binary inside the .env (default: `REALESRGAN_BIN`).

---

## 🚀 Quick Start (CLI Mode)

First, edit .env in order to specify your paths.

Then : 

```bash
mkdir -p "$INPUT_DIR" "$OUTPUT_DIR"
```

And after that you can start ! :

```bash
./upscale.sh input_filename output_filename model passes
```

### 🔧 Parameters

| Param        | Description                                           |
|--------------|-------------------------------------------------------|
| `input_filename`  | File from the `input/` folder                      |
| `output_filename` | Will be saved to the `output/` folder              |
| `model`           | `realesrgan-x4plus`, `realesr-animevideov3-x4`, or `auto` |
| `passes`          | Number of passes: `1`, `2`, `4`, `8`, `16`        |

### 🧪 Example

```bash
./upscale.sh input.jpg upscaled.png realesrgan-x4plus 4
```

---

## 🖱️ GUI Mode (Zenity)

To launch in graphical mode:

```bash
./upscale.sh --mode=gui
```

The GUI will guide you through:
1. File selection
2. Output location
3. Model choice
4. Number of passes

---

## 📁 File Structure

```bash
/tmp/upscale/
├── frames/              # Extracted video frames
├── frames_upscaled/     # Upscaled frames
└── *.log                # Optional history logs
```

---

## 🧾 Output Logging

Every successful run logs into:

```bash
~/upscale_history.log
```

With fields:
```
[TIMESTAMP] | [INPUT] | [MODEL] | [SCALE FACTOR] | [DURATION] | [OUTPUT]
```

---

## 🛠 Customization

You can easily adapt the following settings at the top of the script:

- `REALESRGAN_BIN`: Path to your Real-ESRGAN binary
- `WORKDIR`: Temporary working directory
- `HISTORY_LOG`: Path for the upscale history log

---

## 🛡️ License

This script is distributed under the **MIT License**. Real-ESRGAN is licensed under its respective license.

---

## 🙏 Credits

- [Real-ESRGAN](w) — for the upscaling backend
- `zenity`, `ffmpeg`, and the open-source community ❤️
