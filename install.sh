#!/bin/bash

# =============================================================================
# 🚀 Debian VPS Web Stack Installer
# =============================================================================
# Script utama untuk instalasi dan konfigurasi stack web pada VPS Debian
# Author: VPS Debian Installer Team
# Version: 1.0.0
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"
LOG_FILE="/var/log/vps-installer.log"
DOMAIN=""
PHP_VERSION="8.2"
DB_NAME=""
DB_USER=""
DB_PASS=""
PMA_FOLDER=""
LANGUAGE="en"  # Default language: en (English) or id (Indonesian)

# Load language files
LANGUAGES_DIR="$SCRIPT_DIR/languages"

# Function to get language string
get_text() {
    local key=$1
    if [[ "$LANGUAGE" == "en" ]]; then
        source "$LANGUAGES_DIR/en.sh"
        echo "${EN_STRINGS[$key]}"
    elif [[ "$LANGUAGE" == "id" ]]; then
        source "$LANGUAGES_DIR/id.sh"
        echo "${ID_STRINGS[$key]}"
    else
        # Default to English
        source "$LANGUAGES_DIR/en.sh"
        echo "${EN_STRINGS[$key]}"
    fi
}

# Function to select language
select_language() {
    clear
    print_header
    echo ""
    echo -e "${BLUE}Select language / Pilih bahasa:${NC}"
    echo "1) English"
    echo "2) Indonesia"
    echo ""
    
    while true; do
        read -p "Enter your choice / Masukkan pilihan (1-2) [1]: " lang_choice
        lang_choice=${lang_choice:-1}
        
        case $lang_choice in
            1) LANGUAGE="en"; break ;;
            2) LANGUAGE="id"; break ;;
            *) 
                echo -e "${RED}[ERROR] Invalid choice. Please select 1-2${NC}"
                ;;
        esac
    done
    
    if [[ "$LANGUAGE" == "en" ]]; then
        print_status "Language set to: English"
    else
        print_status "Bahasa diset ke: Indonesia"
    fi
}

# Function to ask user what to do next
ask_continue() {
    echo ""
    print_status "$(get_text "MODULE_COMPLETED")"
    echo -e "${BLUE}$(get_text "WHAT_NEXT")${NC}"
    echo "$(get_text "BACK_TO_MENU")"
    echo "$(get_text "EXIT_NOW")"
    echo ""
    
    while true; do
        read -p "$(get_text "SELECT_NEXT") " continue_choice
        
        case $continue_choice in
            1) return 0 ;; # Continue to menu
            2) 
                print_status "$(get_text "GOODBYE")"
                exit 0
                ;;
            *)
                print_error "$(get_text "INVALID_CHOICE")"
                ;;
        esac
    done
}

# Function to print colored output
print_status() {
    local text=$(get_text "INFO")
    echo -e "${GREEN}[$text]${NC} $1"
}

print_warning() {
    local text=$(get_text "WARNING")
    echo -e "${YELLOW}[$text]${NC} $1"
}

print_error() {
    local text=$(get_text "ERROR")
    echo -e "${RED}[$text]${NC} $1"
}

print_header() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}  🚀 Debian VPS Web Stack Installer${NC}"
    echo -e "${CYAN}================================${NC}"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Script ini harus dijalankan sebagai root atau dengan sudo"
        exit 1
    fi
}

# Function to check system requirements
check_system() {
    print_status "Checking system requirements..."
    
    # Check OS
    if [[ ! -f /etc/debian_version ]]; then
        print_error "Sistem operasi harus Debian/Ubuntu"
        exit 1
    fi
    
    # Check Debian version
    DEBIAN_VERSION=$(cat /etc/debian_version | cut -d. -f1)
    if [[ $DEBIAN_VERSION -lt 10 ]]; then
        print_warning "Debian version $DEBIAN_VERSION detected. Recommended: Debian 10+"
    fi
    
    # Check available memory
    MEMORY=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    if [[ $MEMORY -lt 1024 ]]; then
        print_warning "Available memory: ${MEMORY}MB. Recommended: 1GB+"
    fi
    
    # Check available disk space
    DISK_SPACE=$(df / | awk 'NR==2{printf "%.0f", $4/1024}')
    if [[ $DISK_SPACE -lt 10 ]]; then
        print_warning "Available disk space: ${DISK_SPACE}GB. Recommended: 10GB+"
    fi
    
    print_status "System check completed"
}

# Function to update system
update_system() {
    print_status "Updating system packages..."
    
    apt update -y
    apt upgrade -y
    
    # Install essential packages
    apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release
    
    print_status "System updated successfully"
}

# Function to get user input
get_user_input() {
    print_header
    
    echo -e "${BLUE}Please provide the following information:${NC}"
    echo ""
    
    # Get domain
    while [[ -z "$DOMAIN" ]]; do
        read -p "Enter your domain/subdomain: " DOMAIN
        if [[ -z "$DOMAIN" ]]; then
            print_error "Domain cannot be empty"
        fi
    done
    
    # Get PHP version
    echo ""
    echo "Available PHP versions:"
    echo "1) PHP 8.0"
    echo "2) PHP 8.1"
    echo "3) PHP 8.2 (Recommended)"
    echo "4) PHP 8.3"
    
    while true; do
        read -p "Select PHP version (1-4) [3]: " php_choice
        php_choice=${php_choice:-3}
        
        case $php_choice in
            1) PHP_VERSION="8.0"; break ;;
            2) PHP_VERSION="8.1"; break ;;
            3) PHP_VERSION="8.2"; break ;;
            4) PHP_VERSION="8.3"; break ;;
            *) print_error "Invalid choice. Please select 1-4" ;;
        esac
    done
    
    # Get database information
    echo ""
    read -p "Enter database name [wordpress]: " db_name_input
    DB_NAME=${db_name_input:-wordpress}
    
    read -p "Enter database user [wp_user]: " db_user_input
    DB_USER=${db_user_input:-wp_user}
    
    # Generate random password if not provided
    DB_PASS=$(openssl rand -base64 12)
    print_status "Database password generated: $DB_PASS"
    
    echo ""
    print_status "Configuration summary:"
    echo "Domain: $DOMAIN"
    echo "PHP Version: $PHP_VERSION"
    echo "Database: $DB_NAME"
    echo "Database User: $DB_USER"
    echo "Database Password: $DB_PASS"
    echo ""
    
    read -p "Continue with installation? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_status "Installation cancelled"
        exit 0
    fi
}

# Function to validate domain
validate_domain() {
    print_status "Validating domain: $DOMAIN"
    
    # Check if domain resolves
    if ! nslookup "$DOMAIN" >/dev/null 2>&1; then
        print_warning "Domain $DOMAIN does not resolve. Make sure DNS is configured properly."
        read -p "Continue anyway? (y/N): " continue_anyway
        if [[ ! $continue_anyway =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Get IP address
    DOMAIN_IP=$(nslookup "$DOMAIN" | grep -A1 "Name:" | tail -1 | awk '{print $2}')
    SERVER_IP=$(curl -s ifconfig.me)
    
    if [[ "$DOMAIN_IP" != "$SERVER_IP" ]]; then
        print_warning "Domain $DOMAIN ($DOMAIN_IP) does not point to this server ($SERVER_IP)"
        print_warning "SSL certificate installation may fail"
    else
        print_status "Domain validation successful"
    fi
}

# Function to install PHP using module
install_php() {
    print_status "Installing PHP $PHP_VERSION..."
    
    if [[ -f "$MODULES_DIR/install_php.sh" ]]; then
        source "$MODULES_DIR/install_php.sh"
        install_php "$PHP_VERSION"
    else
        print_error "PHP installation module not found"
        exit 1
    fi
}

# Function to install Nginx using module
install_nginx() {
    print_status "Installing Nginx..."
    
    if [[ -f "$MODULES_DIR/install_nginx.sh" ]]; then
        source "$MODULES_DIR/install_nginx.sh"
        install_nginx "$DOMAIN" "$PHP_VERSION"
    else
        print_error "Nginx installation module not found"
        exit 1
    fi
}

# Function to install database using module
install_database() {
    print_status "Installing MariaDB/MySQL..."
    
    if [[ -f "$MODULES_DIR/install_database.sh" ]]; then
        source "$MODULES_DIR/install_database.sh"
        install_database "$DB_NAME" "$DB_USER" "$DB_PASS"
    else
        print_error "Database installation module not found"
        exit 1
    fi
}

# Function to install WordPress using module
install_wordpress() {
    print_status "Installing WordPress..."
    
    if [[ -f "$MODULES_DIR/install_wp.sh" ]]; then
        source "$MODULES_DIR/install_wp.sh"
        install_wordpress "$DOMAIN" "$DB_NAME" "$DB_USER" "$DB_PASS"
    else
        print_error "WordPress installation module not found"
        exit 1
    fi
}

# Function to install phpMyAdmin using module
install_phpmyadmin() {
    print_status "Installing phpMyAdmin..."
    
    if [[ -f "$MODULES_DIR/install_pma.sh" ]]; then
        source "$MODULES_DIR/install_pma.sh"
        install_phpmyadmin "$DOMAIN" "$PHP_VERSION"
        # Get the generated folder name
        if [[ -f "/root/phpmyadmin_folder.txt" ]]; then
            PMA_FOLDER=$(cat /root/phpmyadmin_folder.txt)
        fi
    else
        print_error "phpMyAdmin installation module not found"
        exit 1
    fi
}

# Function to install Node.js using module
install_nodejs() {
    print_status "Installing Node.js..."
    
    if [[ -f "$MODULES_DIR/install_nodejs.sh" ]]; then
        source "$MODULES_DIR/install_nodejs.sh"
        install_nodejs "18"
    else
        print_error "Node.js installation module not found"
        exit 1
    fi
}

# Function to install FrankenPHP using module
install_frankenphp() {
    print_status "Installing FrankenPHP..."
    
    if [[ -f "$MODULES_DIR/install_frankenphp.sh" ]]; then
        source "$MODULES_DIR/install_frankenphp.sh"
        install_frankenphp "$DOMAIN"
    else
        print_error "FrankenPHP installation module not found"
        exit 1
    fi
}

# Function to install SSL using module
install_ssl() {
    print_status "Installing SSL certificate..."
    
    if [[ -f "$MODULES_DIR/install_ssl.sh" ]]; then
        source "$MODULES_DIR/install_ssl.sh"
        install_ssl "$DOMAIN" "admin@$DOMAIN"
    else
        print_error "SSL installation module not found"
        exit 1
    fi
}

# Function to optimize server using module
optimize_server() {
    print_status "Optimizing server performance..."
    
    if [[ -f "$MODULES_DIR/tuneup.sh" ]]; then
        source "$MODULES_DIR/tuneup.sh"
        tuneup_server "$PHP_VERSION"
    else
        print_error "Server optimization module not found"
        exit 1
    fi
}

# Function to configure web app
configure_webapp() {
    print_status "Configuring web application..."
    
    echo ""
    echo "Select web application type:"
    echo "1) WordPress (Default)"
    echo "2) Laravel"
    echo "3) React/Vue.js (SPA)"
    echo "4) PHP Native"
    
    read -p "Select type (1-4) [1]: " app_choice
    app_choice=${app_choice:-1}
    
    if [[ -f "$MODULES_DIR/configure_webapp.sh" ]]; then
        source "$MODULES_DIR/configure_webapp.sh"
        
        case $app_choice in
            1) configure_webapp "php" "$DOMAIN" "$PHP_VERSION" ;;
            2) configure_webapp "laravel" "$DOMAIN" "$PHP_VERSION" ;;
            3) configure_webapp "spa" "$DOMAIN" ;;
            4) configure_webapp "php_native" "$DOMAIN" "$PHP_VERSION" ;;
            *) configure_webapp "php" "$DOMAIN" "$PHP_VERSION" ;;
        esac
    else
        print_error "Web app configuration module not found"
        exit 1
    fi
}

# Function to show detailed system information
show_system_info() {
    clear
    print_status "🖥️  SYSTEM INFORMATION DASHBOARD"
    echo ""
    
    # Get system data
    OS_INFO=$(lsb_release -d | cut -d: -f2 | xargs 2>/dev/null || echo "Unknown")
    KERNEL=$(uname -r)
    ARCH=$(uname -m)
    HOSTNAME=$(hostname)
    UPTIME=$(uptime -p)
    CPU_CORES=$(nproc)
    MEMORY_TOTAL=$(free -h | awk 'NR==2{print $2}')
    MEMORY_USED=$(free -h | awk 'NR==2{print $3}')
    MEMORY_FREE=$(free -h | awk 'NR==2{print $4}')
    DISK_TOTAL=$(df -h / | awk 'NR==2{print $2}')
    DISK_USED=$(df -h / | awk 'NR==2{print $3}')
    DISK_AVAIL=$(df -h / | awk 'NR==2{print $4}')
    DISK_PERCENT=$(df -h / | awk 'NR==2{print $5}')
    LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}')
    CPU_USAGE=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 2>/dev/null || echo "Unknown")
    PUBLIC_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || echo 'Not available')
    LOCAL_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo 'Not available')
    
    # Header with system overview
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                           🚀 SYSTEM OVERVIEW                                ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # System overview in a nice format
    echo -e "${YELLOW}📋 Basic Information:${NC}"
    echo -e "   🖥️  OS: ${GREEN}$OS_INFO${NC}"
    echo -e "   🐧 Kernel: ${GREEN}$KERNEL${NC}"
    echo -e "   🏗️  Architecture: ${GREEN}$ARCH${NC}"
    echo -e "   🏠 Hostname: ${GREEN}$HOSTNAME${NC}"
    echo -e "   ⏰ Uptime: ${GREEN}$UPTIME${NC}"
    echo ""
    
    # Hardware status with progress bars
    echo -e "${YELLOW}⚡ Hardware Status:${NC}"
    echo -e "   🔥 CPU: ${GREEN}$CPU_CORES cores${NC} | Usage: ${GREEN}${CPU_USAGE}%${NC}"
    
    # Memory bar
    MEMORY_USED_NUM=$(free | awk 'NR==2{printf "%.0f", $3/$2*100}')
    MEMORY_BAR=$(printf "█%.0s" $(seq 1 $((MEMORY_USED_NUM/10))))$(printf "░%.0s" $(seq 1 $((10-MEMORY_USED_NUM/10))))
    echo -e "   💾 Memory: ${GREEN}${MEMORY_USED}/${MEMORY_TOTAL}${NC} | ${MEMORY_BAR} ${GREEN}${MEMORY_USED_NUM}%${NC}"
    
    # Disk bar
    DISK_USED_NUM=$(df / | awk 'NR==2{printf "%.0f", $3/$2*100}')
    DISK_BAR=$(printf "█%.0s" $(seq 1 $((DISK_USED_NUM/10))))$(printf "░%.0s" $(seq 1 $((10-DISK_USED_NUM/10))))
    echo -e "   💿 Disk: ${GREEN}${DISK_USED}/${DISK_TOTAL}${NC} | ${DISK_BAR} ${GREEN}${DISK_USED_NUM}%${NC}"
    
    echo -e "   📊 Load Average: ${GREEN}$LOAD_AVG${NC}"
    echo ""
    
    # Network info
    echo -e "${YELLOW}🌐 Network:${NC}"
    echo -e "   🌍 Public IP: ${GREEN}$PUBLIC_IP${NC}"
    echo -e "   🏠 Local IP: ${GREEN}$LOCAL_IP${NC}"
    echo ""
    
    # Web Stack Status
    echo -e "${YELLOW}🕸️  Web Stack Status:${NC}"
    
    # Web servers
    if command -v nginx &> /dev/null; then
        NGINX_VERSION=$(nginx -v 2>&1 | cut -d/ -f2 2>/dev/null || echo "Unknown")
        NGINX_STATUS=$(systemctl is-active nginx 2>/dev/null || echo "Not found")
        if [[ "$NGINX_STATUS" == "active" ]]; then
            echo -e "   ✅ Nginx: ${GREEN}$NGINX_VERSION${NC} (Running)"
        else
            echo -e "   ❌ Nginx: ${GREEN}$NGINX_VERSION${NC} (Stopped)"
        fi
    else
        echo -e "   ⚪ Nginx: Not installed"
    fi
    
    if command -v apache2 &> /dev/null; then
        APACHE_VERSION=$(apache2 -v 2>/dev/null | head -1 | cut -d: -f2 | cut -d/ -f2 2>/dev/null || echo "Unknown")
        APACHE_STATUS=$(systemctl is-active apache2 2>/dev/null || echo "Not found")
        if [[ "$APACHE_STATUS" == "active" ]]; then
            echo -e "   ✅ Apache: ${GREEN}$APACHE_VERSION${NC} (Running)"
        else
            echo -e "   ❌ Apache: ${GREEN}$APACHE_VERSION${NC} (Stopped)"
        fi
    else
        echo -e "   ⚪ Apache: Not installed"
    fi
    
    # PHP versions
    if command -v php &> /dev/null; then
        PHP_VERSION=$(php -v 2>/dev/null | head -1 | cut -d' ' -f2 2>/dev/null || echo "Unknown")
        echo -e "   🐘 PHP CLI: ${GREEN}$PHP_VERSION${NC}"
        
        # PHP-FPM versions
        for version in 8.3 8.2 8.1 8.0 7.4 7.3; do
            if systemctl list-units --full --all 2>/dev/null | grep -q "php$version-fpm"; then
                status=$(systemctl is-active "php$version-fpm" 2>/dev/null || echo "Not found")
                if [[ "$status" == "active" ]]; then
                    echo -e "   ✅ PHP $version-FPM: Running"
                else
                    echo -e "   ❌ PHP $version-FPM: Stopped"
                fi
            fi
        done
    else
        echo -e "   ⚪ PHP: Not installed"
    fi
    
    # Database
    if command -v mysql &> /dev/null; then
        MYSQL_VERSION=$(mysql --version 2>/dev/null | cut -d' ' -f6 | cut -d',' -f1 2>/dev/null || echo "Unknown")
        MYSQL_STATUS=$(systemctl is-active mysql 2>/dev/null || echo "Not found")
        if [[ "$MYSQL_STATUS" == "active" ]]; then
            echo -e "   ✅ MySQL: ${GREEN}$MYSQL_VERSION${NC} (Running)"
        else
            echo -e "   ❌ MySQL: ${GREEN}$MYSQL_VERSION${NC} (Stopped)"
        fi
    elif command -v mariadb &> /dev/null; then
        MARIADB_VERSION=$(mariadb --version 2>/dev/null | cut -d' ' -f6 | cut -d',' -f1 2>/dev/null || echo "Unknown")
        MARIADB_STATUS=$(systemctl is-active mariadb 2>/dev/null || echo "Not found")
        if [[ "$MARIADB_STATUS" == "active" ]]; then
            echo -e "   ✅ MariaDB: ${GREEN}$MARIADB_VERSION${NC} (Running)"
        else
            echo -e "   ❌ MariaDB: ${GREEN}$MARIADB_VERSION${NC} (Stopped)"
        fi
    else
        echo -e "   ⚪ Database: Not installed"
    fi
    echo ""
    
    # Development Tools
    echo -e "${YELLOW}🛠️  Development Tools:${NC}"
    
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version 2>/dev/null || echo "Unknown")
        NPM_VERSION=$(npm --version 2>/dev/null || echo "Unknown")
        echo -e "   🟢 Node.js: ${GREEN}$NODE_VERSION${NC}"
        echo -e "   📦 npm: ${GREEN}$NPM_VERSION${NC}"
        
        if command -v yarn &> /dev/null; then
            YARN_VERSION=$(yarn --version 2>/dev/null || echo "Unknown")
            echo -e "   🧶 Yarn: ${GREEN}$YARN_VERSION${NC}"
        fi
        
        if command -v pm2 &> /dev/null; then
            PM2_VERSION=$(pm2 --version 2>/dev/null | head -1 | cut -d' ' -f2 2>/dev/null || echo "Unknown")
            echo -e "   ⚡ PM2: ${GREEN}$PM2_VERSION${NC}"
        fi
    else
        echo -e "   ⚪ Node.js: Not installed"
    fi
    
    if command -v composer &> /dev/null; then
        COMPOSER_VERSION=$(composer --version 2>/dev/null | cut -d' ' -f3 2>/dev/null || echo "Unknown")
        echo -e "   🎼 Composer: ${GREEN}$COMPOSER_VERSION${NC}"
    else
        echo -e "   ⚪ Composer: Not installed"
    fi
    
    if command -v git &> /dev/null; then
        GIT_VERSION=$(git --version 2>/dev/null | cut -d' ' -f3 2>/dev/null || echo "Unknown")
        echo -e "   📚 Git: ${GREEN}$GIT_VERSION${NC}"
    else
        echo -e "   ⚪ Git: Not installed"
    fi
    echo ""
    
    # Cache & Performance
    echo -e "${YELLOW}⚡ Cache & Performance:${NC}"
    
    if command -v redis-server &> /dev/null; then
        REDIS_VERSION=$(redis-server --version 2>/dev/null | cut -d' ' -f3 2>/dev/null || echo "Unknown")
        REDIS_STATUS=$(systemctl is-active redis-server 2>/dev/null || echo "Not found")
        if [[ "$REDIS_STATUS" == "active" ]]; then
            echo -e "   ✅ Redis: ${GREEN}$REDIS_VERSION${NC} (Running)"
        else
            echo -e "   ❌ Redis: ${GREEN}$REDIS_VERSION${NC} (Stopped)"
        fi
    else
        echo -e "   ⚪ Redis: Not installed"
    fi
    
    if command -v memcached &> /dev/null; then
        MEMCACHED_VERSION=$(memcached --version 2>/dev/null | cut -d' ' -f2 2>/dev/null || echo "Unknown")
        MEMCACHED_STATUS=$(systemctl is-active memcached 2>/dev/null || echo "Not found")
        if [[ "$MEMCACHED_STATUS" == "active" ]]; then
            echo -e "   ✅ Memcached: ${GREEN}$MEMCACHED_VERSION${NC} (Running)"
        else
            echo -e "   ❌ Memcached: ${GREEN}$MEMCACHED_VERSION${NC} (Stopped)"
        fi
    else
        echo -e "   ⚪ Memcached: Not installed"
    fi
    
    if command -v frankenphp &> /dev/null; then
        FRANKENPHP_VERSION=$(frankenphp version 2>/dev/null | cut -d' ' -f2 2>/dev/null || echo "Unknown")
        FRANKENPHP_STATUS=$(systemctl is-active frankenphp 2>/dev/null || echo "Not found")
        if [[ "$FRANKENPHP_STATUS" == "active" ]]; then
            echo -e "   ✅ FrankenPHP: ${GREEN}$FRANKENPHP_VERSION${NC} (Running)"
        else
            echo -e "   ❌ FrankenPHP: ${GREEN}$FRANKENPHP_VERSION${NC} (Stopped)"
        fi
    else
        echo -e "   ⚪ FrankenPHP: Not installed"
    fi
    echo ""
    
    # SSL & Security
    echo -e "${YELLOW}🔒 SSL & Security:${NC}"
    
    if command -v certbot &> /dev/null; then
        CERTBOT_VERSION=$(certbot --version 2>/dev/null | cut -d' ' -f2 2>/dev/null || echo "Unknown")
        echo -e "   ✅ Certbot: ${GREEN}$CERTBOT_VERSION${NC}"
    else
        echo -e "   ⚪ Certbot: Not installed"
    fi
    
    if command -v openssl &> /dev/null; then
        OPENSSL_VERSION=$(openssl version 2>/dev/null | cut -d' ' -f2 2>/dev/null || echo "Unknown")
        echo -e "   ✅ OpenSSL: ${GREEN}$OPENSSL_VERSION${NC}"
    else
        echo -e "   ⚪ OpenSSL: Not available"
    fi
    echo ""
    
    # Port Status
    echo -e "${YELLOW}🔌 Port Status:${NC}"
    HTTP_CONNS=$(ss -tuln 2>/dev/null | grep ':80 ' | wc -l 2>/dev/null || echo "0")
    HTTPS_CONNS=$(ss -tuln 2>/dev/null | grep ':443 ' | wc -l 2>/dev/null || echo "0")
    SSH_CONNS=$(ss -tuln 2>/dev/null | grep ':22 ' | wc -l 2>/dev/null || echo "0")
    MYSQL_CONNS=$(ss -tuln 2>/dev/null | grep ':3306 ' | wc -l 2>/dev/null || echo "0")
    REDIS_CONNS=$(ss -tuln 2>/dev/null | grep ':6379 ' | wc -l 2>/dev/null || echo "0")
    
    echo -e "   🌐 HTTP (80): ${GREEN}$HTTP_CONNS${NC} connections"
    echo -e "   🔒 HTTPS (443): ${GREEN}$HTTPS_CONNS${NC} connections"
    echo -e "   🔑 SSH (22): ${GREEN}$SSH_CONNS${NC} connections"
    echo -e "   🗄️  MySQL (3306): ${GREEN}$MYSQL_CONNS${NC} connections"
    echo -e "   🚀 Redis (6379): ${GREEN}$REDIS_CONNS${NC} connections"
    echo ""
    
    # Footer
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    📊 System information updated at $(date '+%H:%M:%S')                    ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Interactive menu
    echo -e "${YELLOW}Options:${NC}"
    echo -e "   [1] 🔄 Refresh information"
    echo -e "   [2] 📋 Detailed service status"
    echo -e "   [3] 🖥️  System processes"
    echo -e "   [4] 📊 Resource usage"
    echo -e "   [0] ↩️  Back to main menu"
    echo ""
    
    read -p "Choose an option: " choice
    
    case $choice in
        1)
            show_system_info
            ;;
        2)
            show_detailed_services
            ;;
        3)
            show_system_processes
            ;;
        4)
            show_resource_usage
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid option. Press Enter to continue...${NC}"
            read
            show_system_info
            ;;
    esac
}

# Function to show detailed service status
show_detailed_services() {
    clear
    print_status "🔍 DETAILED SERVICE STATUS"
    echo ""
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                              🚀 SERVICE STATUS                              ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # All services
    services=("nginx" "apache2" "mysql" "mariadb" "redis-server" "memcached" "frankenphp")
    echo -e "${YELLOW}🔧 Main Services:${NC}"
    for service in "${services[@]}"; do
        if systemctl list-unit-files 2>/dev/null | grep -q "$service"; then
            status=$(systemctl is-active "$service" 2>/dev/null || echo "not-found")
            if [[ "$status" == "active" ]]; then
                echo -e "   ✅ $service: ${GREEN}Running${NC}"
            elif [[ "$status" == "inactive" ]]; then
                echo -e "   ⏸️  $service: ${YELLOW}Stopped${NC}"
            else
                echo -e "   ❌ $service: ${RED}Not found${NC}"
            fi
        else
            echo -e "   ⚪ $service: ${GRAY}Not installed${NC}"
        fi
    done
    
    echo ""
    echo -e "${YELLOW}🐘 PHP-FPM Services:${NC}"
    for version in 8.3 8.2 8.1 8.0 7.4 7.3; do
        if systemctl list-unit-files 2>/dev/null | grep -q "php$version-fpm"; then
            status=$(systemctl is-active "php$version-fpm" 2>/dev/null || echo "not-found")
            if [[ "$status" == "active" ]]; then
                echo -e "   ✅ PHP $version-FPM: ${GREEN}Running${NC}"
            elif [[ "$status" == "inactive" ]]; then
                echo -e "   ⏸️  PHP $version-FPM: ${YELLOW}Stopped${NC}"
            else
                echo -e "   ❌ PHP $version-FPM: ${RED}Not found${NC}"
            fi
        else
            echo -e "   ⚪ PHP $version-FPM: ${GRAY}Not installed${NC}"
        fi
    done
    
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo -e "   [1] ↩️  Back to system info"
    echo -e "   [0] 🏠 Back to main menu"
    echo ""
    
    read -p "Choose an option: " choice
    
    case $choice in
        1)
            show_system_info
            ;;
        0)
            return
            ;;
        *)
            show_detailed_services
            ;;
    esac
}

# Function to show system processes
show_system_processes() {
    clear
    print_status "🖥️  SYSTEM PROCESSES"
    echo ""
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                            📊 TOP PROCESSES BY CPU                          ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    ps aux --sort=-%cpu | head -10 | awk 'NR==1{print "   " $0} NR>1{printf "   %-8s %-8s %-6s %-6s %-8s %-8s %-8s %-8s %-8s %-8s %s\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11}'
    
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo -e "   [1] ↩️  Back to system info"
    echo -e "   [0] 🏠 Back to main menu"
    echo ""
    
    read -p "Choose an option: " choice
    
    case $choice in
        1)
            show_system_info
            ;;
        0)
            return
            ;;
        *)
            show_system_processes
            ;;
    esac
}

# Function to show resource usage
show_resource_usage() {
    clear
    print_status "📊 RESOURCE USAGE"
    echo ""
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                              💾 MEMORY USAGE                                ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    free -h
    echo ""
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                              💿 DISK USAGE                                  ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    df -h
    echo ""
    
    echo -e "${YELLOW}Options:${NC}"
    echo -e "   [1] ↩️  Back to system info"
    echo -e "   [0] 🏠 Back to main menu"
    echo ""
    
    read -p "Choose an option: " choice
    
    case $choice in
        1)
            show_system_info
            ;;
        0)
            return
            ;;
        *)
            show_resource_usage
            ;;
    esac
}

# Function to display installation summary
show_summary() {
    print_header
    echo -e "${GREEN}🎉 $(get_text "INSTALLATION_COMPLETED")${NC}"
    echo ""
    echo -e "${BLUE}$(get_text "INSTALLATION_SUMMARY")${NC}"
    echo "Domain: $DOMAIN"
    echo "PHP Version: $PHP_VERSION"
    echo "Database: $DB_NAME"
    echo "Database User: $DB_USER"
    echo "Database Password: $DB_PASS"
    echo ""
    echo -e "${BLUE}$(get_text "ACCESS_INFO")${NC}"
    echo "WordPress: https://$DOMAIN"
    if [[ -n "$PMA_FOLDER" ]]; then
        echo "phpMyAdmin: https://$PMA_FOLDER.$DOMAIN"
    fi
    echo ""
    echo -e "${BLUE}$(get_text "NEXT_STEPS")${NC}"
    echo "1. Complete WordPress setup at https://$DOMAIN"
    if [[ -n "$PMA_FOLDER" ]]; then
        echo "2. Access phpMyAdmin at https://$PMA_FOLDER.$DOMAIN"
    fi
    echo "3. Configure your domain DNS if not done already"
    echo "4. Set up regular backups"
    echo ""
    echo -e "${YELLOW}$(get_text "IMPORTANT")${NC}"
    if [[ -n "$PMA_FOLDER" ]]; then
        echo "- Keep phpMyAdmin folder name secret: $PMA_FOLDER"
    fi
    echo "- Database password: $DB_PASS"
    echo "- Backup script: /usr/local/bin/backup-system.sh"
    echo "- System info: /usr/local/bin/system-info.sh"
    echo ""
    echo -e "${GREEN}$(get_text "HAPPY_HOSTING") 🚀${NC}"
}

# Function to show menu
show_menu() {
    while true; do
        clear
        print_header
        echo ""
        echo -e "${BLUE}$(get_text "SELECT_OPTION")${NC}"
        echo "1) $(get_text "FULL_INSTALL")"
        echo "2) $(get_text "INSTALL_PHP")"
        echo "3) $(get_text "INSTALL_NGINX")"
        echo "4) $(get_text "INSTALL_DB")"
        echo "5) $(get_text "INSTALL_WP")"
        echo "6) $(get_text "INSTALL_PMA")"
        echo "7) $(get_text "INSTALL_NODE")"
        echo "8) $(get_text "INSTALL_FRANKEN")"
        echo "9) $(get_text "INSTALL_SSL")"
        echo "10) $(get_text "OPTIMIZE_SERVER")"
        echo "11) $(get_text "CONFIGURE_WEBAPP")"
        echo "12) $(get_text "SHOW_SYSINFO")"
        echo "0) $(get_text "EXIT")"
        echo ""
        
        read -p "$(get_text "ENTER_CHOICE") (0-12): " choice
        
        case $choice in
            1)
                get_user_input
                validate_domain
                update_system
                install_php
                install_nginx
                install_database
                install_wordpress
                install_phpmyadmin
                install_nodejs
                install_frankenphp
                install_ssl
                optimize_server
                show_summary
                break
                ;;
            2) 
                install_php
                ask_continue
                ;;
            3) 
                install_nginx
                ask_continue
                ;;
            4) 
                install_database
                ask_continue
                ;;
            5) 
                install_wordpress
                ask_continue
                ;;
            6) 
                install_phpmyadmin
                ask_continue
                ;;
            7) 
                install_nodejs
                ask_continue
                ;;
            8) 
                install_frankenphp
                ask_continue
                ;;
            9) 
                install_ssl
                ask_continue
                ;;
            10) 
                optimize_server
                ask_continue
                ;;
            11) 
                configure_webapp
                ask_continue
                ;;
            12)
                show_system_info
                ;;
            0)
                print_status "$(get_text "GOODBYE")"
                exit 0
                ;;
            *)
                print_error "$(get_text "INVALID_CHOICE")"
                sleep 2
                ;;
        esac
    done
}

# Main execution
main() {
    check_root
    check_system
    
    # Select language first
    select_language
    
    if [[ $# -eq 0 ]]; then
        show_menu
    else
        # Command line arguments for automated installation
        case $1 in
            --auto)
                get_user_input
                validate_domain
                update_system
                install_php
                install_nginx
                install_database
                install_wordpress
                install_phpmyadmin
                install_nodejs
                install_frankenphp
                install_ssl
                optimize_server
                show_summary
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --auto    Automated installation"
                echo "  --help    Show this help"
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    fi
}

# Run main function
main "$@"