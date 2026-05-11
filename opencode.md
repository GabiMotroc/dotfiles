# opencode

Enable LSP and other config for opencode.

## Setup

### Linux

```bash
ln -s ~/config/dotfiles/.config/opencode/config.json ~/.config/opencode/config.json
```

### Windows

```cmd
mklink "%APPDATA%\opencode\config.json" "%USERPROFILE%\config\dotfiles\.config\opencode\config.json"
```

## Verify

```bash
opencode debug lsp diagnostics <file>
```
