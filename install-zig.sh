#!/usr/bin/env bash
set -euo pipefail

# Script to install/update the latest Zig and ZLS binaries

TMP_DIR=""
cleanup() {
    [[ -n "$TMP_DIR" ]] && rm -rf "$TMP_DIR"
}

if [ -n "${1:-}" ]; then
    if [ ! -d "${1}" ]; then
        echo "Directory ${1} does not exist."
        exit 1
    fi
    TARGET_DIR="${1}"
else
    TARGET_DIR=$(pwd)
fi

# Use exact version if needed, for example: LATEST_ZIG_VERSION="0.13.0"
LATEST_ZIG_VERSION=$(curl -sf https://ziglang.org/download/index.json | jq -r '.master.version')
if [[ -z "$LATEST_ZIG_VERSION" || "$LATEST_ZIG_VERSION" == "null" ]]; then
    echo "Error: Failed to fetch Zig version from API"
    exit 1
fi

ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    ARCH="aarch64"
elif [ "$ARCH" != "x86_64" ]; then
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
if [ "$OS" = "darwin" ]; then
    OS="macos"
elif [ "$OS" = "linux" ]; then
    OS="linux"
else
    echo "Unsupported OS: $OS"
    exit 1
fi

TMP_DIR=$(mktemp -d)
trap cleanup EXIT

#---------------------------ZIG-----------------------------------

if [ -d "${TARGET_DIR}/zig" ]; then
    if CURRENT_ZIG_VERSION=$("${TARGET_DIR}/zig/zig" version 2>/dev/null | awk '{print $1}'); then
        if [ "$CURRENT_ZIG_VERSION" != "$LATEST_ZIG_VERSION" ]; then
            echo "Deleting old Zig version $CURRENT_ZIG_VERSION..."
            rm -rf "${TARGET_DIR}/zig"
        fi
    else
        echo "Existing Zig installation is broken, removing..."
        rm -rf "${TARGET_DIR}/zig"
    fi
fi

if [ ! -d "${TARGET_DIR}/zig" ]; then
    ZIG_TARBALL="zig-${ARCH}-${OS}-${LATEST_ZIG_VERSION}.tar.xz"
    ZIG_URL="https://ziglang.org/builds/${ZIG_TARBALL}"

    echo "Downloading Zig version $LATEST_ZIG_VERSION to $TMP_DIR..."
    curl -fL -o "${TMP_DIR}/${ZIG_TARBALL}" "$ZIG_URL"

    echo "Extracting Zig binary..."
    mkdir -p "${TARGET_DIR}/zig"
    tar -xf "${TMP_DIR}/${ZIG_TARBALL}" -C "${TARGET_DIR}/zig" --strip-components=1
    rm "${TMP_DIR}/${ZIG_TARBALL}"
fi

#---------------------------ZLS-----------------------------------

LATEST_ZLS_VERSION=$(curl -sf --get "https://releases.zigtools.org/v1/zls/select-version" --data-urlencode "zig_version=${LATEST_ZIG_VERSION}" --data-urlencode "compatibility=only-runtime" | jq -r '.version')
if [[ -z "$LATEST_ZLS_VERSION" || "$LATEST_ZLS_VERSION" == "null" ]]; then
    echo "Error: Failed to fetch ZLS version from API"
    exit 1
fi

if [ -d "${TARGET_DIR}/zls" ]; then
    if CURRENT_ZLS_VERSION=$("${TARGET_DIR}/zls/zls" --version 2>/dev/null | awk '{print $1}'); then
        if [ "$CURRENT_ZLS_VERSION" != "$LATEST_ZLS_VERSION" ]; then
            echo "Deleting old ZLS version $CURRENT_ZLS_VERSION..."
            rm -rf "${TARGET_DIR}/zls"
        fi
    else
        echo "Existing ZLS installation is broken, removing..."
        rm -rf "${TARGET_DIR}/zls"
    fi
fi

if [ ! -d "${TARGET_DIR}/zls" ]; then
    ZLS_TARBALL="zls-${ARCH}-${OS}-${LATEST_ZLS_VERSION}.tar.xz"
    ZLS_URL="https://builds.zigtools.org/${ZLS_TARBALL}"

    echo "Downloading ZLS version $LATEST_ZLS_VERSION to $TMP_DIR..."
    curl -fL -o "${TMP_DIR}/${ZLS_TARBALL}" "$ZLS_URL"

    echo "Extracting ZLS binary..."
    mkdir -p "${TARGET_DIR}/zls"
    tar -xf "${TMP_DIR}/${ZLS_TARBALL}" -C "${TARGET_DIR}/zls"
    rm "${TMP_DIR}/${ZLS_TARBALL}"
fi

printf "Zig and ZLS have been updated successfully in %s.\n" "${TARGET_DIR}"
printf "Zig version: %s\n" "$LATEST_ZIG_VERSION"
printf "ZLS version: %s\n" "$LATEST_ZLS_VERSION"
printf "\nPlease make sure to add the Zig and ZLS directories to your PATH.\n"
printf "For example, add the following lines to your shell configuration file:\n"
printf "export PATH=\"%s/zig:\$PATH\"\n" "${TARGET_DIR}"
printf "export PATH=\"%s/zls:\$PATH\"\n" "${TARGET_DIR}"
