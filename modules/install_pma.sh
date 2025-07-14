#!/bin/bash

# =============================================================================
# phpMyAdmin Installation Module
# =============================================================================
# Instalasi phpMyAdmin dengan opsi nama folder dan domain/subdomain
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

# Function to cleanup on error
cleanup_installation() {
    local folder=$1
    print_warning "Cleaning up installation..."
    rm -rf "/var/www/$folder"
    rm -f "/etc/nginx/sites-enabled/phpmyadmin"
    rm -f "/etc/nginx/sites-available/phpmyadmin"
    print_status "Cleanup completed."
}

install_phpmyadmin() {
    local php_version=${1:-8.2}
    local TEMP_FOLDER="pma_temp"
    local PMA_FOLDER=""
    local DOMAIN_TYPE=""
    local DOMAIN=""
    local PMA_URL=""
    
    print_status "Starting phpMyAdmin Installation..."
    
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
    
    # Create temporary phpMyAdmin directory
    print_status "Creating temporary phpMyAdmin directory..."
    mkdir -p /var/www/$TEMP_FOLDER
    
    # Download phpMyAdmin
    cd /var/www/$TEMP_FOLDER
    print_status "Downloading latest phpMyAdmin..."
    
    # Try multiple download methods with file validation
    DOWNLOAD_SUCCESS=false
    
    # Function to validate downloaded file
    validate_file() {
        local file="$1"
        if [[ -f "$file" ]]; then
            # Check if file is a valid tar.gz (should be > 1MB and start with gzip magic bytes)
            local size=$(stat -c%s "$file" 2>/dev/null || echo "0")
            if [[ $size -gt 1048576 ]]; then  # > 1MB
                if file "$file" | grep -q "gzip compressed data"; then
                    return 0
                fi
            fi
        fi
        return 1
    }
    
    # Method 1: Try official phpMyAdmin download (most reliable)
    echo "🔄 Trying official phpMyAdmin download..."
    if wget -q --timeout=30 --tries=3 https://files.phpmyadmin.net/phpMyAdmin/5.2.2/phpMyAdmin-5.2.2-all-languages.tar.gz; then
        if validate_file "phpMyAdmin-5.2.2-all-languages.tar.gz"; then
            DOWNLOAD_SUCCESS=true
            echo "✅ Download successful via official phpMyAdmin"
        else
            echo "❌ Downloaded file is invalid, trying alternative..."
            rm -f phpMyAdmin-5.2.2-all-languages.tar.gz
        fi
    fi
    
    # Method 2: Try with curl if wget failed
    if [[ "$DOWNLOAD_SUCCESS" == false ]]; then
        echo "🔄 Trying with curl..."
        if curl -L -o phpMyAdmin-5.2.2-all-languages.tar.gz --connect-timeout 30 --max-time 300 https://files.phpmyadmin.net/phpMyAdmin/5.2.2/phpMyAdmin-5.2.2-all-languages.tar.gz; then
            if validate_file "phpMyAdmin-5.2.2-all-languages.tar.gz"; then
                DOWNLOAD_SUCCESS=true
                echo "✅ Download successful via curl"
            else
                echo "❌ Downloaded file is invalid"
                rm -f phpMyAdmin-5.2.2-all-languages.tar.gz
            fi
        fi
    fi
    
    # Method 3: Try GitHub releases as fallback
    if [[ "$DOWNLOAD_SUCCESS" == false ]]; then
        echo "🔄 Trying GitHub releases..."
        if wget -q --timeout=30 --tries=3 https://github.com/phpmyadmin/phpmyadmin/releases/download/5.2.2/phpMyAdmin-5.2.2-all-languages.tar.gz; then
            if validate_file "phpMyAdmin-5.2.2-all-languages.tar.gz"; then
                DOWNLOAD_SUCCESS=true
                echo "✅ Download successful via GitHub releases"
            else
                echo "❌ Downloaded file is invalid"
                rm -f phpMyAdmin-5.2.2-all-languages.tar.gz
            fi
        fi
    fi
    
    if [[ "$DOWNLOAD_SUCCESS" == false ]]; then
        print_error "All download methods failed. Please check your internet connection."
        print_error "Debug information:"
        echo "   • Current directory: $(pwd)"
        echo "   • Files in directory: $(ls -la)"
        echo "   • Network connectivity test:"
        ping -c 1 8.8.8.8 >/dev/null 2>&1 && echo "     ✅ Internet connection OK" || echo "     ❌ Internet connection failed"
        print_error "You can manually download phpMyAdmin from: https://www.phpmyadmin.net/downloads/"
        print_error "And extract it to: /var/www/$TEMP_FOLDER"
        exit 1
    fi
    
    # Extract phpMyAdmin files
    print_status "Extracting phpMyAdmin files..."
    echo "📦 Extracting phpMyAdmin files..."
    
    if [[ -f "phpMyAdmin-5.2.2-all-languages.tar.gz" ]]; then
        tar -xzf phpMyAdmin-5.2.2-all-languages.tar.gz --strip-components=1
        rm phpMyAdmin-5.2.2-all-languages.tar.gz
    elif [[ -f "phpMyAdmin-latest-all-languages.tar.gz" ]]; then
        tar -xzf phpMyAdmin-latest-all-languages.tar.gz --strip-components=1
        rm phpMyAdmin-latest-all-languages.tar.gz
    elif [[ -f "phpMyAdmin-5.2.1-all-languages.tar.gz" ]]; then
        tar -xzf phpMyAdmin-5.2.1-all-languages.tar.gz --strip-components=1
        rm phpMyAdmin-5.2.1-all-languages.tar.gz
    else
        print_error "No phpMyAdmin archive found after download"
        exit 1
    fi
    
    # Validate extraction
    print_status "Validating extracted files..."
    echo "🔍 Checking for required files..."
    
    if [[ ! -f "index.php" ]] || [[ ! -f "config.sample.inc.php" ]]; then
        print_error "phpMyAdmin files not extracted correctly"
        echo "   • Files found: $(ls -la | head -10)"
        print_error "Please check the download and extraction process"
        exit 1
    fi
    
    echo "✅ phpMyAdmin files extracted successfully"
    
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
    chown -R www-data:www-data /var/www/$TEMP_FOLDER
    chmod -R 755 /var/www/$TEMP_FOLDER
    
    # Create temp directory if it doesn't exist
    mkdir -p /var/www/$TEMP_FOLDER/tmp
    chmod 777 /var/www/$TEMP_FOLDER/tmp
    chown www-data:www-data /var/www/$TEMP_FOLDER/tmp
    
    # After successful extraction, ask user for folder name
    while true; do
        echo
        read -p "Do you want to use a custom folder name for security? (y/n): " USE_CUSTOM_FOLDER
        case $USE_CUSTOM_FOLDER in
            [Yy]*)
                while true; do
                    read -p "Enter custom folder name (alphanumeric only): " PMA_FOLDER
                    if [[ $PMA_FOLDER =~ ^[a-zA-Z0-9_-]+$ ]]; then
                        break
                    else
                        print_error "Invalid folder name. Use only letters, numbers, underscore, and hyphen."
                    fi
                done
                break
                ;;
            [Nn]*)
                PMA_FOLDER="pma_$(openssl rand -hex 4)"
                print_status "Using auto-generated folder name: $PMA_FOLDER"
                break
                ;;
            *)
                print_error "Please answer y or n."
                ;;
        esac
    done
    
    # Move files to final location
    if [ -d "/var/www/$PMA_FOLDER" ]; then
        print_error "Folder /var/www/$PMA_FOLDER already exists!"
        read -p "Do you want to remove it and continue? (y/n): " REMOVE_EXISTING
        case $REMOVE_EXISTING in
            [Yy]*)
                rm -rf "/var/www/$PMA_FOLDER"
                ;;
            *)
                print_error "Installation cancelled."
                cleanup_installation $TEMP_FOLDER
                return 1
                ;;
        esac
    fi
    
    mv /var/www/$TEMP_FOLDER /var/www/$PMA_FOLDER
    
    # Ask for domain setup
    while true; do
        echo
        echo "Select domain setup type:"
        echo "1) Install on main domain (example.com/phpmyadmin)"
        echo "2) Install on subdomain (phpmyadmin.example.com)"
        read -p "Enter choice (1 or 2): " DOMAIN_TYPE
        case $DOMAIN_TYPE in
            1)
                read -p "Enter your main domain (e.g., example.com): " DOMAIN
                PMA_URL="$DOMAIN/$PMA_FOLDER"
                break
                ;;
            2)
                read -p "Enter your domain (e.g., example.com): " DOMAIN
                PMA_URL="$PMA_FOLDER.$DOMAIN"
                break
                ;;
            *)
                print_error "Please select 1 or 2."
                ;;
        esac
    done
    
    # Create Nginx configuration based on choice
    print_status "Creating Nginx configuration..."
    if [ "$DOMAIN_TYPE" = "1" ]; then
        # Configuration for main domain
        cat > /etc/nginx/sites-available/phpmyadmin << EOF
location /$PMA_FOLDER {
    alias /var/www/$PMA_FOLDER;
    index index.php index.html index.htm;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    location ~ ^/$PMA_FOLDER/(.+\.php)$ {
        alias /var/www/$PMA_FOLDER/\$1;
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php$php_version-fpm.sock;
        fastcgi_param SCRIPT_FILENAME /var/www/$PMA_FOLDER/\$1;
        fastcgi_param HTTPS on;
    }
    
    location ~ /\.ht {
        deny all;
    }
}
EOF
    else
        # Configuration for subdomain
        cat > /etc/nginx/sites-available/phpmyadmin << EOF
server {
    listen 80;
    listen 443 ssl;
    server_name $PMA_URL;
    
    # SSL Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    # Optimize SSL
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;
    
    # Cloudflare SSL
    set_real_ip_from 103.21.244.0/22;
    set_real_ip_from 103.22.200.0/22;
    set_real_ip_from 103.31.4.0/22;
    set_real_ip_from 104.16.0.0/13;
    set_real_ip_from 104.24.0.0/14;
    set_real_ip_from 108.162.192.0/18;
    set_real_ip_from 131.0.72.0/22;
    set_real_ip_from 141.101.64.0/18;
    set_real_ip_from 162.158.0.0/15;
    set_real_ip_from 172.64.0.0/13;
    set_real_ip_from 173.245.48.0/20;
    set_real_ip_from 188.114.96.0/20;
    set_real_ip_from 190.93.240.0/20;
    set_real_ip_from 197.234.240.0/22;
    set_real_ip_from 198.41.128.0/17;
    set_real_ip_from 2400:cb00::/32;
    set_real_ip_from 2606:4700::/32;
    set_real_ip_from 2803:f800::/32;
    set_real_ip_from 2405:b500::/32;
    set_real_ip_from 2405:8100::/32;
    set_real_ip_from 2c0f:f248::/32;
    set_real_ip_from 2a06:98c0::/29;
    
    real_ip_header CF-Connecting-IP;
    
    # Force HTTPS
    if (\$scheme = http) {
        return 301 https://\$server_name\$request_uri;
    }
    
    root /var/www/$PMA_FOLDER;
    index index.php index.html index.htm;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php$php_version-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTPS on;
        include fastcgi_params;
    }
    
    location ~ /\.ht {
        deny all;
    }
}
EOF
    fi
    
    # Enable site configuration if it's a subdomain
    if [ "$DOMAIN_TYPE" = "2" ]; then
        # Check if symlink already exists
        if [ -L "/etc/nginx/sites-enabled/phpmyadmin" ]; then
            rm -f /etc/nginx/sites-enabled/phpmyadmin
        fi
        
        # Create symlink and check if successful
        if ! ln -sf /etc/nginx/sites-available/phpmyadmin /etc/nginx/sites-enabled/; then
            print_error "Failed to create Nginx symlink!"
            cleanup_installation $PMA_FOLDER
            return 1
        fi
    fi
    
    # Test Nginx configuration
    print_status "Testing Nginx configuration..."
    if nginx -t; then
        print_status "Nginx configuration test successful!"
        
        # Restart Nginx service
        print_status "Restarting Nginx service..."
        if ! systemctl restart nginx; then
            print_error "Failed to restart Nginx!"
            print_warning "Rolling back changes..."
            cleanup_installation $PMA_FOLDER
            return 1
        fi
        
        # Save folder name securely
        echo "$PMA_FOLDER" > /root/phpmyadmin_folder.txt
        chmod 600 /root/phpmyadmin_folder.txt
        
        print_status "Installation completed successfully!"
        if [ "$DOMAIN_TYPE" = "1" ]; then
            print_status "Access URL: http://$PMA_URL"
        else
            print_status "Access URL: http://$PMA_URL"
        fi
        print_warning "IMPORTANT: Keep this folder name secret: $PMA_FOLDER"
        print_status "Folder name saved to: /root/phpmyadmin_folder.txt"
    else
        print_error "Nginx configuration test failed!"
        print_warning "Rolling back changes..."
        cleanup_installation $PMA_FOLDER
        
        echo
        read -p "Do you want to try installation again? (y/n): " TRY_AGAIN
        case $TRY_AGAIN in
            [Yy]*)
                install_phpmyadmin "$@"
                ;;
            *)
                print_error "Installation cancelled."
                return 1
                ;;
        esac
    fi
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_phpmyadmin "$@"
fi