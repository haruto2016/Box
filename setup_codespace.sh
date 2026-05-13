#!/bin/bash

echo "===== WebBox Codespace Setup ====="
sudo apt update

echo "[1/4] Installing Desktop Environment (XFCE4)..."
sudo apt install -y xfce4 xfce4-terminal dbus-x11 fonts-noto-cjk language-pack-ja fcitx5-mozc x11-utils

echo "[2/4] Installing KasmVNC..."
wget -q https://github.com/kasmtech/KasmVNC/releases/download/v1.3.1/kasmvncserver_jammy_1.3.1_amd64.deb
sudo apt install -y ./kasmvncserver_jammy_1.3.1_amd64.deb
rm kasmvncserver_jammy_1.3.1_amd64.deb

echo "[3/4] Installing Google Chrome..."
wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -y ./google-chrome-stable_current_amd64.deb
rm google-chrome-stable_current_amd64.deb

echo "[4/4] Configuring User and Password..."
# user: codespace (or current user), password: password
printf "password\npassword\n" | kasmvncpasswd -u $(whoami) -w

echo "===== Setup Complete! ====="
echo "To start the desktop, run:"
echo "kasmvncserver :1 -select-de xfce -disableBasicAuth -websocketPort 8444"
