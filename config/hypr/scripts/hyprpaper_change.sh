#!/usr/bin/env bash
set -euo pipefail

MONITOR="DP-2"
WALLPAPER_DIR="$HOME/wallpapers"
STATE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/hyprpaper/current_wallpaper"

# Pastas ou imagens para ignorar (separadas por | )
# Exemplo: "dark|jogos|nao_usar.png"
IGNORE_PATTERN="voyager-samurai-square.png|voyager-samurai.png"

CURRENT_WALLPAPER=""
if [[ -f "$STATE_FILE" ]]; then
    CURRENT_WALLPAPER=$(<"$STATE_FILE")
fi

mapfile -t ALL_WALLPAPERS < <(
    find "$WALLPAPER_DIR" -type f \
        \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" -o -iname "*.jxl" \) \
        | sort
)

CANDIDATES=()
AVAILABLE_WALLPAPERS=()
for WALLPAPER in "${ALL_WALLPAPERS[@]}"; do
    if [[ "$WALLPAPER" =~ $IGNORE_PATTERN ]]; then
        continue
    fi

    CANDIDATES+=("$WALLPAPER")

    if [[ "$WALLPAPER" != "$CURRENT_WALLPAPER" ]]; then
        AVAILABLE_WALLPAPERS+=("$WALLPAPER")
    fi
done

if (( ${#CANDIDATES[@]} == 0 )); then
    echo "Nenhum wallpaper encontrado em $WALLPAPER_DIR" >&2
    exit 1
fi

if (( ${#AVAILABLE_WALLPAPERS[@]} == 0 )); then
    AVAILABLE_WALLPAPERS=("${CANDIDATES[@]}")
fi

NEXT_WALLPAPER="${AVAILABLE_WALLPAPERS[RANDOM % ${#AVAILABLE_WALLPAPERS[@]}]}"

APPLIED=0
for _ in {1..20}; do
    if hyprctl hyprpaper wallpaper "$MONITOR, $NEXT_WALLPAPER, cover" >/dev/null 2>&1; then
        APPLIED=1
        break
    fi

    sleep 0.25
done

if (( APPLIED == 0 )); then
    echo "Nao foi possivel aplicar o wallpaper via IPC do hyprpaper" >&2
    exit 1
fi

mkdir -p "$(dirname "$STATE_FILE")"
printf '%s\n' "$NEXT_WALLPAPER" > "$STATE_FILE"

ICON="/tmp/wp_icon.png"
if command -v notify-send >/dev/null 2>&1; then
    if command -v magick >/dev/null 2>&1; then
        magick "$NEXT_WALLPAPER" -resize 256x256 "$ICON" \
            && notify-send -i "$ICON" "Hyprpaper" "Novo wallpaper aplicado..." \
            || true
    elif command -v convert >/dev/null 2>&1; then
        convert "$NEXT_WALLPAPER" -resize 256x256 "$ICON" \
            && notify-send -i "$ICON" "Hyprpaper" "Novo wallpaper aplicado..." \
            || true
    else
        notify-send "Hyprpaper" "Novo wallpaper aplicado..." \
        || true
    fi
fi
