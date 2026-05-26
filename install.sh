#!/data/data/com.termux/files/usr/bin/bash
# ── VIDGET Installer for Termux ──────────────────────
# Author  : Bhavya Jain
# Project : techvyana2.0

echo ""
echo "  Installing VIDGET..."
echo ""

# Update packages
pkg update -y -q && pkg upgrade -y -q

# Core dependencies
pkg install -y curl wget python ffmpeg jq -q

# Install yt-dlp (most reliable method on Termux)
pip install -U yt-dlp 2>/dev/null || \
    curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp \
    -o "$PREFIX/bin/yt-dlp" && chmod +x "$PREFIX/bin/yt-dlp"

# Create vidget dir
mkdir -p "$HOME/vidget/downloads"

# Copy or download the script
if [ -f "./vidget.sh" ]; then
    cp "./vidget.sh" "$HOME/vidget/vidget.sh"
else
    echo "  vidget.sh not found. Place it in the same folder and re-run."
    exit 1
fi

chmod +x "$HOME/vidget/vidget.sh"

# Create a shortcut alias
grep -qxF "alias vidget='bash \$HOME/vidget/vidget.sh'" ~/.bashrc || \
    echo "alias vidget='bash \$HOME/vidget/vidget.sh'" >> ~/.bashrc

echo ""
echo "  ✓ VIDGET installed!"
echo "  ✓ Run it with:  bash ~/vidget/vidget.sh"
echo "  ✓ Or type:      vidget  (after restarting Termux)"
echo ""
