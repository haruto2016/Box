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

# ---- 3. Environment ----
export DISPLAY=:1
export LANG=ja_JP.UTF-8
export XDG_RUNTIME_DIR=/tmp/runtime-user
mkdir -p "$XDG_RUNTIME_DIR"

# ---- 4. Start KasmVNC using the wrapper, passing "2" to bypass the user prompt ----
echo "[START] Launching KasmVNC on :1 port 7860 ..."

# 1の代わりに2を入力することで「権限ユーザーなし（=認証なし）」を選択
echo "2" | kasmvncserver :1 \
    -geometry 1280x720 \
    -depth 24 \
    -websocketPort 7860 \
    -interface 0.0.0.0 \
    -disableBasicAuth \
    -select-de xfce \
    -fg
