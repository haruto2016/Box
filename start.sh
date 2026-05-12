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

# ---- 3. Find Xvnc binary (bypass kasmvncserver wrapper) ----
XVNC=""
for p in /usr/share/kasmvnc/bin/Xvnc /usr/bin/Xvnc /usr/local/bin/Xvnc; do
    if [ -x "$p" ]; then
        XVNC="$p"
        break
    fi
done
if [ -z "$XVNC" ]; then
    XVNC=$(find / -name "Xvnc" -type f 2>/dev/null | head -1)
fi
echo "[INFO] Xvnc binary: $XVNC"

if [ -z "$XVNC" ]; then
    echo "[FATAL] Xvnc binary not found!"
    exit 1
fi

# ---- 4. Find web client directory ----
WWWDIR=""
for d in /usr/share/kasmvnc/www /usr/share/www /usr/local/share/kasmvnc/www; do
    if [ -d "$d" ]; then
        WWWDIR="$d"
        break
    fi
done
echo "[INFO] Web dir: $WWWDIR"

# ---- 5. Environment ----
export DISPLAY=:1
export LANG=ja_JP.UTF-8
export XDG_RUNTIME_DIR=/tmp/runtime-user
mkdir -p "$XDG_RUNTIME_DIR"

# ---- 6. Start Xvnc directly (NO wrapper, NO auth prompt) ----
echo "[START] Launching Xvnc on :1 port 7860 ..."
XVNC_ARGS=(
    :1
    -geometry 1280x720
    -depth 24
    -websocketPort 7860
    -interface 0.0.0.0
    -SecurityTypes None
    -AlwaysShared
)

# Add web directory if found
if [ -n "$WWWDIR" ]; then
    XVNC_ARGS+=(-httpd "$WWWDIR")
fi

# Add SSL if certs exist
if [ -f "$HOME/.vnc/self.cert" ] && [ -f "$HOME/.vnc/self.key" ]; then
    XVNC_ARGS+=(
        -cert "$HOME/.vnc/self.cert"
        -key "$HOME/.vnc/self.key"
    )
fi

"$XVNC" "${XVNC_ARGS[@]}" &
XVNC_PID=$!
echo "[OK] Xvnc started (PID $XVNC_PID)"

# ---- 7. Wait for X server to be ready ----
for i in $(seq 1 15); do
    if xdpyinfo -display :1 >/dev/null 2>&1; then
        echo "[OK] X server ready"
        break
    fi
    echo "[WAIT] X server not ready yet ($i/15)..."
    sleep 1
done

# ---- 8. Start XFCE desktop ----
echo "[START] Launching XFCE4 session..."
startxfce4 &
XFCE_PID=$!
echo "[OK] XFCE started (PID $XFCE_PID)"

echo "===== WebBox is running ====="
echo "  VNC:  ws://0.0.0.0:7860"
echo "  Display: $DISPLAY"
echo "============================="

# ---- 9. Keep container alive ----
wait $XVNC_PID
