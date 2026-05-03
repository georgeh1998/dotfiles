# ベースイメージ: Node.js 20 の軽量版（Debian Slim ベース）
FROM node:20-slim

# --- システムツールのインストール ---
# apt-get update: パッケージリストを最新に更新
# apt-get install -y: 以下のツールをインストール（-y は確認をスキップ）
#   git        : バージョン管理ツール（Claude がコード操作に使う）
#   curl       : HTTP リクエストツール
#   sudo       : 一般ユーザーが管理者コマンドを使えるようにする
#   ca-certificates: HTTPS 通信に必要な証明書
# && rm -rf /var/lib/apt/lists/* : キャッシュを削除してイメージを軽くする
RUN apt-get update && apt-get install -y \
    git \
    curl \
    sudo \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 1001 appuser && \
      useradd --uid 1001 --gid 1001 -m -s /bin/bash appuser && \
      echo "appuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# --- Claude Code のインストール ---
# npm install -g: グローバルにパッケージをインストール
# @anthropic-ai/claude-code: Claude Code の npm パッケージ
RUN npm install -g @anthropic-ai/claude-code

# --- 実行ユーザーを appuser に切り替え ---
# root ではなく一般ユーザーとして実行する
USER appuser
