# System-wide TopVPN Service Setup

This document explains how to convert the user-based TopVPN service to a system-wide service with secure password storage.

## Current Setup (User-based)
- Service runs as user
- Reads config from `~/.topvpn.conf`
- Reads password from `~/.topvpn_pass`

## System-wide Options

### Option 1: Systemd Credentials (Most Secure)
**Files:** `topvpn-system.service`, `topvpn-system`, `setup-system-wide.sh`

**Advantages:**
- Most secure - credentials stored in systemd credential store
- Credentials are encrypted and only accessible to the service
- No plaintext files on disk

**Setup:**
```bash
sudo ./setup-system-wide.sh
```

**Manual Setup:**
```bash
# Create credential files
sudo mkdir -p /etc/topvpn
echo "your_host:port" | sudo tee /etc/topvpn/host
echo "your_username" | sudo tee /etc/topvpn/user
echo "your_password" | sudo tee /etc/topvpn/pass
sudo chmod 600 /etc/topvpn/*

# Install service
sudo cp topvpn-system /usr/local/bin/
sudo cp topvpn-system.service /etc/systemd/system/
sudo chmod +x /usr/local/bin/topvpn-system
sudo systemctl daemon-reload
sudo systemctl enable topvpn-system
```

### Option 2: Environment File (Simpler)
**Files:** `topvpn-system-env.service`, `setup-env.sh`

**Advantages:**
- Simpler setup
- Easy to edit credentials
- Standard systemd approach

**Setup:**
```bash
sudo ./setup-env.sh
```

**Manual Setup:**
```bash
# Create environment file
sudo mkdir -p /etc/topvpn
sudo tee /etc/topvpn/topvpn.env > /dev/null << 'EOF'
TOPVPN_HOST=your_host:port
TOPVPN_USER=your_username
TOPVPN_PASS=your_password
TOPVPN_OTP=your_otp_secret
EOF
sudo chmod 600 /etc/topvpn/topvpn.env

# Install service
sudo cp topvpn-system /usr/local/bin/
sudo cp topvpn-system-env.service /etc/systemd/system/topvpn-system.service
sudo chmod +x /usr/local/bin/topvpn-system
sudo systemctl daemon-reload
sudo systemctl enable topvpn-system
```

## Key Changes for System-wide Service

1. **Service runs as root** instead of user
2. **No user home directory** - credentials stored in `/etc/topvpn/`
3. **Logs go to `/var/log/topvpn_service.log`** instead of `/tmp/`
4. **Service targets `multi-user.target`** instead of `default.target`

## Security Considerations

### Option 1 (Credentials) - Recommended
- Credentials stored in systemd credential store (encrypted)
- Most secure approach
- Requires systemd 239+ for full credential support

### Option 2 (Environment File)
- Credentials stored in plaintext file
- File permissions set to 600 (owner read/write only)
- Simpler but less secure than credentials

## Service Management

```bash
# Start service
sudo systemctl start topvpn-system

# Stop service  
sudo systemctl stop topvpn-system

# Check status
sudo systemctl status topvpn-system

# View logs
sudo journalctl -u topvpn-system -f

# View script logs
sudo tail -f /var/log/topvpn_service.log
```

## Updating Credentials

### Option 1 (Credentials)
```bash
# Update individual credentials
echo "new_password" | sudo tee /etc/topvpn/pass
sudo chmod 600 /etc/topvpn/pass
sudo systemctl restart topvpn-system
```

### Option 2 (Environment File)
```bash
# Edit environment file
sudo nano /etc/topvpn/topvpn.env
sudo systemctl restart topvpn-system
```

## Troubleshooting

1. **Check service status:** `sudo systemctl status topvpn-system`
2. **Check logs:** `sudo journalctl -u topvpn-system -f`
3. **Check script logs:** `sudo tail -f /var/log/topvpn_service.log`
4. **Test script manually:** `sudo /usr/local/bin/topvpn-system`
5. **Verify credentials:** `sudo ls -la /etc/topvpn/`

## Migration from User Service

1. Stop user service: `systemctl --user stop topvpn`
2. Disable user service: `systemctl --user disable topvpn`
3. Choose and setup system-wide service (Option 1 or 2)
4. Test the new service
5. Remove old user service files if desired
