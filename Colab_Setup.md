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

!sudo apt-get update
!DEBIAN_FRONTEND=noninteractive sudo apt-get install -y xfce4 xfce4-terminal tigervnc-standalone-server novnc autocutsel fonts-noto-cjk language-pack-ja

# Google Chromeのインストール
!wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
!DEBIAN_FRONTEND=noninteractive sudo apt-get install -y ./google-chrome-stable_current_amd64.deb

# websockifyはPython環境に確実にインストールする
!pip install websockify

# Cloudflare Tunnel のインストール（バイナリを直接配置）
!wget -q -nc https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
!chmod +x cloudflared-linux-amd64
!sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared

# Google Chromeのショートカットをデスクトップに作成（--no-sandboxが必要なため）
!mkdir -p /root/Desktop
!echo "[Desktop Entry]\nVersion=1.0\nType=Application\nName=Google Chrome\nExec=google-chrome-stable --no-sandbox\nIcon=google-chrome\nTerminal=false" > /root/Desktop/google-chrome.desktop
!chmod +x /root/Desktop/google-chrome.desktop

!echo "✅ Installation Complete!"
```

## 手順 3: サーバー起動＆トンネル開通
次のセルに以下のコードを貼り付けて実行します。
実行すると、ログの最後に `https://xxxx-xxxx.trycloudflare.com` というURLが表示されます。

```python
# セル 2: デスクトップストリーミングの開始
import time
import os
import re

# 古いセッションがあればクリア
os.system("vncserver -kill :1 > /dev/null 2>&1")
os.system("rm -rf /tmp/.X11-unix/X1 /tmp/.X1-lock cloudflared.log websockify.log")

# VNCパスワードの設定
os.system("mkdir -p ~/.vnc")
os.system("echo 'webbox123' | vncpasswd -f > ~/.vnc/passwd")
os.system("chmod 600 ~/.vnc/passwd")

# VNCサーバーの起動
print("Starting Desktop Server...")
os.system("vncserver :1 -geometry 1280x720 -depth 24 -localhost no -SecurityTypes VncAuth")

# クリップボード同期ツールの起動
os.system("autocutsel -fork")

# noVNCブリッジのパスを検索
import shutil
websockify_bin = shutil.which("websockify") or "/usr/local/bin/websockify"

# サーバー起動 (バックグラウンド実行)
print("Starting Web Streamer (websockify)...")
os.system(f"nohup {websockify_bin} --web /usr/share/novnc 6080 localhost:5901 > websockify.log 2>&1 &")

# websockifyが起動するまで数秒待機（ポート6080が開くのを待つ）
time.sleep(5)

print("Starting Cloudflare Tunnel...")
os.system("nohup /usr/local/bin/cloudflared tunnel --url http://localhost:6080 > cloudflared.log 2>&1 &")

print("==================================================================")
print("⏳ トンネルのURLを生成中... (最大20秒お待ちください)")
print("==================================================================")

# URLが出現するまでログを監視
url = ""
for _ in range(20):
    try:
        with open("cloudflared.log", "r") as f:
            for line in f:
                if "trycloudflare.com" in line:
                    match = re.search(r'https://[-0-9a-z]+\.trycloudflare\.com', line)
                    if match:
                        url = match.group(0)
                        break
        if url:
            break
    except Exception:
        pass
    time.sleep(1)

if url:
    print(f"\n✅ 成功しました！以下のURLをコピーして、WebBoxに入力してください。")
    print(f"👉 {url}\n")
else:
    print("\n❌ URLの取得に失敗しました。cloudflared.log の内容:")
    os.system("cat cloudflared.log")

# セルを実行し続ける
while True:
    time.sleep(60)
```
## 次のステップ
1. WebBoxのUIから「クラウドPC」を起動します。
2. 上記で生成された `https://~.trycloudflare.com` のURLを貼り付けます。
3. パスワードを求められたら **`webbox123`** と入力してください。
4. 爆速のLinuxデスクトップが表示され、Chromeでネットサーフィンが楽しめます！
