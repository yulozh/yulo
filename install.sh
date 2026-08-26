#!/bin/bash
# yulo OS One-Click Installer
# Run on Ubuntu 24.04/26.04: sudo ./install.sh
# Installs all yulo customizations directly to the running system

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOTFS="${SCRIPT_DIR}/rootfs"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[yulo]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[yulo]${NC} $1"; }
log_error() { echo -e "${RED}[yulo]${NC} $1"; }

if [ "$EUID" -ne 0 ]; then
    log_error "Please run as root: sudo ./install.sh"
    exit 1
fi

if [ ! -d "$ROOTFS" ]; then
    log_error "rootfs directory not found: $ROOTFS"
    exit 1
fi

echo "========================================"
echo "  yulo OS Installer"
echo "========================================"
echo ""

# Software setup: Chromium in, Firefox and bloat out
log_info "Setting up software..."
apt-get update -qq 2>/dev/null || true
apt-get remove -y firefox firefox-locale-en 2>/dev/null || true
apt-get remove -y gnome-mines gnome-sudoku gnome-mahjongg aisleriot gnome-tetravex 2>/dev/null || true
apt-get remove -y thunderbird 2>/dev/null || true
apt-get remove -y libreoffice-impress libreoffice-math 2>/dev/null || true
apt-get remove -y gnome-todo 2>/dev/null || true
apt-get install -y chromium-browser 2>/dev/null || apt-get install -y chromium 2>/dev/null || true
apt-get autoremove -y 2>/dev/null || true
log_info "  Chromium installed, Firefox and bloat removed"

# Step 1: Copy all files to system
log_info "[1/8] Copying yulo files to system..."
cp -a "${ROOTFS}/." /
log_info "  Files copied"

# Step 2: Set permissions
log_info "[2/8] Setting file permissions..."
chmod -R a+rX /usr/share/themes/Yulo /usr/share/themes/Yulo-Dark /usr/share/icons/Yulo /usr/share/backgrounds/yulo 2>/dev/null || true
chmod +x /usr/lib/yulo/*.sh 2>/dev/null || true
chmod 644 /etc/systemd/system/yulo-*.service 2>/dev/null || true
chmod 644 /etc/os-release /usr/lib/os-release /etc/lsb-release /etc/issue /etc/issue.net 2>/dev/null || true
chmod 644 /etc/dconf/profile/user /etc/dconf/db/local.d/* 2>/dev/null || true
log_info "  Permissions set"

# Step 3: Enable systemd services
log_info "[3/8] Enabling yulo services..."
systemctl enable yulo-first-boot.service 2>/dev/null || true
systemctl enable yulo-hardening.service 2>/dev/null || true
log_info "  Services enabled"

# Step 4: Compile dconf database
log_info "[4/8] Compiling dconf database..."
dconf update 2>/dev/null || true
log_info "  dconf compiled"

# Step 5: Compile icon theme cache
log_info "[5/8] Compiling icon theme cache..."
if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f -t /usr/share/icons/Yulo 2>/dev/null || true
fi
log_info "  Icon cache compiled"

# Step 6: Set Plymouth theme
log_info "[6/8] Setting Plymouth boot theme..."
if command -v plymouth-set-default-theme &>/dev/null; then
    plymouth-set-default-theme -R yulo 2>/dev/null || plymouth-set-default-theme yulo 2>/dev/null || true
fi
log_info "  Plymouth theme set"

# Step 7: Set GTK default settings
log_info "[7/8] Setting default GTK settings..."
mkdir -p /etc/gtk-3.0
cat > /etc/gtk-3.0/settings.ini <<'GTKEOF'
[Settings]
gtk-theme-name=Yulo
gtk-icon-theme-name=Yulo
gtk-font-name=Cantarell 11
gtk-cursor-theme-name=Yaru
gtk-application-prefer-dark-theme=0
GTKEOF
log_info "  GTK defaults set"

# Step 8: Enable GNOME extension for all users
log_info "[8/8] Enabling yulo-shell GNOME extension..."
mkdir -p /etc/dconf/db/local.d
cat > /etc/dconf/db/local.d/02-extensions <<'EXTEOF'
[org/gnome/shell]
enabled-extensions=['yulo-shell@yulo.dev']
disable-user-extensions=false
EXTEOF
dconf update 2>/dev/null || true
log_info "  Extension enabled"

echo ""
echo "========================================"
echo "  Installation Complete!"
echo "========================================"
echo ""
echo "  What was installed:"
echo "  - GTK3/GTK4 themes (Yulo light + dark)"
echo "  - GNOME Shell theme (light + dark)"
echo "  - yulo-shell extension (Win11 taskbar, dark mode, animations)"
echo "  - 4K animated wallpaper (light + dark)"
echo "  - yulo icon theme"
echo "  - Plymouth boot theme"
echo "  - System branding (yulo 1.0 Sakura)"
echo "  - dconf default settings"
echo "  - First-boot setup service"
echo "  - Security hardening service"
echo "  - Vulnerability scanner"
echo ""
echo "  Next steps:"
echo "  1. Log out and log back in (or reboot)"
echo "  2. The yulo theme and taskbar will activate automatically"
echo "  3. Click the sun/moon icon in the bottom-right to toggle dark mode"
echo ""
echo "  To uninstall: restore from backup or reinstall ubuntu-desktop package"
echo ""

exit 0
