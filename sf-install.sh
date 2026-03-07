#!/bin/bash

# ==============================================================================
# プログラム名: sf-install.sh
# 概要: ホームディレクトリ(~)配下に sf-tools をクローン、または現在のブランチを最新化する
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. 設定項目
# ------------------------------------------------------------------------------
# ターゲットディレクトリ（ホームディレクトリ直下）
readonly TARGET_DIR="$HOME/sf-tools"

# リポジトリのURL
readonly REPO_URL="https://github.com/tamashimon-create/sf-tools.git"

# 新規クローン時のデフォルトブランチ
readonly DEFAULT_BRANCH="main"

# 表示色
readonly CLR_INFO='\033[36m'
readonly CLR_SUCCESS='\033[32m'
readonly CLR_ERR='\033[31m'
readonly CLR_CMD='\033[34m'
readonly CLR_RESET='\033[0m'

# ------------------------------------------------------------------------------
# 2. 共通エンジン（画面出力とコマンド実行制御）
# ------------------------------------------------------------------------------
log() {
    local level=$1
    local stage=$2
    local message=$3

    case "$level" in
        "INFO")    echo -e "${CLR_INFO}▶️  [$stage]${CLR_RESET} $message" ;;
        "SUCCESS") echo -e "${CLR_SUCCESS}✅ [$stage]${CLR_RESET} $message" ;;
        "ERROR")   echo -e "${CLR_ERR}❌ [$stage]${CLR_RESET} $message" >&2 ;;
        "CMD")     echo -e "${CLR_CMD}   > Command:${CLR_RESET} $message" ;;
    esac
}

exec_wrapper() {
    local stage=$1
    shift
    local cmd=("$@")

    log "CMD" "$stage" "${cmd[*]}"
    "${cmd[@]}"
    return $?
}

# ------------------------------------------------------------------------------
# 3. メインフロー
# ------------------------------------------------------------------------------
echo "-------------------------------------------------------"
log "INFO" "INIT" "sf-tools のセットアップを開始します"

if [ -d "$TARGET_DIR" ]; then
    # ==========================================
    # パターンA: 既にディレクトリが存在する場合 (現在のブランチを維持してPull)
    # ==========================================
    log "INFO" "UPDATE" "既存のディレクトリを検知しました。最新化を実行します。"
    
    cd "$TARGET_DIR" || {
        log "ERROR" "UPDATE" "ディレクトリへの移動に失敗しました: $TARGET_DIR"
        exit 1
    }

    # リモートの最新情報を取得
    exec_wrapper "UPDATE" git fetch origin
    
    # 現在のローカルブランチ名を取得
    CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || git branch --show-current)
    
    if [ -n "$CURRENT_BRANCH" ]; then
        log "INFO" "UPDATE" "現在のブランチ (${CURRENT_BRANCH}) を Pull します。"
        if exec_wrapper "UPDATE" git pull origin "$CURRENT_BRANCH"; then
            log "SUCCESS" "UPDATE" "最新化が正常に完了しました！"
        else
            log "ERROR" "UPDATE" "最新化に失敗しました。ローカルに変更が残っている等の可能性があります。"
            exit 1
        fi
    else
        # Detached HEADなどでブランチ名が取得できない場合のフォールバック
        log "INFO" "UPDATE" "現在のブランチ名が取得できません。通常の pull を実行します。"
        if exec_wrapper "UPDATE" git pull; then
            log "SUCCESS" "UPDATE" "最新化が正常に完了しました！"
        else
            log "ERROR" "UPDATE" "最新化に失敗しました。"
            exit 1
        fi
    fi

else
    # ==========================================
    # パターンB: ディレクトリが存在しない場合 (デフォルトブランチをClone)
    # ==========================================
    log "INFO" "CLONE" "ディレクトリが存在しません。新規クローンを実行します。"
    
    cd "$HOME" || {
        log "ERROR" "CLONE" "ホームディレクトリへの移動に失敗しました: $HOME"
        exit 1
    }

    # デフォルト(main)でクローンを実行
    if exec_wrapper "CLONE" git clone -b "$DEFAULT_BRANCH" "$REPO_URL" sf-tools; then
        log "SUCCESS" "CLONE" "クローンが正常に完了しました！"
    else
        log "ERROR" "CLONE" "クローンに失敗しました。URLやアクセス権限を確認してください。"
        exit 1
    fi
fi

echo "-------------------------------------------------------"
log "SUCCESS" "FINISH" "すべてのセットアップ工程が完了しました。"
exit 0