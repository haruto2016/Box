# WebBox for Codespaces: 究極の「自分専用」クラウドデスクトップ

GitHub Codespaces を使った、電話認証不要・永続ストレージ付きの爆速デスクトップ環境の構築ガイドです。

## 手順 1: Codespaces の起動
1. 自分の GitHub リポジトリ（Box など）を開きます。
2. 緑色の **「<> Code」** ボタンをクリック。
3. **「Codespaces」** タブにある **「Create codespace on main」** をクリックして起動します。

---

## 手順 2: セットアップ（ターミナルに貼り付け）
VSCode の画面下にある **「TERMINAL」** に以下のコマンドを一気に貼り付けて実行します。
（※初回のみ約3分かかります。一度インストールすれば、次回からは一瞬で起動します！）

```bash
# WebBox Codespaces 自動セットアップ
echo "🚀 WebBox のセットアップを開始します..."

# 必要なパッケージのインストール
sudo apt-get update
wget -q https://github.com/kasmtech/KasmVNC/releases/download/v1.3.1/kasmvncserver_jammy_1.3.1_amd64.deb
sudo apt-get install -y ./kasmvncserver_jammy_1.3.1_amd64.deb
sudo apt-get install -y xfce4 xfce4-terminal autocutsel fonts-noto-cjk language-pack-ja yaru-theme-gtk yaru-theme-icon fcitx5-mozc dbus-x11 pulseaudio

# KasmVNCの設定 (ログインなし・自動ログイン設定)
mkdir -p ~/.vnc
echo -e "version: 1\n\nnetwork:\n  protocol: http\n  port: 8444\n\n  ssl:\n    require_ssl: false\n\n  auth:\n    type: none\n\n" > ~/.vnc/kasmvnc.yaml

# 日本語ロケール設定
sudo locale-gen ja_JP.UTF-8
export LANG=ja_JP.UTF-8

# Google Chromeのインストール
wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt-get install -y ./google-chrome-stable_current_amd64.deb

# デスクトップ起動
echo "🖥️ デスクトップを起動中..."
vncserver -kill :1 > /dev/null 2>&1
kasmvncserver :1 -geometry 1280x720 -depth 24 -select-de xfce --no-password --http-port 8444 --disable-ssl

# ポート転送の設定（自動で公開設定にする）
gh codespace ports visibility 8444:public -c $CODESPACE_NAME

echo "=========================================================="
echo "✅ セットアップ完了！"
echo "1. 画面右下の『Open in Browser』ボタンを押すか、"
echo "2. 『Ports』タブにある 8444 ポートの URL を開いてください。"
echo "=========================================================="
```

---

### この環境のすごいところ：
*   **データが消えない**: Colab と違い、デスクトップに置いたファイルや Chrome の設定は、Codespaces を止めても**自動で保存**されます。
*   **ポート転送が安全**: GitHub 公式のシステムを通すため、学校のフィルタリングに引っかかりません。
*   **WebRTC対応**: 動画もサクサク動きます。

### 次回からの起動方法：
一度インストールが終われば、次からはターミナルで以下の 1 行を打つだけでデスクトップが復活します。
`kasmvncserver :1 -geometry 1280x720 -depth 24 -select-de xfce --no-password --http-port 8444 --disable-ssl`
