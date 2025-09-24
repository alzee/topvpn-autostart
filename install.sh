#!/bin/bash
#
# vim:ft=sh

if ! which expect 2> /dev/null; then
    echo "Error: 'expect' is required for non-interactive login. Install the 'expect' package." >&2
    exit 1
fi

cp topvpn.conf ~/.topvpn.conf # need edit
touch ~/.topvpn_pass # need edit

mkdir -p ~/.config/systemd/user/

cp topvpn ~/.local/bin/

cp topvpn.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now topvpn.service

sudo cp topvpnhelper.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now topvpnhelper.service
