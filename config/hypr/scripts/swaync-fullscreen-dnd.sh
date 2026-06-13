#!/usr/bin/env bash
set -Eeuo pipefail

POLL_INTERVAL="${SWAYNC_FULLSCREEN_DND_POLL_INTERVAL:-1}"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-}"

if [[ -n "$RUNTIME_DIR" && -d "$RUNTIME_DIR" && -w "$RUNTIME_DIR" ]]; then
	STATE_DIR="$RUNTIME_DIR"
else
	STATE_DIR="/tmp"
fi

LOCK_FILE="$STATE_DIR/swaync-fullscreen-dnd.lock"
OWNED_FILE="$STATE_DIR/swaync-fullscreen-dnd.owned"

need() {
	command -v "$1" >/dev/null || {
		echo "Faltando $1" >&2
		exit 1
	}
}

need flock
need hyprctl
need jq
need ncat
need swaync-client
need timeout

exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

get_dnd() {
	local out

	out="$(timeout 2 swaync-client --get-dnd 2>/dev/null || true)"
	case "$out" in
		true|True|TRUE|1)
			printf 'on\n'
			;;
		false|False|FALSE|0)
			printf 'off\n'
			;;
		*)
			return 1
			;;
	esac
}

set_dnd() {
	case "$1" in
		on)
			timeout 2 swaync-client --dnd-on >/dev/null 2>&1 || true
			;;
		off)
			timeout 2 swaync-client --dnd-off >/dev/null 2>&1 || true
			;;
	esac
}

clients_json() {
	local hypr_socket

	hypr_socket="${XDG_RUNTIME_DIR:-}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket.sock"
	if [[ -S "$hypr_socket" ]]; then
		printf 'j/clients' | timeout 2 ncat -U "$hypr_socket"
		return
	fi

	timeout 2 hyprctl -j clients
}

has_fullscreen_window() {
	clients_json 2>/dev/null | jq -e '
		any(.[]?;
			(.mapped == true)
			and (
				((.fullscreen // 0) | tonumber) != 0
				or ((.fullscreenClient // 0) | tonumber) != 0
			)
		)
	' >/dev/null
}

mark_owned() {
	printf '%s\n' "$1" >"$OWNED_FILE"
}

is_owned() {
	[[ -f "$OWNED_FILE" ]] && [[ "$(cat "$OWNED_FILE")" == "1" ]]
}

fullscreen_active=unknown

while :; do
	if has_fullscreen_window; then
		if [[ "$fullscreen_active" != "yes" ]]; then
			if [[ "$(get_dnd || printf unknown)" == "off" ]]; then
				set_dnd on
				mark_owned 1
			else
				mark_owned 0
			fi
			fullscreen_active=yes
		fi
	else
		if [[ "$fullscreen_active" != "no" ]]; then
			if is_owned; then
				set_dnd off
			fi
			mark_owned 0
			fullscreen_active=no
		fi
	fi

	sleep "$POLL_INTERVAL"
done
