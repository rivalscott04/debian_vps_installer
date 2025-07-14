#!/bin/bash

# =============================================================================
# phpMyAdmin Installation Module
# =============================================================================
# Instalasi phpMyAdmin dengan nama folder acak untuk keamanan
# =============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[PHPMYADMIN]${NC} $1"
}

print_error() {
    echo -e "${RED}[PHPMYADMIN ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[PHPMYADMIN WARNING]${NC} $1"
}

install_phpmyadmin() {
    local domain=${1:-localhost}
    local php_version=${2:-8.2}
    
    print_status "Installing phpMyAdmin..."
    
    # Generate random folder name
    print_status "Generating secure folder name..."
    echo "🔐 Generating random folder name for security..."
    PMA_FOLDER="pma_$(openssl rand -hex 8)"
    
    # Create phpMyAdmin directory
    print_status "Creating phpMyAdmin directory..."
    echo "📁 Creating directory: /var/www/$PMA_FOLDER"
    mkdir -p /var/www/$PMA_FOLDER
    
    # Download phpMyAdmin
    cd /var/www/$PMA_FOLDER
    print_status "Downloading phpMyAdmin..."
    echo "⬇️  Downloading latest phpMyAdmin..."
    wget -q https://files.phpmyadmin.net/phpMyAdmin/latest/phpMyAdmin-latest-all-languages.tar.gz
    if [[ $? -ne 0 ]]; then
        print_error "Failed to download phpMyAdmin"
        exit 1
    fi
    
    print_status "Extracting phpMyAdmin files..."
    echo "📦 Extracting phpMyAdmin files..."
    tar -xzf phpMyAdmin-latest-all-languages.tar.gz --strip-components=1
    rm phpMyAdmin-latest-all-languages.tar.gz
    
    # Create configuration
    print_status "Configuring phpMyAdmin..."
    echo "⚙️  Creating configuration file..."
    cp config.sample.inc.php config.inc.php
    sed -i "s/localhost/localhost/" config.inc.php
    
    # Set permissions
    print_status "Setting file permissions..."
    echo "🔐 Setting proper permissions..."
    chown -R www-data:www-data /var/www/$PMA_FOLDER
    chmod -R 755 /var/www/$PMA_FOLDER
    
    # Create Nginx configuration for phpMyAdmin
    print_status "Creating Nginx configuration..."
    echo "🌐 Creating virtual host for phpMyAdmin..."
    cat > /etc/nginx/sites-available/phpmyadmin << EOF
server {
    listen 80;
    server_name $PMA_FOLDER.$domain;
    root /var/www/$PMA_FOLDER;
    index index.php index.html index.htm;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php$php_version-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    
    location ~ /\.ht {
        deny all;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
}
EOF
    
    # Enable site
    print_status "Enabling phpMyAdmin site..."
    echo "🔗 Enabling site configuration..."
    ln -sf /etc/nginx/sites-available/phpmyadmin /etc/nginx/sites-enabled/
    
    # Test and reload Nginx
    print_status "Testing Nginx configuration..."
    echo "🧪 Testing configuration syntax..."
    if nginx -t; then
        print_status "Reloading Nginx..."
        echo "🔄 Reloading Nginx service..."
        systemctl reload nginx
        print_status "phpMyAdmin installed successfully"
        print_status "Access URL: http://$PMA_FOLDER.$domain"
        print_warning "IMPORTANT: Keep this folder name secret: $PMA_FOLDER"
        echo "$PMA_FOLDER" > /root/phpmyadmin_folder.txt
        print_status "Folder name saved to: /root/phpmyadmin_folder.txt"
    else
        print_error "Nginx configuration test failed"
        exit 1
    fi
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_phpmyadmin "$@"
fi