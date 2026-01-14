#!/bin/bash
set -e

########################################
# PxTool - Virtual Android 14 Launcher
########################################

clear
cat <<'EOF'
██████╗ ██╗  ██╗████████╗ ██████╗  ██████╗ ██╗     
██╔══██╗╚██╗██╔╝╚══██╔══╝██╔═══██╗██╔═══██╗██║     
██████╔╝ ╚███╔╝    ██║   ██║   ██║██║   ██║██║     
██╔═══╝  ██╔██╗    ██║   ██║   ██║██║   ██║██║     
██║     ██╔╝ ██╗   ██║   ╚██████╔╝╚██████╔╝███████╗
╚═╝     ╚═╝  ╚═╝   ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝
            PxTool - Android 14 Virtual System
EOF

########################################
# CONFIG
########################################
BASE="/opt/android14"
ISO="$BASE/bliss14.iso"
DISK="$BASE/android14.qcow2"

# ✅ Stable Android 14
ISO_URL="https://downloads.sourceforge.net/project/blissos-x86/Official/BlissOS-v14.3/BlissOS-v14.3-x86_64.iso"

# Ports
VNC_DISPLAY=1
VNC_PORT=5901
NOVNC_PORT=8080

# Resources
RAM_MB=4096
CPU_CORES=4
DISK_SIZE=40G

# Vertical resolution
RESOLUTION="1080x1920"
########################################

# ROOT CHECK
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root"
  exit 1
fi

# KVM CHECK
if [ ! -e /dev/kvm ]; then
  echo "❌ KVM not available on this VPS"
  exit 1
fi

echo "✅ KVM detected"

# DNS FIX
cat >/etc/resolv.conf <<EOF
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF

# INSTALL PACKAGES
echo "📦 Installing dependencies..."
apt update -y
apt install -y \
qemu-system-x86 qemu-utils \
wget curl \
websockify novnc \
net-tools ufw

# AUTO OPEN PORTS
echo "🔓 Opening ports automatically..."
ufw allow $NOVNC_PORT/tcp || true
ufw allow $VNC_PORT/tcp || true
ufw --force enable || true

iptables -I INPUT -p tcp --dport $NOVNC_PORT -j ACCEPT || true
iptables -I INPUT -p tcp --dport $VNC_PORT -j ACCEPT || true

# CREATE DIR
mkdir -p "$BASE"
cd "$BASE"

# DOWNLOAD ISO
if [ ! -f "$ISO" ]; then
  echo "⬇️ Downloading Bliss OS 14 (Android 14)"
  wget --content-disposition -O "$ISO" "$ISO_URL"
fi

# CREATE DISK
if [ ! -f "$DISK" ]; then
  echo "💽 Creating virtual disk"
  qemu-img create -f qcow2 "$DISK" "$DISK_SIZE"
fi

# REMOVE OLD SERVICE
systemctl stop pxtool-android 2>/dev/null || true
systemctl disable pxtool-android 2>/dev/null || true
rm -f /etc/systemd/system/pxtool-android.service

# CREATE SYSTEMD SERVICE
cat >/etc/systemd/system/pxtool-android.service <<EOF
[Unit]
Description=PxTool Android 14 (VNC + noVNC)
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash -c '\
/usr/bin/qemu-system-x86_64 \
-enable-kvm \
-cpu host \
-smp $CPU_CORES \
-m $RAM_MB \
-machine q35,accel=kvm \
-drive file=$DISK,if=virtio,cache=writeback,format=qcow2 \
-cdrom $ISO \
-boot d \
-vga std \
-append "nomodeset xforcevesa video=${RESOLUTION}" \
-netdev user,id=net0 \
-device virtio-net-pci,netdev=net0 \
-vnc 0.0.0.0:$VNC_DISPLAY \
-display none \
-no-reboot & \
sleep 10 && \
/usr/bin/websockify \
--web=/usr/share/novnc \
0.0.0.0:$NOVNC_PORT \
localhost:$VNC_PORT \
'
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# ENABLE & START
systemctl daemon-reload
systemctl enable pxtool-android
systemctl restart pxtool-android

echo ""
echo "=============================================="
echo " PxTool ANDROID 14 IS READY"
echo ""
echo " 🌐 noVNC : http://YOUR_IP:$NOVNC_PORT"
echo " 🖥  VNC   : YOUR_IP:$VNC_PORT"
echo " 📱 Mode  : Vertical (1080x1920)"
echo " 🔑 Root  : Enable in Android Settings"
echo "=============================================="
