#!/data/data/com.termux/files/usr/bin/bash
# ╔══════════════════════════════════════════════════╗
# ║           VIDGET — Offline Video Downloader      ║
# ║        For Termux on Android (No Root)           ║
# ╠══════════════════════════════════════════════════╣
# ║  Author  : Bhavya Jain                           ║
# ║  Project : techvyana2.0                          ║
# ╚══════════════════════════════════════════════════╝
# Usage: bash vidget.sh

# ── Config ──────────────────────────────────────────
VIDGET_DIR="$HOME/vidget"
DOWNLOADS_DIR="$HOME/storage/downloads/termuxmp4"
HISTORY_FILE="$VIDGET_DIR/history.json"
QUEUE_FILE="$VIDGET_DIR/queue.txt"
PAUSE_FILE="$VIDGET_DIR/.paused"
VERSION="1.0.0"

# ── Colors ──────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ── Init ─────────────────────────────────────────────
init_dirs() {
    if [ ! -d "$HOME/storage/downloads" ]; then
        echo -e "${YELLOW}Setting up storage access...${NC}"
        termux-setup-storage
        sleep 2
    fi
    mkdir -p "$DOWNLOADS_DIR"
    [ ! -f "$HISTORY_FILE" ] && echo "[]" > "$HISTORY_FILE"
    [ ! -f "$QUEUE_FILE" ]   && touch "$QUEUE_FILE"
}

# ── Header ───────────────────────────────────────────
print_header() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "  ██╗   ██╗██╗██████╗  ██████╗ ███████╗████████╗"
    echo "  ██║   ██║██║██╔══██╗██╔════╝ ██╔════╝╚══██╔══╝"
    echo "  ██║   ██║██║██║  ██║██║  ███╗█████╗     ██║   "
    echo "  ╚██╗ ██╔╝██║██║  ██║██║   ██║██╔══╝     ██║   "
    echo "   ╚████╔╝ ██║██████╔╝╚██████╔╝███████╗   ██║   "
    echo "    ╚═══╝  ╚═╝╚═════╝  ╚═════╝ ╚══════╝   ╚═╝   "
    echo -e "${NC}${DIM}  Offline Video Downloader for Termux  v${VERSION}${NC}"
    echo -e "${MAGENTA}  Author : Bhavya Jain  │  techvyana2.0${NC}"
    echo -e "${DIM}  ─────────────────────────────────────────────${NC}"
}

# ── Dependency Check ─────────────────────────────────
check_deps() {
    local missing=()
    command -v yt-dlp  &>/dev/null || missing+=("yt-dlp")
    command -v ffmpeg  &>/dev/null || missing+=("ffmpeg")
    command -v jq      &>/dev/null || missing+=("jq")

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "\n${YELLOW}${BOLD}⚠  Missing dependencies: ${missing[*]}${NC}"
        echo -e "${WHITE}Installing now...${NC}\n"
        pkg update -y -q
        for dep in "${missing[@]}"; do
            echo -e "${CYAN}  → Installing ${dep}...${NC}"
            pkg install -y "$dep" -q && \
                echo -e "${GREEN}  ✓ ${dep} installed${NC}" || \
                echo -e "${RED}  ✗ Failed to install ${dep}${NC}"
        done
        echo ""
    fi
}

# ── Quality Menu ─────────────────────────────────────
select_quality() {
    echo -e "\n${WHITE}${BOLD}Select Video Quality:${NC}"
    echo -e "  ${CYAN}1${NC}) 1080p  (Full HD, ~500MB/hr)"
    echo -e "  ${CYAN}2${NC}) 720p   (HD, ~200MB/hr)  ${GREEN}[Recommended]${NC}"
    echo -e "  ${CYAN}3${NC}) 480p   (SD, ~100MB/hr)"
    echo -e "  ${CYAN}4${NC}) 360p   (Low, ~60MB/hr)"
    echo -e "  ${CYAN}5${NC}) Audio  (MP3 only, ~30MB/hr)"
    echo -e "  ${CYAN}6${NC}) Best   (Highest available)"
    echo ""
    read -rp "$(echo -e "${YELLOW}Quality [1-6, default 2]: ${NC}")" q_choice

    case "$q_choice" in
        1) FORMAT="bestvideo[height<=1080]+bestaudio/best[height<=1080]"; QLABEL="1080p" ;;
        3) FORMAT="bestvideo[height<=480]+bestaudio/best[height<=480]";   QLABEL="480p"  ;;
        4) FORMAT="bestvideo[height<=360]+bestaudio/best[height<=360]";   QLABEL="360p"  ;;
        5) FORMAT="bestaudio/best"; QLABEL="Audio"; AUDIO_ONLY=true ;;
        6) FORMAT="bestvideo+bestaudio/best"; QLABEL="Best" ;;
        *) FORMAT="bestvideo[height<=720]+bestaudio/best[height<=720]"; QLABEL="720p"  ;;
    esac
}

# ── Single Download ───────────────────────────────────
download_single() {
    echo -e "\n${WHITE}${BOLD}── Single Download ──────────────────────${NC}"
    read -rp "$(echo -e "${YELLOW}Paste video URL: ${NC}")" url

    [ -z "$url" ] && echo -e "${RED}No URL entered.${NC}" && return

    select_quality

    echo -e "\n${CYAN}Fetching video info...${NC}"
    local title
    title=$(yt-dlp --get-title "$url" 2>/dev/null || echo "Unknown Title")
    echo -e "${WHITE}Title: ${BOLD}${title}${NC}"
    echo -e "${WHITE}Quality: ${CYAN}${QLABEL}${NC}"
    echo ""

    local output_tmpl="$DOWNLOADS_DIR/%(title)s.%(ext)s"
    local yt_args=(
        --format "$FORMAT"
        --output "$output_tmpl"
        --merge-output-format mp4
        --progress
        --no-playlist
        --console-title
    )

    [ "$AUDIO_ONLY" = true ] && yt_args+=(--extract-audio --audio-format mp3)

    echo -e "${GREEN}Starting download...${NC}\n"
    if yt-dlp "${yt_args[@]}" "$url"; then
        echo -e "\n${GREEN}${BOLD}✓ Download complete!${NC}"
        add_to_history "$title" "$url" "$QLABEL" "completed"
    else
        echo -e "\n${RED}✗ Download failed.${NC}"
        add_to_history "$title" "$url" "$QLABEL" "failed"
    fi
    AUDIO_ONLY=false
    press_enter
}

# ── Batch Queue ───────────────────────────────────────
batch_download() {
    echo -e "\n${WHITE}${BOLD}── Batch Queue ──────────────────────────${NC}"
    echo -e "${DIM}Enter one URL per line. Type ${WHITE}DONE${DIM} when finished.${NC}\n"

    local count=0
    while true; do
        read -rp "$(echo -e "${YELLOW}URL $((count+1)) (or DONE): ${NC}")" line
        [ "$line" = "DONE" ] || [ -z "$line" ] && break
        echo "$line" >> "$QUEUE_FILE"
        echo -e "  ${GREEN}✓ Added to queue${NC}"
        ((count++))
    done

    if [ "$count" -eq 0 ]; then
        echo -e "${YELLOW}No URLs added.${NC}"
        press_enter
        return
    fi

    select_quality

    echo -e "\n${WHITE}${BOLD}Starting batch download of ${count} video(s)...${NC}\n"
    local i=1
    while IFS= read -r url; do
        [ -z "$url" ] && continue

        # Check pause
        while [ -f "$PAUSE_FILE" ]; do
            echo -e "${YELLOW}⏸  Paused. Press Enter to resume...${NC}"
            read -r
            rm -f "$PAUSE_FILE"
            echo -e "${GREEN}▶  Resuming...${NC}"
        done

        echo -e "${CYAN}[${i}/${count}] Downloading...${NC}"
        local title
        title=$(yt-dlp --get-title "$url" 2>/dev/null || echo "Video ${i}")
        echo -e "  ${WHITE}${title}${NC}"

        if yt-dlp \
            --format "$FORMAT" \
            --output "$DOWNLOADS_DIR/%(title)s.%(ext)s" \
            --merge-output-format mp4 \
            --progress \
            --no-playlist \
            "$url"; then
            echo -e "  ${GREEN}✓ Done${NC}\n"
            add_to_history "$title" "$url" "$QLABEL" "completed"
        else
            echo -e "  ${RED}✗ Failed${NC}\n"
            add_to_history "$title" "$url" "$QLABEL" "failed"
        fi
        ((i++))
    done < "$QUEUE_FILE"

    # Clear queue
    > "$QUEUE_FILE"
    echo -e "${GREEN}${BOLD}✓ Batch complete!${NC}"
    press_enter
}

# ── Pause / Resume ────────────────────────────────────
toggle_pause() {
    if [ -f "$PAUSE_FILE" ]; then
        rm -f "$PAUSE_FILE"
        echo -e "${GREEN}▶  Downloads resumed.${NC}"
    else
        touch "$PAUSE_FILE"
        echo -e "${YELLOW}⏸  Downloads will pause after the current file.${NC}"
    fi
    sleep 1
}

# ── History ───────────────────────────────────────────
add_to_history() {
    local title="$1" url="$2" quality="$3" status="$4"
    local date
    date=$(date "+%Y-%m-%d %H:%M")
    local entry
    entry=$(jq -n \
        --arg t "$title" \
        --arg u "$url" \
        --arg q "$quality" \
        --arg s "$status" \
        --arg d "$date" \
        '{title:$t, url:$u, quality:$q, status:$s, date:$d}')
    local tmp
    tmp=$(jq --argjson e "$entry" '. += [$e]' "$HISTORY_FILE")
    echo "$tmp" > "$HISTORY_FILE"
}

show_history() {
    echo -e "\n${WHITE}${BOLD}── Download History ─────────────────────${NC}\n"
    local count
    count=$(jq 'length' "$HISTORY_FILE")

    if [ "$count" -eq 0 ]; then
        echo -e "${DIM}  No downloads yet.${NC}"
        press_enter
        return
    fi

    jq -r '.[] | "\(.date)  [\(.status)]  \(.quality)  \(.title)"' "$HISTORY_FILE" | \
    while IFS= read -r line; do
        if [[ $line == *"completed"* ]]; then
            echo -e "  ${GREEN}${line}${NC}"
        else
            echo -e "  ${RED}${line}${NC}"
        fi
    done

    echo -e "\n${DIM}  Total: ${count} entries${NC}"
    echo ""
    echo -e "  ${CYAN}c${NC}) Clear history   ${CYAN}b${NC}) Back"
    read -rp "$(echo -e "${YELLOW}Choice: ${NC}")" ch
    [ "$ch" = "c" ] && echo "[]" > "$HISTORY_FILE" && \
        echo -e "${GREEN}History cleared.${NC}" && sleep 1
}

# ── File Manager ──────────────────────────────────────
manage_files() {
    echo -e "\n${WHITE}${BOLD}── Downloaded Videos ────────────────────${NC}\n"
    local files=("$DOWNLOADS_DIR"/*)
    local count=0

    if [ ! -e "${files[0]}" ]; then
        echo -e "${DIM}  No downloaded videos yet.${NC}"
        press_enter
        return
    fi

    for f in "${files[@]}"; do
        local name size
        name=$(basename "$f")
        size=$(du -sh "$f" 2>/dev/null | cut -f1)
        echo -e "  ${CYAN}$((++count))${NC}) ${WHITE}${name}${NC}  ${DIM}(${size})${NC}"
    done

    local total_size
    total_size=$(du -sh "$DOWNLOADS_DIR" 2>/dev/null | cut -f1)
    echo -e "\n${DIM}  Total storage used: ${total_size}${NC}"
    echo ""
    echo -e "  ${CYAN}d [n]${NC}) Delete file by number   ${CYAN}b${NC}) Back"
    read -rp "$(echo -e "${YELLOW}Choice: ${NC}")" ch

    if [[ "$ch" == d\ * ]]; then
        local num="${ch#d }"
        if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -le "${#files[@]}" ]; then
            local target="${files[$((num-1))]}"
            rm -f "$target"
            echo -e "${GREEN}✓ Deleted: $(basename "$target")${NC}"
            sleep 1
        else
            echo -e "${RED}Invalid number.${NC}"
            sleep 1
        fi
    fi
}

# ── Dashboard ─────────────────────────────────────────
show_dashboard() {
    local queue_count total_files total_size hist_count
    queue_count=$(wc -l < "$QUEUE_FILE" 2>/dev/null || echo 0)
    total_files=$(find "$DOWNLOADS_DIR" -type f 2>/dev/null | wc -l)
    total_size=$(du -sh "$DOWNLOADS_DIR" 2>/dev/null | cut -f1)
    hist_count=$(jq 'length' "$HISTORY_FILE" 2>/dev/null || echo 0)
    local pause_status="${GREEN}Active${NC}"
    [ -f "$PAUSE_FILE" ] && pause_status="${YELLOW}Paused${NC}"

    echo -e "\n${WHITE}${BOLD}── Dashboard ───────────────────────────${NC}"
    echo -e "  ${DIM}Videos downloaded : ${WHITE}${total_files}${NC}"
    echo -e "  ${DIM}Storage used      : ${WHITE}${total_size:-0}${NC}"
    echo -e "  ${DIM}Queue length      : ${WHITE}${queue_count}${NC}"
    echo -e "  ${DIM}History entries   : ${WHITE}${hist_count}${NC}"
    echo -e "  ${DIM}Download status   : ${pause_status}"
    echo -e "  ${DIM}Downloads folder  : ${CYAN}~/storage/downloads/termuxmp4${NC}"
}

# ── Main Menu ─────────────────────────────────────────
press_enter() {
    echo ""
    read -rp "$(echo -e "${DIM}Press Enter to continue...${NC}")"
}

main_menu() {
    while true; do
        print_header
        show_dashboard
        echo -e "\n${WHITE}${BOLD}── Menu ────────────────────────────────${NC}"
        echo -e "  ${CYAN}1${NC}) Download single video"
        echo -e "  ${CYAN}2${NC}) Batch download (queue)"
        echo -e "  ${CYAN}3${NC}) ${YELLOW}⏸ ${NC} Pause / Resume"
        echo -e "  ${CYAN}4${NC}) View download history"
        echo -e "  ${CYAN}5${NC}) Manage downloaded files"
        echo -e "  ${CYAN}6${NC}) Open downloads folder"
        echo -e "  ${CYAN}q${NC}) Quit"
        echo ""
        read -rp "$(echo -e "${YELLOW}Choose [1-6]: ${NC}")" choice

        case "$choice" in
            1) download_single ;;
            2) batch_download ;;
            3) toggle_pause ;;
            4) show_history ;;
            5) manage_files ;;
            6) echo -e "${CYAN}Downloads: ${DOWNLOADS_DIR}${NC}"; termux-open "$DOWNLOADS_DIR" 2>/dev/null; press_enter ;;
            q|Q) echo -e "\n${CYAN}Goodbye!${NC}\n"; exit 0 ;;
            *) echo -e "${RED}Invalid choice.${NC}"; sleep 0.5 ;;
        esac
    done
}

# ── Entry Point ───────────────────────────────────────
init_dirs
check_deps
main_menu
