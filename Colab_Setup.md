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
!sudo apt-get update
!sudo apt-get install -y xfce4 xfce4-terminal tigervnc-standalone-server novnc

# Google Chromeのインストール
!wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
!sudo apt-get install -y ./google-chrome-stable_current_amd64.deb

# websockifyはPython環境に確実にインストールする
!pip install websockify

# Cloudflare Tunnel のインストール（バイナリを直接配置）
!wget -q -nc https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
!chmod +x cloudflared-linux-amd64
!sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared

!echo "✅ Installation Complete!"
```

## 手順 3: サーバー起動＆トンネル開通
次のセルに以下のコードを貼り付けて実行します。
実行すると、ログの最後に `https://xxxx-xxxx.trycloudflare.com` というURLが表示されます。

```python
# セル 2: デスクトップストリーミングの開始
import subprocess
import time
import threading
import os

# 古いVNCセッションがあればクリア
os.system("vncserver -kill :1 > /dev/null 2>&1")
os.system("rm -rf /tmp/.X11-unix/X1 /tmp/.X1-lock cloudflared.log")

# VNCパスワードの設定 (Colabローカル用なので適当でOK)
os.system("mkdir -p ~/.vnc")
os.system("echo 'webbox123' | vncpasswd -f > ~/.vnc/passwd")
os.system("chmod 600 ~/.vnc/passwd")

# VNCサーバーの起動 (解像度はお好みで変更可)
print("Starting Desktop Server...")
os.system("vncserver :1 -geometry 1280x720 -depth 24 -localhost no -SecurityTypes VncAuth")

# noVNCブリッジの起動 (ポート6080でWebからアクセス可能に)
print("Starting Web Streamer...")
import shutil
websockify_path = shutil.which("websockify")
if not websockify_path:
    websockify_path = "/usr/local/bin/websockify"
subprocess.Popen([websockify_path, "--web", "/usr/share/novnc", "6080", "localhost:5901"])
time.sleep(3)

# Cloudflare Tunnelを開通
print("Starting Cloudflare Tunnel...")
def run_tunnel():
    # ログをファイルに書き出して後でURLを抽出する
    with open("cloudflared.log", "w") as f:
        subprocess.run(["/usr/local/bin/cloudflared", "tunnel", "--url", "http://localhost:6080"], stderr=f)

thread = threading.Thread(target=run_tunnel)
thread.daemon = True
thread.start()

print("==================================================================")
print("⏳ トンネルのURLを生成中... (約10秒お待ちください)")
print("==================================================================")

time.sleep(10)
# ログファイルからURLを確実に抽出して表示
os.system("grep -o 'https://[-0-9a-z]*\.trycloudflare\.com' cloudflared.log")

print("👆 上記のURLをコピーして、WebBoxに入力してください。")

# セルを実行し続ける
while True:
    time.sleep(60)
```

## 次のステップ
1. WebBoxのUIから「クラウドPC」を起動します。
2. 上記で生成された `https://~.trycloudflare.com` のURLを貼り付けます。
3. パスワードを求められたら **`webbox123`** と入力してください。
4. 爆速のLinuxデスクトップが表示され、Chromeでネットサーフィンが楽しめます！
