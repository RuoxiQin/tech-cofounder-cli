#!/usr/bin/env bash
# tech-cofounder CLI Installer
# Installs standalone binary release to ~/.local/share/tech-cofounder/ and links ~/.local/bin/tc

set -euo pipefail

GITHUB_REPO="RuoxiQin/tech-cofounder-cli"
GITHUB_RAW_BASE="https://raw.githubusercontent.com/${GITHUB_REPO}/main"
INSTALL_BASE_DIR="${HOME}/.local/share/tech-cofounder"
BIN_DIR="${HOME}/.local/bin"

log_info() {
    printf "\033[1;34m==>\033[0m %s\n" "$1"
}

log_error() {
    printf "\033[1;31mError:\033[0m %s\n" "$1" >&2
}

# 1. Detect OS
OS_NAME="$(uname -s | tr '[:upper:]' '[:lower:]')"
if [ "${OS_NAME}" != "darwin" ]; then
    log_error "tech-cofounder CLI currently only provides standalone releases for macOS (Darwin)."
    exit 1
fi

# 2. Detect Architecture
ARCH_RAW="$(uname -m)"
case "${ARCH_RAW}" in
    x86_64|amd64)
        TARGET_PLATFORM="darwin-amd64"
        ;;
    arm64|aarch64)
        TARGET_PLATFORM="darwin-arm64"
        ;;
    *)
        log_error "Unsupported architecture: ${ARCH_RAW}"
        exit 1
        ;;
esac

# 3. Determine Version
VERSION="${VERSION:-}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

if [ -z "${VERSION}" ]; then
    log_info "Fetching latest release manifest..."
    MANIFEST_URL="${GITHUB_RAW_BASE}/releases/manifest.json"
    if ! curl -fsSL "${MANIFEST_URL}" -o "${TMP_DIR}/manifest.json" 2>/dev/null; then
        # Fallback to local manifest if installed from local repository clone
        LOCAL_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"
        if [ -n "${LOCAL_SCRIPT_DIR}" ] && [ -f "${LOCAL_SCRIPT_DIR}/releases/manifest.json" ]; then
            cp "${LOCAL_SCRIPT_DIR}/releases/manifest.json" "${TMP_DIR}/manifest.json"
        else
            log_error "Could not fetch release manifest from ${MANIFEST_URL}"
            exit 1
        fi
    fi

    VERSION="$(grep -o '"latest": "[^"]*"' "${TMP_DIR}/manifest.json" | head -n 1 | cut -d'"' -f4 || echo "")"
    if [ -z "${VERSION}" ]; then
        VERSION="$(grep -o '"version": "[^"]*"' "${TMP_DIR}/manifest.json" | cut -d'"' -f4 | sort -V | tail -n 1)"
    fi
    if [ -z "${VERSION}" ]; then
        log_error "Could not parse latest version from manifest.json"
        exit 1
    fi
fi

# Normalize version tag
VERSION_TAG="v${VERSION#v}"
CLEAN_VERSION="${VERSION#v}"

ARCHIVE_NAME="tc-${VERSION_TAG}-${TARGET_PLATFORM}.tar.gz"
DOWNLOAD_URL="${GITHUB_RAW_BASE}/releases/${VERSION_TAG}/${ARCHIVE_NAME}"
SHA256SUMS_URL="${GITHUB_RAW_BASE}/releases/${VERSION_TAG}/SHA256SUMS"

log_info "Installing tech-cofounder CLI ${VERSION_TAG} (${TARGET_PLATFORM})..."

# 4. Download release archive and checksums
log_info "Downloading ${ARCHIVE_NAME}..."
LOCAL_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"
LOCAL_ARCHIVE="${LOCAL_SCRIPT_DIR}/releases/${VERSION_TAG}/${ARCHIVE_NAME}"
LOCAL_SHA256SUMS="${LOCAL_SCRIPT_DIR}/releases/${VERSION_TAG}/SHA256SUMS"

if [ -n "${LOCAL_SCRIPT_DIR}" ] && [ -f "${LOCAL_ARCHIVE}" ] && [ -f "${LOCAL_SHA256SUMS}" ]; then
    cp "${LOCAL_ARCHIVE}" "${TMP_DIR}/${ARCHIVE_NAME}"
    cp "${LOCAL_SHA256SUMS}" "${TMP_DIR}/SHA256SUMS"
else
    curl -fsSL "${DOWNLOAD_URL}" -o "${TMP_DIR}/${ARCHIVE_NAME}"
    curl -fsSL "${SHA256SUMS_URL}" -o "${TMP_DIR}/SHA256SUMS"
fi

# 5. Verify Checksum
log_info "Verifying SHA-256 checksum..."
EXPECTED_CHECKSUM="$(grep "${ARCHIVE_NAME}" "${TMP_DIR}/SHA256SUMS" | awk '{print $1}')"
if [ -z "${EXPECTED_CHECKSUM}" ]; then
    log_error "No checksum found for ${ARCHIVE_NAME} in SHA256SUMS"
    exit 1
fi

if command -v shasum >/dev/null 2>&1; then
    ACTUAL_CHECKSUM="$(shasum -a 256 "${TMP_DIR}/${ARCHIVE_NAME}" | awk '{print $1}')"
elif command -v sha256sum >/dev/null 2>&1; then
    ACTUAL_CHECKSUM="$(sha256sum "${TMP_DIR}/${ARCHIVE_NAME}" | awk '{print $1}')"
else
    log_error "Neither shasum nor sha256sum found on system."
    exit 1
fi

if [ "${EXPECTED_CHECKSUM}" != "${ACTUAL_CHECKSUM}" ]; then
    log_error "Checksum verification failed!"
    log_error "Expected: ${EXPECTED_CHECKSUM}"
    log_error "Actual:   ${ACTUAL_CHECKSUM}"
    exit 1
fi
log_info "Checksum verified successfully (${ACTUAL_CHECKSUM})."

# 6. Extract into versioned location
TARGET_VERSION_DIR="${INSTALL_BASE_DIR}/versions/${VERSION_TAG}"
mkdir -p "${TARGET_VERSION_DIR}"
rm -rf "${TARGET_VERSION_DIR:?}"/*

log_info "Extracting into ${TARGET_VERSION_DIR}..."
tar -xzf "${TMP_DIR}/${ARCHIVE_NAME}" -C "${TARGET_VERSION_DIR}"

EXECUTABLE_PATH="${TARGET_VERSION_DIR}/tc/tc"
if [ ! -f "${EXECUTABLE_PATH}" ]; then
    log_error "Extracted executable not found at ${EXECUTABLE_PATH}"
    exit 1
fi
chmod +x "${EXECUTABLE_PATH}"

# 7. Atomically create/update ~/.local/bin/tc symlink
mkdir -p "${BIN_DIR}"
ln -sf "${EXECUTABLE_PATH}" "${BIN_DIR}/tc.tmp"
mv -f "${BIN_DIR}/tc.tmp" "${BIN_DIR}/tc"

log_info "Installed tc ${VERSION_TAG} to ${BIN_DIR}/tc"

# 8. Check PATH
case ":${PATH}:" in
    *:"${BIN_DIR}":*)
        ;;
    *)
        printf "\n\033[1;33mNote:\033[0m %s is not in your PATH.\n" "${BIN_DIR}"
        printf "Add it to your shell configuration (e.g. ~/.zshrc or ~/.bashrc):\n"
        printf "    export PATH=\"\$HOME/.local/bin:\$PATH\"\n\n"
        ;;
esac

log_info "Installation complete! Run 'tc --help' to get started."
