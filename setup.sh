#!/bin/bash

set -eu

LOG_FILE="$PWD/log/$(date +'%Y-%m-%d_%H-%M-%S').log"
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
  brew-cask-completion
  git
  op
  newman
  docker
  google-chrome
  java
  gh
  eb
  fish
  fisher
  fzf
  z
  omf
  bd
  bass
  bat
  fd
)

main() {
  detect_os

  if [ ! is_linux ] && [ ! is_mac ]; then
    abort 'このOSは対応していません'
  fi

  if is_linux; then
    detect_distribution
  fi

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
    log "DISTRIBUTION: $DISTRIBUTION"

    DISTRIBUTION_VERSION_ID="$(grep ^VERSION_ID= /etc/os-release)"
    DISTRIBUTION_VERSION_ID=${DISTRIBUTION_VERSION_ID#VERSION_ID=}
    DISTRIBUTION_VERSION_ID=${DISTRIBUTION_VERSION_ID//\"/}
    log "DISTRIBUTION_VERSION_ID: $DISTRIBUTION_VERSION_ID"

    DISTRIBUTION_ID_LIKE="$(grep ^ID_LIKE= /etc/os-release)"
    DISTRIBUTION_ID_LIKE=${DISTRIBUTION_ID_LIKE#ID_LIKE=}
    log "DISTRIBUTION_ID_LIKE: $DISTRIBUTION_ID_LIKE"

    UBUNTU_CODENAME="$(grep ^UBUNTU_CODENAME= /etc/os-release)"
    UBUNTU_CODENAME=${UBUNTU_CODENAME#UBUNTU_CODENAME=}
    log "UBUNTU_CODENAME: $UBUNTU_CODENAME"
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

  for software in "${SOFTWARE_LIST[@]}"; do
    check_confirm "$software"
  done
}

# only install if not installed
check_confirm() {
  INSTALLED=false

  # fish shell: plugins
  case $1 in
    fisher ) [ -e "$HOME/.config/fish/functions/fisher.fish" ] && INSTALLED=true ;;
    z      ) [ -e "$HOME/.config/fish/conf.d/z.fish" ]         && INSTALLED=true ;;
    omf    ) [ -e "$HOME/.config/fish/conf.d/omf.fish" ]       && INSTALLED=true ;;
    bd     ) [ -e "$HOME/.config/fish/functions/bd.fish" ]     && INSTALLED=true ;;
    bass   ) [ -e "$HOME/.config/fish/functions/bass.fish" ]   && INSTALLED=true ;;
  esac

  if is_exists "$1"; then
      INSTALLED=true
  elif is_exists brew; then
    if [ "$(brew list | grep -c "^$1@*.*$")" -gt 0 ]; then
      INSTALLED=true
    fi
  fi

  if "${INSTALLED}"; then
    log "$1 is already installed"
    return
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
      brew-cask-completion ) setup_brew-cask-completion ;;
      git ) setup_git ;;
      op ) setup_1password-cli ;;
      newman ) setup_newman ;;
      docker ) setup_docker ;;
      google-chrome ) setup_google-chrome ;;
      java ) setup_openjdk ;;
      gh ) setup_gh ;;
      eb ) setup_awsebcli ;;
      fish ) setup_fish ;;
      fisher ) setup_fisher ;;
      fzf ) setup_fzf ;;
      z ) setup_z ;;
      omf ) setup_omf ;;
      bd ) setup_bd ;;
      bass ) setup_bass ;;
      bat ) setup_bat ;;
      fd ) setup_fd ;;
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

is_linux_mint() {
  if [ "$DISTRIBUTION" == "Linux Mint" ]; then
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

setup_brew-cask-completion() {
  if is_exists brew; then
    brew install brew-cask-completion
  else
    setup_brew
  fi
}

setup_git() {
  if is_exists brew; then
    brew install git
  else
    setup_brew
  fi
}

setup_1password-cli() {
  if is_linux; then
    if is_ubuntu; then
      _1PASSWORD_CLI_VERSION=1.12.4
      if [ "$(arch)" = "x86_64" ]; then
        CPU=amd64
      fi
      FILE_NAME="op_linux_${CPU}_v${_1PASSWORD_CLI_VERSION}.zip"
      mkdir -p ./tmp
      curl "https://cache.agilebits.com/dist/1P/op/pkg/v${_1PASSWORD_CLI_VERSION}/$FILE_NAME" -o "./tmp/$FILE_NAME"
      unzip "./tmp/op_linux_${CPU}_v${_1PASSWORD_CLI_VERSION}.zip" -d ./tmp
      gpg --receive-keys 3FEF9748469ADBE15DA7CA80AC2D62742012EA22
      gpg --verify op.sig op
      sudo mv ./tmp/op ./tmp/op.sig /usr/local/bin/.
      rm -rf ./tmp/"$FILE_NAME"
    fi
  fi

  if is_mac; then
    if is_exists brew; then
      brew install --cask 1password-cli
    else
      setup_brew
    fi
  fi
}

setup_newman() {
  if is_exists brew; then
    brew install newman
  else
    setup_brew
  fi
}

setup_docker() {
  if is_linux; then
    if is_ubuntu; then
      sudo apt update
      sudo apt install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg-agent \
        software-properties-common
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
      sudo apt-key fingerprint 0EBFCD88
      CPU=amd64
      if [ "$(arch)" = "x86_64" ]; then
        CPU=amd64
      fi
      if [ ! -e /etc/apt/sources.list.d/docker-ce.list ]; then
        sudo add-apt-repository \
          "deb [arch=${CPU}] https://download.docker.com/linux/ubuntu $UBUNTU_CODENAME stable"
      fi
      sudo apt update
      sudo apt install -y docker-ce docker-ce-cli containerd.io
      sudo gpasswd -a "$USER" docker
      sudo usermod -aG docker "$USER"
      sudo cat /etc/group | grep docker
      sudo systemctl enable docker
      sudo systemctl restart docker
      sudo systemctl daemon-reload
      sudo systemctl status docker
    fi
  fi

  if is_mac; then
    if is_exists brew; then
      brew install --cask docker
    else
      setup_brew
    fi
  fi

  # docker-composeはdockerに同梱されたので一緒にインストールする
  setup_docker-compose
}

setup_google-chrome() {
  if is_linux; then
    if is_ubuntu; then
      CPU=amd64
      if [ "$(arch)" = "x86_64" ]; then
        CPU=amd64
      fi
      sudo add-apt-repository -y \
        "deb [arch=${CPU}] http://dl.google.com/linux/chrome/deb/ stable main"
      wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
      sudo apt update
      sudo apt install -y google-chrome-stable
      sudo rm -rf /etc/apt/sources.list.d/google-chrome.list
    fi
  fi

  if is_mac; then
    if is_exists brew; then
      brew install --cask google-chrome
    else
      setup_brew
    fi
  fi
}

setup_openjdk() {
  if is_exists brew; then
    brew install openjdk@11
  else
    setup_brew
  fi
}

# see: https://github.com/docker/compose/releases
setup_docker-compose() {
  if is_linux; then
    if is_ubuntu; then
      DOCKER_COMPOSE_VERSION=2.2.3
      mkdir -p ~/.docker/cli-plugins/
      curl -SL "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-linux-$(arch)" -o ~/.docker/cli-plugins/docker-compose
      chmod +x ~/.docker/cli-plugins/docker-compose
    fi
  fi
}

setup_gh() {
  if is_exists brew; then
    brew install gh
  else
    setup_brew
  fi
}

setup_awsebcli() {
  if is_exists brew; then
    brew install awsebcli
  else
    setup_brew
  fi
}

setup_fish() {
  if is_exists brew; then
    brew install fish
  else
    setup_brew
  fi
}

setup_fisher() {
  if [ ! -e "$HOME/.config/fish/functions/fisher.fish" ]; then
    curl https://git.io/fisher --create-dirs -sLo "$HOME/.config/fish/functions/fisher.fish"
  fi
}

setup_fzf() {
  if is_exists brew; then
    if is_exists fish; then
      if [ "$(fish -c "fisher ls jethrokuan/fzf" | grep -c "^jethrokuan/fzf$")" = 0 ]; then
        brew install fzf
        fish -c "fisher install jethrokuan/fzf"
        # MEMO: 各種 shell の設定ファイルに追記するスクリプト。bash,zsh,fishすべて設定済なので処理不要
        # "$HOME/.fzf/install" --all
      fi
    else
      setup_fish
    fi
  else
    setup_brew
  fi
}

setup_z() {
  if is_exists brew; then
    brew install z
    if is_exists fish; then
      if [ "$(fish -c "fisher ls jethrokuan/z" | grep -c "^jethrokuan/z$")" = 0 ]; then
        fish -c "fisher install jethrokuan/z"
      fi
    else
      setup_fish
    fi
  else
    setup_brew
  fi
}

setup_omf() {
  if is_exists fish; then
    if [ "$(fish -c "fisher ls oh-my-fish/theme-bobthefish" | grep -c "^oh-my-fish/theme-bobthefish$")" = 0 ]; then
      fish -c "fisher install oh-my-fish/theme-bobthefish"
    fi
  else
    setup_fish
  fi
}

setup_bd() {
  if is_exists fish; then
    if [ "$(fish -c "fisher ls 0rax/fish-bd" | grep -c "^0rax/fish-bd$")" = 0 ]; then
      fish -c "fisher install 0rax/fish-bd"
    fi
  else
    setup_fish
  fi
}

setup_bass() {
  if is_exists fish; then
    if [ "$(fish -c "fisher ls edc/bass" | grep -c "^edc/bass$")" = 0 ]; then
      fish -c "fisher install edc/bass"
    fi
  else
    setup_fish
  fi
}

setup_bat() {
  if is_exists brew; then
    brew install bat
  else
    setup_brew
  fi
}

setup_fd() {
  if is_exists brew; then
    brew install fd
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

versions() {
  for software in "${SOFTWARE_LIST[@]}"; do
    if is_exists "$software"; then
      case $software in
        brew ) log "brew: $(brew -v | head -n 1)" ;;
        asdf ) log "asdf: $(asdf --version)" ;;
        terminator ) log "terminator: $(terminator -v)" ;;
        # TODO: aws-vaultはログの出力形式が特殊なので改行してしまう
        aws-vault )
          log "aws-vault: "
          aws-vault --version ;;
        pre-commit ) log "pre-commit: $(pre-commit -V)" ;;
        awscli ) log "awscli: $(aws --version)" ;;
        mysql-client ) log "mysql-client: $(mysql -V)" ;;
        jq ) log "jq: $(jq --version)" ;;
        session-manager-plugin ) log "session-manager-plugin: $(session-manager-plugin --version)" ;;
        git ) log "git: $(git --version)" ;;
        op ) log "1password-cli: $(op --version)" ;;
        newman ) log "newman: $(newman -v)" ;;
        docker )
          log "docker: $(docker -v)"
          log "docker-compose: $(docker compose version)" ;;
        java )
          log "openjdk(java): "
          java -version ;;
        gh ) log "gh: $(gh version | head -n 1)" ;;
        eb ) log "awsebcli: $(eb --version | head -n 1)" ;;
        fish ) log "fish: $(fish -v)" ;;
        fisher ) log "fisher: $(fisher -v)" ;;
        fzf ) log "fzf: $(fzf --version)" ;;
      esac
    fi
  done
}

if [ "$#" == 0 ]; then
  main
elif [ "$1" == "versions" ]; then
  versions
fi
