#!/usr/bin/env bash

MONITOR="DP-2"
WALLPAPER_DIR="$HOME/wallpapers"
CONF_FILE="$HOME/.config/hypr/hyprpaper.conf"

# Pastas ou imagens para ignorar (separadas por | )
# Exemplo: "dark|jogos|nao_usar.png"
IGNORE_PATTERN="voyager-samurai-square.png|voyager-samurai.png"

# Wallpaper atual
CURRENT_WALLPAPER=$(hyprctl hyprpaper list | awk '{print $2}' | head -n 1)

# Lista de wallpapers filtrando extensões e ignorados
ALL_WALLPAPERS=$(find "$WALLPAPER_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) \
    | grep -Ev "$IGNORE_PATTERN")

# Remove o atual da lista
AVAILABLE_WALLPAPERS=$(echo "$ALL_WALLPAPERS" | grep -vF "$CURRENT_WALLPAPER")

# Escolhe aleatório
NEXT_WALLPAPER=$(echo "$AVAILABLE_WALLPAPERS" | shuf -n 1)

# Aplica no monitor e atualiza o conf
if [[ -n "$NEXT_WALLPAPER" ]]; then
    hyprctl hyprpaper preload "$NEXT_WALLPAPER"
    hyprctl hyprpaper wallpaper "$MONITOR,$NEXT_WALLPAPER"

    # Remove linhas antigas de preload e wallpaper
    sed -i '/^preload/d' "$CONF_FILE"
    sed -i '/^wallpaper/d' "$CONF_FILE"

    # Adiciona novas linhas ao final do arquivo
    {
        echo "# Gerado automaticamente em $(date)"
        echo "preload = $NEXT_WALLPAPER"
        echo "wallpaper = $MONITOR,$NEXT_WALLPAPER"
    } >> "$CONF_FILE"

    ICON="/tmp/wp_icon.png"
    convert "$NEXT_WALLPAPER" -resize 256x256 "$ICON"
    notify-send -i "$ICON" "Hyprpaper" "Novo wallpaper aplicado..."
fi