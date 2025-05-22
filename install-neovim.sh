#!/bin/bash

# Script to install/update neovim in ~/.nvim

PLATFORM=$(uname -s)
if [ "$PLATFORM" == "Darwin" ]; then
    echo "Detected macOS"
    PLATFORM="macos"
elif [ "$PLATFORM" == "Linux" ]; then
    echo "Detected Linux"
    PLATFORM="linux"
else
    echo "Unsupported platform"
    exit 1
fi

ARCH=$(uname -m)
if [ "$ARCH" == "x86_64" ]; then
    ARCH="x64"
elif [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
    ARCH="arm64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

NEOVIM_VERSION="v0.11.0"
DOWNLOAD_URL="https://github.com/neovim/neovim/releases/download/$NEOVIM_VERSION/nvim-${PLATFORM}-${ARCH}.tar.gz"
INSTALL_DIR="$HOME/.nvim"
TMP_DIR=$(mktemp -d)

echo "Temporary directory: $TMP_DIR"

# Remove existing installation if present
if [ -d "$INSTALL_DIR" ]; then
    echo "Updating neovim"
    rm -rf "$INSTALL_DIR"
else
    echo "Installing neovim"
fi

# Download and extract the archive
echo "Downloading neovim from $DOWNLOAD_URL"
curl -L "$DOWNLOAD_URL" -o "$TMP_DIR/nvim-${PLATFORM}-${ARCH}.tar.gz"
if [ $? -ne 0 ]; then
    echo "Error downloading Neovim. Please check the URL and try again."
    exit 1
fi

mkdir -p "$INSTALL_DIR"
echo "Extracting archive..."
tar xzf "$TMP_DIR/nvim-${PLATFORM}-${ARCH}.tar.gz" -C "$INSTALL_DIR" --strip-components=1
if [ $? -ne 0 ]; then
    echo "Error extracting Neovim archive."
    rm -f "$TMP_DIR/nvim-${PLATFORM}-${ARCH}.tar.gz"
    exit 1
fi

# Cleanup temporary directory
rm -rf $TMP_DIR

echo "Neovim installed at $INSTALL_DIR"
echo "You can run Neovim using: $INSTALL_DIR/bin/nvim"
