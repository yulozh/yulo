#!/bin/bash
# yulo OS - 轻量化系统构建
# 移除 GNOME，安装 XFCE 轻量桌面，清理冗余
# 在 chroot 环境中运行，或在真实系统上用 sudo 运行

set -e

echo "[yulo] 开始轻量化构建（GNOME → XFCE）..."

# ===== 1. 移除 GNOME 桌面环境 =====
echo "  移除 GNOME 桌面环境..."
apt-get remove -y --purge \
    gnome-shell gnome-session gnome-session-bin gnome-session-common \
    gnome-shell-common gnome-shell-extension-prefs \
    gnome-shell-extension-desktop-icons-ng \
    gnome-shell-extension-ubuntu-dock \
    gnome-shell-extension-appindicator \
    gnome-tweaks gnome-control-center \
    gdm3 gdm3-common \
    ubuntu-desktop ubuntu-desktop-minimal \
    nautilus nautilus-data nautilus-extension-gnome-terminal \
    gnome-terminal gnome-terminal-data \
    gedit gedit-common \
    gnome-calculator gnome-system-monitor \
    gnome-screenshot gnome-power-manager \
    2>/dev/null || true

# ===== 2. 移除游戏和不必要应用 =====
echo "  移除游戏和不必要应用..."
apt-get remove -y --purge \
    gnome-mines gnome-sudoku gnome-mahjongg aisleriot gnome-tetravex \
    five-or-more four-in-a-row hitori iagno lightsoff quadrapassel \
    swell-foop tali gnome-chess \
    thunderbird \
    libreoffice-impress libreoffice-math \
    gnome-todo gnome-calendar gnome-contacts gnome-maps gnome-weather \
    gnome-clocks gnome-characters gnome-font-viewer \
    gnome-sound-recorder gnome-connections \
    remmina transmission-gtk \
    firefox firefox-locale-en \
    2>/dev/null || true

# ===== 3. 安装 XFCE 轻量桌面环境 =====
echo "  安装 XFCE 桌面环境..."
apt-get install -y --no-install-recommends \
    xfce4 xfce4-goodies \
    lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings \
    thunar thunar-archive-plugin thunar-media-tags-plugin \
    xfce4-terminal \
    mousepad \
    ristretto \
    xfce4-screenshooter \
    xfce4-taskmanager \
    xfce4-whiskermenu-plugin \
    xfce4-docklike-plugin \
    xfce4-statusnotifier-plugin \
    xfce4-notifyd \
    xfce4-power-manager \
    xfce4-settings \
    xfce4-appfinder \
    xfce4-panel \
    xfconf \
    libxfce4ui-utils \
    desktop-base \
    gtk2-engines gtk2-engines-pixbuf \
    gnome-icon-theme \
    ttf-ubuntu-font-family \
    dbus-x11 \
    policykit-1-gnome \
    2>/dev/null || true

# ===== 4. 安装 Chromium 浏览器 =====
echo "  安装 Chromium 浏览器..."
apt-get install -y chromium-browser 2>/dev/null || apt-get install -y chromium 2>/dev/null || true

# ===== 5. 安装中文输入法 =====
echo "  安装中文输入法..."
apt-get install -y --no-install-recommends \
    fcitx5 fcitx5-chinese-addons fcitx5-frontend-gtk3 fcitx5-frontend-qt5 \
    fcitx5-config-qt im-config \
    2>/dev/null || true

# ===== 6. 设置 LightDM 为默认显示管理器 =====
echo "  配置 LightDM..."
echo "/usr/sbin/lightdm" > /etc/X11/default-display-manager 2>/dev/null || true
dpkg-reconfigure -f noninteractive lightdm 2>/dev/null || true

# ===== 7. 设置 XFCE 为默认会话 =====
echo "  设置 XFCE 为默认会话..."
mkdir -p /etc/lightdm/lightdm.conf.d
cat > /etc/lightdm/lightdm.conf.d/90-yulo.conf <<'LIGHTDMEOF'
[Seat:*]
user-session=xfce
greeter-session=lightdm-gtk-greeter
greeter-hide-users=false
greeter-show-manual-login=true
allow-guest=false
LIGHTDMEOF

# ===== 8. 配置 LightDM 欢迎界面 =====
echo "  配置 LightDM 主题..."
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

# ===== 9. 删除示例内容 =====
echo "  删除示例内容..."
rm -rf /usr/share/example-content/ 2>/dev/null || true
rm -f /usr/share/backgrounds/*.jpg /usr/share/backgrounds/*.png 2>/dev/null || true
rm -rf /usr/share/backgrounds/ubuntu/ 2>/dev/null || true

# ===== 10. 清理帮助文档（保留英文和中文） =====
echo "  清理帮助文档..."
if [ -d /usr/share/help ]; then
    find /usr/share/help -mindepth 1 -maxdepth 1 -type d \
        ! -name "en" ! -name "zh_CN" ! -name "zh_TW" \
        -exec rm -rf {} + 2>/dev/null || true
fi

# ===== 11. 清理 locale（保留英文和中文） =====
echo "  清理 locale..."
if [ -d /usr/share/locale ]; then
    find /usr/share/locale -mindepth 1 -maxdepth 1 -type d \
        ! -name "en" ! -name "en_US" ! -name "zh_CN" ! -name "zh_TW" ! -name "zh" \
        -exec rm -rf {} + 2>/dev/null || true
fi

# ===== 12. 自动移除孤立依赖 =====
echo "  自动移除孤立依赖..."
apt-get autoremove -y --purge 2>/dev/null || true

# ===== 13. 清理 apt 缓存 =====
echo "  清理 apt 缓存..."
apt-get clean 2>/dev/null || true
rm -rf /var/lib/apt/lists/* 2>/dev/null || true

# ===== 14. 删除临时文件 =====
rm -rf /tmp/* /var/tmp/* 2>/dev/null || true

echo "[yulo] 轻量化构建完成"
echo "  桌面环境: XFCE (替代 GNOME)"
echo "  显示管理器: LightDM (替代 GDM)"
echo "  文件管理器: Thunar (替代 Nautilus)"
echo "  终端: XFCE Terminal (替代 GNOME Terminal)"
echo "  编辑器: Mousepad (替代 Gedit)"
echo "  浏览器: Chromium"
echo "  输入法: Fcitx5"
echo "  可用空间: $(df -h / | tail -1 | awk '{print $4}')"
