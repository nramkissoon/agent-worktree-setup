#!/usr/bin/env bash
#
# Install claude-worktree tools globally
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${HOME}/.local/bin"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Installing claude-worktree tools...${NC}"
echo ""

# Create install directory
mkdir -p "$INSTALL_DIR"

# Install cwt-init
if [[ -L "$INSTALL_DIR/cwt-init" ]]; then
  rm "$INSTALL_DIR/cwt-init"
fi
ln -sf "$SCRIPT_DIR/bin/cwt-init" "$INSTALL_DIR/cwt-init"
chmod +x "$SCRIPT_DIR/bin/cwt-init"
echo -e "${GREEN}✓${NC} Installed cwt-init to $INSTALL_DIR/cwt-init"

# Check PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo ""
  echo -e "${YELLOW}⚠${NC}  $INSTALL_DIR is not in your PATH"
  echo ""
  echo "Add this to your shell config (~/.zshrc or ~/.bashrc):"
  echo ""
  echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
  echo ""
fi

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Usage:"
echo "  cwt-init <repo-url> <directory>   # Initialize a new project"
echo "  cwt-init --help                   # Show help"
echo ""
