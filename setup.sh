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

echo "Installing zsh, gh, curl, git..."
sudo apt install -y zsh gh curl git

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Oh My Zsh already installed"
fi

ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    echo "Installing powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
else
    echo "Updating powerlevel10k..."
    git -C "$ZSH_CUSTOM/themes/powerlevel10k" pull --ff-only
fi

for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    if [ ! -d "$ZSH_CUSTOM/plugins/$plugin" ]; then
        echo "Installing $plugin..."
        git clone https://github.com/zsh-users/$plugin.git "$ZSH_CUSTOM/plugins/$plugin"
    else
        echo "Updating $plugin..."
        git -C "$ZSH_CUSTOM/plugins/$plugin" pull --ff-only
    fi
done

echo "Copying configs..."
cp alacritty.toml ~/.config/alacritty/alacritty.toml 2>/dev/null || (
    mkdir -p ~/.config/alacritty && cp alacritty.toml ~/.config/alacritty/alacritty.toml)
cp .zshrc ~/.zshrc

if [ "$INSTALL_LAZYGIT" = true ]; then
    echo "Installing lazygit..."
    sudo apt install -y lazygit
fi

if [ "$INSTALL_LAZYDOCKER" = true ]; then
    if command -v lazydocker &>/dev/null; then
        echo "lazydocker already installed"
    else
        echo "Installing lazydocker..."
        curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
    fi
fi

if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Setting zsh as default shell..."
    chsh -s $(which zsh)
else
    echo "zsh is already the default shell"
fi

echo "Done! Log out and back in."
