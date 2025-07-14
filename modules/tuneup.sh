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

echo "=== System Information ==="
echo "OS: $(lsb_release -d | cut -f2)"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"
echo "Uptime: $(uptime -p)"
echo ""

echo "=== Memory Usage ==="
free -h
echo ""

echo "=== Disk Usage ==="
df -h
echo ""

echo "=== Load Average ==="
uptime
echo ""

echo "=== Top Processes ==="
ps aux --sort=-%cpu | head -10
echo ""

echo "=== Network Connections ==="
ss -tuln | grep LISTEN
echo ""

echo "=== Service Status ==="
systemctl is-active nginx php8.2-fpm mysql redis-server
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