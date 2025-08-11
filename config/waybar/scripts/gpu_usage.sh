#!/bin/bash

ICON="󰘚"

LINE=$(radeontop -d - -l 1 2>/dev/null | sed -n '2p')
GPU=$(echo "$LINE" | grep -o "gpu [0-9.]*%" | awk '{printf("%.0f%%",$2)}')

# Ícone maior com alinhamento usando rise
echo "<span size='18000' rise='-3000'>$ICON</span> $GPU"
