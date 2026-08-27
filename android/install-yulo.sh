#!/data/data/com.termux/files/usr/bin/bash
# yulo OS - Termux 一键安装脚本
# 在 Termux 中运行: bash install-yulo.sh

set -e

echo "========================================="
echo "       yulo OS 安卓版安装"
echo "========================================="
echo ""

# 检查是否在 Termux 中
if [ ! -d "/data/data/com.termux" ]; then
    echo "错误: 请在 Termux 中运行此脚本"
    exit 1
fi

echo "[1/5] 安装依赖..."
pkg update -y
pkg install -y proot-distro wget curl pulseaudio

echo ""
echo "[2/5] 下载 yulo OS ARM64 rootfs..."
cd ~
wget -O yulo-arm64-rootfs.tar.xz "https://github.com/yulozh/yulo/releases/download/v1.0/yulo-1.0-arm64-rootfs.tar.xz"

echo ""
echo "[3/5] 导入 yulo OS..."
proot-distro install yulo --tarball yulo-arm64-rootfs.tar.xz

echo ""
echo "[4/5] 配置图形界面..."
# 创建启动脚本
cat > ~/start-yulo.sh <<'START'
#!/data/data/com.termux/files/usr/bin/bash
# yulo OS 启动脚本

# 启动音频
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1

# 启动 VNC 服务器（在 yulo 中）
proot-distro login yulo -- bash -c "
    export DISPLAY=:1
    Xvfb :1 -screen 0 1080x1920x24 &
    sleep 2
    gnome-session &
    x11vnc -display :1 -nopw -listen localhost -xkb -ncache 10 -ncache_cr -forever &
"

echo "yulo OS 已启动！"
echo "请用 VNC 客户端连接 localhost:5900"
START

chmod +x ~/start-yulo.sh

echo ""
echo "[5/5] 配置触摸操控..."
cat > ~/yulo-touch-help.txt <<'HELP'
=========================================
    yulo OS 触摸操控指南
=========================================

【基础操作】
• 单指点击 = 鼠标左键单击
• 单指双击 = 鼠标左键双击
• 单指长按 = 鼠标右键单击
• 单指拖动 = 拖动窗口/选择文本

【滚动操作】
• 双指上下滑动 = 鼠标滚轮上下滚动
• 双指左右滑动 = 水平滚动

【缩放手势】
• 双指捏合 = 缩小
• 双指张开 = 放大

【多任务】
• 三指上滑 = 显示活动概览（所有窗口）
• 三指左右滑 = 切换工作区
• 三指下滑 = 显示桌面

【快捷操作】
• 从底部上滑 = 打开应用列表
• 从顶部下滑 = 打开通知/快捷设置
• 从左边缘右滑 = 返回

【键盘输入】
• 点击输入框 = 弹出软键盘
• 用 Termux 软键盘或系统键盘输入
• 音量键 = 可配置为 Ctrl/Alt

【底部状态栏】
• 左下角开始按钮 = 打开应用菜单
• 中间应用图标 = 点击切换/打开应用
• 右下角时间 = 点击打开日历/通知
• 太阳/月亮图标 = 切换日/夜间模式
• 输入法图标 = 切换中英文
• 电源图标 = 关机/重启菜单

=========================================
HELP

echo ""
echo "========================================="
echo "  安装完成！"
echo "========================================="
echo ""
echo "启动 yulo OS:"
echo "  bash ~/start-yulo.sh"
echo ""
echo "查看触摸操控指南:"
echo "  cat ~/yulo-touch-help.txt"
echo ""
echo "默认账号: yulo / yulo"
echo ""
echo "推荐 VNC 客户端:"
echo "  - VNC Viewer (RealVNC)"
echo "  - bVNC Free"
echo "  - MultiVNC"
echo ""
echo "连接地址: localhost:5900"
echo "========================================="

exit 0
