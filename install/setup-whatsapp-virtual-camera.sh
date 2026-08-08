#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
files_dir="$script_dir/files/etc"

for package in v4l2loopback-dkms v4l-utils ffmpeg; do
  if ! pacman -Q "$package" >/dev/null 2>&1; then
    lxsudo /usr/bin/pacman -S --needed "$package"
  fi
done

lxsudo /usr/bin/install -Dm644 \
  "$files_dir/modprobe.d/whatsapp-virtual-camera.conf" \
  /etc/modprobe.d/whatsapp-virtual-camera.conf
lxsudo /usr/bin/install -Dm644 \
  "$files_dir/modules-load.d/whatsapp-virtual-camera.conf" \
  /etc/modules-load.d/whatsapp-virtual-camera.conf

systemctl --user daemon-reload
printf '%s\n' 'Configuracao instalada. Reinicie o sistema para aplicar as opcoes do modulo.'
