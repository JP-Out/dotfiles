#!/bin/sh
set -eu

app_class="chrome-web.whatsapp.com__-Default"
runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
socket="${runtime_dir}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket.sock"

if [ ! -S "$socket" ] || ! command -v nc >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
	printf '{"text":"WA","tooltip":"WhatsApp","class":"inactive"}\n'
	exit 0
fi

clients_json="$(printf 'j/clients' | nc -U "$socket" 2>/dev/null || printf '[]')"
client_json="$(printf '%s' "$clients_json" | jq -c --arg cls "$app_class" 'map(select(.class == $cls))[0] // empty')"

if [ -z "$client_json" ]; then
	printf '{"text":"","tooltip":"WhatsApp fechado","class":"closed"}\n'
	exit 0
fi

workspace="$(printf '%s' "$client_json" | jq -r '.workspace.name // ""')"

if [ "$workspace" = "special:whatsapp" ]; then
	printf '{"text":"󰖣","tooltip":"WhatsApp oculto","class":"hidden"}\n'
else
	printf '{"text":"󰖣","tooltip":"WhatsApp aberto","class":"active"}\n'
fi
