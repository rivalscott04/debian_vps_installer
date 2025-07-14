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
    
    # Check dependencies
    print_status "Checking dependencies..."
    echo "🔍 Checking required packages..."
    
    # Check if wget and curl are available
    if ! command -v wget &> /dev/null; then
        print_status "Installing wget..."
        apt install -y wget
    fi
    
    if ! command -v curl &> /dev/null; then
        print_status "Installing curl..."
        apt install -y curl
    fi
    
    # Check if PHP is installed
    if ! command -v php &> /dev/null; then
        print_error "PHP is not installed. Please install PHP first."
        exit 1
    fi
    
    # Check if Nginx is installed
    if ! command -v nginx &> /dev/null; then
        print_error "Nginx is not installed. Please install Nginx first."
        exit 1
    fi
    
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
    
    # Try multiple download methods
    DOWNLOAD_SUCCESS=false
    
    # Method 1: Direct wget
    echo "🔄 Trying direct download..."
    if wget -q --timeout=30 --tries=3 https://files.phpmyadmin.net/phpMyAdmin/latest/phpMyAdmin-latest-all-languages.tar.gz; then
        DOWNLOAD_SUCCESS=true
        echo "✅ Download successful via direct method"
    else
        echo "❌ Direct download failed, trying alternative methods..."
        
        # Method 2: Try with curl
        echo "🔄 Trying with curl..."
        if curl -L -o phpMyAdmin-latest-all-languages.tar.gz --connect-timeout 30 --max-time 300 https://files.phpmyadmin.net/phpMyAdmin/latest/phpMyAdmin-latest-all-languages.tar.gz; then
            DOWNLOAD_SUCCESS=true
            echo "✅ Download successful via curl"
        else
            echo "❌ Curl download failed, trying GitHub mirror..."
            
            # Method 3: Try GitHub mirror
            echo "🔄 Trying GitHub mirror..."
            if wget -q --timeout=30 --tries=3 https://github.com/phpmyadmin/phpmyadmin/releases/download/5.2.1/phpMyAdmin-5.2.1-all-languages.tar.gz; then
                DOWNLOAD_SUCCESS=true
                echo "✅ Download successful via GitHub mirror"
            else
                echo "❌ All download methods failed"
            fi
        fi
    fi
    
    if [[ "$DOWNLOAD_SUCCESS" == false ]]; then
        print_error "All download methods failed. Please check your internet connection."
        print_error "You can manually download phpMyAdmin from: https://www.phpmyadmin.net/downloads/"
        print_error "And extract it to: /var/www/$PMA_FOLDER"
        exit 1
    fi
    
    # Extract phpMyAdmin files
    print_status "Extracting phpMyAdmin files..."
    echo "📦 Extracting phpMyAdmin files..."
    
    if [[ -f "phpMyAdmin-latest-all-languages.tar.gz" ]]; then
        tar -xzf phpMyAdmin-latest-all-languages.tar.gz --strip-components=1
        rm phpMyAdmin-latest-all-languages.tar.gz
    elif [[ -f "phpMyAdmin-5.2.1-all-languages.tar.gz" ]]; then
        tar -xzf phpMyAdmin-5.2.1-all-languages.tar.gz --strip-components=1
        rm phpMyAdmin-5.2.1-all-languages.tar.gz
    else
        print_error "No phpMyAdmin archive found after download"
        exit 1
    fi
    
    # Create configuration
    print_status "Configuring phpMyAdmin..."
    echo "⚙️  Creating configuration file..."
    
    # Check if config.sample.inc.php exists
    if [[ -f "config.sample.inc.php" ]]; then
        cp config.sample.inc.php config.inc.php
        sed -i "s/localhost/localhost/" config.inc.php
    else
        print_error "config.sample.inc.php not found. phpMyAdmin may not have downloaded correctly."
        exit 1
    fi
    
    # Set permissions
    print_status "Setting file permissions..."
    echo "🔐 Setting proper permissions..."
    chown -R www-data:www-data /var/www/$PMA_FOLDER
    chmod -R 755 /var/www/$PMA_FOLDER
    
    # Create temp directory if it doesn't exist
    mkdir -p /var/www/$PMA_FOLDER/tmp
    chmod 777 /var/www/$PMA_FOLDER/tmp
    chown www-data:www-data /var/www/$PMA_FOLDER/tmp
    
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
        # Get phpMyAdmin version
        if [[ -f "libraries/classes/Config.php" ]]; then
            PMA_VERSION=$(grep -o "VERSION = '[^']*'" libraries/classes/Config.php | cut -d"'" -f2)
        elif [[ -f "README" ]]; then
            PMA_VERSION=$(grep -o "phpMyAdmin [0-9.]*" README | head -1 | cut -d' ' -f2)
        else
            PMA_VERSION="Latest"
        fi
        
        print_status "phpMyAdmin $PMA_VERSION installed successfully"
        print_status "Access URL: http://$PMA_FOLDER.$domain"
        print_warning "IMPORTANT: Keep this folder name secret: $PMA_FOLDER"
        echo "$PMA_FOLDER" > /root/phpmyadmin_folder.txt
        print_status "Folder name saved to: /root/phpmyadmin_folder.txt"
        
        # Show troubleshooting info
        echo ""
        print_status "📋 Troubleshooting Information:"
        echo "   • If you can't access phpMyAdmin, check:"
        echo "     - Nginx is running: systemctl status nginx"
        echo "     - PHP-FPM is running: systemctl status php$php_version-fpm"
        echo "     - File permissions: ls -la /var/www/$PMA_FOLDER"
        echo "     - Nginx error logs: tail -f /var/log/nginx/error.log"
        echo "   • Default login: root (no password) or create MySQL user"
        echo "   • Security: Consider using .htaccess or IP restrictions"
    else
        print_error "Nginx configuration test failed"
        print_error "Check Nginx configuration: nginx -t"
        print_error "Check Nginx error logs: tail -f /var/log/nginx/error.log"
        exit 1
    fi
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_phpmyadmin "$@"
fi