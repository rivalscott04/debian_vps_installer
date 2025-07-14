#!/bin/bash

# =============================================================================
# Web App Configuration Module
# =============================================================================
# Konfigurasi web application untuk berbagai jenis aplikasi
# =============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[WEBAPP]${NC} $1"
}

print_error() {
    echo -e "${RED}[WEBAPP ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WEBAPP WARNING]${NC} $1"
}

configure_laravel() {
    local domain=${1:-localhost}
    local php_version=${2:-8.2}
    
    print_status "Configuring Laravel application for domain: $domain"
    
    # Create Laravel directory structure
    mkdir -p /var/www/$domain
    cd /var/www/$domain
    
    # Set proper permissions for Laravel
    chown -R www-data:www-data /var/www/$domain
    chmod -R 755 /var/www/$domain
    chmod -R 775 storage bootstrap/cache
    
    # Create Nginx configuration for Laravel
    cat > /etc/nginx/sites-available/$domain << EOF
server {
    listen 80;
    server_name $domain www.$domain;
    root /var/www/$domain/public;
    index index.php index.html index.htm;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php$php_version-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    
    location ~ /\.(?!well-known).* {
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
    
    if nginx -t; then
        systemctl reload nginx
        print_status "Laravel configuration completed"
        print_status "Document root: /var/www/$domain/public"
    else
        print_error "Nginx configuration test failed"
        exit 1
    fi
}

configure_spa() {
    local domain=${1:-localhost}
    
    print_status "Configuring SPA (React/Vue) application for domain: $domain"
    
    # Create SPA directory structure
    mkdir -p /var/www/$domain
    cd /var/www/$domain
    
    # Set proper permissions
    chown -R www-data:www-data /var/www/$domain
    chmod -R 755 /var/www/$domain
    
    # Create Nginx configuration for SPA
    cat > /etc/nginx/sites-available/$domain << EOF
server {
    listen 80;
    server_name $domain www.$domain;
    root /var/www/$domain/dist;
    index index.html index.htm;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    
    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/javascript application/javascript application/json;
}
EOF
    
    # Enable site
    ln -sf /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/
    
    if nginx -t; then
        systemctl reload nginx
        print_status "SPA configuration completed"
        print_status "Document root: /var/www/$domain/dist"
    else
        print_error "Nginx configuration test failed"
        exit 1
    fi
}

configure_php_native() {
    local domain=${1:-localhost}
    local php_version=${2:-8.2}
    
    print_status "Configuring PHP Native application for domain: $domain"
    
    # Create PHP directory structure
    mkdir -p /var/www/$domain
    cd /var/www/$domain
    
    # Create sample index.php
    cat > /var/www/$domain/index.php << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>PHP Native App</title>
</head>
<body>
    <h1>Welcome to PHP Native Application</h1>
    <p>PHP Version: <?php echo phpversion(); ?></p>
    <p>Server Time: <?php echo date('Y-m-d H:i:s'); ?></p>
</body>
</html>
EOF
    
    # Set proper permissions
    chown -R www-data:www-data /var/www/$domain
    chmod -R 755 /var/www/$domain
    
    # Create Nginx configuration for PHP Native
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
    
    if nginx -t; then
        systemctl reload nginx
        print_status "PHP Native configuration completed"
        print_status "Document root: /var/www/$domain"
    else
        print_error "Nginx configuration test failed"
        exit 1
    fi
}

# Main configuration function
configure_webapp() {
    local app_type=${1:-php}
    local domain=${2:-localhost}
    local php_version=${3:-8.2}
    
    case $app_type in
        "laravel")
            configure_laravel "$domain" "$php_version"
            ;;
        "spa")
            configure_spa "$domain"
            ;;
        "php"|"php_native")
            configure_php_native "$domain" "$php_version"
            ;;
        *)
            print_error "Unknown application type: $app_type"
            print_status "Available types: laravel, spa, php"
            exit 1
            ;;
    esac
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    configure_webapp "$@"
fi