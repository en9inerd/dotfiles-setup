#!/usr/bin/env bash

# Script to install dependencies for dotfiles

# Parse script arguments
for i in "$@"
do
case $i in
    --fira-code=*)
    FIRA_CODE="${i#*=}"
    shift
    ;;
    --dotfiles-repo=*)
    DOTFILES_REPO="${i#*=}"
    shift
    ;;
    *)
    # unknown option
    ;;
esac
done

# Set default values
FIRA_CODE=${FIRA_CODE:-1}
DOTFILES_REPO=${DOTFILES_REPO:-"git@github.com:en9inerd/dotfiles.git"}

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
packages=("lazygit" "jq" "go" "nvm" "gpg" "pinentry-mac" "pyenv" "webp" "rg" "zola")

for pkg in "${packages[@]}"; do
    if ! command -v "$pkg" &> /dev/null; then
        echo "$pkg is not installed. Installing $pkg..."
        brew install "$pkg"
        echo "$pkg installed successfully."
    else
        echo "$pkg is already installed."
    fi
done

# Check if neovim is installed
if ! command -v nvim &> /dev/null
then
    echo "Neovim is not installed. Installing neovim..."
    curl -fsSL "https://raw.githubusercontent.com/en9inerd/dotfiles-setup/master/install-neovim.sh" | bash
else
    echo "Neovim is already installed."
fi

# Check if Fira Code is installed
if [ "$fira_code" -eq 0 ]; then
    echo "Skipping Fira Code installation."
else
    FONT_URL="https://github.com/tonsky/FiraCode/releases/latest/download/Fira_Code_v6.2.zip"
    TEMP_DIR=$(mktemp -d)
    FONT_DIR="$HOME/Library/Fonts"
    if [ ! -f "$FONT_DIR/FiraCode-Regular.ttf" ]; then
        echo "Fira Code is not installed. Installing Fira Code..."
        curl -L "$FONT_URL" -o "$TEMP_DIR/fira-code.zip"
        unzip -o "$TEMP_DIR/fira-code.zip" -d "$TEMP_DIR"
        cp "$TEMP_DIR/ttf/"* "$FONT_DIR"
        rm -rf "$TEMP_DIR"
        echo "Fira Code installed successfully."
    else
        echo "Fira Code is already installed."
    fi
fi

# Clone dotfiles repository
DOTFILES_DIR="$HOME/.dotfiles"
DOTFILES_REPO="git@github.com:en9inerd/dotfiles.git"
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Cloning dotfiles repository..."
    git clone --bare "$DOTFILES_REPO" "$DOTFILES_DIR"
    echo "Dotfiles repository cloned successfully."
else
    echo "Dotfiles repository is already cloned."
fi

# Checkout dotfiles repository
echo "Checking out dotfiles repository..."
git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" checkout -f

# Download dotfiles-manager.sh script if not available
if [ ! -f "$HOME/.dotfiles/scripts/dotfiles-manager.sh" ]; then
    echo "Downloading dotfiles manager script..."
    curl -fsSL "https://raw.githubusercontent.com/en9inerd/dotfiles-setup/master/dotfiles-manager.sh" -o "$HOME/.dotfiles/scripts/dotfiles-manager.sh"
fi

# Init dotfiles command as alias in .zshrc that points to dotfiles script
if ! grep -q "alias dotfiles=" "$HOME/.zshrc"; then
    echo "Adding dotfiles alias to .zshrc..."
    echo "Script to manage dotfiles" >> "$HOME/.zshrc"
    echo "alias dotfiles='$DOTFILES_DIR/scripts/dotfiles-manager.sh'" >> "$HOME/.zshrc"
    source "$HOME/.zshrc"
    echo "Dotfiles alias added successfully."
else
    echo "Dotfiles alias is already added to .zshrc."
fi
