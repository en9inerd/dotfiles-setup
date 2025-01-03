#!/bin/bash

# Script to install/update the latest Zig and ZLS binaries

# Define the target directory
if [ -n "$1" ]; then
    # check if the specified directory exists
    if [ ! -d "$1" ]; then
        echo "Directory $1 does not exist."
        exit 1
    fi
    TARGET_DIR=$1
else
    TARGET_DIR=$(pwd)
fi

# Fetch the latest Zig version from the official Zig download page (master branch)
# Use exact version if needed, for example: LATEST_ZIG_VERSION="0.13.0"
LATEST_ZIG_VERSION=$(curl -s https://ziglang.org/download/index.json | jq -r '.master.version')

# Determine the system architecture
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    ARCH="x86_64"
elif [ "$ARCH" = "arm64" ]; then
    ARCH="aarch64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# Determine the operating system
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
if [ "$OS" = "darwin" ]; then
    OS="macos"
elif [ "$OS" = "linux" ]; then
    OS="linux"
else
    echo "Unsupported OS: $OS"
    exit 1
fi

# Create a temporary directory for downloads
TMP_DIR=$(mktemp -d)

#---------------------------ZIG-----------------------------------

# Check existing Zig version and delete if it is different
if [ -d "${TARGET_DIR}/zig" ]; then
    CURRENT_ZIG_VERSION=$("${TARGET_DIR}/zig/zig" version | awk '{print $1}')
    if [ "$CURRENT_ZIG_VERSION" != "$LATEST_ZIG_VERSION" ]; then
        echo "Deleting old Zig version $CURRENT_ZIG_VERSION..."
        rm -rf "${TARGET_DIR}/zig"
    fi
fi

# Download the latest Zig binary if not already present
if [ ! -d "${TARGET_DIR}/zig" ]; then
    ZIG_TARBALL="zig-${OS}-${ARCH}-${LATEST_ZIG_VERSION}.tar.xz"
    ZIG_URL="https://ziglang.org/builds/${ZIG_TARBALL}"

    echo "Downloading Zig version $LATEST_ZIG_VERSION to $TMP_DIR..."
    curl -L -o "${TMP_DIR}/${ZIG_TARBALL}" "$ZIG_URL"

    echo "Extracting Zig binary..."
    mkdir -p "${TARGET_DIR}/zig"
    tar -xf "${TMP_DIR}/${ZIG_TARBALL}" -C "${TARGET_DIR}/zig" --strip-components=1
    rm "${TMP_DIR}/${ZIG_TARBALL}"
fi

#---------------------------ZLS-----------------------------------

# Fetch the latest ZLS version from the official ZLS release page using installed Zig version
LATEST_ZLS_VERSION=$(curl -s --get "https://releases.zigtools.org/v1/zls/select-version" --data-urlencode "zig_version=${LATEST_ZIG_VERSION}" --data-urlencode "compatibility=only-runtime" | jq -r '.version')

# Check existing ZLS version and delete if it is different
if [ -d "${TARGET_DIR}/zls" ]; then
    CURRENT_ZLS_VERSION=$("${TARGET_DIR}/zls/zls" --version | awk '{print $1}')
    if [ "$CURRENT_ZLS_VERSION" != "$LATEST_ZLS_VERSION" ]; then
        echo "Deleting old ZLS version $CURRENT_ZLS_VERSION..."
        rm -rf "${TARGET_DIR}/zls"
    fi
fi

# Download the latest ZLS binary if not already present
if [ ! -d "${TARGET_DIR}/zls" ]; then
    ZLS_TARBALL="zls-${OS}-${ARCH}-${LATEST_ZLS_VERSION}.tar.xz"
    ZLS_URL="https://builds.zigtools.org/${ZLS_TARBALL}"

    echo "Downloading ZLS..."
    curl -L -o "${TMP_DIR}/${ZLS_TARBALL}" "$ZLS_URL"

    echo "Extracting ZLS binary..."
    mkdir -p "${TARGET_DIR}/zls"
    tar -xf "${TMP_DIR}/${ZLS_TARBALL}" -C "${TARGET_DIR}/zls"
    rm "${TMP_DIR}/${ZLS_TARBALL}"
fi

# Cleanup temporary directory
rm -rf "$TMP_DIR"

printf "Zig and ZLS have been updated successfully in %s.\n" "${TARGET_DIR}"
printf "Zig version: %s\n" "$LATEST_ZIG_VERSION"
printf "ZLS version: %s\n" "$LATEST_ZLS_VERSION"
printf "\nPlease make sure to add the Zig and ZLS directories to your PATH.\n"
printf "For example, add the following lines to your shell configuration file:\n"
printf "export PATH=\"%s/zig:\$PATH\"\n" "${TARGET_DIR}"
printf "export PATH=\"%s/zls:\$PATH\"\n" "${TARGET_DIR}"
