#!/usr/bin/env bash
set -euo pipefail

# Carrega identificadores locais que não devem ser versionados.
for ENV_FILE in "${DOTFILES_ENV:-}" "$HOME/.dotfiles/.env.local" "${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/.env.local" "$HOME/.env.local"; do
  [[ -n "$ENV_FILE" && -f "$ENV_FILE" ]] && . "$ENV_FILE"
done

# ===== Sinks preferidos, na ordem desejada =====
PAT_ASTRO_GAME='alsa_output\.usb-Astro_Gaming_Astro_A50-00\.stereo-game'
PAT_ASTRO_CHAT='alsa_output\.usb-Astro_Gaming_Astro_A50-00\.stereo-chat'
PAT_HDMI='alsa_output\.pci-0000_09_00\.1\.hdmi-stereo-extra2'

ORDER=()
MAC_ALEXA_PIPEWIRE=""
if [[ -n "${MAC_ALEXA:-}" ]]; then
  MAC_ALEXA_PIPEWIRE="${MAC_ALEXA//:/_}"
  PAT_ALEXA="bluez_output\\.${MAC_ALEXA_PIPEWIRE}\\.1"
  ORDER+=("$PAT_ALEXA")
fi
ORDER+=("$PAT_ASTRO_GAME" "$PAT_ASTRO_CHAT" "$PAT_HDMI")

# ===== Util =====
mapfile -t SINKS < <(pactl list short sinks | awk '{print $2}')

pick_sink() {
  local pat="$1"
  for s in "${SINKS[@]}"; do
    [[ "$s" =~ $pat ]] && { echo "$s"; return 0; }
  done
  return 1
}

pretty_name() {
  if [[ -n "$MAC_ALEXA_PIPEWIRE" && "$1" == *"bluez_output.${MAC_ALEXA_PIPEWIRE}.1"* ]]; then
    echo "Echo Dot"
    return
  fi

  case "$1" in
    *usb-Astro_Gaming_Astro_A50-00.stereo-game*) echo "Astro A50 (GAME)";;
    *usb-Astro_Gaming_Astro_A50-00.stereo-chat*) echo "Astro A50 (CHAT)";;
    *alsa_output.pci-0000_09_00.1.hdmi-stereo-extra2*) echo "Gigabyte G27FC";;
    *)                                           echo "$1";;
  esac
}

icon_for() {
  case "$1" in
    *usb-Astro_Gaming_Astro_A50-00.stereo-game*)  echo "audio-headset" ;;   # GAME
    *usb-Astro_Gaming_Astro_A50-00.stereo-chat*)  echo "audio-input-microphone" ;;   # VOICE
    *bluez_output.*)                              echo "audio-speakers" ;;           # Alexa
    *alsa_output.pci-0000_09_00.1.hdmi-stereo-extra2*) echo "video-display" ;;
    *)                                            echo "multimedia-volume-control" ;;
  esac
}

has_resolved() {
  local candidate="$1"
  local existing
  for existing in "${RESOLVED[@]}"; do
    [[ "$existing" == "$candidate" ]] && return 0
  done
  return 1
}

# ===== Resolve os preferidos e inclui qualquer outra saida disponivel =====
RESOLVED=()
for pat in "${ORDER[@]}"; do
  resolved="$(pick_sink "$pat" || true)"
  [[ -n "$resolved" ]] && RESOLVED+=("$resolved")
done

for sink in "${SINKS[@]}"; do
  has_resolved "$sink" || RESOLVED+=("$sink")
done

if (( ${#RESOLVED[@]} == 0 )); then
  command -v notify-send >/dev/null && notify-send -u low -a "Áudio" "Nenhuma saída de áudio encontrada"
  echo "Erro: nenhum sink encontrado."
  exit 1
fi

if (( ${#RESOLVED[@]} < 2 )); then
  only="$(pretty_name "${RESOLVED[0]}")"
  command -v notify-send >/dev/null && notify-send -u low -a "Áudio" "Só há uma saída de áudio disponível" "$only"
  echo "Apenas um sink disponível: ${RESOLVED[0]}"
  exit 0
fi

# ===== Descobre o próximo da ordem =====
current="$(pactl info | awk -F': ' '/Default Sink/{print $2}')"
next=""
for i in "${!RESOLVED[@]}"; do
  if [[ "${RESOLVED[$i]}" == "$current" ]]; then
    next="${RESOLVED[$(( (i+1) % ${#RESOLVED[@]} ))]}"
    break
  fi
done

# Se não achou (sink atual não está na lista), vai pro primeiro
[[ -z "$next" ]] && next="${RESOLVED[0]}"

# ===== Define e move as streams =====
pactl set-default-sink "$next"
pactl list short sink-inputs | awk '{print $1}' | while read -r id; do
  pactl move-sink-input "$id" "$next"
done

# ===== Notificação bonita =====
pretty="$(pretty_name "$next")"
icon="$(icon_for "$next")"
command -v notify-send >/dev/null && notify-send -u low -a "Áudio" -i "$icon" "Saída alterada" "$pretty"
