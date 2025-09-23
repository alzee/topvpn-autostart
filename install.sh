#!/bin/bash
#
# vim:ft=sh

# cp topvpn.conf ~/.topvpn.conf # need edit
# touch ~/.topvpn_pass # need edit

mkdir -p ~/.config/systemd/user/

cp topvpn.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now topvpn.service

sudo cp topvpnhelper.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now topvpnhelper.service
