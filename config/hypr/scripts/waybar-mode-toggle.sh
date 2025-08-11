#!/usr/bin/env bash
set -euo pipefail

WITH_BAR="3,10,10,10"
NO_BAR="10,10,10,10"

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/waybar"
MODE_FILE="$STATE_DIR/mode"
MANUAL_FILE="$STATE_DIR/manual_state"
mkdir -p "$STATE_DIR"

# ícones (nome sem .svg, o tema resolve)
ICON_KB="blueman-keyboard"
ICON_MOUSE="blueman-mouse"

need(){ command -v "$1" >/dev/null || { echo "Faltando $1"; exit 1; }; }
need hyprctl; need jq; need pkill
read_mode(){ [[ -f "$MODE_FILE" ]] && cat "$MODE_FILE" || echo hover; }

get_cursor_xy(){ hyprctl -j cursorpos | jq -r '"\(.x|floor) \(.y|floor)"'; }
get_monitor_top_for_x(){
  local x="$1"
  hyprctl -j monitors | jq -r --argjson x "$x" '
    .[] | select($x >= .x and $x < (.x + .width)) | .y
  ' | head -n1
}
active_ws_id(){ hyprctl -j monitors | jq '.[] | select(.focused==true).activeWorkspace.id'; }
tiled_count_on_ws(){
  local ws="$1"
  hyprctl -j clients | jq --argjson ws "$ws" '
    [ .[] | select(.workspace.id==$ws and .floating==false and .mapped==true)
          | select((.class // "" | ascii_downcase) != "rofi")
    ] | length
  '
}

show_bar(){ pkill -SIGUSR1 waybar || true; hyprctl keyword general:gaps_out "$WITH_BAR" >/dev/null; }
hide_bar(){ pkill -SIGUSR2 waybar || true; hyprctl keyword general:gaps_out "$NO_BAR"   >/dev/null; }

SHOW_ZONE=2
HIDE_ZONE=44

mode="$(read_mode)"
if [[ "$mode" == "hover" ]]; then
  # -> MANUAL: fixa visível + gaps com barra
  echo "manual" > "$MODE_FILE"
  echo "shown"  > "$MANUAL_FILE"
  show_bar
  command -v notify-send >/dev/null && notify-send -i "$ICON_KB" "Waybar" "Modo: manual (teclado)"
else
  # -> HOVER: sincroniza já, sem esperar mexer o mouse
  echo "hover" > "$MODE_FILE"

  ws="$(active_ws_id)"
  tiled="$(tiled_count_on_ws "$ws" 2>/dev/null || echo 0)"
  read -r cx cy < <(get_cursor_xy)
  top_y="$(get_monitor_top_for_x "$cx")"

  if (( tiled == 0 )); then
    show_bar
  elif [[ -n "$top_y" ]]; then
    if (( cy <= top_y + SHOW_ZONE )); then
      show_bar
    elif (( cy > top_y + HIDE_ZONE )); then
      hide_bar
    else
      hide_bar
    fi
  else
    hide_bar
  fi

  command -v notify-send >/dev/null && notify-send -i "$ICON_MOUSE" "Waybar" "Modo: hover (mouse)"
fi
