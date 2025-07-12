# 🚀 Debian VPS Web Stack Installer

> **Skrip modular otomatis untuk setup lengkap stack web pada VPS Debian**

[![Debian](https://img.shields.io/badge/Debian-10%2F11%2F12-A81D33?style=flat&logo=debian)](https://www.debian.org/)
[![PHP](https://img.shields.io/badge/PHP-8.0--8.3-777BB4?style=flat&logo=php)](https://php.net/)
[![Nginx](https://img.shields.io/badge/Nginx-Latest-009639?style=flat&logo=nginx)](https://nginx.org/)
[![WordPress](https://img.shields.io/badge/WordPress-Ready-21759B?style=flat&logo=wordpress)](https://wordpress.org/)

## 📋 Daftar Isi

- [🎯 Tentang Proyek](#-tentang-proyek)
- [✨ Fitur Utama](#-fitur-utama)
- [📋 Persyaratan Sistem](#-persyaratan-sistem)
- [🚀 Cara Instalasi](#-cara-instalasi)
- [📁 Struktur Proyek](#-struktur-proyek)
- [⚙️ Konfigurasi](#️-konfigurasi)
- [🔒 Keamanan](#-keamanan)
- [🛠️ Troubleshooting](#️-troubleshooting)
- [📝 Changelog](#-changelog)
- [🤝 Kontribusi](#-kontribusi)
- [⚠️ Disclaimer](#️-disclaimer)

## 🎯 Tentang Proyek

**Debian VPS Web Stack Installer** adalah kumpulan skrip bash modular yang dirancang untuk mengotomatisasi proses instalasi dan konfigurasi lengkap stack web modern pada VPS berbasis Debian. Dengan tool ini, Anda dapat setup server web production-ready dalam hitungan menit.

### 🎯 Tujuan Utama

- ⚡ **Otomatisasi Total**: Setup server web tanpa intervensi manual
- 🧩 **Modular Design**: Komponen terpisah untuk fleksibilitas maksimal
- 🔒 **Security First**: Konfigurasi keamanan terbaik practices
- 📈 **Performance Optimized**: Tuning server untuk performa optimal
- 🛠️ **Easy Maintenance**: Struktur yang mudah dipelihara dan diupdate

## ✨ Fitur Utama

### 🌐 Web Stack Components
- ✅ **PHP 8.0-8.3** dengan ekstensi lengkap (OPcache, Redis, msgpack, igbinary)
- ✅ **Nginx** web server dengan konfigurasi optimal
- ✅ **MariaDB/MySQL** database server
- ✅ **Node.js** runtime environment
- ✅ **FrankenPHP** untuk performa PHP yang lebih baik

### 🎨 Web Applications
- ✅ **WordPress** instalasi otomatis dengan konfigurasi database
- ✅ **phpMyAdmin** dengan nama folder acak untuk keamanan
- ✅ **Web App Support**: Laravel, React/Vue.js, PHP Native

### 🔒 Security & SSL
- ✅ **SSL/TLS** otomatis via Let's Encrypt (Certbot)
- ✅ **Domain Validation** dengan DNS A record detection
- ✅ **Security Hardening** untuk Nginx dan PHP
- ✅ **Random phpMyAdmin folder** untuk mencegah brute force

### ⚡ Performance & Optimization
- ✅ **Server Tuning** (sysctl optimization)
- ✅ **Caching Layers** (Redis, OPcache, msgpack, igbinary)
- ✅ **Backup System** (database & system backup)
- ✅ **Server Monitoring** tools

## 📋 Persyaratan Sistem

### 💻 Hardware Minimum
- **RAM**: 1GB (2GB recommended)
- **Storage**: 10GB free space
- **CPU**: 1 core (2 cores recommended)

### 🖥️ Software Requirements
- **OS**: Debian 10 (Buster), 11 (Bullseye), atau 12 (Bookworm)
- **Access**: Root privileges (sudo atau root user)
- **Network**: Koneksi internet stabil
- **Domain**: Domain/subdomain aktif dengan DNS A record mengarah ke IP VPS

### 🌐 Domain Setup
Sebelum menjalankan installer, pastikan:
1. Domain/subdomain sudah aktif
2. DNS A record mengarah ke IP VPS
3. Port 80 dan 443 terbuka di firewall

## 🚀 Cara Instalasi

### 📥 Download & Setup

```bash
# 1. Clone repository
git clone https://github.com/yourusername/vpsdebianinstaller.git
cd vpsdebianinstaller

# 2. Berikan permission execute
chmod +x install.sh

# 3. Jalankan installer
./install.sh
```

### 🎯 Quick Start

```bash
# Install dengan satu command
curl -sSL https://raw.githubusercontent.com/yourusername/vpsdebianinstaller/main/install.sh | bash
```

### 📋 Langkah-langkah Instalasi

1. **System Update**: Update dan upgrade sistem Debian
2. **PHP Installation**: Pilih versi PHP (8.0-8.3) dan ekstensi
3. **Web Server**: Install dan konfigurasi Nginx
4. **Database**: Setup MariaDB/MySQL
5. **Applications**: Install WordPress dan phpMyAdmin
6. **SSL Setup**: Konfigurasi SSL dengan Let's Encrypt
7. **Optimization**: Tuning server dan caching
8. **Security**: Hardening dan backup setup

## 📁 Struktur Proyek

```
vpsdebianinstaller/
├── 📄 install.sh              # Menu utama installer
├── 📁 modules/                # Skrip modular
│   ├── 🔧 install_php.sh      # PHP installation & configuration
│   ├── 🌐 install_nginx.sh    # Nginx web server setup
│   ├── 🗄️ install_wp.sh      # WordPress installation
│   ├── 📊 install_pma.sh      # phpMyAdmin setup
│   ├── ⚙️ configure_webapp.sh # Web app configuration
│   └── 🚀 tuneup.sh          # Server optimization
├── 📄 README.md              # Dokumentasi ini
└── 📄 .gitignore            # Git ignore rules
```

### 🔧 Module Descriptions

| Module | Description | Dependencies |
|--------|-------------|--------------|
| `install_php.sh` | PHP installation dengan ekstensi lengkap | - |
| `install_nginx.sh` | Nginx web server + security config | PHP |
| `install_wp.sh` | WordPress + database setup | PHP, Nginx, MySQL |
| `install_pma.sh` | phpMyAdmin dengan security | PHP, Nginx, MySQL |
| `configure_webapp.sh` | Web app deployment config | PHP, Nginx |
| `tuneup.sh` | Server optimization & caching | All modules |

## ⚙️ Konfigurasi

### 🌐 Web Application Types

Installer mendukung berbagai jenis web application:

| Type | Document Root | Use Case |
|------|---------------|----------|
| **Laravel** | `/public` | Laravel applications |
| **React/Vue** | `/dist` | Single Page Applications |
| **PHP Native** | `/` | Traditional PHP websites |
| **WordPress** | `/` | WordPress sites |

### 🔧 PHP Configuration

- **Versions**: 8.0, 8.1, 8.2, 8.3
- **Extensions**: OPcache, Redis, msgpack, igbinary, mysqli, pdo_mysql
- **Settings**: Optimized untuk production

### 🗄️ Database Setup

- **MariaDB/MySQL** dengan konfigurasi secure
- **Database creation** otomatis untuk WordPress
- **User management** dengan privileges minimal

## 🔒 Keamanan

### 🛡️ Security Features

- **Random phpMyAdmin folder** untuk mencegah brute force attacks
- **Nginx configuration validation** sebelum deployment
- **DNS validation** untuk SSL certificate setup
- **Firewall rules** untuk port management
- **PHP security settings** (disable dangerous functions)

### 🔐 SSL/TLS Configuration

- **Let's Encrypt** certificates otomatis
- **Domain validation** dengan DNS checks
- **Auto-renewal** setup
- **HTTP to HTTPS** redirect

### 🚫 Security Hardening

- **Nginx security headers**
- **PHP security settings**
- **Database user privileges**
- **File permissions** optimal

## 🛠️ Troubleshooting

### ❌ Common Issues

#### 1. DNS Resolution Error
```bash
# Check DNS records
dig yourdomain.com A
nslookup yourdomain.com
```

#### 2. SSL Certificate Issues
```bash
# Test SSL configuration
certbot certificates
nginx -t
```

#### 3. PHP Configuration Problems
```bash
# Check PHP status
php -v
php -m | grep -E "(opcache|redis|msgpack)"
```

#### 4. Database Connection Issues
```bash
# Test MySQL connection
mysql -u root -p -e "SHOW DATABASES;"
```

### 🔍 Debug Commands

```bash
# Check service status
systemctl status nginx php8.2-fpm mysql

# View logs
tail -f /var/log/nginx/error.log
tail -f /var/log/php8.2-fpm.log

# Test configuration
nginx -t
php-fpm8.2 -t
```

## 📝 Changelog

### Version 1.0.0 (Current)
- ✅ Initial release
- ✅ PHP 8.0-8.3 support
- ✅ WordPress & phpMyAdmin installation
- ✅ SSL automation
- ✅ Server optimization

### Planned Features
- 🔄 Docker support
- 🔄 Multi-site setup
- 🔄 Backup automation
- 🔄 Monitoring integration

## 🤝 Kontribusi

Kontribusi sangat dihargai! Berikut cara berkontribusi:

1. **Fork** repository ini
2. **Create** feature branch (`git checkout -b feature/AmazingFeature`)
3. **Commit** perubahan (`git commit -m 'Add AmazingFeature'`)
4. **Push** ke branch (`git push origin feature/AmazingFeature`)
5. **Open** Pull Request

### 📋 Coding Standards

- Gunakan **bash** untuk semua scripts
- Tambahkan **comments** yang jelas
- Test di **Debian 11** minimal
- Update **documentation** jika ada perubahan

## ⚠️ Disclaimer

### 🚨 Important Notes

- **Development Use**: Gunakan di lingkungan development atau server pribadi
- **Backup First**: Selalu backup sistem sebelum menjalankan installer
- **Testing**: Test di environment terpisah sebelum production
- **Updates**: Regularly update sistem dan aplikasi

### 📞 Support

Jika mengalami masalah:

1. **Check** troubleshooting section
2. **Search** existing issues
3. **Create** new issue dengan detail lengkap
4. **Include** system information dan error logs

---

<div align="center">

**Made with ❤️ for Debian VPS users**

[![GitHub stars](https://img.shields.io/github/stars/yourusername/vpsdebianinstaller?style=social)](https://github.com/yourusername/vpsdebianinstaller)
[![GitHub forks](https://img.shields.io/github/forks/yourusername/vpsdebianinstaller?style=social)](https://github.com/yourusername/vpsdebianinstaller)

</div>
