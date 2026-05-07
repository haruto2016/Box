# WebBox Pro: ネイティブ・クラウドデスクトップ構築ガイド

QEMUを使わず、Colabの巨大なマシンスペック（RAM 12GB）を100%直接使い切る「爆速クラウドPC」を構築します。

## 手順 1: Colab ノートブックの作成
1. [Google Colab](https://colab.research.google.com/) にアクセスし、新しいノートブックを作成します。

## 手順 2: デスクトップ環境の完全インストール
最初のセルに以下のコードを貼り付け、実行します。（数分かかります）
軽量デスクトップ(XFCE)、VNCサーバー、Chromeブラウザを一括で導入します。

```bash
# セル 1: ネイティブ・デスクトップ環境の構築
!echo "Installing Desktop Environment and Browser..."

# Colabのバックグラウンド更新と競合しないようにロックが解除されるまで待機
!while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do echo "Waiting for apt lock..."; sleep 2; done;

# キーボード設定を自動で「日本語」に選択する設定（これで質問が出なくなります）
!echo "keyboard-configuration keyboard-configuration/layout select Japanese" | sudo debconf-set-selections
!echo "keyboard-configuration keyboard-configuration/variant select Japanese (OADG 109A)" | sudo debconf-set-selections

# KasmVNC (WebRTC対応・超高速VNC) のインストール
!wget -q https://github.com/kasmtech/KasmVNC/releases/download/v1.3.1/kasmvncserver_jammy_1.3.1_amd64.deb
!sudo apt-get update
!DEBIAN_FRONTEND=noninteractive sudo apt-get install -y ./kasmvncserver_jammy_1.3.1_amd64.deb
!sudo apt-get install -y xfce4 xfce4-terminal autocutsel fonts-noto-cjk language-pack-ja yaru-theme-gtk yaru-theme-icon fcitx5-mozc dbus-x11 pulseaudio

# KasmVNCの設定 (パスワードと起動設定)
!mkdir -p ~/.kasmsync
!echo "webbox123" | vncpasswd -f > ~/.vnc/passwd
!chmod 600 ~/.vnc/passwd
!mkdir -p ~/.vnc
!echo -e "version: 1\n\nnetwork:\n  protocol: http\n  port: 8444\n\n  ssl:\n    require_ssl: false\n\n  udp:\n    public_ip: 127.0.0.1\n\nencoding:\n  encodings:\n    - video\n    - webp\n    - tight\n\n" > ~/.vnc/kasmvnc.yaml

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

# Google Chromeのインストール (修正版)
!wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
!DEBIAN_FRONTEND=noninteractive sudo apt-get install -y ./google-chrome-stable_current_amd64.deb
!mkdir -p /root/Desktop
!mkdir -p /root/.chrome-profile
!echo -e "[Desktop Entry]\nVersion=1.0\nType=Application\nName=Google Chrome\nExec=/usr/bin/google-chrome-stable --no-sandbox --user-data-dir=/root/.chrome-profile\nIcon=google-chrome\nTerminal=false" > /root/Desktop/google-chrome.desktop
!chmod +x /root/Desktop/google-chrome.desktop

# ffmpeg（音声ストリーミング用）のインストール
!sudo apt-get install -y ffmpeg

!echo "✅ Installation Complete! (Ultimate Speed Mode)"
!echo "💡 ヒント: YouTubeのログイン状態を保存したい場合は、セルの冒頭に「from google.colab import drive; drive.mount('/content/drive')」を追加し、--user-data-dirを /content/drive/MyDrive/chrome-profile に変更してください。"
```

## 手順 3: サーバー起動＆トンネル開通 (Ultimate)
次のセルに以下のコードを貼り付けて実行します。
実行すると、ログの最後に `https://xxxx-xxxx.trycloudflare.com` というURLが表示されます。

```python
# セル 2: デスクトップストリーミングの開始 (KasmVNC WebRTC Mode)
import time
import os
import re

# 古いセッションの掃除
os.system("kasmvncserver -kill :1 > /dev/null 2>&1")
os.system("rm -rf /tmp/.X11-unix/X1 /tmp/.X1-lock cloudflared.log websockify.log")

# VNCサーバーの起動環境設定 (日本語化とIME)
os.environ["LANG"] = "ja_JP.UTF-8"
os.environ["GTK_IM_MODULE"] = "fcitx"
os.environ["QT_IM_MODULE"] = "fcitx"
os.environ["XMODIFIERS"] = "@im=fcitx"

# KasmVNCサーバーの起動 (WebRTC + H.264で動画もサクサク)
print("Starting KasmVNC Server (Ultimate Speed Mode)...")
os.system("kasmvncserver :1 -geometry 1280x720 -depth 24 -select-de xfce")

# IME(日本語入力)とオーディオの起動
os.system("DISPLAY=:1 fcitx5 -d > /dev/null 2>&1")
os.system("pulseaudio --start --exit-idle-time=-1 > /dev/null 2>&1")

# クリップボード同期ツールの起動
os.system("autocutsel -fork")

# KasmVNCは8444ポートで動作します
print("Starting Cloudflare Tunnel...")
os.system("nohup /usr/local/bin/cloudflared tunnel --url http://localhost:8444 > cloudflared.log 2>&1 &")

print("==================================================================")
print("⏳ トンネルのURLを生成中... (最大20秒お待ちください)")
print("==================================================================")

# URLが見つかるまでログを監視するループ
vnc_url = ""
audio_url = ""
for _ in range(20):
    try:
        if not vnc_url and os.path.exists("cloudflared.log"):
            with open("cloudflared.log", "r") as f:
                match = re.search(r'https://[-0-9a-z]+\.trycloudflare\.com', f.read())
                if match: vnc_url = match.group(0)
        if not audio_url and os.path.exists("cloudflared_audio.log"):
            with open("cloudflared_audio.log", "r") as f:
                match = re.search(r'https://[-0-9a-z]+\.trycloudflare\.com', f.read())
                if match: audio_url = match.group(0)
        if vnc_url and audio_url: break
    except: pass
    time.sleep(1)

if vnc_url:
    print(f"\n✅ 接続準備完了！")
    print(f"🖥 画面用URL: {vnc_url}")
    if audio_url:
        print(f"🔊 音声用URL: {audio_url}")
        print(f"  (※音を聴くには、音声用URLを新しいタブで開き、「再生」ボタンを押してください)")
    print(f"\n👆 画面用URLをコピーして、WebBoxに入力してください。")
else:
    print("\n❌ 取得失敗。")

# セルを実行し続ける
while True:
    time.sleep(60)
```
## 次のステップ
1. WebBoxのUIから「クラウドPC」を起動します。
2. 上記で生成された `https://~.trycloudflare.com` のURLを貼り付けます。
3. パスワードを求められたら **`webbox123`** と入力してください。
4. 爆速のLinuxデスクトップが表示され、Chromeでネットサーフィンが楽しめます！
