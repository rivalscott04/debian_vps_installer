#!/bin/bash

# =============================================================================
# WordPress Installation Module
# =============================================================================
# Instalasi WordPress dengan konfigurasi database
# =============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[WORDPRESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[WORDPRESS ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WORDPRESS WARNING]${NC} $1"
}

install_wordpress() {
    local domain=${1:-localhost}
    local db_name=${2:-wordpress}
    local db_user=${3:-wp_user}
    local db_pass=${4:-}
    
    if [[ -z "$db_pass" ]]; then
        db_pass=$(openssl rand -base64 12)
    fi
    
    print_status "Installing WordPress for domain: $domain"
    
    # Create web directory
    mkdir -p /var/www/$domain
    cd /var/www/$domain
    
    # Download WordPress
    wget -q https://wordpress.org/latest.tar.gz
    if [[ $? -ne 0 ]]; then
        print_error "Failed to download WordPress"
        exit 1
    fi
    
    tar -xzf latest.tar.gz --strip-components=1
    rm latest.tar.gz
    
    # Set permissions
    chown -R www-data:www-data /var/www/$domain
    chmod -R 755 /var/www/$domain
    
    # Create wp-config.php
    cp wp-config-sample.php wp-config.php
    sed -i "s/database_name_here/$db_name/" wp-config.php
    sed -i "s/username_here/$db_user/" wp-config.php
    sed -i "s/password_here/$db_pass/" wp-config.php
    
    # Generate WordPress keys
    SALT=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
    if [[ $? -eq 0 ]]; then
        sed -i "/#@-/,/#@+/c\\$SALT" wp-config.php
    else
        print_warning "Failed to generate WordPress keys. Using default keys."
    fi
    
    # Create database if not exists
    mysql -u root -p$db_pass -e "CREATE DATABASE IF NOT EXISTS $db_name CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || \
    mysql -u root -e "CREATE DATABASE IF NOT EXISTS $db_name CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    
    # Create database user if not exists
    mysql -u root -p$db_pass -e "CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_pass'; GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost'; FLUSH PRIVILEGES;" 2>/dev/null || \
    mysql -u root -e "CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_pass'; GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost'; FLUSH PRIVILEGES;"
    
    print_status "WordPress installed successfully"
    print_status "Database: $db_name"
    print_status "Database User: $db_user"
    print_status "Database Password: $db_pass"
    print_status "Access WordPress at: http://$domain"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_wordpress "$@"
fi