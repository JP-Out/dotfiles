#!/bin/sh
set -eu

app_class="chrome-web.whatsapp.com__-Default"

hypr_dispatch() {
	hyprctl dispatch "$@" >/dev/null
}

active_info="$(hyprctl activewindow 2>/dev/null || true)"
active_class="$(printf '%s\n' "$active_info" | awk -F': ' '$1 ~ /^[[:space:]]*class$/ { print $2; exit }')"
active_address="$(printf '%s\n' "$active_info" | awk '/^Window / { print $2; exit }')"

case "$active_address" in
	0x*|"") ;;
	*) active_address="0x${active_address}" ;;
esac

if [ "$active_class" = "$app_class" ] && [ -n "$active_address" ] && [ "$active_address" != "0x0" ]; then
	hypr_dispatch movetoworkspacesilent "special:whatsapp,address:${active_address}"
	exit 0
fi

hypr_dispatch killactive
