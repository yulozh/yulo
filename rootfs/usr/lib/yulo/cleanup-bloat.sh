#!/bin/bash
# yulo OS - 清理原系统冗余
# 删除不需要的游戏、软件、示例图片、帮助文档等
# 在 chroot 环境中运行，或在真实系统上用 sudo 运行

set -e

echo "[yulo] 清理系统冗余..."

# ===== 1. 删除游戏 =====
echo "  删除游戏..."
apt-get remove -y --purge \
    gnome-mines gnome-sudoku gnome-mahjongg aisleriot gnome-tetravex \
    five-or-more four-in-a-row hitori iagno lightsoff quadrapassel \
    swell-foop tali gnome-chess 2>/dev/null || true

# ===== 2. 删除不必要的应用 =====
echo "  删除不必要的应用..."
apt-get remove -y --purge \
    thunderbird \
    libreoffice-impress libreoffice-math \
    gnome-todo gnome-calendar gnome-contacts gnome-maps gnome-weather \
    gnome-clocks gnome-characters gnome-font-viewer \
    gnome-sound-recorder gnome-connections \
    remmina transmission-gtk \
    2>/dev/null || true

# 删除 Firefox（用 Chromium 替代）
apt-get remove -y --purge firefox firefox-locale-en 2>/dev/null || true

# ===== 3. 安装 Chromium =====
echo "  安装 Chromium 浏览器..."
apt-get install -y chromium-browser 2>/dev/null || apt-get install -y chromium 2>/dev/null || true

# ===== 4. 删除示例内容 =====
echo "  删除示例内容..."
rm -rf /usr/share/example-content/ 2>/dev/null || true
rm -f /usr/share/backgrounds/*.jpg /usr/share/backgrounds/*.png 2>/dev/null || true
rm -rf /usr/share/backgrounds/ubuntu/ 2>/dev/null || true

# ===== 5. 删除不必要的帮助文档（保留英文和中文） =====
echo "  清理帮助文档..."
if [ -d /usr/share/help ]; then
    find /usr/share/help -mindepth 1 -maxdepth 1 -type d \
        ! -name "en" ! -name "zh_CN" ! -name "zh_TW" \
        -exec rm -rf {} + 2>/dev/null || true
fi

# ===== 6. 删除不必要的 locale（保留英文和中文） =====
echo "  清理 locale..."
if [ -d /usr/share/locale ]; then
    find /usr/share/locale -mindepth 1 -maxdepth 1 -type d \
        ! -name "en" ! -name "en_US" ! -name "zh_CN" ! -name "zh_TW" ! -name "zh" \
        -exec rm -rf {} + 2>/dev/null || true
fi

# ===== 7. 清理 apt 缓存 =====
echo "  清理 apt 缓存..."
apt-get clean 2>/dev/null || true
rm -rf /var/lib/apt/lists/* 2>/dev/null || true

# ===== 8. 删除临时文件 =====
rm -rf /tmp/* /var/tmp/* 2>/dev/null || true

# ===== 9. 删除 man pages（可选，节省约 50MB） =====
# rm -rf /usr/share/man/* 2>/dev/null || true

# ===== 10. 删除文档（可选，节省约 100MB） =====
# rm -rf /usr/share/doc/* 2>/dev/null || true

echo "[yulo] 清理完成"
echo "  释放空间: $(df -h / | tail -1 | awk '{print $4}') 可用"
