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
    "ghostty" "tmux" "lazygit" "jq" "go" "nvm" "gpg"
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

# Clone dotfiles as bare repo if not already cloned
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Cloning dotfiles repository using --separate-git-dir..."
    TEMP_CLONE_DIR=$(mktemp -d)
    git clone --separate-git-dir="$DOTFILES_DIR" "$DOTFILES_REPO" "$TEMP_CLONE_DIR"

    echo "Backing up conflicting files before checkout..."
    mkdir -p "$HOME/dotfiles-backup"
    git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" ls-tree -r --name-only HEAD | while read -r file; do
        if [ -e "$HOME/$file" ]; then
            mkdir -p "$(dirname "$HOME/dotfiles-backup/$file")"
            cp -p "$HOME/$file" "$HOME/dotfiles-backup/$file"
        fi
    done

    cp -rT "$TEMP_CLONE_DIR" "$HOME"
    rm -rf "$TEMP_CLONE_DIR"
    echo "Dotfiles checked out."
else
    echo "Dotfiles repo already exists at $DOTFILES_DIR."
fi

# Configure bare repository
/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME config status.showUntrackedFiles no

# Download dotfiles-manager.sh
if [ ! -f "$DOTFILES_MANAGER" ]; then
    echo "Downloading dotfiles manager script..."
    mkdir -p "$(dirname "$DOTFILES_MANAGER")"
    curl -fsSL "https://raw.githubusercontent.com/en9inerd/dotfiles-setup/master/dotfiles-manager.sh" -o "$DOTFILES_MANAGER"
    chmod +x "$DOTFILES_MANAGER"
fi

# Add alias to .zshrc
if ! grep -q "alias dotfiles=" "$HOME/.zshrc"; then
    echo "Adding dotfiles alias to .zshrc..."
    echo -e "\n# Dotfiles management\nalias dotfiles='$DOTFILES_MANAGER'" >> "$HOME/.zshrc"
else
    echo "Dotfiles alias already present in .zshrc."
fi

echo "✅ Dotfiles setup completed successfully."
