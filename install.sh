#!/usr/bin/env bash
# Script to install dependencies for dotfiles
set -euo pipefail

if ! command -v brew &> /dev/null
then
    echo "Brew is not installed. Installing brew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "Brew installed successfully."
    # Add brew to PATH for the rest of this script (Apple Silicon and Intel)
    if [ -f "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f "/usr/local/bin/brew" ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    echo "Brew is already installed."
fi

packages=(
    "tmux" "jq" "go" "fnm" "gpg" "tree-sitter-cli"
    "pinentry-mac" "pyenv" "webp" "rg" "zola" "fd" "fzf"
)

for pkg in "${packages[@]}"; do
    if ! brew list "$pkg" &>/dev/null; then
        echo "Installing $pkg..."
        brew install "$pkg"
    else
        echo "$pkg is already installed."
    fi
done

if ! brew list --cask aerospace &>/dev/null; then
    echo "Installing AeroSpace..."
    brew install --cask nikitabobko/tap/aerospace
else
    echo "AeroSpace is already installed."
fi

if [ ! -d "/Applications/Ghostty.app" ]; then
    echo "Installing Ghostty..."
    curl -fsSL "https://raw.githubusercontent.com/en9inerd/dotfiles-setup/master/install-ghostty.sh" | bash
else
    echo "Ghostty is already installed."
fi

if [ ! -f "$HOME/.nvim/bin/nvim" ]; then
    echo "Installing Neovim..."
    curl -fsSL "https://raw.githubusercontent.com/en9inerd/dotfiles-setup/master/install-neovim.sh" | bash
else
    echo "Neovim is already installed."
fi

SDFM_PATH="$HOME/.local/bin/sdfm"
if [ ! -f "$SDFM_PATH" ]; then
    echo "Downloading sdfm script..."
    mkdir -p "$(dirname "$SDFM_PATH")"
    curl -fsSL "https://raw.githubusercontent.com/en9inerd/sdfm/master/sdfm.sh" -o "$SDFM_PATH"
    chmod +x "$SDFM_PATH"
    echo "sdfm installed to $SDFM_PATH"
else
    echo "sdfm is already present at $SDFM_PATH"
fi

if [ -f "$HOME/.zshrc" ] && ! grep -qF 'export PATH="$PATH:$HOME/.local/bin"' "$HOME/.zshrc"; then
    echo "Adding ~/.local/bin to PATH in .zshrc..."
    echo -e '\n# Add local bin to PATH\nexport PATH="$PATH:$HOME/.local/bin"' >> "$HOME/.zshrc"
elif [ ! -f "$HOME/.zshrc" ]; then
    echo "Warning: ~/.zshrc not found, skipping PATH modification"
fi

echo "Dotfiles setup completed successfully."
