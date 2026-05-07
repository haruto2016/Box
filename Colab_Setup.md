# WebBox Pro: ネイティブ・クラウドデスクトップ構築ガイド

QEMUを使わず、Colabの巨大なマシンスペック（RAM 12GB）を100%直接使い切る「爆速クラウドPC」を構築します。

## 手順 1: Colab ノートブックの作成
1. [Google Colab](https://colab.research.google.com/) にアクセスし、新しいノートブックを作成します。

## 手順 2: デスクトップ環境の完全インストール
最初のセルに以下のコードを貼り付け、実行します。（数分かかります）
軽量デスクトップ(XFCE)、超高速VNC(KasmVNC)、Chromeブラウザを一括で導入します。

```bash
# セル 1: ネイティブ・デスクトップ環境の構築
!echo "Installing Desktop Environment and Browser..."

# Colabのバックグラウンド更新と競合しないようにロックが解除されるまで待機
!while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do echo "Waiting for apt lock..."; sleep 2; done;

# キーボード設定を自動で「日本語」に選択する設定
!echo "keyboard-configuration keyboard-configuration/layout select Japanese" | sudo debconf-set-selections
!echo "keyboard-configuration keyboard-configuration/variant select Japanese (OADG 109A)" | sudo debconf-set-selections

# KasmVNC (WebRTC対応・超高速VNC) のインストール
!wget -q https://github.com/kasmtech/KasmVNC/releases/download/v1.3.1/kasmvncserver_jammy_1.3.1_amd64.deb
!sudo apt-get update
!DEBIAN_FRONTEND=noninteractive sudo apt-get install -y ./kasmvncserver_jammy_1.3.1_amd64.deb
!sudo apt-get install -y xfce4 xfce4-terminal autocutsel fonts-noto-cjk language-pack-ja yaru-theme-gtk yaru-theme-icon fcitx5-mozc dbus-x11 pulseaudio

# KasmVNCの設定 (ログインなし・自動ログイン設定)
!mkdir -p ~/.vnc
!echo -e "version: 1\n\nnetwork:\n  protocol: http\n  port: 8444\n\n  ssl:\n    require_ssl: false\n\n  udp:\n    public_ip: 127.0.0.1\n\nencoding:\n  encodings:\n    - video\n    - webp\n    - tight\n\nauth:\n  type: none\n\n" > ~/.vnc/kasmvnc.yaml

# Cloudflare Tunnel のインストール（バイナリを直接配置）
!wget -q -nc https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
!chmod +x cloudflared-linux-amd64
!sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared

# 日本語ロケールとIMEの設定
!sudo locale-gen ja_JP.UTF-8
!echo 'export LANG=ja_JP.UTF-8' >> ~/.bashrc
!echo 'export GTK_IM_MODULE=fcitx' >> ~/.bashrc
!echo 'export QT_IM_MODULE=fcitx' >> ~/.bashrc
!echo 'export XMODIFIERS=@im=fcitx' >> ~/.bashrc

# Ubuntu風の見た目に設定
!xfconf-query -c xsettings -p /Net/ThemeName -s "Yaru-dark" --create
!xfconf-query -c xsettings -p /Net/IconThemeName -s "Yaru" --create
!xfconf-query -c xfwm4 -p /general/theme -s "Yaru-dark" --create

# Google Chromeのインストール
!wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
!DEBIAN_FRONTEND=noninteractive sudo apt-get install -y ./google-chrome-stable_current_amd64.deb

# rclone（個人ドライブ接続ツール）のインストール
!sudo apt-get install -y rclone

# rcloneの設定作成 (ここに先ほどの許可証を貼り付けます)
REFRESH_TOKEN = "ここにコピーした許可証（1//...）を貼り付けてください"

import os
os.makedirs(os.path.expanduser("~/.config/rclone"), exist_ok=True)
with open(os.path.expanduser("~/.config/rclone/rclone.conf"), "w") as f:
    f.write(f'[personal_drive]\ntype = drive\nscope = drive\ntoken = {{"refresh_token":"{REFRESH_TOKEN}"}}\n')

!echo "✅ Installation Complete! (Organization Bypass Mode)"
```

## 手順 3: サーバー起動＆データ同期 (Personal Cloud Sync)
次のセルに以下のコードを貼り付けて実行します。
**学校の制限（Google Driveマウント禁止）を回避して、個人のドライブと通信します。**

```python
# セル 2: デスクトップ起動 ＆ 個人ドライブ同期
import time
import os
import re
import threading

IMG_NAME = "webbox_data.img"
LOCAL_PATH = f"/content/{IMG_NAME}"
REMOTE_PATH = f"personal_drive:WebBox_Data/{IMG_NAME}"
MOUNT_POINT = "/mnt/webbox_data"

# 1. 個人ドライブからディスクイメージをダウンロード
print("Connecting to Personal Google Drive...")
if os.system(f"rclone ls {REMOTE_PATH}") == 0:
    print("Found existing data. Downloading...")
    os.system(f"rclone copy {REMOTE_PATH} /content/ -P")
else:
    print("No existing data found. Creating new 2GB disk...")
    os.system(f"truncate -s 2G {LOCAL_PATH}")
    os.system(f"mkfs.ext4 {LOCAL_PATH}")

# 2. ディスクをマウントしてリンク作成
print("Mounting Disk Image...")
os.system(f"mkdir -p {MOUNT_POINT}")
os.system(f"mount -o loop {LOCAL_PATH} {MOUNT_POINT}")

def link_dir(src, dst_name):
    dst = f"{MOUNT_POINT}/{dst_name}"
    os.makedirs(dst, exist_ok=True)
    if os.path.islink(src): os.unlink(src)
    elif os.path.exists(src): os.system(f"rm -rf {src}")
    os.symlink(dst, src)

link_dir("/root/Desktop", "Desktop")
link_dir("/root/.chrome-profile", "chrome-profile")

# 3. バックグラウンドで定期的に個人ドライブへ保存する機能
def auto_backup():
    while True:
        time.sleep(300) # 5分ごとに保存
        print("☁️ Auto-syncing data to Personal Drive...")
        os.system(f"rclone copy {LOCAL_PATH} personal_drive:WebBox_Data/ -P")

threading.Thread(target=auto_backup, daemon=True).start()

# 4. KasmVNCサーバーの起動
print("Starting KasmVNC Server...")
os.system("kasmvncserver -kill :1 > /dev/null 2>&1")
os.system("rm -rf /tmp/.X11-unix/X1 /tmp/.X1-lock cloudflared.log")
os.environ["LANG"] = "ja_JP.UTF-8"

# サーバーをバックグラウンドで起動 (パスワード入力をバイパス)
os.system("nohup kasmvncserver :1 -geometry 1280x720 -depth 24 -select-de xfce --no-password > kasmvnc.log 2>&1 &")

# サーバーが立ち上がるまで少し待機
time.sleep(5)

# IMEとオーディオの起動
os.system("DISPLAY=:1 fcitx5 -d > /dev/null 2>&1")
os.system("pulseaudio --start --exit-idle-time=-1 > /dev/null 2>&1")
os.system("autocutsel -fork")

# クラウドフレアトンネル起動
print("Starting Cloudflare Tunnel...")
os.system("nohup /usr/local/bin/cloudflared tunnel --url http://localhost:8444 > cloudflared.log 2>&1 &")

print("==================================================================")
print("⏳ トンネルのURLを生成中...")
print("==================================================================")

url = ""
for _ in range(20):
    try:
        if os.path.exists("cloudflared.log"):
            with open("cloudflared.log", "r") as f:
                match = re.search(r'https://[-0-9a-z]+\.trycloudflare\.com', f.read())
                if match: url = match.group(0); break
    except: pass
    time.sleep(1)

if url:
    print(f"\n✅ 接続準備完了！\n👉 URL: {url}\n")
    print(f"※ 5分ごとに個人のGoogleドライブに自動保存されます。")
else:
    print("\n❌ URL取得失敗。")

while True:
    time.sleep(60)
```
