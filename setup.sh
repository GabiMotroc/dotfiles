#!/bin/bash
set -e

echo "Installing zsh..."
sudo apt install -y zsh

echo "Installing Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

echo "Installing powerlevel10k..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

echo "Installing plugins..."
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

echo "Copying configs..."
cp alacritty.toml ~/.config/alacritty/alacritty.toml 2>/dev/null || (
    mkdir -p ~/.config/alacritty && cp alacritty.toml ~/.config/alacritty/alacritty.toml)
cp .zshrc ~/.zshrc

echo "Setting zsh as default shell..."
chsh -s $(which zsh)

echo "Done! Log out and back in."
