#!/bin/bash

echo "===== WebBox Codespace Ultimate Setup ====="

# 1. 自動化設定（質問をスキップ）
export DEBIAN_FRONTEND=noninteractive

echo "[1/7] Installing Desktop & Japanese Environment..."
sudo apt-get update
sudo apt-get install -y xfce4 xfce4-terminal dbus-x11 fonts-noto-cjk fonts-ipafont fonts-ipaexfont \
    language-pack-ja fcitx5-mozc x11-utils ssl-cert pulseaudio pavucontrol wget curl

echo "[2/7] Installing KasmVNC..."
wget -q https://github.com/kasmtech/KasmVNC/releases/download/v1.3.1/kasmvncserver_jammy_1.3.1_amd64.deb
sudo apt-get install -y ./kasmvncserver_jammy_1.3.1_amd64.deb
rm kasmvncserver_jammy_1.3.1_amd64.deb

echo "[3/7] Installing & Patching Google Chrome..."
wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt-get install -y ./google-chrome-stable_current_amd64.deb
rm google-chrome-stable_current_amd64.deb
# Chromeのサンドボックス/共有メモリバグを修正
sudo sed -i 's|HERE/google-chrome"|HERE/google-chrome" --no-sandbox --disable-gpu --disable-dev-shm-usage --password-store=basic|g' /opt/google/chrome/google-chrome

echo "[4/7] Configuring SSL and KasmVNC..."
mkdir -p "$HOME/.vnc"
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$HOME/.vnc/self.key" \
    -out "$HOME/.vnc/self.cert" \
    -subj "/CN=localhost" 2>/dev/null

cat > "$HOME/.vnc/kasmvnc.yaml" <<YAML
network:
  protocol: http
  interface: 0.0.0.0
  websocket_port: 8444
  ssl:
    require_ssl: false
    pem_certificate: $HOME/.vnc/self.cert
    pem_key: $HOME/.vnc/self.key
desktop:
  resolution:
    width: 1280
    height: 720
  allow_resize: true
YAML

echo "[5/7] Disabling Screensaver and Power Management..."
# XFCEのスリープ/ログオフ対策
mkdir -p "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml"
xfconf-query -c xfce4-screensaver -p /saver/enabled -n -t bool -s false 2>/dev/null || true
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -n -t int -s 0 2>/dev/null || true
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-on-ac-sleep -n -t int -s 0 2>/dev/null || true

echo "[6/7] Setting up Japanese IME (Mozc)..."
# 日本語入力の自動起動設定
cat > "$HOME/.xsessionrc" <<EOL
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
fcitx5 -d &
pulseaudio --start --exit-idle-time=-1 &
EOL

echo "[7/7] Configuring User and Password..."
printf "password\npassword\n" | kasmvncpasswd -u $(whoami) -w

echo "===== All Setup Complete! ====="
echo "Run this command to start the desktop:"
echo "kasmvncserver :1 -select-de xfce -disableBasicAuth -websocketPort 8444 -cert $HOME/.vnc/self.cert -key $HOME/.vnc/self.key"
