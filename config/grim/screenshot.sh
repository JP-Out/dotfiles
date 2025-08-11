#!/usr/bin/env bash
set -euo pipefail

SAVE_DIR="${SAVE_DIR:-$HOME/media/screenshots}"
TEMP_DIR="${TEMP_DIR:-$HOME/temp/screenshot-temp}"
TIMEOUT_SEC="${TIMEOUT_SEC:-20}"
DEBUG="${DEBUG:-0}"
log(){ [ "$DEBUG" = "1" ] && echo "DEBUG: $*" >&2 || true; }

mkdir -p "$SAVE_DIR" "$TEMP_DIR"

mode="${1:-full}"
ts="$(date +'%Y-%m-%d_%H-%M-%S')"
TMP="$TEMP_DIR/screenshot_${ts}.png"
OUT="$SAVE_DIR/screenshot_${ts}.png"
save_done=false

cleanup(){
  if ! $save_done && [ -f "$TMP" ]; then
    log "cleanup: removendo TMP $TMP"
    rm -f -- "$TMP"
  fi
  if [ -n "${MON_PID:-}" ] && kill -0 "$MON_PID" 2>/dev/null; then
    kill "$MON_PID" 2>/dev/null || true
  fi
  rm -f -- "${MON_LOG:-}" 2>/dev/null || true
}
trap cleanup EXIT

# 0) Inicia monitor antes da notificação
MON_LOG="$(mktemp -t notifmon.XXXXXX.log)"
stdbuf -oL -eL dbus-monitor --session "interface='org.freedesktop.Notifications',member='ActionInvoked'" \
  >"$MON_LOG" 2>&1 &
MON_PID=$!
sleep 0.15

# 1) Captura
if [ "$mode" = "area" ]; then
  geo="$(slurp || true)"
  [ -z "${geo:-}" ] && exit 0
  grim -g "$geo" "$TMP"
else
  grim "$TMP"
fi
log "capturado TMP=$TMP"

# 2) Clipboard
wl-copy --type image/png < "$TMP"

# 3) Notificação com ação "save"
nid_raw="$(gdbus call --session \
  --dest org.freedesktop.Notifications \
  --object-path /org/freedesktop/Notifications \
  --method org.freedesktop.Notifications.Notify \
  "Screenshot" 0 "" \
  "Captura de Tela realizada" \
  "Clique em <b>Salvar</b> para gravar em ~/media/screenshots" \
  '["save","Salvar em ~/media/screenshots"]' \
  '{"urgency": <byte 0>}' \
  8000)"
NID="$(printf '%s\n' "$nid_raw" | awk 'match($0,/uint32[[:space:]]+([0-9]+)/,m){print m[1]; exit}')"

# 4) Espera pelo clique
deadline=$(( $(date +%s) + TIMEOUT_SEC ))
found=0
while [ $(date +%s) -le "$deadline" ]; do
  if awk -v nid="$NID" '
        /member=ActionInvoked/ { got=0 }
        $1=="uint32" && $2==nid { got=1 }
        $1=="string" && $0 ~ /"save"/ && got==1 { print "HIT"; exit }
      ' "$MON_LOG" | grep -q "^HIT$"; then
    found=1
    break
  fi
  sleep 0.15
done

if [ "$found" = "1" ]; then
  mv -- "$TMP" "$OUT"
  save_done=true
  gdbus call --session \
    --dest org.freedesktop.Notifications \
    --object-path /org/freedesktop/Notifications \
    --method org.freedesktop.Notifications.Notify \
    "Screenshot" 0 "$OUT" \
    "Salva!" "Arquivo: $OUT" '[]' '{}' 4000 >/dev/null
fi

# 5) Saída no terminal
if $save_done; then
  echo "$OUT"
else
  echo "(clipboard)"
fi
