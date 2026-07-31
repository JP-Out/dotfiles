#!/usr/bin/env bash
set -euo pipefail

WINDOW_TITLE_PREFIX="Hypr RTSP Stream"
WINDOW_CLASS="hypr-rtsp-stream"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/hyprland-ipc.sh
source "$SCRIPT_DIR/lib/hyprland-ipc.sh"

usage() {
    echo "Uso: $(basename "$0") X Y" >&2
}

need() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Faltando dependência: $1" >&2
        exit 1
    }
}

main() {
    local x="${1:-}"
    local y="${2:-}"
    local active address class title

    if [[ -z "$x" || -z "$y" ]]; then
        usage
        exit 2
    fi

    [[ "$x" =~ ^-?[0-9]+$ && "$y" =~ ^-?[0-9]+$ ]] || {
        echo "X e Y precisam ser números inteiros." >&2
        exit 2
    }

    need hyprctl
    need jq

    active="$(hyprctl -j activewindow 2>/dev/null || true)"
    [[ -n "$active" && "$active" != "{}" ]] || exit 0

    IFS=$'\t' read -r address class title < <(
        jq -r '
            [
                (.address // ""),
                (.class // ""),
                (.title // "")
            ] | @tsv
        ' <<< "$active"
    )

    if [[ "$class" != "$WINDOW_CLASS" && "$title" != "$WINDOW_TITLE_PREFIX"* ]]; then
        exit 0
    fi

    [[ -n "$address" ]] || exit 0
    local selector
    selector="$(hypr_address_selector "$address")"
    hypr_dispatch "hl.dsp.window.float({ action = \"on\", window = $selector })" >/dev/null
    hypr_dispatch "hl.dsp.window.move({ x = $x, y = $y, window = $selector })" >/dev/null
}

main "$@"
