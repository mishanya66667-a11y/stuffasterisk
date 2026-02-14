#!/bin/bash

#############################################
# Clean Installer for Asterisk 22
# Ubuntu 22.04 / 24.04
#############################################

set -e

echo "=========================================="
echo "     Installing Asterisk 22"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Root check
if [ "$EUID" -ne 0 ]; then
    error "Run with sudo!"
    exit 1
fi

log "Updating system..."
apt-get update
apt-get upgrade -y

log "Installing dependencies..."
apt-get install -y \
    wget build-essential git curl \
    libssl-dev libncurses5-dev libxml2-dev \
    libsqlite3-dev uuid-dev libjansson-dev \
    libedit-dev

# Create asterisk user BEFORE install
log "Creating asterisk system user..."
id -u asterisk &>/dev/null || \
useradd -r -d /var/lib/asterisk -s /usr/sbin/nologin asterisk

log "Downloading Asterisk 22..."
cd /usr/src
wget -q https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-22-current.tar.gz

log "Extracting..."
tar -xzf asterisk-22-current.tar.gz
cd asterisk-22*/

log "Installing prerequisites..."
./contrib/scripts/install_prereq install

log "Configuring (bundled pjproject)..."
./configure --with-pjproject-bundled

log "Selecting modules..."
make menuselect.makeopts
menuselect/menuselect \
    --enable CORE-SOUNDS-EN-GSM \
    --enable MOH-OPSOUND-GSM \
    --enable EXTRA-SOUNDS-EN-GSM \
    menuselect.makeopts

log "Compiling..."
make -j$(nproc)

log "Installing..."
make install
make samples
make install-logrotate

# Set permissions
log "Setting permissions..."
chown -R asterisk:asterisk /etc/asterisk
chown -R asterisk:asterisk /var/{lib,log,spool}/asterisk
chown -R asterisk:asterisk /usr/lib/asterisk

# Create native systemd service
log "Creating systemd service..."

cat > /etc/systemd/system/asterisk.service <<EOF
[Unit]
Description=Asterisk PBX
After=network.target

[Service]
Type=simple
User=asterisk
Group=asterisk
ExecStart=/usr/sbin/asterisk -f -U asterisk -G asterisk
ExecReload=/usr/sbin/asterisk -rx "core reload"
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

log "Reloading systemd..."
systemctl daemon-reload

log "Enabling service..."
systemctl enable asterisk

log "Starting Asterisk..."
systemctl start asterisk

sleep 3

log "Service status:"
systemctl status asterisk --no-pager

echo ""
echo "=========================================="
echo -e "${GREEN}✅ Asterisk 22 Installed Successfully!${NC}"
echo "=========================================="
echo ""
echo "Useful commands:"
echo "  Console:   sudo asterisk -rvvv"
echo "  Status:    sudo systemctl status asterisk"
echo "  Restart:   sudo systemctl restart asterisk"
echo "  Logs:      sudo tail -f /var/log/asterisk/messages"
echo ""
