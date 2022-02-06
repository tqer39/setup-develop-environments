#!/bin/bash

set -eu

LOG_FILE="$PWD/log/$(date +'%Y-%m-%d_%H-%M-%S').log"

main() {
  detect_os

  if [ "$PLATFORM" != 'linux' ] && [ "$PLATFORM" != 'mac' ]; then
    abort 'このOSは対応していません'
  fi

  detect_distribution
  setup

  exit 0
}

abort() {
  printf "%s\n" "$@"
  exit 1
}

detect_os() {
  if [ "$(uname)" == "Darwin" ]; then
    PLATFORM=mac
  elif [ "$(uname -s)" == "MINGW" ]; then
    PLATFORM=windows
  elif [ "$(uname -s)" == "Linux" ]; then
    PLATFORM=linux
  else
    PLATFORM="Unknown OS"
    abort "Your platform ($(uname -a)) is not supported."
  fi
}

detect_distribution() {
  if [ -e /etc/lsb-release ]; then
    DISTRIBUTION="$(grep ^NAME= /etc/os-release)"
    DISTRIBUTION=${DISTRIBUTION#NAME=}
    DISTRIBUTION=${DISTRIBUTION//\"/}
    DISTRIBUTION_VERSION=$(grep ^UBUNTU_CODENAME= /etc/os-release | cut -c 17-)
    log "Distribution: $DISTRIBUTION"
    log "Distribution Version: $DISTRIBUTION_VERSION"
  elif [ -e /etc/debian_version ] || [ -e /etc/debian_release ]; then
    DISTRIBUTION=debian
  elif [ -e /etc/redhat-release ]; then
    if [ -e /etc/oracle-release ]; then
      DISTRIBUTION=oracle
    else
      DISTRIBUTION=redhat
    fi
  elif [ -e /etc/fedora-release ]; then
    DISTRIBUTION=fedora
  elif [ -e /etc/arch-release ]; then
    DISTRIBUTION=arch
  else
    DISTRIBUTION="Unknown Distribution"
    abort "Your distributio is not supported."
  fi
}

setup() {
  SOFTWARE_LIST=(
    brew
    asdf
  )

  for software in "${SOFTWARE_LIST[@]}"; do
    check_confirm "$software"
  done
}

check_confirm() {
  if is_exists $1; then
    log "$1 is already installed"
    return
  fi

  if confirm "$1 をインストールします。よろしいですか？"; then
    case $1 in
      brew ) setup_brew ;;
      asdf ) setup_asdf ;;
    esac
  else
    log "do not install $1."
  fi
}

confirm() {
  while true; do
    echo -n "$* [y/n]: "
    read -r ANSWER
    case $ANSWER in
      [Yy]*)
        return 0
        ;;
      [Nn]*)
        return 1
        ;;
      *)
        echo "yまたはnを入力してください"
        ;;
    esac
  done
}

is_exists() {
  which "$1" >/dev/null 2>&1
  return $?
}

setup_brew() {
  # インストーラでプラットフォームの差分を吸収している
  echo "brew is not installed"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
}

setup_asdf() {
  if is_exists brew; then
    brew install asdf
    echo "brew is not installed"
  else
    setup_brew
  fi
}

# スクリプトのログファイルを残す関数
log() {
  mkdir -p "$PWD/log"
  echo "$1"
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] | $1" >> "$LOG_FILE"
}

main