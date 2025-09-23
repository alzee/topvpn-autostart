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

# Ensure variables exist; allow reading password from a file if not set
TOPVPN_HOST=${TOPVPN_HOST:-}
TOPVPN_USER=${TOPVPN_USER:-}
TOPVPN_PASS=${TOPVPN_PASS:-}

if [ -z "$TOPVPN_HOST" ] || [ -z "$TOPVPN_USER" ]; then
    echo "Error: TOPVPN_HOST and TOPVPN_USER must be set in the environment." >&2
    exit 1
fi

if [ -z "$TOPVPN_PASS" ] && [ -f "$HOME/.topvpn_pass" ]; then
    TOPVPN_PASS=$(cat "$HOME/.topvpn_pass")
fi

if [ -z "$TOPVPN_PASS" ]; then
    echo "Error: TOPVPN_PASS is empty. Export it or put the password in ~/.topvpn_pass" >&2
    exit 1
fi

# Export variables so expect can read via env(...)
export TOPVPN_HOST TOPVPN_USER TOPVPN_PASS TOPVPN_DEBUG

expect <<'EOF'
# Enable debug if requested
if {[info exists env(TOPVPN_DEBUG)] && $env(TOPVPN_DEBUG) ne ""} {
    exp_internal 1
    log_user 1
}

set timeout 60

spawn /opt/TopSAP/topvpn login

expect -re {Input your server address.*:}
after 200
send -- "$env(TOPVPN_HOST)\r"

expect -re {Choose the Login_mode:}
after 200
send -- "1\r"

expect -re {Please enter user and password:}

expect -re {User:}
after 200
send -- "$env(TOPVPN_USER)\r"

expect -re {Password:}
after 200
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
