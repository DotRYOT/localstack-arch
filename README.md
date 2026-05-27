# localstack-arch
> A terminal-driven, XAMPP-like local PHP development stack for Arch Linux & cachyOS.  
> Apache • PHP-FPM • MariaDB • phpMyAdmin • Interactive CLI Dashboard

[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?logo=arch-linux&logoColor=white)](https://archlinux.org)
[![CachyOS](https://img.shields.io/badge/CachyOS-0099E5?logo=linux&logoColor=white)](https://cachyos.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/Bash-4EAA25?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)

## ✨ Features
- 🚀 **One-command setup** – Installs & configures Apache, PHP 8.x (PHP-FPM), MariaDB, and phpMyAdmin
- 🖥️ **Interactive TUI Dashboard** – Manage services, view logs, fix permissions, and scaffold test projects without leaving the terminal
- ⚡ **Modern PHP Handler** – Uses PHP-FPM instead of legacy `mod_php` (faster, lower memory, isolated pools)
- 🔒 **Secure by default** – Runs `mariadb-secure-installation`, configures socket-based PHP-FPM, and generates a random blowfish secret for phpMyAdmin
- 📦 **Arch/cachyOS Native** – Follows standard filesystem layout (`/srv/http/`, `/etc/httpd/`, `systemd`)
- 🛠️ **Zero external dependencies** – Pure Bash + standard Arch utilities

## 📋 Prerequisites
- Arch Linux or cachyOS (rolling release)
- `sudo` access for a regular user
- Active internet connection for `pacman` downloads

## 🛠️ Installation & Usage
```bash
# 1. Download the script
curl -sSL https://raw.githubusercontent.com/<your-username>/localstack-arch/main/setup-xampp-ui.sh -o localstack-arch.sh

# 2. Make it executable
chmod +x localstack-arch.sh

# 3. Run it
./localstack-arch.sh