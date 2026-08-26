#!/bin/bash
# Yulo OS Security Hardening Script
# Disables telemetry, cloud backdoors, and hardens system

set -e

echo "[yulo-hardening] Starting security hardening..."

# 1. Remove telemetry and data collection packages
echo "[yulo-hardening] Removing telemetry packages..."
apt-get purge -y \
    ubuntu-report \
    popularity-contest \
    apport \
    apport-symptoms \
    whoopsie \
    2>/dev/null || true

# 2. Disable telemetry services
echo "[yulo-hardening] Disabling telemetry services..."
systemctl disable --now apport.service 2>/dev/null || true
systemctl disable --now whoopsie.service 2>/dev/null || true
systemctl mask apport.service 2>/dev/null || true
systemctl mask whoopsie.service 2>/dev/null || true

# 3. Disable cloud-init backdoors
echo "[yulo-hardening] Disabling cloud-init..."
systemctl disable --now cloud-init.service 2>/dev/null || true
systemctl disable --now cloud-config.service 2>/dev/null || true
systemctl disable --now cloud-final.service 2>/dev/null || true
systemctl disable --now cloud-init-local.service 2>/dev/null || true
systemctl mask cloud-init.service 2>/dev/null || true
systemctl mask cloud-config.service 2>/dev/null || true
systemctl mask cloud-final.service 2>/dev/null || true
systemctl mask cloud-init-local.service 2>/dev/null || true
touch /etc/cloud/cloud-init.disabled 2>/dev/null || true

# 4. Disable snapd telemetry (if snapd exists)
echo "[yulo-hardening] Disabling snapd telemetry..."
if command -v snap &>/dev/null; then
    snap set system refresh.hold=forever 2>/dev/null || true
fi

# 5. Harden sysctl
echo "[yulo-hardening] Hardening sysctl..."
cat > /etc/sysctl.d/99-yulo-hardening.conf <<'SYSCTLEOF'
# IP spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore ICMP broadcast requests
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Disable ICMP redirect acceptance
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0

# Log martian packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# SYN flood protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2

# Disable IPv6 if not needed (comment out to keep IPv6)
# net.ipv6.conf.all.disable_ipv6 = 1
# net.ipv6.conf.default.disable_ipv6 = 1

# Kernel hardening
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.printk = 3 3 3 3
kernel.kexec_load_disabled = 1
kernel.sysrq = 0
kernel.unprivileged_bpf_disabled = 1
net.core.bpf_jit_harden = 2

# Protect against symlink/hardlink attacks
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.protected_fifos = 2
fs.protected_regular = 2

# Disable core dumps
fs.suid_dumpable = 0
SYSCTLEOF
sysctl -p /etc/sysctl.d/99-yulo-hardening.conf 2>/dev/null || true

# 6. Disable core dumps
echo "[yulo-hardening] Disabling core dumps..."
cat > /etc/security/limits.d/99-yulo-nocore.conf <<'LIMITSEOF'
* hard core 0
* soft core 0
LIMITSEOF
echo '* hard core 0' >> /etc/security/limits.conf 2>/dev/null || true
mkdir -p /etc/systemd/coredump.conf.d
cat > /etc/systemd/coredump.conf.d/yulo-disable.conf <<'COREEOF'
[Coredump]
Storage=none
ProcessSizeMax=0
COREEOF

# 7. Set up firewall
echo "[yulo-hardening] Configuring firewall..."
if command -v ufw &>/dev/null; then
    ufw default deny incoming 2>/dev/null || true
    ufw default allow outgoing 2>/dev/null || true
    ufw enable 2>/dev/null || true
fi

# 8. Hidden /tmp
echo "[yulo-hardening] Hardening /tmp..."
# Note: /tmp tmpfs mount should be in fstab, handled at build time

# 9. Disable unused filesystems
echo "[yulo-hardening] Disabling unused filesystems..."
cat > /etc/modprobe.d/99-yulo-disable-fs.conf <<'FSEOF'
install cramfs /bin/true
install freevxfs /bin/true
install jffs2 /bin/true
install hfs /bin/true
install hfsplus /bin/true
install squashfs /bin/true
install udf /bin/true
install vfat /bin/true
FSEOF

# 10. Harden SSH (if installed)
echo "[yulo-hardening] Hardening SSH..."
if [ -f /etc/ssh/sshd_config ]; then
    sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config 2>/dev/null || true
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config 2>/dev/null || true
    sed -i 's/^#*X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config 2>/dev/null || true
    sed -i 's/^#*MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config 2>/dev/null || true
fi

# 11. Remove unnecessary SUID binaries
echo "[yulo-hardening] Removing unnecessary SUID binaries..."
chmod u-s /usr/bin/ntfs-3g 2>/dev/null || true
chmod u-s /usr/bin/su 2>/dev/null || true  # Keep sudo, remove su
chmod u-s /usr/bin/mount 2>/dev/null || true
chmod u-s /usr/bin/umount 2>/dev/null || true
chmod u-s /usr/bin/pkexec 2>/dev/null || true

# 12. Harden password policies
echo "[yulo-hardening] Hardening password policies..."
if [ -f /etc/login.defs ]; then
    sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' /etc/login.defs 2>/dev/null || true
    sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 1/' /etc/login.defs 2>/dev/null || true
    sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 7/' /etc/login.defs 2>/dev/null || true
fi

# 13. Disable USB storage (optional - comment out if needed)
# echo "install usb-storage /bin/true" > /etc/modprobe.d/99-yulo-disable-usb.conf

# 14. Set file permissions on sensitive files
echo "[yulo-hardening] Setting file permissions..."
chmod 700 /root 2>/dev/null || true
chmod 600 /etc/shadow 2>/dev/null || true
chmod 600 /etc/gshadow 2>/dev/null || true
chmod 644 /etc/passwd 2>/dev/null || true
chmod 644 /etc/group 2>/dev/null || true

echo "[yulo-hardening] Security hardening complete."
exit 0
