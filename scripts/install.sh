#!/bin/bash
# Homelab Bootstrap Installation Script
# Installs required dependencies and sets up the homelab environment

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOMELAB_DIR="$(dirname "$SCRIPT_DIR")"

echo "🚀 Homelab Bootstrap Installation"
echo "=================================="
echo ""

# Check if running on macOS or Linux
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "📦 Detected macOS"
    INSTALLER="brew"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "📦 Detected Linux"
    if command -v apt-get &> /dev/null; then
        INSTALLER="apt"
    elif command -v yum &> /dev/null; then
        INSTALLER="yum"
    else
        echo "❌ Unsupported Linux distribution"
        exit 1
    fi
else
    echo "❌ Unsupported operating system: $OSTYPE"
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Docker
if ! command_exists docker; then
    echo "🐳 Installing Docker..."
    if [[ "$INSTALLER" == "brew" ]]; then
        brew install --cask docker
        echo "⚠️  Please start Docker Desktop from Applications"
    elif [[ "$INSTALLER" == "apt" ]]; then
        sudo apt-get update
        sudo apt-get install -y docker.io docker-compose-plugin
        sudo usermod -aG docker "$USER"
        echo "⚠️  Please log out and back in for group changes to take effect"
    elif [[ "$INSTALLER" == "yum" ]]; then
        sudo yum install -y docker docker-compose-plugin
        sudo systemctl enable docker
        sudo systemctl start docker
        sudo usermod -aG docker "$USER"
        echo "⚠️  Please log out and back in for group changes to take effect"
    fi
else
    echo "✅ Docker already installed"
fi

# Install Docker Compose (if not using plugin)
if ! docker compose version &> /dev/null; then
    echo "🐳 Installing Docker Compose..."
    if [[ "$INSTALLER" == "brew" ]]; then
        brew install docker-compose
    elif [[ "$INSTALLER" == "apt" ]]; then
        sudo apt-get install -y docker-compose-plugin
    elif [[ "$INSTALLER" == "yum" ]]; then
        sudo yum install -y docker-compose-plugin
    fi
else
    echo "✅ Docker Compose already installed"
fi

# Create homelab network
echo "🌐 Creating homelab Docker network..."
if ! docker network ls | grep -q homelab; then
    docker network create homelab
    echo "✅ Created homelab network"
else
    echo "✅ Homelab network already exists"
fi

# Link shell configs
echo "🔗 Setting up shell configuration..."
if [[ -n "${ZSH_VERSION:-}" ]]; then
    if ! grep -q "homelab.*zshrc" ~/.zshrc 2>/dev/null; then
        echo "" >> ~/.zshrc
        echo "# Homelab configuration" >> ~/.zshrc
        echo "source $HOMELAB_DIR/env/shell/.zshrc" >> ~/.zshrc
        echo "✅ Added homelab config to ~/.zshrc"
    else
        echo "✅ Homelab config already in ~/.zshrc"
    fi
elif [[ -n "${BASH_VERSION:-}" ]]; then
    if ! grep -q "homelab.*bashrc" ~/.bashrc 2>/dev/null; then
        echo "" >> ~/.bashrc
        echo "# Homelab configuration" >> ~/.bashrc
        echo "source $HOMELAB_DIR/env/shell/.bashrc" >> ~/.bashrc
        echo "✅ Added homelab config to ~/.bashrc"
    else
        echo "✅ Homelab config already in ~/.bashrc"
    fi
fi

# Link git config
echo "🔗 Setting up git configuration..."
if [[ ! -f ~/.gitconfig ]] || ! grep -q "homelab.*gitconfig" ~/.gitconfig 2>/dev/null; then
    if [[ -f ~/.gitconfig ]]; then
        echo "" >> ~/.gitconfig
        echo "# Homelab git configuration" >> ~/.gitconfig
        echo "[include]" >> ~/.gitconfig
        echo "    path = $HOMELAB_DIR/env/git/.gitconfig" >> ~/.gitconfig
    else
        cp "$HOMELAB_DIR/env/git/.gitconfig" ~/.gitconfig
    fi
    echo "✅ Git configuration linked"
    echo "⚠️  Please edit ~/.gitconfig to set your name and email"
else
    echo "✅ Git config already linked"
fi

echo ""
echo "✨ Installation complete!"
echo ""
echo "Next steps:"
echo "1. Review and update .env files in each docker service directory"
echo "2. Run './scripts/docker.sh setup' to initialize all services"
echo "3. Check docs/setup.md for detailed setup instructions"

