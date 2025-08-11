#!/usr/bin/env bash
set -euo pipefail

# ===== Identificação exata dos seus sinks =====
PAT_ALEXA='bluez_output\.68_B6_91_8D_DB_B5\.1'
PAT_ASTRO_GAME='alsa_output\.usb-Astro_Gaming_Astro_A50-00\.stereo-game'
PAT_ASTRO_CHAT='alsa_output\.usb-Astro_Gaming_Astro_A50-00\.stereo-chat'

# ===== Lista completa na ordem desejada =====
ORDER=("$PAT_ALEXA" "$PAT_ASTRO_GAME" "$PAT_ASTRO_CHAT")

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
  case "$1" in
    *usb-Astro_Gaming_Astro_A50-00.stereo-game*) echo "Astro A50 (GAME)";;
    *usb-Astro_Gaming_Astro_A50-00.stereo-chat*) echo "Astro A50 (CHAT)";;
    *bluez_output.68_B6_91_8D_DB_B5.1*)          echo "Echo Dot";;
    *)                                           echo "$1";;
  esac
}

icon_for() {
  case "$1" in
    *usb-Astro_Gaming_Astro_A50-00.stereo-game*)  echo "audio-headset" ;;   # GAME
    *usb-Astro_Gaming_Astro_A50-00.stereo-chat*)  echo "audio-input-microphone" ;;   # VOICE
    *bluez_output.*)                              echo "audio-speakers" ;;           # Alexa
    *)                                            echo "multimedia-volume-control" ;;
  esac
}

# ===== Resolve todos os nomes reais =====
RESOLVED=()
for pat in "${ORDER[@]}"; do
  resolved="$(pick_sink "$pat" || true)"
  [[ -n "$resolved" ]] && RESOLVED+=("$resolved")
done

if (( ${#RESOLVED[@]} < 2 )); then
  command -v notify-send >/dev/null && notify-send -u low -a "Áudio" "Não encontrado todos os dispositivos configurados"
  echo "Erro: Sinks configurados não encontrados."
  exit 1
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
