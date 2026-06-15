#!/usr/bin/env bash
# AnixartEX TUI — установщик для Linux (любой дистрибутив с bash, curl/wget, tar)
set -euo pipefail

DEFAULT_VERSION="2.0.0"
DEFAULT_RELEASE_TAG="celestia"
DEFAULT_BASE_URL="https://github.com/ShakhShirakawa/AnixartEX_TUI-releases/releases/download"

VERSION="${ANIXARTEX_VERSION:-$DEFAULT_VERSION}"
RELEASE_TAG="${ANIXARTEX_RELEASE_TAG:-$DEFAULT_RELEASE_TAG}"
INSTALL_DIR="${ANIXARTEX_INSTALL_DIR:-$HOME/.local/share/anixartex-tui}"
BIN_DIR="${HOME}/.local/bin"
BASE_URL="${ANIXARTEX_BASE_URL:-$DEFAULT_BASE_URL}"

ARCHIVE="anixartex-tui-${VERSION}.tar.gz"
DOWNLOAD_URL="${BASE_URL}/${RELEASE_TAG}/${ARCHIVE}"

log() { printf '→ %s\n' "$*"; }
die() { printf 'Ошибка: %s\n' "$*" >&2; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "нужна команда: $1"
}

check_node() {
  need_cmd node
  local major
  major="$(node -p "process.versions.node.split('.')[0]")"
  if [[ "$major" -lt 24 ]]; then
    die "нужен Node.js 24 LTS+, сейчас: $(node -v). Установи: https://nodejs.org"
  fi
}

rebuild_urls() {
  ARCHIVE="anixartex-tui-${VERSION}.tar.gz"
  DOWNLOAD_URL="${BASE_URL}/${RELEASE_TAG}/${ARCHIVE}"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --version)
        VERSION="$2"
        rebuild_urls
        shift 2
        ;;
      --tag)
        RELEASE_TAG="$2"
        rebuild_urls
        shift 2
        ;;
      --dir)
        INSTALL_DIR="$2"
        shift 2
        ;;
      -h|--help)
        printf '%s\n' \
          "AnixartEX TUI — установщик для Linux" \
          "" \
          "Использование: install-linux.sh [--version VER] [--tag TAG] [--dir PATH]" \
          "" \
          "  --version   версия архива (по умолчанию ${DEFAULT_VERSION})" \
          "  --tag       тег GitHub Release (по умолчанию ${DEFAULT_RELEASE_TAG})" \
          "  --dir       каталог установки" \
          "" \
          "Требования: Node.js 24 LTS+, bash, curl или wget, tar"
        exit 0
        ;;
      *)
        die "неизвестный аргумент: $1"
        ;;
    esac
  done
}

download_archive() {
  local dest="$1"
  log "скачивание ${VERSION} (${RELEASE_TAG})"
  log "$DOWNLOAD_URL"

  if need_cmd curl; then
    curl -fL --progress-bar "$DOWNLOAD_URL" -o "$dest"
  elif need_cmd wget; then
    wget -q --show-progress -O "$dest" "$DOWNLOAD_URL"
  else
    die "нужен curl или wget"
  fi
}

install_release() {
  local tmp archive_path
  tmp="$(mktemp -d)"
  trap "rm -rf '${tmp}'" EXIT

  archive_path="$tmp/$ARCHIVE"
  download_archive "$archive_path"

  log "установка в $INSTALL_DIR"
  mkdir -p "$INSTALL_DIR"
  tar -xzf "$archive_path" -C "$tmp"

  local extracted="$tmp/anixartex-tui-${VERSION}"
  [[ -d "$extracted" ]] || die "неверная структура архива"

  rm -rf "$INSTALL_DIR"
  mv "$extracted" "$INSTALL_DIR"

  mkdir -p "$BIN_DIR"
  ln -sf "$INSTALL_DIR/bin/anixartex.js" "$BIN_DIR/anixartex"

  if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    log "добавь в PATH: export PATH=\"\$HOME/.local/bin:\$PATH\""
    log "или добавь строку в ~/.bashrc / ~/.zshrc"
  fi

  log "готово: anixartex v${VERSION}"
  log "запуск: anixartex"
}

main() {
  parse_args "$@"
  check_node
  install_release
}

main "$@"
