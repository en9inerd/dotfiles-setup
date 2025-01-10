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
DOTFILES_DIR="$HOME/.dotfiles"

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
    if ! brew list "$pkg" &> /dev/null; then
        echo "$pkg is not installed. Installing $pkg..."
        brew install "$pkg"
        echo "$pkg installed successfully."
    else
        echo "$pkg is already installed."
    fi
done

# Check if neovim is installed
if [ ! -f $HOME/.nvim/bin/nvim ];
then
    echo "Neovim is not installed. Installing neovim..."
    curl -fsSL "https://raw.githubusercontent.com/en9inerd/dotfiles-setup/master/install-neovim.sh" | bash
else
    echo "Neovim is already installed."
fi

# Check if Fira Code is installed
if [ "$FIRA_CODE" -eq 0 ]; then
    echo "Skipping Fira Code installation."
else
    FONT_URL="https://github.com/tonsky/FiraCode/releases/latest/download/Fira_Code_v6.2.zip"
    TEMP_DIR=$(mktemp -d)
    FONT_DIR="$HOME/Library/Fonts"
    if [ ! -f "$FONT_DIR/FiraCode-Regular.ttf" ]; then
        echo "Fira Code is not installed. Installing Fira Code..."
        echo "Downloading Fira Code to $TEMP_DIR..."
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
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Cloning dotfiles repository..."
    git clone --bare "$DOTFILES_REPO" "$DOTFILES_DIR"
    echo "Dotfiles repository cloned successfully."
else
    echo "Dotfiles repository is already cloned."
fi

# Download dotfiles-manager.sh script if not available
DOTFILES_MANAGER="$DOTFILES_DIR/scripts/dotfiles-manager.sh"
if [ ! -f "$DOTFILES_MANAGER" ]; then
    echo "Downloading dotfiles manager script..."
    mkdir -p "$(dirname "$DOTFILES_MANAGER")"
    curl -fsSL "https://raw.githubusercontent.com/en9inerd/dotfiles-setup/master/dotfiles-manager.sh" -o "$DOTFILES_MANAGER"
    chmod +x "$DOTFILES_MANAGER"
fi

# Add dotfiles alias to .zshrc
if ! grep -q "alias dotfiles=" "$HOME/.zshrc"; then
    echo "Adding dotfiles alias to .zshrc..."
    echo "# Dotfiles management script" >> "$HOME/.zshrc"
    echo -e "alias dotfiles='\$HOME/.dotfiles/scripts/dotfiles-manager.sh'\n" >> "$HOME/.zshrc"
    echo "Dotfiles alias added successfully."
else
    echo "Dotfiles alias is already added to .zshrc"
fi

# Configure bare repository
/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME config status.showUntrackedFiles no

# Checkout dotfiles repository
echo "Checking out dotfiles repository..."
if ! $DOTFILES_MANAGER checkout; then
    echo "Error during checkout. There may be conflicts with existing files."
    echo "Please resolve the conflicts and rerun the script."
    exit 1
fi

echo "Dotfiles setup completed successfully."
