#!/bin/bash
# Yulo OS First-Boot Setup Script
# Runs once on first boot to apply all customizations

set -e

MARKER="/var/lib/yulo/first-boot-done"

if [ -f "$MARKER" ]; then
    exit 0
fi

mkdir -p /var/lib/yulo

echo "[yulo] Running first-boot setup..."

# 1. Compile dconf database
echo "[yulo] Compiling dconf database..."
dconf update 2>/dev/null || true

# 2. Set Plymouth theme
echo "[yulo] Setting Plymouth boot theme..."
if command -v plymouth-set-default-theme &>/dev/null; then
    plymouth-set-default-theme -R yulo 2>/dev/null || plymouth-set-default-theme yulo 2>/dev/null || true
fi

# 3. Set default GTK theme for all users
echo "[yulo] Setting default GTK theme..."
mkdir -p /etc/gtk-3.0
cat > /etc/gtk-3.0/settings.ini <<'GTKEOF'
[Settings]
gtk-theme-name=Yulo
gtk-icon-theme-name=Yulo
gtk-font-name=Cantarell 11
gtk-cursor-theme-name=Yaru
gtk-cursor-theme-size=0
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
gtk-application-prefer-dark-theme=0
GTKEOF

# 4. Set default wallpaper for GDM
echo "[yulo] Setting GDM wallpaper..."
mkdir -p /etc/dconf/profile
cat > /etc/dconf/profile/gdm <<'GDMPROF'
user
system-db:gdm
file-db:/usr/share/gdm/greeter-dconf-defaults
GDMPROF

mkdir -p /etc/dconf/db/gdm.d
cat > /etc/dconf/db/gdm.d/01-yulo-gdm <<'GDMCONF'
[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/yulo/wallpaper_4k_poster.png'
picture-options='zoom'

[org/gnome/desktop/interface]
gtk-theme='Yulo'
icon-theme='Yulo'
color-scheme='prefer-light'

[org/gnome/login-screen]
logo='/usr/share/pixmaps/yulo-logo.png'
disable-restart-buttons=false
disable-user-list=false
banner-message-enable=false
GDMCONF
dconf update 2>/dev/null || true

# 5. Enable GNOME extension for all users
echo "[yulo] Enabling yulo-shell extension..."
mkdir -p /etc/dconf/db/local.d
cat > /etc/dconf/db/local.d/01-extensions <<'EXTCONF'
[org/gnome/shell]
enabled-extensions=['yulo-shell@yulo.dev','ubuntu-appindicators@ubuntu.com']
disable-user-extensions=false
EXTCONF
dconf update 2>/dev/null || true

# 6. Compile icon theme cache
echo "[yulo] Compiling icon theme cache..."
if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f -t /usr/share/icons/Yulo 2>/dev/null || true
fi

# 7. Set hostname
echo "[yulo] Setting hostname..."
hostnamectl set-hostname yulo 2>/dev/null || echo "yulo" > /etc/hostname || true

# 8. Copy logo to pixmaps
echo "[yulo] Installing logo..."
cp /usr/share/plymouth/themes/yulo/logo.png /usr/share/pixmaps/yulo-logo.png 2>/dev/null || true

# 9. Set file permissions
echo "[yulo] Setting permissions..."
chmod -R a+rX /usr/share/themes/Yulo /usr/share/themes/Yulo-Dark /usr/share/icons/Yulo /usr/share/backgrounds/yulo 2>/dev/null || true
chmod a+r /usr/share/pixmaps/yulo-logo.png 2>/dev/null || true

# 10. Mark as done
touch "$MARKER"
echo "[yulo] First-boot setup complete."

exit 0
