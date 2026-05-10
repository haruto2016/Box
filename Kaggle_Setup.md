# WebBox for Kaggle: 超高速クラウドデスクトップ構築ガイド

Kaggle の強力な環境（RAM 13GB / 12時間連続稼働）をフル活用して、自分だけのデスクトップ環境を構築します。

## 準備：Kaggle ノートブックの設定
1. [Kaggle](https://www.kaggle.com/) で新しい Notebook を作成します。
2. 右側のパネルの **Settings** で以下を確認してください。
   - **Internet**: **ON** に設定（※必須：電話番号認証が必要です）
   - **Accelerator**: **None** (CPUのみで十分速いです)

---

## 手順 1: デスクトップ環境のインストール
最初のセルに以下のコードを貼り付けて実行します。（約3〜5分かかります）

{% raw %}
```bash
# セル 1: インストール（Kaggle対応版）
!echo "Installing Desktop Environment..."

# KasmVNCのインストール
!wget -q https://github.com/kasmtech/KasmVNC/releases/download/v1.3.1/kasmvncserver_jammy_1.3.1_amd64.deb
!sudo apt-get update
!DEBIAN_FRONTEND=noninteractive sudo apt-get install -y ./kasmvncserver_jammy_1.3.1_amd64.deb
!sudo apt-get install -y xfce4 xfce4-terminal autocutsel fonts-noto-cjk language-pack-ja yaru-theme-gtk yaru-theme-icon fcitx5-mozc dbus-x11 pulseaudio

# KasmVNCの設定
!mkdir -p ~/.vnc
!echo -e "version: 1\n\nnetwork:\n  protocol: http\n  port: 8444\n\n  ssl:\n    require_ssl: false\n\n  auth:\n    type: none\n\n" > ~/.vnc/kasmvnc.yaml

# 日本語ロケール設定
!sudo locale-gen ja_JP.UTF-8
!sudo update-locale LANG=ja_JP.UTF-8

# Google Chromeのインストール
!wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
!sudo apt-get install -y ./google-chrome-stable_current_amd64.deb

# rclone（個人ドライブ接続ツール）のインストール
!sudo apt-get install -y rclone

# rcloneの設定作成 (ここに先ほどの許可証を貼り付けます)
# ==========================================
REFRESH_TOKEN = "ここにコピーした許可証（1//...）を貼り付けてください"
# ==========================================

import os
os.makedirs(os.path.expanduser("~/.config/rclone"), exist_ok=True)
with open(os.path.expanduser("~/.config/rclone/rclone.conf"), "w") as f:
    f.write(f'[personal_drive]\ntype = drive\nscope = drive\ntoken = {{"refresh_token":"{REFRESH_TOKEN}"}}\n')

# トンネルツール (Localtunnel) のインストール
!npm install -g localtunnel

!echo "✅ Installation Complete! (Kaggle Mode)"
```
{% endraw %}

## 手順 2: サーバー起動＆データ同期
次のセルに以下のコードを貼り付けて実行します。

```python
# セル 2: デスクトップ起動 ＆ 同期開始
import time
import os
import subprocess
import threading

IMG_NAME = "webbox_data_kaggle.img"
LOCAL_PATH = f"/kaggle/working/{IMG_NAME}"
REMOTE_PATH = f"personal_drive:WebBox_Data/{IMG_NAME}"
MOUNT_POINT = "/mnt/webbox_data"

# 1. データ同期
print("Connecting to Personal Google Drive...")
if os.system(f"rclone ls {REMOTE_PATH}") == 0:
    print("Found existing data. Downloading...")
    os.system(f"rclone copy {REMOTE_PATH} /kaggle/working/ -P")
else:
    print("No existing data found. Creating new 2GB disk...")
    os.system(f"truncate -s 2G {LOCAL_PATH}")
    os.system(f"mkfs.ext4 {LOCAL_PATH}")

# 2. マウント
print("Mounting Disk Image...")
os.system(f"sudo mkdir -p {MOUNT_POINT}")
os.system(f"sudo mount -o loop {LOCAL_PATH} {MOUNT_POINT}")
os.system(f"sudo chown -R 1000:1000 {MOUNT_POINT}")

# シンボリックリンク作成
def link_dir(src, dst_name):
    dst = f"{MOUNT_POINT}/{dst_name}"
    os.makedirs(dst, exist_ok=True)
    if os.path.exists(src): os.system(f"rm -rf {src}")
    os.system(f"ln -s {dst} {src}")

link_dir("/home/kaggle/Desktop", "Desktop")
link_dir("/home/kaggle/.chrome-profile", "chrome-profile")

# 3. バックグラウンド保存
def auto_backup():
    while True:
        time.sleep(300)
        print("☁️ Auto-syncing to Personal Drive...")
        os.system(f"rclone copy {LOCAL_PATH} personal_drive:WebBox_Data/ -P")

threading.Thread(target=auto_backup, daemon=True).start()

# 4. サーバー起動
print("Starting KasmVNC Server...")
os.system("kasmvncserver -kill :1 > /dev/null 2>&1")
os.environ["LANG"] = "ja_JP.UTF-8"
cmd = "kasmvncserver :1 -geometry 1280x720 -depth 24 -select-de xfce --no-password --http-port 8444 --disable-ssl"
subprocess.Popen(cmd.split(), stdout=open("kasmvnc.log", "w"), stderr=subprocess.STDOUT, preexec_fn=os.setpgrp)

time.sleep(5)
os.system("DISPLAY=:1 fcitx5 -d > /dev/null 2>&1")

# 5. トンネル起動 (Localtunnel)
print("Starting Tunnel (Localtunnel)...")
lt_proc = subprocess.Popen(["lt", "--port", "8444"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

# URLを取得して表示
for line in lt_proc.stdout:
    if "your url is:" in line:
        url = line.split("is:")[1].strip()
        print("\n==================================================================")
        print(f"✅ 接続準備完了！\n👉 URL: {url}")
        print("==================================================================")
        break

while True:
    time.sleep(60)
```
