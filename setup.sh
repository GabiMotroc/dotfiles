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

install_or_update https://github.com/romkatv/powerlevel10k.git \
    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" powerlevel10k

for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    install_or_update "https://github.com/zsh-users/$plugin.git" \
        "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin" "$plugin"
done

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

echo "Copying configs..."
mkdir -p ~/.config/alacritty
cp alacritty.toml ~/.config/alacritty/alacritty.toml
cp .zshrc ~/.zshrc

if [ "$INSTALL_LAZYGIT" = true ]; then
    echo "Installing lazygit..."
    apt_install lazygit
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
