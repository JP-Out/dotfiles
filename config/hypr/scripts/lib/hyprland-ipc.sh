#!/bin/sh

# Helpers for Hyprland's Lua IPC. This file is sourced by both POSIX shell and
# Bash scripts, so keep it portable.

hypr_lua_quote() {
    command -v jq >/dev/null 2>&1 || {
        echo "Faltando dependência: jq" >&2
        return 1
    }
    printf '%s' "$1" | jq -Rs .
}

hypr_address_selector() {
    case "$1" in
        0x*) address_hex=${1#0x} ;;
        *)
            echo "Endereço de janela inválido: $1" >&2
            return 2
            ;;
    esac

    case "$address_hex" in
        ""|*[!0-9a-fA-F]*)
            echo "Endereço de janela inválido: $1" >&2
            return 2
            ;;
        *) hypr_lua_quote "address:$1" ;;
    esac
}

hypr_dispatch() {
    hyprctl dispatch "$1"
}

hypr_eval() (
    attempt=1
    while [ "$attempt" -le 3 ]; do
        if output=$(hyprctl eval "$1" 2>&1); then
            printf '%s\n' "$output"
            exit 0
        fi

        if [ "$attempt" -eq 3 ]; then
            printf '%s\n' "$output" >&2
            exit 1
        fi

        attempt=$((attempt + 1))
        sleep 0.05
    done
)

hypr_set_gaps() {
    [ "$#" -eq 4 ] || {
        echo "hypr_set_gaps exige quatro valores." >&2
        return 2
    }

    for gap in "$@"; do
        case "$gap" in
            ""|*[!0-9]*)
                echo "Margens inválidas: $*" >&2
                return 2
                ;;
        esac
    done

    hypr_eval "hl.config({ general = { gaps_out = { top = $1, right = $2, bottom = $3, left = $4 } } })"
}
