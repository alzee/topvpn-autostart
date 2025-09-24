#!/bin/bash
#
# Setup script for system-wide TopVPN service
# This script helps configure the system-wide TopVPN service with secure credential storage

set -e

echo "Setting up system-wide TopVPN service..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# Create credentials directory
mkdir -p /etc/topvpn
chmod 700 /etc/topvpn

# Create log directory
mkdir -p /var/log
touch /var/log/topvpn_service.log
chmod 644 /var/log/topvpn_service.log

# Install the system-wide script
cp topvpn-system /usr/local/bin/
chmod +x /usr/local/bin/topvpn-system

# Install the systemd service file
cp topvpn-system.service /etc/systemd/system/

# Prompt for credentials
echo "Please enter your TopVPN credentials:"
read -p "Host (host:port): " host
read -p "Username: " user
read -s -p "Password: " pass
echo

# Store credentials securely
echo "$host" > /etc/topvpn/host
echo "$user" > /etc/topvpn/user
echo "$pass" > /etc/topvpn/pass

# Set proper permissions
chmod 600 /etc/topvpn/host
chmod 600 /etc/topvpn/user
chmod 600 /etc/topvpn/pass

# Optional: OTP setup
read -p "Do you want to set up OTP (2FA) support? (y/n): " setup_otp
if [ "$setup_otp" = "y" ] || [ "$setup_otp" = "Y" ]; then
    read -s -p "Enter OTP secret or leave empty: " otp_secret
    echo
    if [ -n "$otp_secret" ]; then
        echo "$otp_secret" > /etc/topvpn/otp
        chmod 600 /etc/topvpn/otp
    fi
fi

cp topvpnhelper.service /etc/systemd/system/

# Reload systemd and enable service
systemctl daemon-reload
systemctl enable --now topvpnhelper.service
systemctl enable --now topvpn-system.service

echo "System-wide TopVPN service has been configured!"
echo "To start the service: sudo systemctl start topvpn-system"
echo "To check status: sudo systemctl status topvpn-system"
echo "To view logs: sudo journalctl -u topvpn-system -f"
