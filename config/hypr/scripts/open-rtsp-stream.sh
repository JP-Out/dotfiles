#!/usr/bin/env bash
set -euo pipefail

WINDOW_TITLE_PREFIX="Hypr RTSP Stream"
WINDOW_CLASS="hypr-rtsp-stream"
WINDOW_X=12
WINDOW_Y=840
WINDOW_WIDTH=405
WINDOW_HEIGHT=230

usage() {
    echo "Uso: $(basename "$0") sticky|normal" >&2
}

need() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Faltando dependência: $1" >&2
        exit 1
    }
}

need_hyprland() {
    hyprctl -j monitors >/dev/null 2>&1 || {
        echo "Não foi possível conectar ao Hyprland via hyprctl." >&2
        exit 1
    }
}

load_env() {
    local env_file="$HOME/.dotfiles/.env.local"
    [[ -f "$env_file" ]] || return 0

    set -a
    # shellcheck disable=SC1090
    source "$env_file"
    set +a
}

stream_url() {
    local url host user password port path

    url="${HYPR_RTSP_URL:-${RTSP_STREAM_URL:-${CAMERA_RTSP_URL:-}}}"
    if [[ -n "$url" ]]; then
        printf '%s\n' "$url"
        return 0
    fi

    host="${HYPR_RTSP_HOST:-${RTSP_HOST:-${IP_CAMERA:-${CAMERA_IP:-${CAMERA_HOST:-}}}}}"
    user="${HYPR_RTSP_USER:-${RTSP_USER:-camshell}}"
    password="${HYPR_RTSP_PASSWORD:-${RTSP_PASSWORD:-${CAMERA_PASSWORD:-}}}"
    port="${HYPR_RTSP_PORT:-${RTSP_PORT:-554}}"
    path="${HYPR_RTSP_PATH:-${RTSP_PATH:-stream1}}"

    if [[ -z "$host" || -z "$password" ]]; then
        echo "Configure HYPR_RTSP_URL ou IP_CAMERA/CAMERA_PASSWORD no .env.local." >&2
        exit 1
    fi

    printf 'rtsp://%s:%s@%s:%s/%s\n' "$user" "$password" "$host" "$port" "$path"
}

rtsp_window_rows() {
    local normal_only="${1:-false}"

    hyprctl -j clients | jq -r \
        --arg class "$WINDOW_CLASS" \
        --arg prefix "$WINDOW_TITLE_PREFIX" \
        --argjson normal_only "$normal_only" '
        [
            .[]
            | select(
                (.class // "") == $class
                or ((.title // "") | startswith($prefix))
            )
            | select(($normal_only | not) or ((.pinned // false) == false))
            | {
                address,
                pid,
                focus: (.focusHistoryID // 999999)
            }
        ]
        | sort_by(.focus)
        | reverse
        | .[]
        | [.address, (.pid | tostring)]
        | @tsv
    '
}

close_rtsp_window() {
    local address="$1"
    local pid="$2"

    hyprctl dispatch closewindow address:"$address" >/dev/null 2>&1 || true
    sleep 0.1
    kill "$pid" >/dev/null 2>&1 || true
}

close_all_rtsp_windows() {
    local address pid

    while IFS=$'\t' read -r address pid; do
        [[ -n "${address:-}" ]] || continue
        close_rtsp_window "$address" "$pid"
    done < <(rtsp_window_rows false)
}

limit_normal_rtsp_windows() {
    local address pid excess i
    local rows=()

    mapfile -t rows < <(rtsp_window_rows true)
    excess=$((${#rows[@]} - 2))
    (( excess > 0 )) || return 0

    for ((i = 0; i < excess; i++)); do
        IFS=$'\t' read -r address pid <<< "${rows[$i]}"
        [[ -n "${address:-}" ]] || continue
        close_rtsp_window "$address" "$pid"
    done
}

find_window_address() {
    local mpv_pid="$1"
    local window_title="$2"

    hyprctl -j clients | jq -r \
        --argjson pid "$mpv_pid" \
        --arg title "$window_title" '
        first(.[] | select(
            .pid == $pid
            or .title == $title
        ) | .address) // empty
    '
}

apply_window_properties() {
    local address="$1"
    local mode="$2"

    hyprctl --batch "\
dispatch focuswindow address:$address; \
dispatch setfloating address:$address; \
dispatch resizewindowpixel exact ${WINDOW_WIDTH} ${WINDOW_HEIGHT},address:$address; \
dispatch movewindowpixel exact ${WINDOW_X} ${WINDOW_Y},address:$address; \
"

    if [[ "$mode" == "sticky" ]]; then
        hyprctl dispatch pin address:"$address" >/dev/null
    fi
}

main() {
    local mode="${1:-}"
    case "$mode" in
        sticky|normal) ;;
        *) usage; exit 2 ;;
    esac

    need hyprctl
    need jq
    need mpv
    need_hyprland
    load_env

    if [[ "$mode" == "sticky" ]]; then
        close_all_rtsp_windows
    else
        limit_normal_rtsp_windows
    fi

    local window_title="${WINDOW_TITLE_PREFIX} ($$)"
    local stream
    stream="$(stream_url)"

    mpv \
        --demuxer-lavf-o=rtsp_transport=tcp \
        --cache=yes \
        --cache-pause=no \
        --demuxer-readahead-secs=5 \
        --demuxer-max-bytes=64MiB \
        --force-window=immediate \
        --video-sync=display-resample \
        --mute=yes \
        --title="$window_title" \
        --wayland-app-id="$WINDOW_CLASS" \
        "$stream" >/tmp/hypr-rtsp-stream.log 2>&1 &

    local mpv_pid="$!"
    local address=""

    for _ in {1..100}; do
        address="$(find_window_address "$mpv_pid" "$window_title")"
        [[ -n "$address" && "$address" != "null" ]] && break
        sleep 0.05
    done

    if [[ -z "$address" || "$address" == "null" ]]; then
        kill "$mpv_pid" 2>/dev/null || true
        echo "Não foi possível localizar a janela do mpv." >&2
        exit 1
    fi

    apply_window_properties "$address" "$mode"
}

main "$@"
