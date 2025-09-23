#!/bin/bash
#
# vim:ft=sh

############### Variables ###############

############### Functions ###############

############### Main Part ###############

set -x
dir=/opt/TopSAP

# $dir/TopVPNhelper

# The topvpn binary reads the password from /dev/tty (not stdin),
# so we need a PTY. Use expect to automate the interactive prompts.

if ! command -v expect >/dev/null 2>&1; then
    echo "Error: 'expect' is required for non-interactive login. Install the 'expect' package." >&2
    exit 1
fi

# Ensure variables are exported so expect can read via env(...)
export TOPVPN_HOST TOPVPN_USER TOPVPN_PASS

expect <<'EOF'
set timeout 60

spawn /opt/TopSAP/topvpn login

expect -re {Input your server address.*:}
send -- "$env(TOPVPN_HOST)\r"

expect -re {Choose the Login_mode:}
send -- "1\r"

expect -re {User:}
send -- "$env(TOPVPN_USER)\r"

expect -re {Password:}
send -- "$env(TOPVPN_PASS)\r"

# Hand over control to user/terminal in case further prompts appear
interact
EOF

# Previous attempts (stdin) won't work because password is read from /dev/tty:
# $dir/topvpn login <<EOF
# $TOPVPN_HOST
# 1
# $TOPVPN_USER
# $TOPVPN_PASS
# EOF

# $dir/topvpn login <(echo && echo "$TOPVPN_HOST" && echo 1 && echo "$TOPVPN_USER")

# printf "$TOPVPN_HOST\n1\n$TOPVPN_USER\n$TOPVPN_PASS\n" | $dir/topvpn login
