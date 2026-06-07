#!/bin/sh
set -eu

app_class="chrome-web.whatsapp.com__-Default"
runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
socket="${runtime_dir}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket.sock"

clients_json() {
	if [ -S "$socket" ] && command -v nc >/dev/null 2>&1; then
		printf 'j/clients' | nc -U "$socket" 2>/dev/null || printf '[]'
	else
		printf '[]'
	fi
}

client_json() {
	clients_json | jq -c --arg cls "$app_class" 'map(select(.class == $cls))[0] // empty'
}

client_address() {
	client_json | jq -r '.address // empty'
}

client_workspace() {
	client_json | jq -r '.workspace.name // empty'
}

case "${1:-}" in
	open)
		exec "$HOME/.local/bin/whatsapp-web-chromium"
		;;
	hide)
		workspace="$(client_workspace)"
		address="$(client_address)"
		if [ -n "$address" ] && [ "$workspace" != "special:whatsapp" ]; then
			hyprctl dispatch movetoworkspacesilent "special:whatsapp,address:${address}" >/dev/null
		fi
		;;
	quit)
		address="$(client_address)"
		if [ -n "$address" ]; then
			hyprctl dispatch closewindow "address:${address}" >/dev/null || true
		fi
		;;
	*)
		exit 2
		;;
esac
