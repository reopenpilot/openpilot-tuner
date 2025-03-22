#!/bin/bash
#
# bash <(curl -fsSL https://raw.githubusercontent.com/reopenpilot/openpilot-tuner/install-tailscale.sh)
#

set -e

echo "🔧 Remounting / as rw..."
sudo mount -o remount,rw /

echo "🌐 Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

echo "⛔ Stopping tailscaled service..."
sudo systemctl stop tailscaled

echo "🔧 Remounting / as rw again..."
sudo mount -o remount,rw /

echo "✏️ Updating tailscaled.service to use /persist/var/lib/tailscale..."
sudo sed -i 's|/var/lib/tailscale|/persist/var/lib/tailscale|g' /lib/systemd/system/tailscaled.service

echo "🔄 Reloading systemd..."
sudo systemctl daemon-reload

echo "🔧 Remounting /persist as rw..."
sudo mount -o remount,rw /persist

echo "📁 Creating /persist/var/lib/tailscale directory..."
sudo mkdir -p /persist/var/lib/tailscale

echo "▶️ Starting tailscaled service..."
sudo systemctl start tailscaled

echo "⬆️ Bringing Tailscale up..."
sudo tailscale up

echo "⌨️ Press any key to continue..."
read -n 1 -s -r -p ""

echo "🔁 Rebooting system..."
sudo reboot
