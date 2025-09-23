#!/bin/bash
#
# vim:ft=sh

############### Variables ###############

############### Functions ###############

############### Main Part ###############

set -x
dir=/opt/TopSAP

# $dir/TopVPNhelper

$dir/topvpn login <<EOF
$TOPVPN_HOST
1
$TOPVPN_USER
$TOPVPN_PASS
EOF

# $dir/topvpn login <(echo && echo "$TOPVPN_HOST" && echo 1 && echo "$TOPVPN_USER")

# printf "$TOPVPN_HOST\n1\n$TOPVPN_USER\n$TOPVPN_PASS\n" | $dir/topvpn login
