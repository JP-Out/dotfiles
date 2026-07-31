#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/hyprland-ipc.sh
source "$SCRIPT_DIR/lib/hyprland-ipc.sh"

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/waybar"
MODE_FILE="$STATE_DIR/mode"
MANUAL_FILE="$STATE_DIR/manual_state"
mkdir -p "$STATE_DIR"

# Sempre entra em modo manual ao usar este toggle
echo "manual" > "$MODE_FILE"

current_state="hidden"
[[ -f "$MANUAL_FILE" ]] && current_state="$(cat "$MANUAL_FILE")"

if [[ "$current_state" == "shown" ]]; then
  pkill -SIGUSR2 waybar || true
  hypr_set_gaps 10 10 10 10 >/dev/null
  echo "hidden" > "$MANUAL_FILE"
else
  pkill -SIGUSR1 waybar || true
  hypr_set_gaps 3 10 10 10 >/dev/null
  echo "shown" > "$MANUAL_FILE"
fi
