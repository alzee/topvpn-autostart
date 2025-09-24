#!/bin/bash
#
# vim:ft=sh

if ! which expect &> /dev/null; then
    echo "Error: 'expect' is required for non-interactive login. Install the 'expect' package." >&2
    exit 1
fi

# Prompt for credentials
echo "Please enter your TopVPN credentials:"
read -p "Host (host:port): " host
read -p "Username: " user
read -s -p "Password: " pass
echo

# Store credentials securely
echo "TOPVPN_HOST=$host" > ~/.topvpn.conf
echo "TOPVPN_USER=$user" >> ~/.topvpn.conf
echo "$pass" > ~/.topvpn_pass

mkdir -p ~/.config/systemd/user/

cp topvpn ~/.local/bin/

cp topvpn.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now topvpn.service

sudo cp topvpnhelper.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now topvpnhelper.service
