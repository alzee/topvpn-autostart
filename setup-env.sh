#!/bin/bash
# Simple setup for system-wide TopVPN with environment file

echo "Setting up system-wide TopVPN service with environment file..."

# Create directory and files
sudo mkdir -p /etc/topvpn
sudo mkdir -p /usr/local/bin

# Copy files
sudo cp topvpn-system /usr/local/bin/
sudo cp topvpn-system-env.service /etc/systemd/system/topvpn-system.service

# Make script executable
sudo chmod +x /usr/local/bin/topvpn-system

# Create environment file
echo "Creating environment file at /etc/topvpn/topvpn.env"
echo "Please edit this file with your credentials:"
echo "TOPVPN_HOST=your_host:port"
echo "TOPVPN_USER=your_username" 
echo "TOPVPN_PASS=your_password"
echo "TOPVPN_OTP=your_otp_secret (optional)"

sudo tee /etc/topvpn/topvpn.env > /dev/null << 'EOF'
TOPVPN_HOST=your_host:port
TOPVPN_USER=your_username
TOPVPN_PASS=your_password
TOPVPN_OTP=your_otp_secret
EOF

# Set secure permissions
sudo chmod 600 /etc/topvpn/topvpn.env

# Reload systemd
sudo systemctl daemon-reload
sudo systemctl enable topvpn-system.service

echo "Setup complete!"
echo "1. Edit /etc/topvpn/topvpn.env with your credentials"
echo "2. Start service: sudo systemctl start topvpn-system"
echo "3. Check status: sudo systemctl status topvpn-system"
