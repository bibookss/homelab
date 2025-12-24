#!/bin/bash
# LazyVim Installation Script
# Installs and configures LazyVim for Neovim

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOMELAB_DIR="$(dirname "$SCRIPT_DIR")"
VIM_DIR="$HOMELAB_DIR/env/vim/lazyvim"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}ℹ️  $1${NC}"
}

print_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Neovim is installed
if ! command -v nvim &> /dev/null; then
    print_error "Neovim is not installed"
    echo "Install with:"
    echo "  macOS: brew install neovim"
    echo "  Linux: sudo apt-get install neovim (or your package manager)"
    exit 1
fi

NVIM_VERSION=$(nvim --version | head -n 1 | awk '{print $2}')
print_info "Found Neovim version: $NVIM_VERSION"

# Backup existing config
if [[ -d "$HOME/.config/nvim" ]]; then
    print_warn "Existing Neovim config found at ~/.config/nvim"
    read -p "Backup existing config? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        BACKUP_DIR="$HOME/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$HOME/.config/nvim" "$BACKUP_DIR"
        print_info "Backed up to $BACKUP_DIR"
    else
        print_error "Installation cancelled"
        exit 1
    fi
fi

# Install LazyVim
print_info "Installing LazyVim..."
mkdir -p "$HOME/.config/nvim"
git clone https://github.com/LazyVim/starter "$HOME/.config/nvim" --depth=1

# Link homelab LazyVim config
if [[ -d "$VIM_DIR" ]]; then
    print_info "Linking homelab LazyVim configuration..."
    # Copy custom configs if they exist
    if [[ -f "$VIM_DIR/config.lua" ]]; then
        cp "$VIM_DIR/config.lua" "$HOME/.config/nvim/lua/config.lua"
    fi
    if [[ -d "$VIM_DIR/lua" ]]; then
        cp -r "$VIM_DIR/lua"/* "$HOME/.config/nvim/lua/" 2>/dev/null || true
    fi
fi

print_info "LazyVim installed successfully!"
print_info "Start Neovim with: nvim"
print_info "LazyVim will automatically install plugins on first launch"

