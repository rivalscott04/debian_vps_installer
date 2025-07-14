#!/bin/bash

# =============================================================================
# SSL Installation Module
# =============================================================================
# Instalasi SSL/TLS dengan Let's Encrypt (Certbot)
# =============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[SSL]${NC} $1"
}

print_error() {
    echo -e "${RED}[SSL ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[SSL WARNING]${NC} $1"
}

validate_domain() {
    local domain=$1
    
    print_status "Validating domain: $domain"
    
    # Check if domain resolves
    if ! nslookup "$domain" >/dev/null 2>&1; then
        print_warning "Domain $domain does not resolve. Make sure DNS is configured properly."
        return 1
    fi
    
    # Get IP address
    DOMAIN_IP=$(nslookup "$domain" | grep -A1 "Name:" | tail -1 | awk '{print $2}')
    SERVER_IP=$(curl -s ifconfig.me)
    
    if [[ "$DOMAIN_IP" != "$SERVER_IP" ]]; then
        print_warning "Domain $domain ($DOMAIN_IP) does not point to this server ($SERVER_IP)"
        print_warning "SSL certificate installation may fail"
        return 1
    fi
    
    print_status "Domain validation successful"
    return 0
}

install_ssl() {
    local domain=${1:-localhost}
    local email=${2:-admin@$domain}
    
    print_status "Installing SSL certificate for domain: $domain"
    
    # Validate domain first
    if ! validate_domain "$domain"; then
        print_warning "Domain validation failed. Continue anyway? (y/N)"
        read -r response
        if [[ ! $response =~ ^[Yy]$ ]]; then
            print_status "SSL installation cancelled"
            exit 0
        fi
    fi
    
    # Install Certbot
    print_status "Installing Certbot..."
    echo "📦 Installing Let's Encrypt Certbot..."
    apt install -y certbot python3-certbot-nginx
    
    # Stop Nginx temporarily for standalone mode
    print_status "Stopping Nginx for certificate validation..."
    echo "⏸️  Temporarily stopping Nginx..."
    systemctl stop nginx
    
    # Get SSL certificate using standalone mode
    print_status "Obtaining SSL certificate..."
    echo "🔐 Requesting SSL certificate from Let's Encrypt..."
    if certbot certonly --standalone -d $domain -d www.$domain --non-interactive --agree-tos --email $email; then
        print_status "SSL certificate obtained successfully"
        
        # Configure Nginx for SSL
        if [[ -f /etc/nginx/sites-available/$domain ]]; then
            print_status "Configuring Nginx for SSL..."
            echo "⚙️  Backing up original configuration..."
            # Backup original config
            cp /etc/nginx/sites-available/$domain /etc/nginx/sites-available/$domain.backup
            
            # Create SSL configuration
            echo "🔐 Creating SSL-enabled configuration..."
            cat > /etc/nginx/sites-available/$domain << EOF
server {
    listen 80;
    server_name $domain www.$domain;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $domain www.$domain;
    
    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;
    
    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
    root /var/www/$domain;
    index index.php index.html index.htm;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
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
            
            # Test and reload Nginx
            print_status "Testing Nginx configuration..."
            echo "🧪 Testing SSL configuration..."
            if nginx -t; then
                print_status "Starting Nginx with SSL..."
                echo "🚀 Starting and reloading Nginx..."
                systemctl start nginx
                systemctl reload nginx
                print_status "Nginx configured for SSL successfully"
            else
                print_error "Nginx configuration test failed"
                echo "⚠️  Restoring original configuration..."
                # Restore backup
                cp /etc/nginx/sites-available/$domain.backup /etc/nginx/sites-available/$domain
                systemctl start nginx
                exit 1
            fi
        fi
        
        # Setup auto-renewal
        print_status "Setting up auto-renewal..."
        echo "⏰ Scheduling certificate auto-renewal..."
        (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet --nginx") | crontab -
        
        print_status "SSL certificate installed successfully"
        print_status "Access your site at: https://$domain"
        print_status "Auto-renewal scheduled daily at 12:00 PM"
        
    else
        print_error "SSL certificate installation failed"
        systemctl start nginx
        exit 1
    fi
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_ssl "$@"
fi 