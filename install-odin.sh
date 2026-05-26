#!/usr/bin/env bash
set -e

# Script to install/update Odin compiler and OLS (Odin Language Server)
# Usage: install-odin.sh [target_dir] [odin_version]
#   odin_version: "latest" (default) or a release tag like "dev-2024-09"
#   Also configurable via ODIN_VERSION env var

TMP_DIR=""
cleanup() {
    [[ -n "$TMP_DIR" ]] && rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if [ -n "${1:-}" ]; then
    if [ ! -d "${1}" ]; then
        echo "Directory ${1} does not exist."
        exit 1
    fi
    TARGET_DIR="${1}"
else
    TARGET_DIR=$(pwd)
fi

ODIN_VERSION="${2:-${ODIN_VERSION:-latest}}"

ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    ODIN_ARCH="arm64"
elif [ "$ARCH" = "x86_64" ]; then
    ODIN_ARCH="amd64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
if [ "$OS" = "darwin" ]; then
    ODIN_OS="macos"
elif [ "$OS" = "linux" ]; then
    ODIN_OS="ubuntu"
else
    echo "Unsupported OS: $OS"
    exit 1
fi

TMP_DIR=$(mktemp -d)

#---------------------------ODIN-----------------------------------

GH_ODIN_API="https://api.github.com/repos/odin-lang/Odin/releases"
JQ_FILTER='{tag_name, assets: [.assets[] | {name, browser_download_url}]}'
if [ "$ODIN_VERSION" = "latest" ]; then
    # /releases/latest skips pre-releases; Odin dev builds are pre-releases, use list endpoint
    RELEASE_JSON=$(curl -sS "${GH_ODIN_API}?per_page=1" | jq -c ".[0] | ${JQ_FILTER}")
else
    RELEASE_JSON=$(curl -sS "${GH_ODIN_API}/tags/${ODIN_VERSION}" | jq -c "${JQ_FILTER}")
fi

LATEST_ODIN_VERSION=$(echo "$RELEASE_JSON" | jq -r '.tag_name')
if [[ -z "$LATEST_ODIN_VERSION" || "$LATEST_ODIN_VERSION" == "null" ]]; then
    echo "Error: Failed to fetch Odin release from GitHub API"
    exit 1
fi

ODIN_ASSET_URL=$(echo "$RELEASE_JSON" | jq -r --arg os "$ODIN_OS" --arg arch "$ODIN_ARCH" \
    '.assets[] | select(.name | test($os + ".*" + $arch)) | .browser_download_url' | head -1)

if [[ -z "$ODIN_ASSET_URL" ]]; then
    echo "Error: No Odin asset found for ${ODIN_OS}/${ODIN_ARCH}"
    echo "Available assets:"
    echo "$RELEASE_JSON" | jq -r '.assets[].name'
    exit 1
fi

ODIN_ARCHIVE=$(basename "$ODIN_ASSET_URL")

if [ -d "${TARGET_DIR}/odin" ]; then
    if CURRENT_ODIN_TAG=$("${TARGET_DIR}/odin/odin" version 2>/dev/null | grep -oE 'dev-[0-9]+-[0-9]+' | head -1); then
        if [ "$CURRENT_ODIN_TAG" != "$LATEST_ODIN_VERSION" ]; then
            echo "Deleting old Odin version $CURRENT_ODIN_TAG..."
            rm -rf "${TARGET_DIR}/odin"
        fi
    else
        echo "Existing Odin installation is broken, removing..."
        rm -rf "${TARGET_DIR}/odin"
    fi
fi

if [ ! -d "${TARGET_DIR}/odin" ]; then
    echo "Downloading Odin ${LATEST_ODIN_VERSION}..."
    curl -fL -o "${TMP_DIR}/${ODIN_ARCHIVE}" "$ODIN_ASSET_URL"

    echo "Extracting Odin..."
    EXTRACT_DIR="${TMP_DIR}/odin-extract"
    mkdir -p "$EXTRACT_DIR"
    if [[ "$ODIN_ARCHIVE" == *.zip ]]; then
        unzip -q "${TMP_DIR}/${ODIN_ARCHIVE}" -d "$EXTRACT_DIR"
    else
        tar -xf "${TMP_DIR}/${ODIN_ARCHIVE}" -C "$EXTRACT_DIR"
    fi

    # Flatten one level of nesting if archive contains a single subdirectory
    ENTRIES=("$EXTRACT_DIR"/*/)
    if [ ${#ENTRIES[@]} -eq 1 ] && [ -d "${ENTRIES[0]}" ]; then
        mv "${ENTRIES[0]}" "${TARGET_DIR}/odin"
    else
        mv "$EXTRACT_DIR" "${TARGET_DIR}/odin"
    fi
fi

printf "Odin installed successfully in %s.\n" "${TARGET_DIR}"
printf "Odin version: %s\n" "$LATEST_ODIN_VERSION"
printf "\nAdd to PATH:\n"
printf "export PATH=\"%s/odin:\$PATH\"\n" "${TARGET_DIR}"
