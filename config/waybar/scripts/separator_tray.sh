#!/usr/bin/env bash

set -euo pipefail

if command -v busctl >/dev/null 2>&1; then
    ITEMS=$(
        busctl --user get-property \
            org.kde.StatusNotifierWatcher \
            /StatusNotifierWatcher \
            org.kde.StatusNotifierWatcher \
            RegisteredStatusNotifierItems 2>/dev/null \
        | awk '{ print $2 }'
    )

    if [[ "${ITEMS:-0}" =~ ^[0-9]+$ ]] && (( ITEMS > 0 )); then
        echo "│"
        exit 0
    fi
fi

# Fallback para sessões onde o watcher DBus ainda não respondeu.
if pgrep -f 'discord|steam|steamwebhelper|telegram-desktop|nm-applet|blueman-applet|obs|keybase-gui|nextcloud|copyq|zapzap' >/dev/null 2>&1; then
    echo "│"
else
    echo ""
fi
