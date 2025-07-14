#!/bin/bash

# =============================================================================
# PHP Installation Module
# =============================================================================
# Instalasi PHP dan ekstensi yang diperlukan
# =============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[PHP]${NC} $1"
}

print_error() {
    echo -e "${RED}[PHP ERROR]${NC} $1"
}

install_php() {
    local php_version=${1:-8.2}
    
    print_status "Installing PHP $php_version..."
    
    # Add PHP repository
    apt install -y software-properties-common
    add-apt-repository -y ppa:ondrej/php
    apt update
    
    # Install PHP and extensions
    apt install -y php$php_version php$php_version-fpm php$php_version-cli php$php_version-common \
                   php$php_version-mysql php$php_version-zip php$php_version-gd php$php_version-mbstring \
                   php$php_version-curl php$php_version-xml php$php_version-bcmath php$php_version-json \
                   php$php_version-opcache php$php_version-redis php$php_version-msgpack php$php_version-igbinary
    
    # Configure PHP
    sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 64M/' /etc/php/$php_version/fpm/php.ini
    sed -i 's/post_max_size = 8M/post_max_size = 64M/' /etc/php/$php_version/fpm/php.ini
    sed -i 's/memory_limit = 128M/memory_limit = 256M/' /etc/php/$php_version/fpm/php.ini
    sed -i 's/max_execution_time = 30/max_execution_time = 300/' /etc/php/$php_version/fpm/php.ini
    
    # Enable and start PHP-FPM
    systemctl enable php$php_version-fpm
    systemctl start php$php_version-fpm
    
    print_status "PHP $php_version installed successfully"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_php "$@"
fi