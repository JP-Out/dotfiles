#!/usr/bin/env bash
set -euo pipefail

# Carrega o identificador local sem expô-lo na configuração da Waybar.
for env_file in \
  "${DOTFILES_ENV:-}" \
  "$HOME/.dotfiles/.env.local" \
  "${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/.env.local" \
  "$HOME/.env.local"
do
  [[ -n "$env_file" && -f "$env_file" ]] || continue
  # shellcheck disable=SC1090
  source "$env_file"
  break
done

: "${MAC_ALEXA:?Defina MAC_ALEXA em um .env.local; consulte .env.example}"

bluetoothctl disconnect "$MAC_ALEXA" || true
sleep 1
bluetoothctl connect "$MAC_ALEXA"

# feedback opcional
command -v notify-send >/dev/null && notify-send -a Waybar "Bluetooth" "Reconectado a Alexa"
