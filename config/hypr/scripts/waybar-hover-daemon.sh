#!/usr/bin/env bash
set -Eeuo pipefail

WITH_BAR="3,10,10,10"
NO_BAR="10,10,10,10"

SHOW_ZONE=2
HIDE_ZONE=44
POLL=0.08

need(){ command -v "$1" >/dev/null || { echo "Faltando $1"; exit 1; }; }
need hyprctl; need jq; need pkill

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/waybar"
MODE_FILE="$STATE_DIR/mode"              # "hover" | "manual"
MANUAL_FILE="$STATE_DIR/manual_state"    # "shown" | "hidden"
mkdir -p "$STATE_DIR"

read_mode(){   [[ -f "$MODE_FILE"   ]] && cat "$MODE_FILE"   || echo hover; }
read_manual(){ [[ -f "$MANUAL_FILE" ]] && cat "$MANUAL_FILE" || echo hidden; }

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
    [ .[]
      | select(.workspace.id==$ws and .floating==false and .mapped==true)
      | select((.class // "" | ascii_downcase) != "rofi")
    ] | length
  '
}

show_bar(){ pkill -SIGUSR1 waybar || true; hyprctl keyword general:gaps_out "$WITH_BAR" >/dev/null; }
hide_bar(){ pkill -SIGUSR2 waybar || true; hyprctl keyword general:gaps_out "$NO_BAR"   >/dev/null; }

state="hidden"
hide_bar

while :; do
  mode="$(read_mode)"
  ws="$(active_ws_id)"
  tiled="$(tiled_count_on_ws "$ws" 2>/dev/null || echo 0)"

  if [[ "$mode" == "manual" ]]; then
    # --- NOVO: em manual, workspace vazio SEMPRE mostra; senão, obedece ao estado manual ---
    if (( tiled == 0 )); then
      if [[ "$state" != "shown" ]]; then show_bar; state="shown"; fi
    else
      case "$(read_manual)" in
        shown)
          if [[ "$state" != "shown" ]]; then show_bar; state="shown"; fi
          ;;
        hidden|*)
          if [[ "$state" != "hidden" ]]; then hide_bar; state="hidden"; fi
          ;;
      esac
    fi
    sleep "$POLL"; continue
  fi

  # --- MODO HOVER (inalterado): workspace vazio mostra; senão, hover por zona ---
  if (( tiled == 0 )); then
    if [[ "$state" != "shown" ]]; then show_bar; state="shown"; fi
    sleep "$POLL"; continue
  fi

  read -r cx cy < <(get_cursor_xy)
  top_y="$(get_monitor_top_for_x "$cx")"

  if [[ -n "$top_y" ]]; then
    if (( cy <= top_y + SHOW_ZONE )); then
      if [[ "$state" != "shown" ]]; then show_bar; state="shown"; sleep 0.15; fi
    elif (( cy > top_y + HIDE_ZONE )); then
      if [[ "$state" != "hidden" ]]; then hide_bar; state="hidden"; sleep 0.20; fi
    fi
  fi

  sleep "$POLL"
done
