#!/bin/bash
# yulo OS 一键构建完整 ISO
# 在 Ubuntu 22.04/24.04/26.04 上运行: sudo ./build-full-iso.sh
# 自动下载 Ubuntu 26.04 ISO，注入 yulo 定制层，输出 yulo-1.0.iso

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${SCRIPT_DIR}/iso-build"
SOURCE_ISO="${WORK_DIR}/ubuntu-26.04-desktop-amd64.iso"
OUTPUT_ISO="${SCRIPT_DIR}/yulo-1.0-desktop-amd64.iso"
YULO_ROOTFS="${SCRIPT_DIR}/rootfs"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[yulo]${NC} $1"; }
warn()  { echo -e "${YELLOW}[yulo]${NC} $1"; }
error() { echo -e "${RED}[yulo]${NC} $1"; }

# 检查 root
if [ "$EUID" -ne 0 ]; then
    error "请用 sudo 运行: sudo ./build-full-iso.sh"
    exit 1
fi

# 检查 yulo rootfs
if [ ! -d "$YULO_ROOTFS" ]; then
    error "找不到 rootfs 目录: $YULO_ROOTFS"
    exit 1
fi

echo "========================================"
echo "  yulo OS 完整 ISO 构建"
echo "========================================"
echo ""

# 1. 安装依赖
info "[1/6] 安装构建工具..."
apt-get update -qq
apt-get install -y squashfs-tools xorriso p7zip-full rsync wget curl
info "  工具就绪"

# 2. 下载 Ubuntu ISO
mkdir -p "$WORK_DIR"
if [ ! -f "$SOURCE_ISO" ]; then
    info "[2/6] 下载 Ubuntu 26.04 LTS ISO (约 6.1GB)..."
    wget -c --show-progress -O "$SOURCE_ISO" \
        "https://releases.ubuntu.com/26.04/ubuntu-26.04-desktop-amd64.iso"
    info "  下载完成"
else
    info "[2/6] ISO 已存在，跳过下载"
fi

# 3. 提取 ISO
info "[3/6] 提取 ISO 内容..."
ISO_EXTRACT="${WORK_DIR}/iso-extract"
rm -rf "$ISO_EXTRACT"
mkdir -p "$ISO_EXTRACT"
7z x "$SOURCE_ISO" -o"$ISO_EXTRACT" -y > /dev/null 2>&1 || \
xorriso -osirrox on -indev "$SOURCE_ISO" -extract / "$ISO_EXTRACT" > /dev/null 2>&1
# 修复权限
chmod -R +w "$ISO_EXTRACT" 2>/dev/null || true
info "  提取完成"

# 4. 解压 squashfs，注入 yulo
info "[4/6] 解压系统镜像并注入 yulo..."
SQUASHFS="${ISO_EXTRACT}/casper/filesystem.squashfs"
if [ ! -f "$SQUASHFS" ]; then
    # 尝试其他路径
    SQUASHFS=$(find "$ISO_EXTRACT" -name "filesystem.squashfs" | head -1)
fi
if [ -z "$SQUASHFS" ] || [ ! -f "$SQUASHFS" ]; then
    error "找不到 filesystem.squashfs"
    exit 1
fi

SQUASH_DIR="${WORK_DIR}/squashfs-root"
rm -rf "$SQUASH_DIR"
unsquashfs -d "$SQUASH_DIR" "$SQUASHFS" > /dev/null 2>&1
info "  系统镜像已解压"

# 复制 yulo rootfs 进去
info "  注入 yulo 定制层..."
rsync -a "$YULO_ROOTFS/" "$SQUASH_DIR/"

# 设置权限
chmod -R a+rX "$SQUASH_DIR/usr/share/themes/" 2>/dev/null || true
chmod -R a+rX "$SQUASH_DIR/usr/share/icons/" 2>/dev/null || true
chmod -R a+rX "$SQUASH_DIR/usr/share/backgrounds/" 2>/dev/null || true
chmod +x "$SQUASH_DIR/usr/lib/yulo/"*.sh 2>/dev/null || true

# 重新打包 squashfs
info "  重新打包系统镜像..."
rm -f "$SQUASHFS"
mksquashfs "$SQUASH_DIR" "$SQUASHFS" -comp xz -b 1M -noappend > /dev/null 2>&1
info "  系统镜像打包完成"

# 5. 更新 manifest
info "[5/6] 更新软件清单..."
MANIFEST="${ISO_EXTRACT}/casper/filesystem.manifest"
if [ -f "$MANIFEST" ]; then
    chroot "$SQUASH_DIR" dpkg-query -W --showformat='${Package} ${Version}\n' > "$MANIFEST" 2>/dev/null || true
fi
# 清理
rm -rf "$SQUASH_DIR"

# 6. 重新生成 ISO
info "[6/6] 生成 yulo ISO..."
# 找到 boot 相关文件
EFI_IMG=""
if [ -f "${ISO_EXTRACT}/boot/grub/efi.img" ]; then
    EFI_IMG="${ISO_EXTRACT}/boot/grub/efi.img"
elif [ -f "${ISO_EXTRACT}/EFI/BOOT/efi.img" ]; then
    EFI_IMG="${ISO_EXTRACT}/EFI/BOOT/efi.img"
fi

# 用 xorriso 生成可启动 ISO
xorriso -as mkisofs \
    -r -V "yulo 1.0" \
    -J -joliet-long -l -iso-level 3 \
    -o "$OUTPUT_ISO" \
    ${EFI_IMG:+-eltorito-alt-boot -e --interval:appended_partition:0:all:: -no-emul-boot} \
    -isohybrid-gpt-basdat \
    -isohybrid-apm-hfsplus \
    "$ISO_EXTRACT" 2>&1 | tail -3 || \
warn "  xorriso 高级启动参数失败，尝试基础模式..." && \
xorriso -as mkisofs \
    -r -V "yulo 1.0" \
    -J -joliet-long -l \
    -o "$OUTPUT_ISO" \
    "$ISO_EXTRACT" 2>&1 | tail -3

# 清理
rm -rf "$ISO_EXTRACT"

echo ""
echo "========================================"
echo "  构建完成!"
echo "========================================"
echo ""
echo "  输出文件: $OUTPUT_ISO"
ls -lh "$OUTPUT_ISO" 2>/dev/null || true
echo ""
echo "  用虚拟机 (VMware/VirtualBox/QEMU) 加载这个 ISO 就能安装 yulo OS"
echo "  也可以用 dd 或 Rufus 写到 U 盘做实体机安装"
echo ""
exit 0
