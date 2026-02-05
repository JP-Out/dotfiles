#!/usr/bin/env bash
# float-once.sh CLASS WIDTH HEIGHT [X Y]
# Ex: float-once.sh org.kde.kdenlive 900 700
# Ex: float-once.sh com.github.hluk.copyq 300 400 80% 60%

CLASS="$1"
W="$2"
H="$3"
X="${4:-center}"
Y="${5:-center}"

# espera a janela aparecer
for i in {1..80}; do
  addr="$(hyprctl -j clients | jq -r --arg c "$CLASS" '.[] | select(.class==$c) | .address' | head -n1)"
  [[ -n "$addr" && "$addr" != "null" ]] && break
  sleep 0.05
done

[[ -z "$addr" || "$addr" == "null" ]] && exit 1

# aplica regras na marra
hyprctl --batch "\
dispatch focuswindow address:$addr; \
dispatch setfloating address:$addr; \
dispatch resizewindowpixel exact $W $H,address:$addr; \
"

if [[ "$X" == "center" ]]; then
  hyprctl dispatch centerwindow address:"$addr"
else
  hyprctl dispatch movewindowpixel exact "$X" "$Y",address:"$addr"
fi
