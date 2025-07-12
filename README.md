# 🧩 Debian VPS Installer

Skrip modular untuk otomatisasi instalasi dan konfigurasi stack web pada VPS berbasis Debian.

## 📦 Fitur Utama

- ✅ Update & upgrade sistem otomatis
- ✅ Instalasi PHP (pilih versi 8.0–8.3 + ekstensi lengkap)
- ✅ Instalasi Node.js, Nginx, MariaDB/MySQL
- ✅ Instalasi WordPress otomatis + konfigurasi database
- ✅ Instalasi & konfigurasi FrankenPHP
- ✅ Instalasi PMA (phpMyAdmin) dengan nama folder acak + vhost
- ✅ Pilihan konfigurasi Web App (JS → `/dist`, Laravel → `/public`, PHP native → root)
- ✅ SSL (via Certbot) dengan validasi domain DNS
- ✅ Validasi domain/subdomain, deteksi DNS A record
- ✅ Optimasi server: tuning sysctl, backup sistem, info server, backup database
- ✅ Caching: Redis, OPcache, msgpack, igbinary

## 🛠️ Cara Penggunaan

```bash
git clone https://your-git-url/vps-installer
cd vps-installer
chmod +x install.sh
./install.sh
```

## 📁 Struktur Modular

- `install.sh` - Menu utama
- `modules/` - Berisi skrip modular seperti:
  - `install_php.sh`
  - `install_nginx.sh`
  - `install_wp.sh`
  - `install_pma.sh`
  - `configure_webapp.sh`
  - `tuneup.sh`

## 🔒 Keamanan

- Folder phpMyAdmin disamarkan secara acak
- Konfigurasi Nginx diuji (`nginx -t`) sebelum diaktifkan
- Validasi DNS domain sebelum setup SSL

## 🧪 Persyaratan

- VPS Debian 10/11/12
- Akses root
- Domain/subdomain aktif dan mengarah ke IP VPS

## ⚠️ Disclaimer

Gunakan di lingkungan development atau server pribadi. Backup sebelum menjalankan skrip.
