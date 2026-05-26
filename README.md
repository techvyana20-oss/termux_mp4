# termux_mp4 — Offline Video Downloader for Termux 🎬

termux_mp4 is a lightweight Android Termux project that provides an easy interface for downloading and managing offline videos from supported sources.

No Root Required.

Author: Bhavya Jain  
Project: techvyana2.0

---

# Features

✓ Single video download  
✓ Batch queue download  
✓ Pause / Resume  
✓ Download history  
✓ Multiple quality options  
✓ MP3 extraction mode  
✓ Download dashboard  
✓ File manager  
✓ Offline storage support  

---

# Installation

Update packages:

```bash
pkg update && pkg upgrade -y
```

Clone repository:

```bash
git clone https://github.com/techvyana20-oss/termux_mp4.git
cd termux_mp4
```

Run installer:

```bash
chmod +x install.sh
bash install.sh
```

Start VIDGET:

```bash
vidget
```

or

```bash
bash ~/vidget/vidget.sh
```

---

# Libraries and Dependencies Explained

VIDGET uses several libraries and tools together. Each library has a specific purpose.

---

## 1. yt-dlp

Purpose:
Main video information and media download engine.

Why we use it:

- Retrieves video information
- Gets title and metadata
- Supports multiple formats
- Allows quality selection
- Handles media stream extraction

How it works in VIDGET:

When the user enters a URL:

1. yt-dlp checks the video information
2. Retrieves available media streams
3. Selects the requested quality
4. Starts downloading
5. Sends the media to FFmpeg if merging is required

Example:

```bash
yt-dlp --get-title URL
```

or

```bash
yt-dlp --format best URL
```

---

## 2. FFmpeg

Purpose:
Processes and converts media files.

Why we use it:

- Combines video and audio streams
- Converts formats
- Extracts MP3 audio
- Creates final MP4 output

How it works in VIDGET:

Some media sources provide:

Video file only:
video.mp4

Audio file only:
audio.m4a

FFmpeg merges:

video.mp4 + audio.m4a

into:

final_video.mp4

Example:

```bash
ffmpeg -i video.mp4 -i audio.m4a output.mp4
```

---

## 3. jq

Purpose:
JSON processor.

Why we use it:

- Stores download history
- Reads history records
- Creates structured logs
- Handles queue data

How it works in VIDGET:

Example history:

```json
[
 {
   "title":"Sample Video",
   "quality":"720p",
   "status":"completed"
 }
]
```

---

## 4. Python

Purpose:
Runtime environment and package support.

Why we use it:

- Allows pip package installation
- Supports yt-dlp installation
- Easy package management

Installed using:

```bash
pkg install python
```

---

## 5. curl

Purpose:
Transfers files using URLs.

Why we use it:

- Downloads external files
- Fetches updates
- Downloads fallback packages

Example:

```bash
curl URL
```

---

## 6. wget

Purpose:
Downloads files directly.

Why we use it:

- Backup download utility
- Faster direct file retrieval
- Download automation

Example:

```bash
wget URL
```

---

# Project Structure

```text
termux_mp4/
│
├── install.sh
├── vidget.sh
├── downloads/
├── history.json
├── queue.txt
├── README.md
├── LICENSE
```

---

# Disclaimer

This project is intended only for educational and learning purposes.

Users are responsible for ensuring their use complies with applicable laws, platform terms, and content permissions.

The developers are not responsible for misuse.
