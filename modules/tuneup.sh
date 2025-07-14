#!/bin/bash

# =============================================================================
# Server Optimization Module
# =============================================================================
# Optimasi server untuk performa dan keamanan
# =============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[TUNEUP]${NC} $1"
}

print_error() {
    echo -e "${RED}[TUNEUP ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[TUNEUP WARNING]${NC} $1"
}

install_redis() {
    print_status "Installing Redis..."
    
    echo "📦 Installing Redis server..."
    apt install -y redis-server
    
    # Configure Redis
    print_status "Configuring Redis..."
    echo "⚙️  Optimizing Redis memory settings..."
    sed -i 's/# maxmemory <bytes>/maxmemory 256mb/' /etc/redis/redis.conf
    sed -i 's/# maxmemory-policy noeviction/maxmemory-policy allkeys-lru/' /etc/redis/redis.conf
    
    print_status "Starting Redis service..."
    echo "🚀 Enabling and starting Redis..."
    systemctl enable redis-server
    systemctl start redis-server
    
    print_status "Redis installed and configured"
}

configure_opcache() {
    local php_version=${1:-8.2}
    
    print_status "Configuring PHP OPcache..."
    
    # Create OPcache configuration
    echo "⚙️  Creating OPcache configuration for PHP $php_version..."
    cat > /etc/php/$php_version/fpm/conf.d/10-opcache.ini << EOF
opcache.enable=1
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=4000
opcache.revalidate_freq=2
opcache.fast_shutdown=1
opcache.enable_cli=1
opcache.validate_timestamps=0
opcache.save_comments=1
EOF
    
    # Restart PHP-FPM
    print_status "Restarting PHP-FPM..."
    echo "🔄 Restarting PHP-FPM with OPcache..."
    systemctl restart php$php_version-fpm
    
    print_status "OPcache configured for PHP $php_version"
}

optimize_sysctl() {
    print_status "Optimizing system kernel parameters..."
    
    # Backup current sysctl
    echo "💾 Backing up current sysctl configuration..."
    cp /etc/sysctl.conf /etc/sysctl.conf.backup.$(date +%Y%m%d_%H%M%S)
    
    # Add optimization parameters
    echo "⚡ Adding performance optimization parameters..."
    cat >> /etc/sysctl.conf << EOF

# Network optimization
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_no_metrics_save = 1
net.core.netdev_max_backlog = 5000

# File system optimization
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288

# Memory optimization
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
EOF
    
    # Apply changes
    print_status "Applying kernel parameters..."
    echo "🔄 Applying new sysctl parameters..."
    sysctl -p
    
    print_status "System kernel parameters optimized"
}

setup_monitoring() {
    print_status "Setting up basic monitoring..."
    
    # Install monitoring tools
    echo "📦 Installing monitoring tools..."
    apt install -y htop iotop nethogs nload
    
    # Create system info script
    print_status "Creating system monitoring script..."
    echo "📝 Creating system information script..."
    cat > /usr/local/bin/system-info.sh << 'EOF'
#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== System Information ===${NC}"
echo "OS: $(lsb_release -d | cut -d: -f2 | xargs)"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime -p)"
echo "System Time: $(date)"
echo "Timezone: $(timedatectl show --property=Timezone --value 2>/dev/null || echo 'Unknown')"
echo ""

echo -e "${BLUE}=== Hardware Information ===${NC}"
echo "CPU: $(nproc) cores"
echo "Memory: $(free -h | awk 'NR==2{print $2}') total, $(free -h | awk 'NR==2{print $3}') used, $(free -h | awk 'NR==2{print $4}') free"
echo "Swap: $(free -h | awk 'NR==3{print $2}') total, $(free -h | awk 'NR==3{print $3}') used, $(free -h | awk 'NR==3{print $4}') free"
echo "Disk: $(df -h / | awk 'NR==2{print $2}') total, $(df -h / | awk 'NR==2{print $3}') used, $(df -h / | awk 'NR==2{print $4}') available"
echo "Disk Usage: $(df -h / | awk 'NR==2{print $5}') used"
echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo "CPU Usage: $(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 2>/dev/null || echo "Unknown")%"
echo ""

echo -e "${BLUE}=== Web Server Information ===${NC}"
if command -v nginx &> /dev/null; then
    nginx_version=$(nginx -v 2>&1 | cut -d/ -f2 2>/dev/null || echo "Unknown")
    echo "Nginx: $nginx_version"
    echo "Nginx Status: $(systemctl is-active nginx 2>/dev/null || echo 'Not found')"
else
    echo "Nginx: Not installed"
fi

if command -v apache2 &> /dev/null; then
    apache_version=$(apache2 -v 2>/dev/null | head -1 | cut -d: -f2 | cut -d/ -f2 2>/dev/null || echo "Unknown")
    echo "Apache: $apache_version"
    echo "Apache Status: $(systemctl is-active apache2 2>/dev/null || echo 'Not found')"
else
    echo "Apache: Not installed"
fi
echo ""

echo -e "${BLUE}=== PHP Information ===${NC}"
if command -v php &> /dev/null; then
    php_version=$(php -v 2>/dev/null | head -1 | cut -d' ' -f2 2>/dev/null || echo "Unknown")
    echo "PHP CLI: $php_version"
    
    # Check for PHP-FPM versions
    for version in 8.3 8.2 8.1 8.0 7.4 7.3; do
        if systemctl list-units --full --all 2>/dev/null | grep -q "php$version-fpm"; then
            status=$(systemctl is-active "php$version-fpm" 2>/dev/null || echo "Not found")
            echo "PHP $version-FPM: $status"
        fi
    done
else
    echo "PHP: Not installed"
fi
echo ""

echo -e "${BLUE}=== Database Information ===${NC}"
if command -v mysql &> /dev/null; then
    mysql_version=$(mysql --version 2>/dev/null | cut -d' ' -f6 | cut -d',' -f1 2>/dev/null || echo "Unknown")
    echo "MySQL: $mysql_version"
    echo "MySQL Status: $(systemctl is-active mysql 2>/dev/null || echo 'Not found')"
elif command -v mariadb &> /dev/null; then
    mariadb_version=$(mariadb --version 2>/dev/null | cut -d' ' -f6 | cut -d',' -f1 2>/dev/null || echo "Unknown")
    echo "MariaDB: $mariadb_version"
    echo "MariaDB Status: $(systemctl is-active mariadb 2>/dev/null || echo 'Not found')"
else
    echo "Database: Not installed"
fi
echo ""

echo -e "${BLUE}=== Node.js Information ===${NC}"
if command -v node &> /dev/null; then
    node_version=$(node --version 2>/dev/null || echo "Unknown")
    echo "Node.js: $node_version"
    npm_version=$(npm --version 2>/dev/null || echo "Unknown")
    echo "npm: $npm_version"
    if command -v yarn &> /dev/null; then
        yarn_version=$(yarn --version 2>/dev/null || echo "Unknown")
        echo "Yarn: $yarn_version"
    fi
    if command -v pm2 &> /dev/null; then
        pm2_version=$(pm2 --version 2>/dev/null | head -1 | cut -d' ' -f2 2>/dev/null || echo "Unknown")
        echo "PM2: $pm2_version"
    fi
else
    echo "Node.js: Not installed"
fi

if command -v composer &> /dev/null; then
    composer_version=$(composer --version 2>/dev/null | cut -d' ' -f3 2>/dev/null || echo "Unknown")
    echo "Composer: $composer_version"
else
    echo "Composer: Not installed"
fi

if command -v git &> /dev/null; then
    git_version=$(git --version 2>/dev/null | cut -d' ' -f3 2>/dev/null || echo "Unknown")
    echo "Git: $git_version"
else
    echo "Git: Not installed"
fi
echo ""

echo -e "${BLUE}=== Cache & Performance ===${NC}"
if command -v redis-server &> /dev/null; then
    redis_version=$(redis-server --version 2>/dev/null | cut -d' ' -f3 2>/dev/null || echo "Unknown")
    echo "Redis: $redis_version"
    echo "Redis Status: $(systemctl is-active redis-server 2>/dev/null || echo 'Not found')"
else
    echo "Redis: Not installed"
fi

if command -v memcached &> /dev/null; then
    memcached_version=$(memcached --version 2>/dev/null | cut -d' ' -f2 2>/dev/null || echo "Unknown")
    echo "Memcached: $memcached_version"
    echo "Memcached Status: $(systemctl is-active memcached 2>/dev/null || echo 'Not found')"
fi

if command -v frankenphp &> /dev/null; then
    frankenphp_version=$(frankenphp version 2>/dev/null | cut -d' ' -f2 2>/dev/null || echo "Unknown")
    echo "FrankenPHP: $frankenphp_version"
    echo "FrankenPHP Status: $(systemctl is-active frankenphp 2>/dev/null || echo 'Not found')"
else
    echo "FrankenPHP: Not installed"
fi
echo ""

# Port Information
echo -e "${BLUE}=== Port Information ===${NC}"
echo "HTTP (80): $(ss -tuln 2>/dev/null | grep ':80 ' | wc -l 2>/dev/null || echo "0") connections"
echo "HTTPS (443): $(ss -tuln 2>/dev/null | grep ':443 ' | wc -l 2>/dev/null || echo "0") connections"
echo "SSH (22): $(ss -tuln 2>/dev/null | grep ':22 ' | wc -l 2>/dev/null || echo "0") connections"
echo "MySQL (3306): $(ss -tuln 2>/dev/null | grep ':3306 ' | wc -l 2>/dev/null || echo "0") connections"
echo "Redis (6379): $(ss -tuln 2>/dev/null | grep ':6379 ' | wc -l 2>/dev/null || echo "0") connections"
echo ""

# Kernel Information
echo -e "${BLUE}=== Kernel Information ===${NC}"
echo "Kernel Version: $(uname -r)"
echo "Kernel Architecture: $(uname -m)"
echo "Kernel Command Line: $(cat /proc/cmdline 2>/dev/null | cut -c1-80)..."
echo ""

echo -e "${BLUE}=== Service Status Summary ===${NC}"
services=("nginx" "apache2" "mysql" "mariadb" "redis-server" "memcached" "frankenphp")
for service in "${services[@]}"; do
    if systemctl list-unit-files 2>/dev/null | grep -q "$service"; then
        status=$(systemctl is-active "$service" 2>/dev/null || echo "not-found")
        if [[ "$status" == "active" ]]; then
            echo -e "${GREEN}✅ $service: Running${NC}"
        elif [[ "$status" == "inactive" ]]; then
            echo -e "${YELLOW}⏸️  $service: Stopped${NC}"
        else
            echo -e "${RED}❌ $service: Not found${NC}"
        fi
    fi
done

# PHP-FPM Services
echo ""
echo -e "${BLUE}=== PHP-FPM Services ===${NC}"
for version in 8.3 8.2 8.1 8.0 7.4 7.3; do
    if systemctl list-unit-files 2>/dev/null | grep -q "php$version-fpm"; then
        status=$(systemctl is-active "php$version-fpm" 2>/dev/null || echo "not-found")
        if [[ "$status" == "active" ]]; then
            echo -e "${GREEN}✅ PHP $version-FPM: Running${NC}"
        elif [[ "$status" == "inactive" ]]; then
            echo -e "${YELLOW}⏸️  PHP $version-FPM: Stopped${NC}"
        else
            echo -e "${RED}❌ PHP $version-FPM: Not found${NC}"
        fi
    fi
done
EOF
    
    chmod +x /usr/local/bin/system-info.sh
    
    print_status "Monitoring tools installed"
    print_status "Run: /usr/local/bin/system-info.sh for system information"
}

create_backup_script() {
    print_status "Creating backup script..."
    
    echo "📝 Creating automated backup script..."
    cat > /usr/local/bin/backup-system.sh << 'EOF'
#!/bin/bash

# System backup script
BACKUP_DIR="/var/backups/system"
DATE=$(date +%Y%m%d_%H%M%S)
DOMAIN="your-domain.com"  # Change this

mkdir -p $BACKUP_DIR

echo "Starting backup at $(date)"

# Backup database
echo "Backing up database..."
mysqldump -u root -p wordpress > $BACKUP_DIR/db_backup_$DATE.sql
gzip $BACKUP_DIR/db_backup_$DATE.sql

# Backup web files
echo "Backing up web files..."
tar -czf $BACKUP_DIR/web_backup_$DATE.tar.gz /var/www/$DOMAIN

# Backup configurations
echo "Backing up configurations..."
tar -czf $BACKUP_DIR/config_backup_$DATE.tar.gz /etc/nginx /etc/php /etc/mysql

# Keep only last 7 backups
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed at $(date)"
echo "Backup location: $BACKUP_DIR"
EOF
    
    chmod +x /usr/local/bin/backup-system.sh
    
    # Add to crontab (daily backup at 2 AM)
    print_status "Scheduling automated backups..."
    echo "⏰ Scheduling daily backup at 2:00 AM..."
    (crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/backup-system.sh") | crontab -
    
    print_status "Backup script created and scheduled for daily execution at 2 AM"
}

setup_firewall() {
    print_status "Setting up basic firewall..."
    
    # Install UFW if not present
    echo "📦 Installing UFW firewall..."
    apt install -y ufw
    
    # Reset UFW
    print_status "Configuring firewall rules..."
    echo "🔒 Resetting UFW configuration..."
    ufw --force reset
    
    # Set default policies
    echo "🛡️  Setting default policies..."
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow SSH
    echo "🔓 Allowing SSH access..."
    ufw allow ssh
    
    # Allow HTTP and HTTPS
    echo "🌐 Allowing HTTP and HTTPS..."
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Enable UFW
    print_status "Enabling firewall..."
    echo "🚀 Enabling UFW firewall..."
    ufw --force enable
    
    print_status "Firewall configured and enabled"
}

optimize_nginx() {
    print_status "Optimizing Nginx configuration..."
    
    # Backup current config
    echo "💾 Backing up Nginx configuration..."
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d_%H%M%S)
    
    # Get number of CPU cores
    CPU_CORES=$(nproc)
    echo "⚡ Detected $CPU_CORES CPU cores"
    
    # Optimize worker processes
    print_status "Optimizing worker processes..."
    echo "🔧 Setting worker processes to $CPU_CORES..."
    sed -i "s/worker_processes auto;/worker_processes $CPU_CORES;/" /etc/nginx/nginx.conf
    
    # Add performance settings
    echo "⚙️  Adding performance settings..."
    sed -i '/events {/a\    use epoll;\n    worker_connections 1024;\n    multi_accept on;' /etc/nginx/nginx.conf
    
    # Test and reload
    print_status "Testing Nginx configuration..."
    echo "🧪 Testing optimized configuration..."
    if nginx -t; then
        print_status "Reloading Nginx..."
        echo "🔄 Reloading Nginx with optimized settings..."
        systemctl reload nginx
        print_status "Nginx optimized"
    else
        print_error "Nginx configuration test failed"
        exit 1
    fi
}

# Main optimization function
tuneup_server() {
    local php_version=${1:-8.2}
    
    print_status "Starting server optimization..."
    
    install_redis
    configure_opcache "$php_version"
    optimize_sysctl
    setup_monitoring
    create_backup_script
    setup_firewall
    optimize_nginx
    
    print_status "Server optimization completed!"
    print_status "System is now optimized for better performance"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tuneup_server "$@"
fi