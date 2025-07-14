#!/bin/bash

# =============================================================================
# FrankenPHP Installation Module
# =============================================================================
# Instalasi FrankenPHP untuk performa PHP yang lebih baik
# =============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[FRANKENPHP]${NC} $1"
}

print_error() {
    echo -e "${RED}[FRANKENPHP ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[FRANKENPHP WARNING]${NC} $1"
}

install_frankenphp() {
    local domain=${1:-localhost}
    
    print_status "Installing FrankenPHP..."
    
    # Download FrankenPHP
    print_status "Downloading FrankenPHP..."
    echo "⬇️  Downloading latest FrankenPHP..."
    cd /tmp
    wget -q https://github.com/dunglas/frankenphp/releases/latest/download/frankenphp-linux-x86_64.tar.gz
    
    if [[ $? -ne 0 ]]; then
        print_error "Failed to download FrankenPHP"
        exit 1
    fi
    
    # Extract and install
    print_status "Extracting and installing FrankenPHP..."
    echo "📦 Extracting FrankenPHP binary..."
    tar -xzf frankenphp-linux-x86_64.tar.gz
    echo "📁 Installing to /usr/local/bin/"
    mv frankenphp /usr/local/bin/
    chmod +x /usr/local/bin/frankenphp
    
    # Create FrankenPHP service
    print_status "Creating systemd service..."
    echo "⚙️  Creating FrankenPHP service configuration..."
    cat > /etc/systemd/system/frankenphp.service << EOF
[Unit]
Description=FrankenPHP Server
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/$domain
ExecStart=/usr/local/bin/frankenphp run --config /etc/frankenphp/Caddyfile
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    
    # Create FrankenPHP configuration
    print_status "Creating FrankenPHP configuration..."
    echo "⚙️  Creating Caddyfile configuration..."
    mkdir -p /etc/frankenphp
    cat > /etc/frankenphp/Caddyfile << EOF
{
    order php_server before file_server
}

$domain {
    root * /var/www/$domain
    encode gzip
    php_server
    file_server
}

www.$domain {
    root * /var/www/$domain
    encode gzip
    php_server
    file_server
}
EOF
    
    # Set permissions
    print_status "Setting permissions..."
    echo "🔐 Setting proper permissions..."
    chown -R www-data:www-data /etc/frankenphp
    
    # Enable and start FrankenPHP
    print_status "Starting FrankenPHP service..."
    echo "🚀 Enabling and starting FrankenPHP..."
    systemctl daemon-reload
    systemctl enable frankenphp
    systemctl start frankenphp
    
    # Clean up
    print_status "Cleaning up temporary files..."
    echo "🧹 Removing temporary files..."
    rm -f /tmp/frankenphp-linux-x86_64.tar.gz
    
    print_status "FrankenPHP installed successfully"
    print_status "Service: frankenphp"
    print_status "Configuration: /etc/frankenphp/Caddyfile"
    print_status "Access your site at: http://$domain"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_frankenphp "$@"
fi 