#!/bin/bash

# =============================================================================
# Nginx Installation Module
# =============================================================================
# Instalasi Nginx dan konfigurasi virtual host
# =============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[NGINX]${NC} $1"
}

print_error() {
    echo -e "${RED}[NGINX ERROR]${NC} $1"
}

install_nginx() {
    local domain=${1:-localhost}
    local php_version=${2:-8.2}
    
    print_status "Installing Nginx..."
    
    apt install -y nginx
    
    # Create web directory
    mkdir -p /var/www/$domain
    
    # Create Nginx configuration
    cat > /etc/nginx/sites-available/$domain << EOF
server {
    listen 80;
    server_name $domain www.$domain;
    root /var/www/$domain;
    index index.php index.html index.htm;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
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
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
}
EOF
    
    # Enable site
    ln -sf /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Test Nginx configuration
    if nginx -t; then
        systemctl enable nginx
        systemctl reload nginx
        print_status "Nginx installed and configured successfully"
    else
        print_error "Nginx configuration test failed"
        exit 1
    fi
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_nginx "$@"
fi