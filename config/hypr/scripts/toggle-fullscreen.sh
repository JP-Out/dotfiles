#!/usr/bin/env bash
set -euo pipefail

WINDOW_TITLE_PREFIX="Hypr RTSP Stream"
WINDOW_CLASS="hypr-rtsp-stream"
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/hypr-rtsp-stream"
STATE_FILE="$STATE_DIR/fullscreen-pinned-address"

default_fullscreen() {
    hyprctl dispatch fullscreen
}

active_window() {
    hyprctl -j activewindow 2>/dev/null
}

main() {
    local active address class title pinned fullscreen saved_address

    active="$(active_window || true)"
    if [[ -z "$active" || "$active" == "{}" ]]; then
        default_fullscreen
        return
    fi

    IFS=$'\t' read -r address class title pinned fullscreen < <(
        jq -r '
            [
                (.address // ""),
                (.class // ""),
                (.title // ""),
                (.pinned // false | tostring),
                (.fullscreen // 0 | tostring)
            ] | @tsv
        ' <<< "$active"
    )

    if [[ "$class" != "$WINDOW_CLASS" && "$title" != "$WINDOW_TITLE_PREFIX"* ]]; then
        default_fullscreen
        return
    fi

    saved_address=""
    [[ -f "$STATE_FILE" ]] && saved_address="$(cat "$STATE_FILE")"

    if [[ "$fullscreen" != "0" && "$saved_address" == "$address" ]]; then
        hyprctl dispatch fullscreen
        sleep 0.05
        hyprctl dispatch pin address:"$address" >/dev/null
        rm -f "$STATE_FILE"
        return
    fi

    if [[ "$pinned" == "true" ]]; then
        mkdir -p "$STATE_DIR"
        printf '%s\n' "$address" > "$STATE_FILE"
        hyprctl dispatch pin address:"$address" >/dev/null
        sleep 0.05
        hyprctl dispatch fullscreen
        return
    fi

    default_fullscreen
}

main "$@"
