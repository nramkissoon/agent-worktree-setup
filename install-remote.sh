#!/usr/bin/env bash
#
# Remote installer for claude-worktree
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/OWNER/claude-worktree/main/install-remote.sh | bash
#
# Or with a specific version:
#   curl -fsSL https://raw.githubusercontent.com/OWNER/claude-worktree/main/install-remote.sh | bash -s -- v1.0.0
#

set -e

# Configuration - UPDATE THESE FOR YOUR REPO
REPO_OWNER="${CWT_REPO_OWNER:-OWNER}"
REPO_NAME="${CWT_REPO_NAME:-claude-worktree}"
INSTALL_DIR="${CWT_INSTALL_DIR:-$HOME/.local/bin}"
DATA_DIR="${CWT_DATA_DIR:-$HOME/.claude-worktree}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
  echo ""
  echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${BLUE}║${NC}  ${BOLD}Claude Worktree Installer${NC}                                ${BOLD}${BLUE}║${NC}"
  echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

print_step() {
  echo -e "${BLUE}▶${NC} $1"
}

print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

# Detect OS and architecture
detect_platform() {
  OS="$(uname -s)"
  ARCH="$(uname -m)"

  # shellcheck disable=SC2034  # PLATFORM used by caller
  case "$OS" in
    Linux*)  PLATFORM="linux" ;;
    Darwin*) PLATFORM="darwin" ;;
    *)       PLATFORM="unknown" ;;
  esac

  case "$ARCH" in
    x86_64)  ARCH="amd64" ;;
    arm64)   ARCH="arm64" ;;
    aarch64) ARCH="arm64" ;;
    *)       ARCH="unknown" ;;
  esac
}

# Check for required commands
check_dependencies() {
  local missing=()

  for cmd in curl git; do
    if ! command -v "$cmd" &> /dev/null; then
      missing+=("$cmd")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    print_error "Missing required commands: ${missing[*]}"
    exit 1
  fi
}

# Get latest version from GitHub
get_latest_version() {
  local latest
  latest=$(curl -fsSL "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest" 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

  if [[ -z "$latest" ]]; then
    # Fallback to VERSION file on main branch
    latest=$(curl -fsSL "https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/main/VERSION" 2>/dev/null | tr -d '[:space:]')
    if [[ -n "$latest" ]]; then
      latest="v${latest}"
    fi
  fi

  echo "$latest"
}

# Download and install
install_cwt() {
  local version="$1"
  local temp_dir

  temp_dir=$(mktemp -d)
  trap 'rm -rf "$temp_dir"' EXIT

  print_step "Downloading claude-worktree ${version}..."

  # Determine download URL
  local download_url
  if [[ "$version" == "main" || "$version" == "latest" ]]; then
    download_url="https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/refs/heads/main.tar.gz"
  else
    download_url="https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/refs/tags/${version}.tar.gz"
  fi

  # Download and extract
  if ! curl -fsSL "$download_url" | tar -xz -C "$temp_dir"; then
    print_error "Failed to download from $download_url"
    exit 1
  fi

  # Find extracted directory
  local extracted_dir
  extracted_dir=$(find "$temp_dir" -maxdepth 1 -type d -name "${REPO_NAME}*" | head -1)

  if [[ -z "$extracted_dir" ]]; then
    print_error "Failed to find extracted files"
    exit 1
  fi

  # Create directories
  print_step "Installing to ${INSTALL_DIR}..."
  mkdir -p "$INSTALL_DIR"
  mkdir -p "$DATA_DIR"

  # Copy files to data directory
  cp -r "$extracted_dir"/* "$DATA_DIR/"

  # Store version info
  echo "$version" > "$DATA_DIR/.installed-version"

  # Create symlink for cwt-init
  if [[ -f "$DATA_DIR/bin/cwt-init" ]]; then
    chmod +x "$DATA_DIR/bin/cwt-init"
    ln -sf "$DATA_DIR/bin/cwt-init" "$INSTALL_DIR/cwt-init"
    print_success "Installed cwt-init"
  fi

  # Make install script executable
  chmod +x "$DATA_DIR/install.sh"

  print_success "Installation complete!"
}

# Check if PATH includes install directory
check_path() {
  if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo ""
    print_warning "$INSTALL_DIR is not in your PATH"
    echo ""
    echo "Add this to your shell config (~/.zshrc or ~/.bashrc):"
    echo ""
    echo -e "  ${BOLD}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
    echo ""
    echo "Then reload your shell:"
    echo ""
    echo -e "  ${BOLD}source ~/.zshrc${NC}  # or ~/.bashrc"
    echo ""
  fi
}

# Print usage instructions
print_usage() {
  echo ""
  echo -e "${BOLD}${GREEN}Installation successful!${NC}"
  echo ""
  echo -e "${BOLD}Quick Start:${NC}"
  echo ""
  echo "  # Initialize a new project with worktree setup"
  echo -e "  ${BOLD}cwt-init git@github.com:org/repo.git my-project${NC}"
  echo ""
  echo "  # Check version"
  echo -e "  ${BOLD}cwt-init --version${NC}"
  echo ""
  echo "  # Update to latest version"
  echo -e "  ${BOLD}cwt-init --update${NC}"
  echo ""
  echo "  # Show help"
  echo -e "  ${BOLD}cwt-init --help${NC}"
  echo ""
}

main() {
  print_header

  # Parse arguments
  local version="${1:-}"

  detect_platform
  check_dependencies

  # Get version to install
  if [[ -z "$version" || "$version" == "latest" ]]; then
    print_step "Checking for latest version..."
    version=$(get_latest_version)

    if [[ -z "$version" ]]; then
      print_warning "Could not determine latest version, using main branch"
      version="main"
    else
      print_success "Latest version: $version"
    fi
  fi

  install_cwt "$version"
  check_path
  print_usage
}

main "$@"
