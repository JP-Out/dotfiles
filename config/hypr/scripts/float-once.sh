#!/usr/bin/env bash
# float-once.sh CLASS WIDTH HEIGHT [X Y]
# Ex: float-once.sh org.kde.kdenlive 900 700
# Ex: float-once.sh com.github.hluk.copyq 300 400 1500 600

set -euo pipefail

if (( $# < 3 || $# == 4 || $# > 5 )); then
  echo "Uso: $(basename "$0") CLASS WIDTH HEIGHT [X Y]" >&2
  exit 2
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/hyprland-ipc.sh
source "$SCRIPT_DIR/lib/hyprland-ipc.sh"

CLASS="$1"
W="$2"
H="$3"
X="${4:-center}"
Y="${5:-center}"

[[ "$W" =~ ^[0-9]+$ && "$H" =~ ^[0-9]+$ ]] || {
  echo "Largura e altura precisam ser números inteiros positivos." >&2
  exit 2
}

if [[ "$X" != "center" ]] && ! [[ "$X" =~ ^-?[0-9]+$ && "$Y" =~ ^-?[0-9]+$ ]]; then
  echo "X e Y precisam ser números inteiros ou ambos devem ser 'center'." >&2
  exit 2
fi

command -v hyprctl >/dev/null 2>&1 || { echo "Faltando dependência: hyprctl" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "Faltando dependência: jq" >&2; exit 1; }

# Espera a janela aparecer.
addr=""
for i in {1..80}; do
  addr="$(hyprctl -j clients | jq -r --arg c "$CLASS" '.[] | select(.class==$c) | .address' | head -n1)"
  [[ -n "$addr" && "$addr" != "null" ]] && break
  sleep 0.05
done

[[ -z "$addr" || "$addr" == "null" ]] && exit 1

selector="$(hypr_address_selector "$addr")"
hypr_dispatch "hl.dsp.focus({ window = $selector })" >/dev/null
hypr_dispatch "hl.dsp.window.float({ action = \"on\", window = $selector })" >/dev/null
hypr_dispatch "hl.dsp.window.resize({ x = $W, y = $H, window = $selector })" >/dev/null

if [[ "$X" == "center" ]]; then
  hypr_dispatch "hl.dsp.window.center({ window = $selector })" >/dev/null
else
  hypr_dispatch "hl.dsp.window.move({ x = $X, y = $Y, window = $selector })" >/dev/null
fi
