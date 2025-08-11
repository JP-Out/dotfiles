#!/usr/bin/env bash

PLAYER="spotify"
STEP=0.05  # 5% por scroll

get_volume() {
    playerctl --player=$PLAYER volume 2>/dev/null || echo 0
}

set_volume() {
    local vol=$1
    # Limita entre 0 e 1
    awk -v v="$vol" 'BEGIN {
        if (v < 0) v = 0;
        if (v > 1) v = 1;
        print v;
    }' | xargs playerctl --player=$PLAYER volume
}

current=$(get_volume)

case "$1" in
    up)
        new=$(awk -v c="$current" -v s="$STEP" 'BEGIN{print c+s}')
        set_volume "$new"
        ;;
    down)
        new=$(awk -v c="$current" -v s="$STEP" 'BEGIN{print c-s}')
        set_volume "$new"
        ;;
    reset)
        set_volume 0.5
        ;;
    *)
        echo "Uso: $0 {up|down|reset}"
        ;;
esac
