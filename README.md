# localstack-arch

> A terminal-first, XAMPP-style local PHP stack for Arch Linux and CachyOS.  
> Apache • PHP-FPM • MariaDB • phpMyAdmin • Interactive CLI dashboard

[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?logo=arch-linux&logoColor=white)](https://archlinux.org)
[![CachyOS](https://img.shields.io/badge/CachyOS-0099E5?logo=linux&logoColor=white)](https://cachyos.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/Bash-4EAA25?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)

> ⚠️ Disclaimer: This is an AI-assisted project.

## ✨ Features

- 🚀 **One-command setup** – Installs & configures Apache, PHP 8.x (PHP-FPM), MariaDB, and phpMyAdmin
- 🖥️ **Interactive TUI dashboard** – Manage services, inspect logs, fix permissions, and scaffold test projects without leaving the terminal
- ⚡ **Modern PHP Handler** – Uses PHP-FPM instead of legacy `mod_php` (faster, lower memory, isolated pools)
- 🔒 **Secure by default** – Runs `mariadb-secure-installation`, configures socket-based PHP-FPM, and generates a random blowfish secret for phpMyAdmin
- 📦 **Arch Linux and CachyOS native** – Follows standard filesystem layout (`/srv/http/`, `/etc/httpd/`, `systemd`)
- 🛠️ **Zero external dependencies** – Pure Bash + standard Arch utilities

## 📋 Prerequisites

- Arch Linux or CachyOS (rolling release)
- `sudo` access for a regular user
- Active internet connection for `pacman` downloads

## 🛠️ Installation & Usage

```bash
# 1. Download the script
curl -sSL https://raw.githubusercontent.com/DotRYOT/localstack-arch/main/setup-xampp-ui.sh -o localstack-arch.sh
```

```bash
# 2. Make it executable
chmod +x localstack-arch.sh
```

```bash
# 3. Run it
./localstack-arch.sh
```

### ⚠️ Do not run as root. The script will prompt for sudo automatically.

## 🖥️ Interactive Dashboard

After installation, the script launches a persistent CLI menu.

### 📋 Quick Actions

1. Check Service Status
2. Restart All Services
3. View Apache Logs
4. Fix Web Root Permissions
5. Create Test Project
6. Exit

## 🌐 Accessing Your Stack

| Service           | URL                         | Credentials                        |
| ----------------- | --------------------------- | ---------------------------------- |
| Apache Web Server | http://localhost            | N/A                                |
| phpMyAdmin        | http://localhost/phpmyadmin | `root` + password set during setup |

## 📁 Paths & Permissions

- 📁 Default web root: `/srv/http/`
- 💡 Symlink projects: `sudo ln -s ~/myproject /srv/http/myproject`
- 🔑 Fix permissions: `sudo chown -R $USER:users /srv/http/`

## 🛠️ Manual Management

```bash
# Service control
sudo systemctl {start|stop|restart|status} httpd mariadb php-fpm

# View live logs
sudo journalctl -u httpd -f
sudo journalctl -u mariadb -f
sudo journalctl -u php-fpm -f

# Add PHP extensions
sudo pacman -S php-redis php-xdebug php-imagick
sudo systemctl restart php-fpm
```

### 🐛 Troubleshooting

- **Port 80 in use?** Run `sudo lsof -i :80` to find conflicts, or change `Listen 80` in `/etc/httpd/conf/httpd.conf`.
- **MariaDB root login fails?** Run `sudo mysql_secure_installation` again, or reset via `sudo mysql` (no password on fresh install).
- **phpMyAdmin "Configuration incomplete" warning?** The script auto-generates a `blowfish_secret`. Verify `/etc/webapps/phpMyAdmin/config.inc.php` exists and is not empty.

### 🤝 Contributing

PRs, issues, and feature requests are welcome.

Please follow:

- Fork and create a feature branch
- Use Git names in `MMDDYYYY/HHMM` format (24-hour time), for example: `05272026/1751`
- Keep changes POSIX/bash compliant
- Test on fresh Arch Linux and CachyOS VMs before submitting
