#!/bin/bash

set -eu

LOG_FILE="$PWD/log/$(date +'%Y-%m-%d_%H-%M-%S').log"

main() {
  detect_os


  if [ "$_PLATFORM" == 'linux' -a "$_PLATFORM" == 'mac' ]; then
    detect_distribution
  fi

  if [ "$_PLATFORM" == "linux" ]; then
    install_linux
  elif [ "$_PLATFORM" == 'mac' ]; then
    # TODO: install mac
    # install_mac
  else
    abort 'このOSは対応していません'
  fi

  exit 0
}

abort() {
  printf "%s\n" "$@"
  exit 1
}

detect_os() {
  if [ "$(uname)" == "Darwin" ]; then
    _PLATFORM=mac
  elif [ "$(expr substr $(uname -s) 1 5)" == "MINGW" ]; then
    _PLATFORM=windows
  elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    _PLATFORM=linux
  else
    _PLATFORM="Unknown OS"
    abort "Your platform ($(uname -a)) is not supported."
  fi
}

detect_distribution() {
  if [ -e /etc/lsb-release ]; then
    _DISTRIBUTION=ubuntu
    _DISTRIBUTION_VERSION=$(cat /etc/os-release | grep UBUNTU_CODENAME= | cut -c 17-)
    echo $_DISTRIBUTION
    echo $_DISTRIBUTION_VERSION
  elif [ -e /etc/debian_version ] || [ -e /etc/debian_release ]; then
    _DISTRIBUTION=debian
  elif [ -e /etc/redhat-release ]; then
    if [ -e /etc/oracle-release ]; then
      _DISTRIBUTION=oracle
    else
      _DISTRIBUTION=redhat
    fi
  elif [ -e /etc/fedora-release ]; then
    _DISTRIBUTION=fedora
  elif [ -e /etc/arch-release ]; then
    _DISTRIBUTION=arch
  else
    echo "Your distributio is not supported."
    _DISTRIBUTION="Unknown Distribution"
    exit 1
  fi
}

install_linux() {
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

# install_mac() {
#   # TODO: macOSの設定
# }

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
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] | $@" >> "$LOG_FILE"
  log
}

main