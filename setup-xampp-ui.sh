#!/bin/bash
set -e

# ─────────────────────────────────────────────────────────────
# 🎨 CONSOLE UI HELPERS
# ─────────────────────────────────────────────────────────────
RED='\033[0;31m'    GREEN='\033[0;32m'   YELLOW='\033[1;33m'
BLUE='\033[0;34m'   CYAN='\033[0;36m'    BOLD='\033[1m'
NC='\033[0m'

SCRIPT_REPO_URL="https://github.com/DotRYOT/localstack-arch"
SCRIPT_RAW_URL="https://raw.githubusercontent.com/DotRYOT/localstack-arch/main/setup-xampp-ui.sh"
STACK_PACKAGES=(apache php php-fpm mariadb phpmyadmin php-gd php-mysql php-intl php-xml php-zip php-mbstring php-curl php-bcmath php-tokenizer php-phar php-fileinfo)

ui_header() {
    echo -e "\n${CYAN}${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║$(printf "%${#1}s" | sed 's/ / /g')                            ║${NC}"
    echo -e "${CYAN}${BOLD}║ ${1}                           ║${NC}"
    echo -e "${CYAN}${BOLD}║                                                          ║${NC}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════╝${NC}\n"
}

ui_step() {
    local step=$1; shift
    local msg="$1"; shift
    local bar=$(printf '■%.0s' $(seq 1 $step))$(printf '□%.0s' $(seq 1 $((6-step))))
    echo -e "${BLUE}[${bar}]${NC} ${BOLD}${msg}${NC}"
}

ui_success() { echo -e "\n${GREEN}✅ $1${NC}"; }
ui_info()    { echo -e "${YELLOW}ℹ  $1${NC}"; }
ui_error()   { echo -e "${RED}❌ $1${NC}" >&2; }
ui_divider() { echo -e "${CYAN}─────────────────────────────────────────────────────────────${NC}"; }

self_update_script() {
    local script_path tmp_file downloader

    script_path=$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || printf '%s' "$0")
    tmp_file=$(mktemp)

    if command -v curl >/dev/null 2>&1; then
        downloader="curl -fsSL"
    elif command -v wget >/dev/null 2>&1; then
        downloader="wget -qO-"
    else
        ui_info "Skipping auto-update because neither curl nor wget is installed"
        rm -f "$tmp_file"
        return 0
    fi

    if ! eval "$downloader \"$SCRIPT_RAW_URL\"" > "$tmp_file" 2>/dev/null; then
        ui_info "Skipping auto-update because the latest script could not be downloaded"
        rm -f "$tmp_file"
        return 0
    fi

    if cmp -s "$tmp_file" "$script_path"; then
        rm -f "$tmp_file"
        ui_info "Installer is already up to date"
        return 0
    fi

    chmod --reference="$script_path" "$tmp_file" 2>/dev/null || chmod +x "$tmp_file"

    if cp "$tmp_file" "$script_path" 2>/dev/null || sudo cp "$tmp_file" "$script_path"; then
        rm -f "$tmp_file"
        ui_info "Updated installer from $SCRIPT_REPO_URL"
        exec "$script_path" "$@"
    fi

    rm -f "$tmp_file"
    ui_info "Skipping auto-update because $script_path could not be replaced"
}

is_stack_installed() {
    local package

    for package in "${STACK_PACKAGES[@]}"; do
        if pacman -Q "$package" >/dev/null 2>&1; then
            return 0
        fi
    done

    [ -f /etc/httpd/conf/extra/php.conf ] || [ -f /etc/httpd/conf/extra/phpmyadmin.conf ]
}

cleanup_stack_config() {
    sudo rm -f /etc/httpd/conf/extra/php.conf /etc/httpd/conf/extra/phpmyadmin.conf
    sudo sed -i '/^Include conf\/extra\/php\.conf$/d' /etc/httpd/conf/httpd.conf 2>/dev/null || true
    sudo sed -i '/^Include conf\/extra\/phpmyadmin\.conf$/d' /etc/httpd/conf/httpd.conf 2>/dev/null || true
}

uninstall_stack() {
    clear
    ui_header "UNINSTALL XAMPP-LIKE STACK"
    ui_info "This removes Apache, PHP, MariaDB, phpMyAdmin, and the extra config written by this script"
    read -r -p "  ➤ Continue uninstall? [y/N]: " confirm

    case "$confirm" in
        [yY]|[yY][eE][sS]) ;;
        *) ui_info "Uninstall cancelled"; return 0 ;;
    esac

    ui_step 1 "Stopping services..."
    sudo systemctl disable --now httpd mariadb php-fpm > /dev/null 2>&1 || true

    ui_step 2 "Removing generated configuration..."
    cleanup_stack_config

    ui_step 3 "Removing packages..."
    sudo pacman -Rns --noconfirm "${STACK_PACKAGES[@]}" > /dev/null 2>&1 || true

    ui_step 4 "Cleaning test project symlink..."
    if [ -L /srv/http/test ]; then
        sudo rm -f /srv/http/test
    fi

    ui_success "Stack removed"
    exit 0
}

handle_existing_installation() {
    local choice

    if ! is_stack_installed; then
        return 0
    fi

    clear
    ui_header "EXISTING INSTALLATION DETECTED"
    ui_info "This system already has parts of the localstack-arch stack installed"
    echo -e "  1) ${BOLD}Reinstall / Repair${NC}"
    echo -e "  2) ${BOLD}Uninstall Stack${NC}"
    echo -e "  3) ${BOLD}Exit${NC}\n"

    while true; do
        read -r -p "  ➤ Select option [1-3]: " choice
        case "$choice" in
            1) return 0 ;;
            2) uninstall_stack ;;
            3) clear; ui_info "No changes made"; exit 0 ;;
            *) echo -e "${RED}Invalid option. Try again.${NC}\n" ;;
        esac
    done
}

# ─────────────────────────────────────────────────────────────
# 🔒 PRE-FLIGHT CHECKS
# ─────────────────────────────────────────────────────────────
if [[ $EUID -eq 0 ]]; then
    ui_error "Run as a regular user. Sudo will be used automatically."
    exit 1
fi

if ! command -v pacman &>/dev/null; then
    ui_error "This script requires cachyOS/Arch Linux (pacman not found)."
    exit 1
fi

self_update_script "$@"
handle_existing_installation

# ─────────────────────────────────────────────────────────────
# 🚀 MAIN SETUP
# ─────────────────────────────────────────────────────────────
clear
ui_header "CACHYOS XAMPP-LIKE STACK SETUP"
echo -e " ${BLUE}• Apache + PHP 8.x (PHP-FPM)${NC}"
echo -e " ${BLUE}• MariaDB (MySQL compatible)${NC}"
echo -e " ${BLUE}• phpMyAdmin (Web GUI)${NC}\n"

# 1/6 Update
ui_step 1 "Updating package database..."
sudo pacman -Sy --noconfirm --quiet > /dev/null 2>&1 || true

# 2/6 Install
ui_step 2 "Installing core packages..."
sudo pacman -S --noconfirm --quiet apache php php-fpm mariadb phpmyadmin \
php-gd php-mysql php-intl php-xml php-zip php-mbstring php-curl \
php-bcmath php-tokenizer php-phar php-fileinfo > /dev/null 2>&1

# 3/6 Apache + PHP-FPM
ui_step 3 "Configuring Apache & PHP-FPM..."
sudo sed -i 's/^#LoadModule proxy_module modules\/mod_proxy.so/LoadModule proxy_module modules\/mod_proxy.so/' /etc/httpd/conf/httpd.conf 2>/dev/null || true
sudo sed -i 's/^#LoadModule proxy_fcgi_module modules\/mod_proxy_fcgi.so/LoadModule proxy_fcgi_module modules\/mod_proxy_fcgi.so/' /etc/httpd/conf/httpd.conf 2>/dev/null || true

sudo tee /etc/httpd/conf/extra/php.conf > /dev/null << 'EOF'
<FilesMatch \.php$>
    SetHandler "proxy:unix:/run/php-fpm/www.sock|fcgi://localhost"
</FilesMatch>
DirectoryIndex index.php index.html
EOF

grep -q "Include conf/extra/php.conf" /etc/httpd/conf/httpd.conf || \
echo "Include conf/extra/php.conf" | sudo tee -a /etc/httpd/conf/httpd.conf > /dev/null

# 4/6 MariaDB
ui_step 4 "Initializing MariaDB..."
sudo systemctl enable --now mariadb > /dev/null 2>&1
ui_info "Starting interactive security setup..."
ui_info "Follow prompts to set root password & secure installation"
sudo mariadb-secure-installation || true

# 5/6 phpMyAdmin
ui_step 5 "Configuring phpMyAdmin..."
[ ! -f /etc/webapps/phpMyAdmin/config.inc.php ] && \
sudo cp /etc/webapps/phpMyAdmin/config.sample.inc.php /etc/webapps/phpMyAdmin/config.inc.php

if grep -q "\$cfg\['blowfish_secret'\] = ''" /etc/webapps/phpMyAdmin/config.inc.php 2>/dev/null; then
    SECRET=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32)
    sudo sed -i "s/\$cfg\['blowfish_secret'\] = ''/\$cfg['blowfish_secret'] = '$SECRET'/" /etc/webapps/phpMyAdmin/config.inc.php
fi

sudo tee /etc/httpd/conf/extra/phpmyadmin.conf > /dev/null << 'EOF'
Alias /phpmyadmin "/usr/share/webapps/phpMyAdmin"
<Directory "/usr/share/webapps/phpMyAdmin">
    DirectoryIndex index.php
    AllowOverride All
    Options FollowSymLinks
    Require all granted
</Directory>
EOF

grep -q "Include conf/extra/phpmyadmin.conf" /etc/httpd/conf/httpd.conf || \
echo "Include conf/extra/phpmyadmin.conf" | sudo tee -a /etc/httpd/conf/httpd.conf > /dev/null

# 6/6 Start Services
ui_step 6 "Starting services..."
sudo systemctl enable --now httpd php-fpm > /dev/null 2>&1

# ─────────────────────────────────────────────────────────────
# 🖥️ POST-SETUP DASHBOARD
# ─────────────────────────────────────────────────────────────
clear
ui_header "✅ SETUP COMPLETE!"

echo -e "${GREEN}  🌐 Web Root:${NC}        /srv/http/"
echo -e "${GREEN}  🖥️ Apache:${NC}          http://localhost"
echo -e "${GREEN}  🗄️ phpMyAdmin:${NC}      http://localhost/phpmyadmin\n"
ui_divider

# Interactive Menu
while true; do
    echo -e "${CYAN}  📋 Quick Actions:${NC}"
    echo -e "  1) ${BOLD}Check Service Status${NC}"
    echo -e "  2) ${BOLD}Restart All Services${NC}"
    echo -e "  3) ${BOLD}View Apache Logs${NC}"
    echo -e "  4) ${BOLD}Fix Web Root Permissions${NC}"
    echo -e "  5) ${BOLD}Create Test Project${NC}"
    echo -e "  6) ${BOLD}Exit${NC}\n"
    
    read -p "  ➤ Select option [1-6]: " choice
    case $choice in
        1) clear; sudo systemctl status httpd mariadb php-fpm --no-pager; echo -e "\nPress Enter to continue..."; read ;;
        2) clear; sudo systemctl restart httpd mariadb php-fpm; echo -e "${GREEN}Services restarted!${NC}\nPress Enter to continue..."; read ;;
        3) clear; sudo journalctl -u httpd --no-pager -n 20; echo -e "\nPress Enter to continue..."; read ;;
        4) sudo chown -R "$USER:users" /srv/http/; echo -e "${GREEN}Permissions fixed!${NC}\nPress Enter to continue..."; read ;;
        5) mkdir -p ~/projects/xampp-test; echo '<?php phpinfo(); ?>' > ~/projects/xampp-test/index.php; sudo ln -sf ~/projects/xampp-test /srv/http/test; echo -e "${GREEN}Test project created! Visit http://localhost/test${NC}\nPress Enter to continue..."; read ;;
        6) clear; ui_success "Happy coding! 🚀"; exit 0 ;;
        *) echo -e "${RED}Invalid option. Try again.${NC}\n" ;;
    esac
    clear
    ui_header "✅ SETUP COMPLETE!"
    echo -e "${GREEN}  🌐 Web Root:${NC}        /srv/http/"
    echo -e "${GREEN}  🖥️ Apache:${NC}          http://localhost"
    echo -e "${GREEN}  🗄️ phpMyAdmin:${NC}      http://localhost/phpmyadmin\n"
    ui_divider
done