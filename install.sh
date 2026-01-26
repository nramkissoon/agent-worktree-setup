#!/usr/bin/env bash
#
# Install claude-worktree tools from local clone
#
# Usage:
#   ./install.sh              Install cwt-init to ~/.local/bin
#   ./install.sh --uninstall  Remove installed files
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${CWT_INSTALL_DIR:-$HOME/.local/bin}"
DATA_DIR="${CWT_DATA_DIR:-$HOME/.claude-worktree}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

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

do_install() {
  echo ""
  echo -e "${BOLD}${BLUE}Installing claude-worktree...${NC}"
  echo ""

  # Read version
  local version="dev"
  if [[ -f "$SCRIPT_DIR/VERSION" ]]; then
    version=$(cat "$SCRIPT_DIR/VERSION" | tr -d '[:space:]')
  fi

  print_step "Version: $version"

  # Create directories
  mkdir -p "$INSTALL_DIR"
  mkdir -p "$DATA_DIR"

  # Copy entire project to data directory (for updates to work)
  print_step "Installing to $DATA_DIR..."
  rsync -a --exclude='.git' "$SCRIPT_DIR/" "$DATA_DIR/"

  # Store version info
  echo "v${version}" > "$DATA_DIR/.installed-version"
  echo "local" > "$DATA_DIR/.install-method"

  # Create symlink for cwt-init
  print_step "Creating symlink in $INSTALL_DIR..."

  if [[ -L "$INSTALL_DIR/cwt-init" || -f "$INSTALL_DIR/cwt-init" ]]; then
    rm "$INSTALL_DIR/cwt-init"
  fi

  chmod +x "$DATA_DIR/bin/cwt-init"
  ln -sf "$DATA_DIR/bin/cwt-init" "$INSTALL_DIR/cwt-init"

  print_success "Installed cwt-init to $INSTALL_DIR/cwt-init"

  # Check PATH
  if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo ""
    print_warning "$INSTALL_DIR is not in your PATH"
    echo ""
    echo "Add this to your shell config (~/.zshrc or ~/.bashrc):"
    echo ""
    echo -e "  ${BOLD}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
    echo ""
  fi

  echo ""
  print_success "Installation complete!"
  echo ""
  echo -e "${BOLD}Usage:${NC}"
  echo "  cwt-init <repo-url> <directory>   # Initialize a new project"
  echo "  cwt-init --help                   # Show help"
  echo "  cwt-init --version                # Show version"
  echo "  cwt-init --update                 # Update to latest version"
  echo ""
}

do_uninstall() {
  echo ""
  echo -e "${BOLD}${BLUE}Uninstalling claude-worktree...${NC}"
  echo ""

  # Remove symlink
  if [[ -L "$INSTALL_DIR/cwt-init" ]]; then
    rm "$INSTALL_DIR/cwt-init"
    print_success "Removed $INSTALL_DIR/cwt-init"
  fi

  # Remove data directory
  if [[ -d "$DATA_DIR" ]]; then
    rm -rf "$DATA_DIR"
    print_success "Removed $DATA_DIR"
  fi

  echo ""
  print_success "Uninstall complete!"
  echo ""
}

main() {
  case "$1" in
    --uninstall|-u)
      do_uninstall
      ;;
    --help|-h)
      echo "Usage:"
      echo "  ./install.sh              Install cwt-init"
      echo "  ./install.sh --uninstall  Remove installed files"
      ;;
    *)
      do_install
      ;;
  esac
}

main "$@"
