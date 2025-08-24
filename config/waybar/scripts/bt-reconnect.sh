#!/usr/bin/env bash
set -e
# Carrega o MAC sem expor na Waybar
[ -f "$HOME/.dotfiles/.env.local" ] && . "$HOME/.dotfiles/.env.local"
: "${MAC_ALEXA:?Defina MAC_ALEXA em ~/.dotfiles/.env.local}"

bluetoothctl disconnect "$MAC_ALEXA" || true
sleep 1
bluetoothctl connect "$MAC_ALEXA"

# feedback opcional
command -v notify-send >/dev/null && notify-send -a Waybar "Bluetooth" "Reconectado a Alexa"
