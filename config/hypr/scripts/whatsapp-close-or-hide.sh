#!/bin/sh
set -eu

app_class="chrome-web.whatsapp.com__-Default"
helper="$HOME/.config/hypr/scripts/lib/hyprland-ipc.sh"
[ -r "$helper" ] || { echo "Helper do Hyprland não encontrado: $helper" >&2; exit 1; }
# shellcheck source=lib/hyprland-ipc.sh
. "$helper"

active_info="$(hyprctl -j activewindow 2>/dev/null || printf '{}')"
active_class="$(printf '%s' "$active_info" | jq -r '.class // empty')"
active_address="$(printf '%s' "$active_info" | jq -r '.address // empty')"

if [ "$active_class" = "$app_class" ] && [ -n "$active_address" ] && [ "$active_address" != "0x0" ]; then
	selector="$(hypr_address_selector "$active_address")"
	hypr_dispatch "hl.dsp.window.move({ workspace = \"special:whatsapp\", follow = false, window = $selector })" >/dev/null
	exit 0
fi

hypr_dispatch 'hl.dsp.window.close()' >/dev/null
