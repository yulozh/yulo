#!/bin/bash
# yulo OS ISO Builder
# Builds a custom yulo ISO from Ubuntu 26.04 LTS
# Run on Ubuntu 24.04/26.04 with root: sudo ./build-yulo-iso.sh
#
# Prerequisites:
#   sudo apt install squashfs-tools xorriso p7zip-full rsync

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${SCRIPT_DIR}/build"
SOURCE_ISO="${SCRIPT_DIR}/../Downloads/ubuntu-26.04-desktop-amd64.iso"
OUTPUT_ISO="${SCRIPT_DIR}/yulo-1.0-desktop-amd64.iso"
ROOTFS_DIR="${WORK_DIR}/rootfs"
ISO_DIR="${WORK_DIR}/iso"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check root
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root (sudo)"
    exit 1
fi

# Check source ISO
if [ ! -f "$SOURCE_ISO" ]; then
    log_error "Source ISO not found: $SOURCE_ISO"
    log_info "Download Ubuntu 26.04 LTS desktop ISO first."
    exit 1
fi

# Check tools
for tool in mksquashfs unsquashfs xorriso 7z rsync; do
    if ! command -v "$tool" &>/dev/null; then
        log_error "Required tool not found: $tool"
        log_info "Install with: sudo apt install squashfs-tools xorriso p7zip-full rsync"
        exit 1
    fi
done

log_info "========================================"
log_info "  yulo OS ISO Builder"
log_info "========================================"
log_info "Source: $SOURCE_ISO"
log_info "Output: $OUTPUT_ISO"
log_info "Work:   $WORK_DIR"
log_info ""

# Clean previous build
log_info "Cleaning previous build..."
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR" "$ISO_DIR" "$ROOTFS_DIR"

# Step 1: Extract ISO
log_info "[1/8] Extracting source ISO..."
7z x "$SOURCE_ISO" -o"$ISO_DIR" -y > /dev/null 2>&1
# Fix permissions
chmod -R a+rwX "$ISO_DIR"
log_info "  ISO extracted to $ISO_DIR"

# Step 2: Extract squashfs
log_info "[2/8] Extracting squashfs filesystem..."
SQUASHFS_FILE=$(find "$ISO_DIR" -name "filesystem.squashfs" | head -1)
if [ -z "$SQUASHFS_FILE" ]; then
    log_error "filesystem.squashfs not found in ISO"
    exit 1
fi
log_info "  Found: $SQUASHFS_FILE"
unsquashfs -d "$ROOTFS_DIR" -f "$SQUASHFS_FILE" > /dev/null 2>&1
log_info "  Squashfs extracted to $ROOTFS_DIR"

# Step 3: Apply yulo customizations
log_info "[3/8] Applying yulo customizations..."
YULO_ROOTFS="${SCRIPT_DIR}/rootfs"
if [ -d "$YULO_ROOTFS" ]; then
    rsync -av "$YULO_ROOTFS/" "$ROOTFS_DIR/" > /dev/null 2>&1
    log_info "  Custom files copied"
else
    log_warn "  yulo rootfs directory not found: $YULO_ROOTFS"
fi

# Set proper ownership
chown -R root:root "$ROOTFS_DIR"
# Fix permissions on scripts
chmod +x "$ROOTFS_DIR/usr/lib/yulo/"*.sh 2>/dev/null || true
chmod +x "$ROOTFS_DIR/etc/systemd/system/"*.service 2>/dev/null || true

# Step 4: Configure first-boot services
log_info "[4/8] Configuring first-boot services..."
# Enable yulo-first-boot service
if [ -f "$ROOTFS_DIR/etc/systemd/system/yulo-first-boot.service" ]; then
    mkdir -p "$ROOTFS_DIR/etc/systemd/system/graphical.target.wants"
    ln -sf "/etc/systemd/system/yulo-first-boot.service" \
        "$ROOTFS_DIR/etc/systemd/system/graphical.target.wants/yulo-first-boot.service"
    log_info "  yulo-first-boot service enabled"
fi

# Enable yulo-hardening service
if [ -f "$ROOTFS_DIR/etc/systemd/system/yulo-hardening.service" ]; then
    mkdir -p "$ROOTFS_DIR/etc/systemd/system/multi-user.target.wants"
    ln -sf "/etc/systemd/system/yulo-hardening.service" \
        "$ROOTFS_DIR/etc/systemd/system/multi-user.target.wants/yulo-hardening.service"
    log_info "  yulo-hardening service enabled"
fi

# Enable GNOME extension
mkdir -p "$ROOTFS_DIR/usr/share/gnome-shell/extensions"
if [ -d "$ROOTFS_DIR/usr/share/gnome-shell/extensions/yulo-shell@yulo.dev" ]; then
    log_info "  yulo-shell extension installed"
fi

# Step 5: Set Plymouth theme
log_info "[5/8] Configuring Plymouth boot theme..."
if [ -d "$ROOTFS_DIR/usr/share/plymouth/themes/yulo" ]; then
    # Set as default in the rootfs
    mkdir -p "$ROOTFS_DIR/etc/alternatives"
    ln -sf "/usr/share/plymouth/themes/yulo/yulo.plymouth" \
        "$ROOTFS_DIR/etc/alternatives/default.plymouth" 2>/dev/null || true
    log_info "  Plymouth theme set to yulo"
fi

# Step 6: Repack squashfs
log_info "[6/8] Repacking squashfs..."
SQUASHFS_DIR=$(dirname "$SQUASHFS_FILE")
SQUASHFS_NAME=$(basename "$SQUASHFS_FILE")
rm -f "$SQUASHFS_FILE"
mksquashfs "$ROOTFS_DIR" "$SQUASHFS_FILE" \
    -comp xz -Xbcj x86 -b 1048576 -no-recovery -noappend \
    -e boot > /dev/null 2>&1
log_info "  Squashfs repacked"

# Step 7: Update md5sum.txt
log_info "[7/8] Updating md5sum.txt..."
cd "$ISO_DIR"
if [ -f md5sum.txt ]; then
    find . -type f -not -name md5sum.txt -not -path './isolinux/*' -print0 | \
        xargs -0 md5sum > md5sum.txt.new 2>/dev/null
    mv md5sum.txt.new md5sum.txt
    log_info "  md5sum.txt updated"
fi
cd "$SCRIPT_DIR"

# Step 8: Build ISO with xorriso
log_info "[8/8] Building bootable ISO..."

# Get original xorriso command from ISO if available
XORRISO_CMD=""
if [ -f "$ISO_DIR/.disk/mkisofs" ]; then
    XORRISO_CMD=$(cat "$ISO_DIR/.disk/mkisofs")
    log_info "  Using original xorriso command from ISO"
fi

if [ -n "$XORRISO_CMD" ]; then
    # Replace output path
    eval "$XORRISO_CMD" -o "$OUTPUT_ISO" 2>&1 | tail -3
else
    # Build with standard Ubuntu xorriso options
    xorriso -as mkisofs \
        -r -V "yulo 1.0" \
        -J -joliet-long -l -cache-inodes \
        -iso-level 3 \
        -b boot/grub/i386-pc/eltorito.img \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        --grub2-boot-info \
        --grub2-mbr "$ISO_DIR/boot/grub/i386-pc/boot_hybrid.img" \
        -eltorito-alt-boot \
        -e EFI/boot/grubx64.efi \
        -no-emul-boot \
        -isohybrid-gpt-basdat \
        -o "$OUTPUT_ISO" \
        "$ISO_DIR" 2>&1 | tail -3
fi

if [ -f "$OUTPUT_ISO" ]; then
    log_info ""
    log_info "========================================"
    log_info "  BUILD SUCCESS"
    log_info "========================================"
    log_info "Output: $OUTPUT_ISO"
    log_info "Size:   $(du -h "$OUTPUT_ISO" | cut -f1)"
    log_info "MD5:    $(md5sum "$OUTPUT_ISO" | cut -d' ' -f1)"
    log_info "SHA256: $(sha256sum "$OUTPUT_ISO" | cut -d' ' -f1)"
    log_info ""
    log_info "To write to USB: sudo dd if=$OUTPUT_ISO of=/dev/sdX bs=4M status=progress"
    log_info "To test in VM: qemu-system-x86_64 -cdrom $OUTPUT_ISO -m 4G"
else
    log_error "ISO build failed"
    exit 1
fi

# Cleanup
log_info "Cleaning up build directory..."
rm -rf "$WORK_DIR"
log_info "Done."

exit 0
