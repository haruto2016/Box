# WebBox for Hugging Face Spaces: 24時間止まらない最強デスクトップ

Hugging Face の無料枠（16GBメモリ）をフル活用した、電話認証不要・24時間稼働のデスクトップ環境構築ガイドです。

## 特徴
*   **24時間365日稼働**: 毎日8時間どころか、ずっと動き続けます。
*   **メモリ 16GB**: Colab よりサクサク動きます。
*   **電話認証不要**: GitHub アカウント等で登録するだけ。
*   **データ保存**: Google Drive と連携して、ファイルを永続化します。

---

## 手順 1: Hugging Face で Space を作る
1.  [Hugging Face](https://huggingface.co/new-space) にログインします。
2.  **Space name**: `webbox`（好きな名前）
3.  **SDK**: **「Docker」** を選択（※ここが一番重要です！）
4.  **Template**: 「Blank」を選択。
5.  **Public/Private**: 自分だけが使うなら「Private」がおすすめ。
6.  「Create Space」ボタンを押します。

---

## 手順 2: ファイルの作成
画面上の **「Files」** タブを押し、**「+ Add file」>「Create a new file」** から以下の2つのファイルを作ります。

### 1. `Dockerfile`
（以下の内容をすべてコピーして貼り付け、保存してください）

```dockerfile
FROM ubuntu:22.04

# 必要なパッケージのインストール
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    wget curl xfce4 xfce4-terminal fonts-noto-cjk language-pack-ja \
    fcitx5-mozc dbus-x11 pulseaudio sudo rclone \
    && apt-get clean

# KasmVNCのグループ作成とユーザー追加
RUN groupadd kasmvnc

# KasmVNCのインストール
RUN wget -q https://github.com/kasmtech/KasmVNC/releases/download/v1.3.1/kasmvncserver_jammy_1.3.1_amd64.deb \
    && apt-get install -y ./kasmvncserver_jammy_1.3.1_amd64.deb \
    && rm kasmvncserver_jammy_1.3.1_amd64.deb

# Google Chromeのインストール
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get install -y ./google-chrome-stable_current_amd64.deb \
    && rm google-chrome-stable_current_amd64.deb

# ユーザー設定
RUN useradd -m -u 1000 -G kasmvnc user
ENV HOME=/home/user
WORKDIR $HOME
USER user

# 起動スクリプトの準備
COPY --chown=user:user start.sh /start.sh
RUN chmod +x /start.sh

# KasmVNCのポート
EXPOSE 8444

CMD ["/start.sh"]
```

### 2. `start.sh`
（以下の `REFRESH_TOKEN` の部分を自分のものに書き換えて保存してください）

```bash
#!/bin/bash

# ==========================================
# Google Drive 連携設定
# ==========================================
REFRESH_TOKEN="ここに自分の許可証を貼り付け"
# ==========================================

# rcloneの設定作成
mkdir -p ~/.config/rclone
echo "[personal_drive]
type = drive
scope = drive
token = {\"refresh_token\":\"$REFRESH_TOKEN\"}" > ~/.config/rclone/rclone.conf

# SSL証明書の自己署名作成 (KasmVNCの起動エラー回避用)
mkdir -p ~/.vnc
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ~/.vnc/self.key -out ~/.vnc/self.cert \
    -subj "/C=JP/ST=Tokyo/L=WebBox/CN=localhost"

# KasmVNCのユーザーパスワード設定
(echo "webbox123"; echo "webbox123") | kasmvncpasswd -u user

# KasmVNC 1.3.1 用の正しい設定ファイル作成
echo "
network:
  http_port: 8444
  ssl:
    require_ssl: false
    cert_path: /home/user/.vnc/self.cert
    key_path: /home/user/.vnc/self.key
auth:
  method: none
users:
  user:
    password: \"\"
    permissions:
      - allow_all
" > ~/.vnc/kasmvnc.yaml

# 日本語設定
export LANG=ja_JP.UTF-8

# KasmVNC起動 (設定ファイルを指定して起動)
kasmvncserver :1 -geometry 1280x720 -depth 24 -select-de xfce --interface 0.0.0.0
```

---

## 手順 3: 接続
1.  ファイルを保存すると自動的にビルドが始まります（「Building」が「Running」になるまで待つ）。
2.  「Running」になったら、画面上の **「Embed this Space」** またはURLから直接アクセス！
3.  WebBox の接続先には、Hugging Face の画面に表示されている URL を入力してください。

---

### 💡 ストレージについてのアドバイス
Hugging Face には有料の「Persistent Storage」がありますが、**追加する必要はありません。**
上記の設定で Google Drive と連携しているため、デスクトップ上のファイルは無料で安全に保存されます！
