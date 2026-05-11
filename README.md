# dotfiles

Alacritty + zsh + Oh My Zsh + powerlevel10k configuration.

## Fresh machine setup

```bash
sudo apt install -y gh curl git zsh
gh auth login
git clone https://github.com/GabiMotroc/dotfiles.git ~/config/dotfiles
cd ~/config/dotfiles
bash setup.sh
```

After setup, optionally configure tools:
- [opencode](opencode.md) — LSP-enabled AI coding agent

Optionally install more tools:

```bash
./setup.sh --lazygit    # install lazygit
./setup.sh --lazydocker # install lazydocker
./setup.sh --all        # install everything
```
