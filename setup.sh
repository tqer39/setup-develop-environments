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
    DISTRIBUTION_ID_LIKE="$(grep ^ID_LIKE= /etc/os-release)"
    DISTRIBUTION_ID_LIKE=${DISTRIBUTION_ID_LIKE#ID_LIKE=}
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
  setup_snap

  SOFTWARE_LIST=(
    brew
    asdf
    terminator
    postman
    pre-commit
    slack
    bash-completion
    im-config
    aws-vault
    awscli
    mysql-client
    jq
    session-manager-plugin
    1password
  )

  for software in "${SOFTWARE_LIST[@]}"; do
    check_confirm "$software"
  done
}

check_confirm() {
  if is_exists "$1"; then
    log "$1 is already installed"
    return
  elif is_exists brew; then
    if [ "$(brew list | grep -c "$1")" -gt 0 ]; then
      log "$1 is already installed"
      return
    fi
  fi

  if confirm "$1 をインストールします。よろしいですか？"; then
    case $1 in
      brew ) setup_brew ;;
      asdf ) setup_asdf ;;
      terminator ) setup_terminator ;;
      postman ) setup_postman ;;
      pre-commit ) setup_pre-commit ;;
      slack ) setup_slack ;;
      bash-completion ) setup_bash-completion ;;
      im-config ) setup_im-config ;;
      aws-vault ) setup_aws-vault ;;
      awscli ) setup_awscli ;;
      mysql-client ) setup_mysql-client ;;
      jq ) setup_jq ;;
      session-manager-plugin ) setup_session-manager-plugin ;;
      1password ) setup_1password ;;
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

is_linux() {
  if [ "$PLATFORM" == 'linux' ]; then
    return 0
  else
    return 1
  fi
}

is_ubuntu() {
  if [ "$DISTRIBUTION_ID_LIKE" = "ubuntu" ]; then
    return 0
  else
    return 1
  fi
}

is_mac() {
  if [ "$PLATFORM" == 'mac' ]; then
    return 0
  else
    return 1
  fi
}

setup_snap() {
  if is_linux; then
    log "setup_snap"

    if [ -e /etc/apt/preferences.d/nosnap.pref ]; then
      sudo rm /etc/apt/preferences.d/nosnap.pref
    fi

    if ! is_exists snap; then
      sudo apt update
      sudo apt install -y snapd
    fi
  fi
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

setup_terminator() {
  if is_linux; then
    if is_exists apt; then
      sudo apt install -y terminator
    elif is_exists yum; then
      sudo yum install -y terminator
    else
      abort "Your OS is not supported."
    fi
  fi

  if is_mac; then
    if is_exists brew; then
      brew install --build-from-source terminator
    fi
  fi
}

setup_postman() {
  if is_linux; then
    sudo snap install postman
  fi

  if is_mac; then
    brew install --cask postman
  fi
}

setup_pre-commit() {
  brew install pre-commit
}

setup_slack() {
  if is_linux; then
    if is_exists snap; then
      sudo snap install slack --classic
    else
      setup_snap
    fi
  fi

  if is_mac; then
    if is_exists brew; then
      brew install --cask slack
    else
      setup_brew
    fi
  fi
}

setup_bash-completion() {
  if is_exists brew; then
    brew install bash-completion@2
  else
    setup_brew
  fi
}

setup_im-config() {
  if is_linux && is_ubuntu; then
    echo 1111
    sudo apt update
    sudo apt-get install -y fcitx
    sudo apt-get install -y fcitx-frontend-gtk2 \
      fcitx-frontend-gtk3 \
      fcitx-ui-classic \
      fcitx-config-gtk \
      mozc-utils-gui \
      im-config
    im-config -n fcitx
  fi
}

setup_aws-vault() {
  if is_exists brew; then
    brew install aws-vault
  else
    setup_brew
  fi
}

setup_awscli() {
  if is_exists brew; then
    brew install awscli
  else
    setup_brew
  fi
}

setup_mysql-client() {
  if is_exists brew; then
    brew install mysql-client
  else
    setup_brew
  fi
}

setup_jq() {
  if is_exists brew; then
    brew install jq
  else
    setup_brew
  fi
}

setup_session-manager-plugin() {
  if is_ubuntu; then
    # see: https://docs.aws.amazon.com/ja_jp/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html
    if [ "$(arch)" = "x86_64" ]; then
      curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
      sudo dpkg -i session-manager-plugin.deb
      rm -rf session-manager-plugin.deb
    fi
  fi
}

setup_1password() {
  if is_ubuntu; then
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
    echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | sudo tee /etc/apt/sources.list.d/1password.list
    sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
    curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
    sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
    sudo apt update
    sudo apt install -y 1password
  fi

  if is_mac; then
    if is_exists brew; then
      brew install --cask 1password
    else
      setup_brew
    fi
  fi
}

# スクリプトのログファイルを残す関数
log() {
  mkdir -p "$PWD/log"
  echo "$1"
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] | $1" >> "$LOG_FILE"
}

main
