FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. OS packages
RUN apt-get update && apt-get install -y \
    wget curl openssl ssl-cert x11-utils \
    xfce4 xfce4-terminal \
    fonts-noto-cjk language-pack-ja \
    fcitx5-mozc dbus-x11 pulseaudio pavucontrol sudo rclone \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. KasmVNC (must be root)
RUN wget -q https://github.com/kasmtech/KasmVNC/releases/download/v1.3.1/kasmvncserver_jammy_1.3.1_amd64.deb \
    && apt-get update && apt-get install -y ./kasmvncserver_jammy_1.3.1_amd64.deb \
    && rm kasmvncserver_jammy_1.3.1_amd64.deb \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. Google Chrome (must be root)
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get update && apt-get install -y ./google-chrome-stable_current_amd64.deb \
    && rm google-chrome-stable_current_amd64.deb \
    && sed -i 's|HERE/google-chrome"|HERE/google-chrome" --no-sandbox --disable-gpu --disable-dev-shm-usage --password-store=basic|g' /opt/google/chrome/google-chrome \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 4. Create user AFTER all installs
RUN groupadd kasmvnc && \
    useradd -m -u 1000 -G kasmvnc user

# 5. Copy start script (as root, then chown)
COPY --chown=user:user start.sh /start.sh
RUN chmod +x /start.sh

# 6. Switch to non-root user
ENV HOME=/home/user
WORKDIR /home/user
USER user

EXPOSE 7860

CMD ["/start.sh"]
