#!/bin/bash

# =============================================================================
# Database Installation Module
# =============================================================================
# Instalasi MariaDB/MySQL dengan konfigurasi secure
# =============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[DATABASE]${NC} $1"
}

print_error() {
    echo -e "${RED}[DATABASE ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[DATABASE WARNING]${NC} $1"
}

install_database() {
    local db_name=${1:-wordpress}
    local db_user=${2:-wp_user}
    local db_pass=${3:-}
    
    if [[ -z "$db_pass" ]]; then
        db_pass=$(openssl rand -base64 12)
    fi
    
    print_status "Installing MariaDB/MySQL..."
    
    # Install MariaDB
    echo "📦 Installing MariaDB server and client..."
    apt install -y mariadb-server mariadb-client
    
    # Start and enable MariaDB
    print_status "Starting MariaDB service..."
    echo "🚀 Enabling and starting MariaDB..."
    systemctl enable mariadb
    systemctl start mariadb
    
    # Secure MySQL installation
    print_status "Securing MariaDB installation..."
    echo "🔒 Running MySQL secure installation..."
    mysql_secure_installation << EOF

y
0
$db_pass
$db_pass
y
y
y
y
EOF
    
    # Create database and user
    print_status "Creating database and user..."
    echo "🗄️  Creating database: $db_name"
    echo "👤 Creating user: $db_user"
    mysql -u root -p$db_pass << EOF
CREATE DATABASE IF NOT EXISTS $db_name CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_pass';
GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    # Configure MariaDB for better performance
    print_status "Optimizing MariaDB performance..."
    echo "⚡ Configuring performance settings..."
    cat >> /etc/mysql/mariadb.conf.d/50-server.cnf << EOF

# Performance optimization
innodb_buffer_pool_size = 256M
innodb_log_file_size = 64M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT
query_cache_size = 32M
query_cache_type = 1
max_connections = 100
EOF
    
    # Restart MariaDB
    print_status "Restarting MariaDB with new configuration..."
    echo "🔄 Restarting MariaDB service..."
    systemctl restart mariadb
    
    print_status "Database installed and configured successfully"
    print_status "Database: $db_name"
    print_status "Database User: $db_user"
    print_status "Database Password: $db_pass"
    print_status "Root Password: $db_pass"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_database "$@"
fi 