#!/usr/bin/env bash
# Script to install dependencies for dotfiles
set -e

# Parse script arguments
for i in "$@"; do
    case $i in
        --fira-code=*) FIRA_CODE="${i#*=}"; shift ;;
        --dotfiles-repo=*) DOTFILES_REPO="${i#*=}"; shift ;;
        *) ;;
    esac
done

# Set default values
FIRA_CODE=${FIRA_CODE:-1}
DOTFILES_REPO=${DOTFILES_REPO:-"git@github.com:en9inerd/dotfiles.git"}
DOTFILES_DIR="$HOME/.dotfiles"
DOTFILES_MANAGER="$DOTFILES_DIR/scripts/dotfiles-manager.sh"

# Check if brew is installed
if ! command -v brew &> /dev/null
then
    echo "Brew is not installed. Installing brew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "Brew installed successfully."
else
    echo "Brew is already installed."
fi

# List of packages to install
packages=(
    "ghostty" "tmux" "jq" "go" "nvm" "gpg"
    "pinentry-mac" "pyenv" "webp" "rg" "zola" "fd", "fzf"
)

for pkg in "${packages[@]}"; do
    if ! brew list "$pkg" &>/dev/null; then
        echo "Installing $pkg..."
        brew install "$pkg"
    else
        echo "$pkg is already installed."
    fi
done

# Check if neovim is installed
if [ ! -f $HOME/.nvim/bin/nvim ];
then
    echo "Installing Neovim..."
    curl -fsSL "https://raw.githubusercontent.com/en9inerd/dotfiles-setup/master/install-neovim.sh" | bash
else
    echo "Neovim is already installed."
fi

# Fira Code font installation
if [ "$FIRA_CODE" -ne 0 ]; then
    FONT_URL="https://github.com/tonsky/FiraCode/releases/latest/download/Fira_Code_v6.2.zip"
    FONT_DIR="$HOME/Library/Fonts"
    if [ ! -f "$FONT_DIR/FiraCode-Regular.ttf" ]; then
        echo "Installing Fira Code font..."
        TEMP_DIR=$(mktemp -d)
        curl -L "$FONT_URL" -o "$TEMP_DIR/fira-code.zip"
        unzip -o "$TEMP_DIR/fira-code.zip" -d "$TEMP_DIR"
        cp "$TEMP_DIR/ttf/"* "$FONT_DIR"
        rm -rf "$TEMP_DIR"
        echo "Fira Code installed."
    else
        echo "Fira Code is already installed."
    fi
else
    echo "Skipping Fira Code installation."
fi

# Install sdfm script into ~/.local/bin
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

# Add ~/.local/bin to PATH if needed
if ! grep -q 'export PATH="$PATH:$HOME/.local/bin"' "$HOME/.zshrc"; then
    echo "Adding ~/.local/bin to PATH in .zshrc..."
    echo -e '\n# Add local bin to PATH\nexport PATH="$PATH:$HOME/.local/bin"' >> "$HOME/.zshrc"
fi

echo "✅ Dotfiles setup completed successfully."
