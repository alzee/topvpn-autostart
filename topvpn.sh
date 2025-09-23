#!/bin/bash
#
# vim:ft=sh

############### Variables ###############

############### Functions ###############

# Function to log messages with timestamp
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /tmp/topvpn_service.log
}

# Function to cleanup on exit
cleanup() {
    if [ -n "$HELPER_PID" ] && kill -0 $HELPER_PID 2>/dev/null; then
        log_message "Stopping TopVPN helper (PID: $HELPER_PID)"
        kill $HELPER_PID 2>/dev/null
    fi
}

# Set up cleanup trap
trap cleanup EXIT

############### Main Part ###############

log_message "Starting TopVPN auto-login service"

dir=/opt/TopSAP

# Start Client Server
log_message "Starting TopVPN helper service..."
if [ ! -f "$dir/TopVPNhelper" ]; then
    log_message "Error: TopVPNhelper not found at $dir/TopVPNhelper"
    exit 1
fi

# Start TopVPNhelper in background
log_message "Launching TopVPNhelper from $dir/TopVPNhelper"
nohup "$dir/TopVPNhelper" > /tmp/topvpn_helper.log 2>&1 &
HELPER_PID=$!

# Wait for the helper to start up (check if it's running and responsive)
log_message "Waiting for TopVPN helper to initialize..."
for i in {1..30}; do
    if kill -0 $HELPER_PID 2>/dev/null; then
        # Check if the helper is responsive by looking for expected output or process state
        sleep 2
        if [ $i -eq 30 ]; then
            log_message "Warning: TopVPN helper started but may not be fully ready"
        fi
    else
        log_message "Error: TopVPN helper failed to start"
        log_message "Helper log contents:"
        cat /tmp/topvpn_helper.log | while read line; do
            log_message "  $line"
        done
        exit 1
    fi
done

log_message "TopVPN helper service started successfully (PID: $HELPER_PID)"

# Source config file if it exists
if [ -f "$HOME/.topvpn.conf" ]; then
    source "$HOME/.topvpn.conf"
fi

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
    log_message "Error: TOPVPN_HOST and TOPVPN_USER must be set in the environment."
    exit 1
fi

if [ -z "$TOPVPN_PASS" ] && [ -f "$HOME/.topvpn_pass" ]; then
    TOPVPN_PASS=$(< "$HOME/.topvpn_pass")
fi

if [ -z "$TOPVPN_PASS" ]; then
    log_message "Error: TOPVPN_PASS is empty. Export it or put the password in ~/.topvpn_pass"
    exit 1
fi

log_message "Starting TopVPN login process for user: $TOPVPN_USER at host: $TOPVPN_HOST"

# Export variables so expect can read via env(...)
export TOPVPN_HOST TOPVPN_USER TOPVPN_PASS TOPVPN_DEBUG TOPVPN_OTP

expect <<'EOF'
# Enable debug if requested and log transcript
if {[info exists env(TOPVPN_DEBUG)] && $env(TOPVPN_DEBUG) ne ""} {
    exp_internal 1
    log_user 1
}

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
        puts "Login successful!"
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
        puts "TopVPN process ended."
    }
}
EOF

# Check if the expect script completed successfully
if [ $? -eq 0 ]; then
    log_message "TopVPN login process completed successfully"
else
    log_message "TopVPN login process failed or was interrupted"
    exit 1
fi

log_message "TopVPN auto-login service finished"

# Previous attempts (stdin) won't work because password is read from /dev/tty:
# $dir/topvpn login <<EOF
# $TOPVPN_HOST
# 1
# $TOPVPN_USER
# $TOPVPN_PASS
# EOF

# $dir/topvpn login <(echo && echo "$TOPVPN_HOST" && echo 1 && echo "$TOPVPN_USER")

# printf "$TOPVPN_HOST\n1\n$TOPVPN_USER\n$TOPVPN_PASS\n" | $dir/topvpn login
