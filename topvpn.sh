#!/bin/bash
#
# vim:ft=sh

############### Variables ###############

############### Functions ###############

############### Main Part ###############

dir=/opt/TopSAP

$dir/TopVPNhelper

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
    TOPVPN_PASS=$(< "$HOME/.topvpn_pass")
fi

if [ -z "$TOPVPN_PASS" ]; then
    echo "Error: TOPVPN_PASS is empty. Export it or put the password in ~/.topvpn_pass" >&2
    exit 1
fi

# Export variables so expect can read via env(...)
export TOPVPN_HOST TOPVPN_USER TOPVPN_PASS TOPVPN_DEBUG TOPVPN_OTP

expect <<'EOF'
# Enable debug if requested and log transcript
if {[info exists env(TOPVPN_DEBUG)] && $env(TOPVPN_DEBUG) ne ""} {
    exp_internal 1
    log_user 1
}
log_file -a ~/.topvpn.expect.log

set timeout 90

spawn /opt/TopSAP/topvpn login

expect -re {Input your server address.*:}
send -- "$env(TOPVPN_HOST)\r"

expect -re {Choose the Login_mode:}
send -- "1\r"

expect -re {Please enter user and password:}

expect -re {User:}
send -- "$env(TOPVPN_USER)\r"

expect -re {Password:}
#after 200
send -- "$env(TOPVPN_PASS)\r"

# Handle possible follow-up prompts (certificate trust, OTP, etc.)
expect {
    -re {(Verification|Verify|Dynamic|OTP|Two.*Factor|Double.*Factor).*:} {
        if {[info exists env(TOPVPN_OTP)] && $env(TOPVPN_OTP) ne ""} {
            after 200
            send -- "$env(TOPVPN_OTP)\r"
            exp_continue
        } else {
            puts "Extra verification required (OTP). Set TOPVPN_OTP to automate. Handing control to user."
            interact
        }
    }
    -re {(accept|trust|certificate).*(yes|no|y/n)} {
        after 200
        send -- "y\r"
        exp_continue
    }
    -re {(Login success|Connected|Welcome).*$} {
        # Successful indicators
    }
    -re {(Login failed|Invalid|Error).*$} {
        # Failure indicators; fall through to user
        puts "Login reported failure. Handing control to user."
        interact
    }
    timeout {
        puts "Timed out waiting after password. Handing control to user."
        interact
    }
    eof {
        # Process exited; nothing more to do
    }
}
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
