#!/bin/bash

# =============================================================================
# Node.js Installation Module
# =============================================================================
# Instalasi Node.js runtime environment
# =============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[NODEJS]${NC} $1"
}

print_error() {
    echo -e "${RED}[NODEJS ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[NODEJS WARNING]${NC} $1"
}

install_nodejs() {
    local node_version=${1:-18}
    
    print_status "Installing Node.js $node_version..."
    
    # Install NodeSource repository
    print_status "Adding NodeSource repository..."
    echo "📦 Adding NodeSource repository for Node.js $node_version..."
    curl -fsSL https://deb.nodesource.com/setup_$node_version.x | bash -
    
    # Install Node.js and npm
    print_status "Installing Node.js and npm..."
    echo "📦 Installing Node.js runtime..."
    apt install -y nodejs
    
    # Install global packages
    print_status "Installing global packages..."
    echo "📦 Updating npm to latest version..."
    npm install -g npm@latest
    echo "📦 Installing yarn and pm2..."
    npm install -g yarn pm2
    
    # Verify installation
    print_status "Verifying installation..."
    echo "✅ Checking installed versions..."
    NODE_VERSION=$(node --version)
    NPM_VERSION=$(npm --version)
    
    print_status "Node.js installed successfully"
    print_status "Node.js version: $NODE_VERSION"
    print_status "npm version: $NPM_VERSION"
    print_status "Global packages: yarn, pm2"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_nodejs "$@"
fi 