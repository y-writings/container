#!/usr/bin/env bash
# Purpose:
#   Codex Cloud (Ubuntu) 上で、再現可能な開発環境を構築する。
#   - apt でベースパッケージを導入
#   - Determinate Systems Nix installer で Nix を導入
#   - flake から devtools をインストール
#   - src/codex-cloud 配下の追加実行ファイルを順次実行
#
# Usage:
#   bash src/codex-cloud/setup.sh
#
# Preconditions:
#   - Ubuntu 系 OS
#   - sudo 権限
#   - インターネット接続
#   - リポジトリルートで実行されること

set -euo pipefail

log_info() {
  echo "[INFO] $*"
}

log_warn() {
  echo "[WARN] $*"
}

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CODEX_CLOUD_DIR="${REPO_ROOT}/src/codex-cloud"

if [[ ! -f "${CODEX_CLOUD_DIR}/flake.nix" ]]; then
  echo "[ERROR] flake.nix が見つかりません: ${CODEX_CLOUD_DIR}/flake.nix" >&2
  exit 1
fi

install_apt_packages() {
  log_info "Step 1/4: apt ベースパッケージを確認します"

  local required_packages=(
    ca-certificates
    curl
    xz-utils
    git
  )

  local missing_packages=()
  local pkg
  for pkg in "${required_packages[@]}"; do
    if dpkg -s "${pkg}" >/dev/null 2>&1; then
      log_info "apt パッケージ '${pkg}' は既に導入済みです (skip)"
    else
      missing_packages+=("${pkg}")
    fi
  done

  if [[ "${#missing_packages[@]}" -eq 0 ]]; then
    log_info "必要な apt パッケージはすべて導入済みです"
    return
  fi

  log_info "不足パッケージをインストールします: ${missing_packages[*]}"
  sudo apt-get update
  sudo apt-get install -y "${missing_packages[@]}"
}

ensure_nix() {
  log_info "Step 2/4: Nix (Determinate Systems installer) を確認します"

  if command -v nix >/dev/null 2>&1; then
    log_info "Nix は既に導入済みです (skip)"
    return
  fi

  log_info "Nix をインストールします"
  curl --proto '=https' --tlsv1.2 -fsSL https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm

  # installer が shell profile を更新するため、現在のシェルにも反映を試みる
  if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    # shellcheck source=/dev/null
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  elif [[ -f "${HOME}/.nix-profile/etc/profile.d/nix.sh" ]]; then
    # shellcheck source=/dev/null
    source "${HOME}/.nix-profile/etc/profile.d/nix.sh"
  fi

  if ! command -v nix >/dev/null 2>&1; then
    log_warn "このシェルで nix コマンドが未検出です。新しいシェルで再実行してください"
    exit 1
  fi
}

setup_flake_env() {
  log_info "Step 3/4: Nix flake 環境をセットアップします"

  cd "${CODEX_CLOUD_DIR}"

  if ! nix --extra-experimental-features "nix-command flakes" flake metadata . >/dev/null; then
    echo "[ERROR] flake metadata の取得に失敗しました" >&2
    exit 1
  fi

  log_info "devtools プロファイルをインストール/更新します"
  nix --extra-experimental-features "nix-command flakes" \
    profile install .#devtools --priority 5
}

run_local_executables() {
  log_info "Step 4/4: src/codex-cloud 配下の追加実行ファイルを実行します"

  local script
  local executed=0

  while IFS= read -r -d '' script; do
    if [[ "${script}" == "${CODEX_CLOUD_DIR}/setup.sh" ]]; then
      continue
    fi

    log_info "実行: ${script}"
    "${script}"
    executed=1
  done < <(find "${CODEX_CLOUD_DIR}" -maxdepth 1 -type f -name '*.sh' -perm -u+x -print0 | sort -z)

  if [[ "${executed}" -eq 0 ]]; then
    log_info "実行対象の追加ファイルはありませんでした (setup.sh を除く)"
  fi
}

main() {
  log_info "Codex Cloud セットアップを開始します"
  install_apt_packages
  ensure_nix
  setup_flake_env
  run_local_executables
  log_info "Codex Cloud セットアップが完了しました"
}

main "$@"
