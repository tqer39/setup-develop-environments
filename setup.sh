#!/bin/bash

set -eu

LOG_FILE="$PWD/log/$(date +'%Y-%m-%d_%H-%M-%S').log"

main() {
  detect_os

  if [ "$PLATFORM" != 'linux' -a "$PLATFORM" != 'mac' ]; then
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
  elif [ "$(expr substr $(uname -s) 1 5)" == "MINGW" ]; then
    PLATFORM=windows
  elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    PLATFORM=linux
  else
    PLATFORM="Unknown OS"
    abort "Your platform ($(uname -a)) is not supported."
  fi
}

detect_distribution() {
  if [ -e /etc/lsb-release ]; then
    DISTRIBUTION=ubuntu
    DISTRIBUTION_VERSION=$(cat /etc/os-release | grep UBUNTU_CODENAME= | cut -c 17-)
    log $DISTRIBUTION
    log $DISTRIBUTION_VERSION
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
    echo "Your distributio is not supported."
    DISTRIBUTION="Unknown Distribution"
    exit 1
  fi
}

setup() {
  check_confirm "brew"
}

check_confirm() {
  if confirm "$1 をインストールします。よろしいですか？"; then
    case $1 in
      brew ) setup_brew ;;
    esac
  else
    echo "No"
  fi
}

confirm() {
  while true; do
    echo -n "$* [y/n]: "
    read ANS
    case $ANS in
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
  if is_exists brew; then
    echo "brew is already installed"
  else
    # インストーラでプラットフォームの差分を吸収している
    echo "brew is not installed"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
  fi
}

# スクリプトのログファイルを残す関数
log() {
  mkdir -p "$PWD/log"
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] | $1" >> "$LOG_FILE"
  log
}

main