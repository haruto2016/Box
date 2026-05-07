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

# 永続化用フォルダの準備
!mkdir -p /root/Desktop
!mkdir -p /root/.chrome-profile
!mkdir -p /mnt/webbox_data

!echo "✅ Installation Complete! (Disk Image Persistence Mode)"
```

## 手順 3: サーバー起動＆トンネル開通 (Disk Image & Persistent)
次のセルに以下のコードを貼り付けて実行します。
**実行時にGoogleドライブのマウント許可を求められるので、承認してください。**

```python
# セル 2: デスクトップストリーミングの開始 (Disk Image Mode)
import time
import os
import re
from google.colab import drive

# 1. Googleドライブをマウント
print("Mounting Google Drive...")
drive.mount('/content/drive')
IMG_PATH = "/content/drive/MyDrive/webbox_data.img"
MOUNT_POINT = "/mnt/webbox_data"

# 2. ディスクイメージ（2GB）の作成とマウント
if not os.path.exists(IMG_PATH):
    print("Creating new 2GB Disk Image (This may take a minute)...")
    os.system(f"truncate -s 2G {IMG_PATH}")
    os.system(f"mkfs.ext4 {IMG_PATH}")

print("Mounting Disk Image...")
os.system(f"mkdir -p {MOUNT_POINT}")
os.system(f"mount -o loop {IMG_PATH} {MOUNT_POINT}")

# 3. データのシンボリックリンク作成（実体はディスクイメージ内）
def link_dir(src, dst_name):
    dst = f"{MOUNT_POINT}/{dst_name}"
    os.makedirs(dst, exist_ok=True)
    if os.path.islink(src): os.unlink(src)
    elif os.path.exists(src): os.system(f"rm -rf {src}")
    os.symlink(dst, src)

link_dir("/root/Desktop", "Desktop")
link_dir("/root/.chrome-profile", "chrome-profile")

# Chromeショートカットの再作成
os.system(f'echo -e "[Desktop Entry]\\nVersion=1.0\\nType=Application\\nName=Google Chrome\\nExec=/usr/bin/google-chrome-stable --no-sandbox --user-data-dir=/root/.chrome-profile\\nIcon=google-chrome\\nTerminal=false" > /root/Desktop/google-chrome.desktop')
os.system("chmod +x /root/Desktop/google-chrome.desktop")

# 4. 古いセッションの掃除
os.system("kasmvncserver -kill :1 > /dev/null 2>&1")
os.system("rm -rf /tmp/.X11-unix/X1 /tmp/.X1-lock cloudflared.log")

# VNCサーバーの起動環境設定 (日本語化とIME)
os.environ["LANG"] = "ja_JP.UTF-8"
os.environ["GTK_IM_MODULE"] = "fcitx"
os.environ["QT_IM_MODULE"] = "fcitx"
os.environ["XMODIFIERS"] = "@im=fcitx"

# KasmVNCサーバーの起動 (認証なし設定)
print("Starting KasmVNC Server (Ultimate Speed Mode)...")
os.system("kasmvncserver :1 -geometry 1280x720 -depth 24 -select-de xfce")

# IME(日本語入力)とオーディオの起動
os.system("DISPLAY=:1 fcitx5 -d > /dev/null 2>&1")
os.system("pulseaudio --start --exit-idle-time=-1 > /dev/null 2>&1")

# クリップボード同期ツールの起動
os.system("autocutsel -fork")

# クラウドフレアトンネル起動
print("Starting Cloudflare Tunnel...")
os.system("nohup /usr/local/bin/cloudflared tunnel --url http://localhost:8444 > cloudflared.log 2>&1 &")

print("==================================================================")
print("⏳ トンネルのURLを生成中... (最大20秒お待ちください)")
print("==================================================================")

# URL抽出ループ
url = ""
for _ in range(20):
    try:
        if os.path.exists("cloudflared.log"):
            with open("cloudflared.log", "r") as f:
                match = re.search(r'https://[-0-9a-z]+\.trycloudflare\.com', f.read())
                if match:
                    url = match.group(0)
                    break
    except: pass
    time.sleep(1)

if url:
    print(f"\n✅ 接続準備完了！")
    print(f"👉 URL: {url}")
    print(f"\n👆 上記URLをコピーして、WebBoxに入力してください。")
else:
    print("\n❌ 取得失敗。")

# 接続維持
while True:
    time.sleep(60)
```

## 次のステップ
1. WebBoxのUIから「クラウドPC」を起動します。
2. 上記で生成された `https://~.trycloudflare.com` のURLを貼り付けます。
3. ログイン画面なしで、爆速のLinuxデスクトップが表示されます！
4. デスクトップやChromeの設定はすべてGoogleドライブに保存され、次回も引き継がれます。
