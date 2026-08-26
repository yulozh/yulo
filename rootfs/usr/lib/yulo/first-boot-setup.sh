#!/bin/bash
# yulo OS First-Boot Setup Script (XFCE Edition)
# Runs once on first boot to apply all customizations

set -e

MARKER="/var/lib/yulo/first-boot-done"

if [ -f "$MARKER" ]; then
    exit 0
fi

mkdir -p /var/lib/yulo

echo "[yulo] Running first-boot setup (XFCE)..."

# 1. 设置默认应用
echo "[yulo] Setting default applications..."
mkdir -p /etc/xdg
cat > /etc/xdg/mimeapps.list <<'MIMEEOF'
[Default Applications]
x-scheme-handler/http=chromium-browser.desktop
x-scheme-handler/https=chromium-browser.desktop
text/html=chromium-browser.desktop
inode/directory=thunar.desktop
text/plain=mousepad.desktop
image/jpeg=ristretto.desktop
image/png=ristretto.desktop
MIMEEOF

# 2. 配置 LightDM
echo "[yulo] Configuring LightDM..."
mkdir -p /etc/lightdm/lightdm.conf.d
cat > /etc/lightdm/lightdm.conf.d/90-yulo.conf <<'LIGHTDMEOF'
[Seat:*]
user-session=xfce
greeter-session=lightdm-gtk-greeter
greeter-hide-users=false
greeter-show-manual-login=true
allow-guest=false
LIGHTDMEOF

# 3. 配置 LightDM 欢迎界面
echo "[yulo] Setting LightDM theme..."
cat > /etc/lightdm/lightdm-gtk-greeter.conf <<'GREETEREOF'
[greeter]
background=/usr/share/backgrounds/yulo/wallpaper_4k_poster.png
theme-name=Yulo
icon-theme-name=Yulo
font-name=Cantarell 11
xft-antialias=true
xft-hintstyle=hintslight
xft-rgba=rgb
indicators=~host;~spacer;~clock;~spacer;~session;~power
clock-format=%H:%M
GREETEREOF

# 4. 设置环境变量（输入法）
echo "[yulo] Setting environment variables..."
cat > /etc/environment <<'ENVEOF'
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
ENVEOF

# 5. 配置 Fcitx5 自动启动
echo "[yulo] Configuring Fcitx5 autostart..."
mkdir -p /etc/xdg/autostart
cat > /etc/xdg/autostart/fcitx5.desktop <<'FCITXEOF'
[Desktop Entry]
Version=1.0
Name=Fcitx 5
GenericName=Input Method
Comment=Start Input Method
Exec=fcitx5
Icon=fcitx
Terminal=false
Type=Application
Categories=System;Utility;
StartupNotify=false
NoDisplay=true
Hidden=false
FCITXEOF

# 6. 编译图标主题缓存
echo "[yulo] Compiling icon theme cache..."
if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f -t /usr/share/icons/Yulo 2>/dev/null || true
fi

# 7. 设置主机名
echo "[yulo] Setting hostname..."
hostnamectl set-hostname yulo 2>/dev/null || echo "yulo" > /etc/hostname || true

# 8. 安装 logo
echo "[yulo] Installing logo..."
cp /usr/share/plymouth/themes/yulo/logo.png /usr/share/pixmaps/yulo-logo.png 2>/dev/null || true

# 9. 设置文件权限
echo "[yulo] Setting file permissions..."
chmod -R a+rX /usr/share/themes/Yulo /usr/share/themes/Yulo-Dark /usr/share/icons/Yulo /usr/share/backgrounds/yulo 2>/dev/null || true
chmod a+r /usr/share/pixmaps/yulo-logo.png 2>/dev/null || true
chmod +x /usr/bin/yulo-dark-mode-toggle 2>/dev/null || true

# 10. 为默认用户复制配置
echo "[yulo] Copying config to default user..."
if [ -d "/home/user" ]; then
    cp -r /etc/skel/.config /home/user/ 2>/dev/null || true
    chown -R user:user /home/user/.config 2>/dev/null || true
fi

# 11. 启用 LightDM
echo "[yulo] Enabling LightDM..."
systemctl enable lightdm 2>/dev/null || true

# 12. 标记完成
touch "$MARKER"
echo "[yulo] First-boot setup complete (XFCE Edition)."

exit 0
