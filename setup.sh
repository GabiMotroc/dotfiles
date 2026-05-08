#!/bin/bash
set -e

INSTALL_LAZYGIT=false
INSTALL_LAZYDOCKER=false
PROMPT=true

for arg in "$@"; do
    case $arg in
        --lazygit) INSTALL_LAZYGIT=true; PROMPT=false ;;
        --lazydocker) INSTALL_LAZYDOCKER=true; PROMPT=false ;;
        --all) INSTALL_LAZYGIT=true; INSTALL_LAZYDOCKER=true; PROMPT=false ;;
    esac
done

if [ "$PROMPT" = true ]; then
    read -p "Install lazygit? (y/N): " reply
    [[ "$reply" =~ ^[Yy]$ ]] && INSTALL_LAZYGIT=true
    read -p "Install lazydocker? (y/N): " reply
    [[ "$reply" =~ ^[Yy]$ ]] && INSTALL_LAZYDOCKER=true
fi

install_or_update() {
    local url=$1 dir=$2 name=$3
    if [ ! -d "$dir" ]; then
        echo "Installing $name..."
        mkdir -p "$(dirname "$dir")"
        git clone --depth=1 "$url" "$dir"
    else
        echo "Updating $name..."
        git -C "$dir" pull --ff-only
    fi
}

apt_install() {
    local packages=("$@")
    sudo apt install -y "${packages[@]}"
}

echo "Installing system packages..."
apt_install zsh gh curl git

if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

install_or_update https://github.com/romkatv/powerlevel10k.git \
    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" powerlevel10k

for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    install_or_update "https://github.com/zsh-users/$plugin.git" \
        "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin" "$plugin"
done

echo "Copying configs..."
mkdir -p ~/.config/alacritty
cp alacritty.toml ~/.config/alacritty/alacritty.toml
cp .zshrc ~/.zshrc

if [ "$INSTALL_LAZYGIT" = true ] && ! command -v lazygit &>/dev/null; then
    echo "Installing lazygit..."
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
    curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    sudo tar xf /tmp/lazygit.tar.gz -C /usr/local/bin lazygit
    rm /tmp/lazygit.tar.gz
fi

if [ "$INSTALL_LAZYDOCKER" = true ] && ! command -v lazydocker &>/dev/null; then
    echo "Installing lazydocker..."
    curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
fi

if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Setting zsh as default shell..."
    chsh -s "$(which zsh)"
fi

echo "Done! Log out and back in."
