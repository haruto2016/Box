#!/bin/bash

echo "===== WebBox Codespace Setup (Fixed) ====="

# 1. 質問をスキップしてインストール
export DEBIAN_FRONTEND=noninteractive

echo "[1/4] Installing Desktop Environment (XFCE4)..."
sudo apt-get update
sudo apt-get install -y xfce4 xfce4-terminal dbus-x11 fonts-noto-cjk language-pack-ja fcitx5-mozc x11-utils ssl-cert

echo "[2/4] Installing KasmVNC..."
wget -q https://github.com/kasmtech/KasmVNC/releases/download/v1.3.1/kasmvncserver_jammy_1.3.1_amd64.deb
sudo apt-get install -y ./kasmvncserver_jammy_1.3.1_amd64.deb
rm kasmvncserver_jammy_1.3.1_amd64.deb

echo "[3/4] Generating SSL Certificate..."
mkdir -p "$HOME/.vnc"
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$HOME/.vnc/self.key" \
    -out "$HOME/.vnc/self.cert" \
    -subj "/CN=localhost" 2>/dev/null

# 設定ファイルの作成
cat > "$HOME/.vnc/kasmvnc.yaml" <<YAML
network:
  protocol: http
  interface: 0.0.0.0
  websocket_port: 8444
  ssl:
    require_ssl: false
    pem_certificate: $HOME/.vnc/self.cert
    pem_key: $HOME/.vnc/self.key
YAML

echo "[4/4] Configuring User and Password..."
# user: $(whoami), password: password
printf "password\npassword\n" | kasmvncpasswd -u $(whoami) -w

echo "===== Setup Complete! ====="
echo "To start the desktop, run:"
echo "kasmvncserver :1 -select-de xfce -disableBasicAuth -websocketPort 8444 -cert $HOME/.vnc/self.cert -key $HOME/.vnc/self.key"
