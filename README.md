# 🚀 VPS Debian Installer

**Installer otomatis untuk VPS berbasis Debian dengan stack web lengkap**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: Debian](https://img.shields.io/badge/Platform-Debian%20Based-blue.svg)](https://www.debian.org/)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)

## 📋 Deskripsi

VPS Debian Installer adalah script installer otomatis yang dirancang untuk menginstal dan mengkonfigurasi stack web lengkap pada VPS berbasis Debian. Script ini mendukung semua distribusi Linux yang menggunakan APT sebagai package manager (Debian, Ubuntu, Linux Mint, Pop!_OS, dll).

## ✨ Fitur Utama

### 🌐 **Web Stack Lengkap**
- **Nginx** - Web server berperforma tinggi
- **Apache2** - Web server tradisional (opsional)
- **PHP** - Versi 8.3, 8.2, 8.1, 8.0, 7.4, 7.3 dengan FPM
- **MySQL/MariaDB** - Database server
- **Redis** - Cache dan session storage
- **Memcached** - Memory caching

### 🛠️ **Development Tools**
- **Node.js** - Runtime JavaScript
- **npm & Yarn** - Package managers
- **PM2** - Process manager untuk Node.js
- **Composer** - Dependency manager PHP
- **Git** - Version control system

### 🔒 **Security & SSL**
- **Let's Encrypt/Certbot** - SSL certificates gratis
- **OpenSSL** - Cryptographic library
- **UFW Firewall** - Firewall configuration
- **Security hardening** - Optimasi keamanan

### ⚡ **Performance & Optimization**
- **FrankenPHP** - PHP runtime berperforma tinggi
- **OPcache** - PHP bytecode caching
- **Redis caching** - Session dan cache storage
- **Nginx optimization** - Konfigurasi performa
- **System tuning** - Optimasi kernel dan sistem

### 📱 **CMS & Applications**
- **WordPress** - CMS populer
- **phpMyAdmin** - Database management
- **Custom web applications** - Dukungan aplikasi kustom

### 🖥️ **System Monitoring**
- **Interactive System Dashboard** - Informasi sistem real-time dengan UI yang menarik
- **Service Status Monitoring** - Status semua services dengan emoji
- **Resource Usage Tracking** - Monitoring CPU, memory, disk
- **Process Monitoring** - Top processes by CPU usage
- **Port Status** - Monitoring koneksi port
- **Automated Backups** - Backup otomatis harian

## 🎯 **Kompatibilitas**

### ✅ **Distribusi yang Didukung**
- **Debian** (11, 12, 13)
- **Ubuntu** (20.04, 22.04, 24.04)
- **Linux Mint** (20, 21, 22)
- **Pop!_OS** (20.04, 22.04, 24.04)
- **Elementary OS** (6, 7)
- **Zorin OS** (16, 17)
- **Kali Linux** (2023, 2024)
- **Parrot OS** (5.x)
- **MX Linux** (21, 23)
- **Dan semua distribusi berbasis Debian lainnya**

### 🔧 **Requirements**
- Sistem operasi berbasis Debian dengan APT
- Akses root atau sudo privileges
- Koneksi internet stabil
- Minimal 1GB RAM (2GB recommended)
- Minimal 10GB disk space

## 🚀 **Instalasi**

### **Metode 1: Download & Install**
```bash
# Download script
wget https://raw.githubusercontent.com/yourusername/vpsdebianinstaller/main/install.sh

# Berikan permission execute
chmod +x install.sh

# Jalankan installer
sudo ./install.sh
```

### **Metode 2: Clone Repository**
```bash
# Clone repository
git clone https://github.com/yourusername/vpsdebianinstaller.git

# Masuk ke direktori
cd vpsdebianinstaller

# Jalankan installer
sudo ./install.sh
```

### **Metode 3: One-liner**
```bash
curl -sSL https://raw.githubusercontent.com/yourusername/vpsdebianinstaller/main/install.sh | sudo bash
```

## 📖 **Cara Penggunaan**

### **1. Menu Utama**
Setelah menjalankan script, Anda akan melihat menu utama dengan opsi:

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                        🚀 VPS DEBIAN INSTALLER                               ║
╚══════════════════════════════════════════════════════════════════════════════╝

[1]  🐘 Install PHP (8.3, 8.2, 8.1, 8.0, 7.4, 7.3)
[2]  🌐 Install Nginx
[3]  🗄️  Install Database (MySQL/MariaDB)
[4]  🟢 Install Node.js & npm
[5]  ⚡ Install FrankenPHP
[6]  📱 Install WordPress
[7]  🗂️  Install phpMyAdmin
[8]  🔒 Install SSL (Let's Encrypt)
[9]  ⚙️  Configure Web Application
[10] 🚀 Server Optimization & Tune-up
[11] 🔧 System Maintenance
[12] 📊 System Information Dashboard
[0]  🚪 Exit

Choose an option:
```

### **2. System Information Dashboard**
Fitur baru yang interaktif dan menarik:

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                           🚀 SYSTEM OVERVIEW                                ║
╚══════════════════════════════════════════════════════════════════════════════╝

📋 Basic Information:
   🖥️  OS: Ubuntu 22.04.3 LTS
   🐧 Kernel: 5.15.0-88-generic
   🏗️  Architecture: x86_64
   🏠 Hostname: server.example.com
   ⏰ Uptime: up 5 days, 3 hours, 45 minutes

⚡ Hardware Status:
   🔥 CPU: 4 cores | Usage: 12%
   💾 Memory: 1.2G/2.0G | ████████░░ 60%
   💿 Disk: 8.5G/20G | ███████░░░ 42%
   📊 Load Average: 0.15, 0.12, 0.08

🌐 Network:
   🌍 Public IP: 203.0.113.1
   🏠 Local IP: 192.168.1.100

🕸️  Web Stack Status:
   ✅ Nginx: 1.18.0 (Running)
   🐘 PHP CLI: 8.2.15
   ✅ PHP 8.2-FPM: Running
   ✅ MySQL: 8.0.35 (Running)
   ✅ Redis: 7.0.15 (Running)

🛠️  Development Tools:
   🟢 Node.js: v18.19.0
   📦 npm: 9.8.1
   🎼 Composer: 2.6.5
   📚 Git: 2.34.1

Options:
   [1] 🔄 Refresh information
   [2] 📋 Detailed service status
   [3] 🖥️  System processes
   [4] 📊 Resource usage
   [0] ↩️  Back to main menu
```

## 📁 **Struktur Project**

```
vpsdebianinstaller/
├── install.sh                 # Script utama installer
├── modules/                   # Modul-modul installer
│   ├── install_php.sh        # Installer PHP
│   ├── install_nginx.sh      # Installer Nginx
│   ├── install_database.sh   # Installer Database
│   ├── install_nodejs.sh     # Installer Node.js
│   ├── install_frankenphp.sh # Installer FrankenPHP
│   ├── install_wp.sh         # Installer WordPress
│   ├── install_pma.sh        # Installer phpMyAdmin
│   ├── install_ssl.sh        # Installer SSL
│   ├── configure_webapp.sh   # Konfigurasi web app
│   └── tuneup.sh             # Optimasi server
├── languages/                 # File bahasa
│   ├── en.sh                 # English
│   └── id.sh                 # Indonesian
└── README.md                 # Dokumentasi
```

## ⚙️ **Konfigurasi**

### **Environment Variables**
```bash
# PHP Version (default: 8.2)
PHP_VERSION=8.2

# Database Type (mysql/mariadb)
DB_TYPE=mysql

# Domain Name
DOMAIN=example.com

# Database Credentials
DB_NAME=wordpress
DB_USER=wp_user
DB_PASS=secure_password
```

### **Custom Configuration**
Setiap modul dapat dikonfigurasi secara terpisah:

```bash
# PHP Configuration
sudo nano /etc/php/8.2/fpm/php.ini

# Nginx Configuration
sudo nano /etc/nginx/sites-available/default

# MySQL Configuration
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
```

## 🔒 **Security Features**

### **Firewall Configuration**
- UFW firewall dengan rules yang aman
- Port 22 (SSH), 80 (HTTP), 443 (HTTPS) terbuka
- Semua port lain tertutup secara default

### **SSL/TLS Security**
- Let's Encrypt certificates otomatis
- Auto-renewal certificates
- HSTS headers
- Modern SSL configuration

### **System Hardening**
- Disable root login SSH
- Change default SSH port (opsional)
- Fail2ban protection
- Regular security updates

## 📊 **Monitoring & Maintenance**

### **System Information Dashboard**
- Real-time system monitoring
- Interactive UI dengan emoji dan warna
- Progress bars untuk resource usage
- Service status dengan indikator visual
- Port monitoring
- Process monitoring

### **Automated Maintenance**
- Daily system backups
- Log rotation
- Security updates
- Performance monitoring

### **Manual Maintenance Commands**
```bash
# System information
/usr/local/bin/system-info.sh

# Backup system
/usr/local/bin/backup-system.sh

# Check service status
systemctl status nginx php8.2-fpm mysql redis-server

# View logs
tail -f /var/log/nginx/error.log
tail -f /var/log/php8.2-fpm.log
```

## 🐛 **Troubleshooting**

### **Common Issues**

#### **1. PHP-FPM tidak berjalan**
```bash
# Check status
sudo systemctl status php8.2-fpm

# Restart service
sudo systemctl restart php8.2-fpm

# Check configuration
sudo php-fpm8.2 -t
```

#### **2. Nginx error**
```bash
# Check configuration
sudo nginx -t

# Check error logs
sudo tail -f /var/log/nginx/error.log

# Restart Nginx
sudo systemctl restart nginx
```

#### **3. Database connection error**
```bash
# Check MySQL status
sudo systemctl status mysql

# Reset MySQL root password
sudo mysql_secure_installation

# Check MySQL logs
sudo tail -f /var/log/mysql/error.log
```

#### **4. SSL certificate issues**
```bash
# Check certificate status
sudo certbot certificates

# Renew certificates
sudo certbot renew

# Check SSL configuration
sudo nginx -t
```

### **Log Files Location**
```bash
# Nginx logs
/var/log/nginx/access.log
/var/log/nginx/error.log

# PHP-FPM logs
/var/log/php8.2-fpm.log

# MySQL logs
/var/log/mysql/error.log

# System logs
/var/log/syslog
/var/log/auth.log
```

## 📈 **Performance Optimization**

### **Nginx Optimization**
- Worker processes sesuai CPU cores
- Connection pooling
- Gzip compression
- Browser caching

### **PHP Optimization**
- OPcache enabled
- Memory limit optimization
- Max execution time tuning
- File upload limits

### **Database Optimization**
- InnoDB buffer pool
- Query cache
- Connection pooling
- Index optimization

### **System Optimization**
- Kernel parameters tuning
- Swap optimization
- File descriptor limits
- Process limits

## 🔄 **Updates & Maintenance**

### **Regular Updates**
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update PHP packages
sudo apt update && sudo apt upgrade php8.2-* -y

# Update Nginx
sudo apt update && sudo apt upgrade nginx -y
```

### **Backup Strategy**
- Daily automated backups
- Database dumps
- Configuration backups
- Web files backup
- 7-day retention policy

## 🤝 **Contributing**

Kontribusi sangat dihargai! Silakan:

1. Fork repository ini
2. Buat branch fitur baru (`git checkout -b feature/AmazingFeature`)
3. Commit perubahan (`git commit -m 'Add some AmazingFeature'`)
4. Push ke branch (`git push origin feature/AmazingFeature`)
5. Buat Pull Request

### **Development Guidelines**
- Gunakan bash scripting best practices
- Tambahkan komentar yang jelas
- Test pada berbagai distribusi Debian
- Update dokumentasi sesuai perubahan

## 📝 **Changelog**

### **v2.0.0** (2024-01-15)
- ✨ **NEW**: Interactive System Information Dashboard
- ✨ **NEW**: Support for all Debian-based distributions
- ✨ **NEW**: Visual progress bars dan emoji indicators
- ✨ **NEW**: Multi-language support (EN/ID)
- ✨ **NEW**: FrankenPHP integration
- ✨ **NEW**: Advanced monitoring features
- 🔧 **IMPROVED**: Error handling dan user experience
- 🔧 **IMPROVED**: Modular architecture
- 🐛 **FIXED**: System information display issues

### **v1.5.0** (2024-01-10)
- ✨ **NEW**: Node.js dan npm support
- ✨ **NEW**: Redis caching
- ✨ **NEW**: SSL automation
- 🔧 **IMPROVED**: PHP version management
- 🔧 **IMPROVED**: Database installation

### **v1.0.0** (2024-01-01)
- 🎉 **INITIAL RELEASE**
- Basic web stack installation
- WordPress dan phpMyAdmin support
- Basic security features

## 📄 **License**

Project ini dilisensikan di bawah MIT License - lihat file [LICENSE](LICENSE) untuk detail.

## 🙏 **Acknowledgments**

- [Debian Project](https://www.debian.org/) - Sistem operasi dasar
- [Nginx](https://nginx.org/) - Web server
- [PHP](https://www.php.net/) - Programming language
- [MySQL](https://www.mysql.com/) - Database server
- [Let's Encrypt](https://letsencrypt.org/) - SSL certificates
- [WordPress](https://wordpress.org/) - CMS platform

## 📞 **Support**

Jika Anda mengalami masalah atau memiliki pertanyaan:

- 📧 **Email**: rival.biasrori@gmail.com
- 📖 **Documentation**: [Wiki](https://github.com/yourusername/vpsdebianinstaller/wiki)
- 🐛 **Issues**: [GitHub Issues](https://github.com/yourusername/vpsdebianinstaller/issues)

---

**⭐ Jika project ini membantu Anda, jangan lupa untuk memberikan star! ⭐**
