#!/bin/bash
echo "===== WebBox on Hugging Face Spaces ====="
date
echo "User: $(whoami) | HOME: $HOME"

# ---- 1. SSL certificate ----
mkdir -p "$HOME/.vnc"
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$HOME/.vnc/self.key" \
    -out "$HOME/.vnc/self.cert" \
    -subj "/CN=localhost" 2>/dev/null
echo "[OK] SSL certificate"

# ---- 2. Cleanup stale locks ----
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true
rm -rf "$HOME/.kasmpasswd" 2>/dev/null || true

# ---- 3. Environment ----
export DISPLAY=:1
export LANG=ja_JP.UTF-8
export XDG_RUNTIME_DIR=/tmp/runtime-user
mkdir -p "$XDG_RUNTIME_DIR"

# ---- 4. Create KasmVNC User ----
printf "password\npassword\n" | kasmvncpasswd -u user -w
echo "[OK] Created KasmVNC user 'user' with default config"

# ---- 5. KasmVNC Config ----
cat > "$HOME/.vnc/kasmvnc.yaml" <<'YAML'
network:
  protocol: http
  interface: 0.0.0.0
  websocket_port: 7860
  ssl:
    require_ssl: false
    pem_certificate: /home/user/.vnc/self.cert
    pem_key: /home/user/.vnc/self.key
desktop:
  resolution:
    width: 1280
    height: 720
  allow_resize: true
YAML
echo "[OK] KasmVNC config"

# ---- 5.5. Disabling Screensaver & Setting up Japanese IME/Audio ----
mkdir -p "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml"

cat > "$HOME/.xsessionrc" <<EOL
# Screensaver and Power Management Disable
xfconf-query -c xfce4-screensaver -p /saver/enabled -n -t bool -s false 2>/dev/null || true
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -n -t int -s 0 2>/dev/null || true

export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
fcitx5 -d &
pulseaudio --start --exit-idle-time=-1 &
EOL

# ---- 5.6. Create Desktop Shortcuts ----
mkdir -p "$HOME/Desktop"
cat > "$HOME/Desktop/google-chrome.desktop" <<EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=Google Chrome
Comment=Access the Internet
Exec=/usr/bin/google-chrome --no-sandbox --disable-gpu --disable-dev-shm-usage --password-store=basic %U
Icon=google-chrome
Path=
Terminal=false
StartupNotify=true
Categories=Network;WebBrowser;
EOL
chmod +x "$HOME/Desktop/google-chrome.desktop"

# ---- 6. Start KasmVNC using the wrapper ----
echo "[START] Launching KasmVNC on :1 port 7860 ..."

exec kasmvncserver :1 \
    -geometry 1280x720 \
    -depth 24 \
    -websocketPort 7860 \
    -interface 0.0.0.0 \
    -cert "$HOME/.vnc/self.cert" \
    -key "$HOME/.vnc/self.key" \
    -select-de xfce \
    -fg
