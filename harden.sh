#!/bin/bash

# Script run as root
if [ "$EUID" -ne 0 ]; then
  echo "[-] Please run as root (use sudo)"
  exit 1
fi

echo "[*] Starting Server Hardening Process..."
NEW_SSH_PORT=2222

# System Updates
echo "[*] Updating system packages..."
apt-get update -y > /dev/null
apt-get upgrade -y > /dev/null

# Firewall Configuration
echo "[*] Configuring UFW Firewall..."
apt-get install ufw -y > /dev/null
ufw default deny incoming
ufw default allow outgoing
# Allow new SSH port
ufw allow $NEW_SSH_PORT/tcp
# Enable firewall
ufw --force enable

# Secure SSH
echo "[*] Hardening SSH Configuration..."
SSHD_CONFIG="/etc/ssh/sshd_config"

# Backup original config
cp $SSHD_CONFIG "${SSHD_CONFIG}.bak"

# Disable Root Login
sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' $SSHD_CONFIG
sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' $SSHD_CONFIG

# Change default port
sed -i "s/^#Port 22.*/Port $NEW_SSH_PORT/" $SSHD_CONFIG
sed -i "s/^Port 22.*/Port $NEW_SSH_PORT/" $SSHD_CONFIG

# Disable empty passwords
sed -i 's/^#PermitEmptyPasswords.*/PermitEmptyPasswords no/' $SSHD_CONFIG
sed -i 's/^PermitEmptyPasswords.*/PermitEmptyPasswords no/' $SSHD_CONFIG

# Network Hardening 
echo "[*] Disabling IPv6 and hardening network..."
SYSCTL_CONF="/etc/sysctl.conf"
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> $SYSCTL_CONF
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> $SYSCTL_CONF
echo "net.ipv4.tcp_syncookies = 1" >> $SYSCTL_CONF # Protect against SYN floods
sysctl -p > /dev/null

# Restart Services
echo "[*] Restarting SSH service..."
systemctl restart sshd

echo "[+] Hardening complete. IMPORTANT: SSH is now running on port $NEW_SSH_PORT."
