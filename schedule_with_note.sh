#!/usr/bin/env bash
set -euo pipefail

# Dynamic scheduler with note for next check
# Usage: ./schedule_with_note.sh <minutes> "<note>" [target_window]

# Secure IFS handling
IFS=$'\n\t'

# Input validation
MINUTES=${1:-3}
NOTE=${2:-"Standard check-in"}
TARGET=${3:-"tmux-orc:0"}

# Validate numeric input using explicit character checks
bad_chars=${MINUTES//[0-9]}
if [[ -n $bad_chars ]] || [[ $MINUTES -eq 0 ]] || [[ $MINUTES -gt 9999 ]]; then
    echo "Error: Invalid minutes value (must be 1-9999)" >&2
    exit 64  # EX_USAGE
fi

# Validate target format using character whitelisting
bad_chars=${TARGET//[A-Za-z0-9_:.-]}
if [[ -n $bad_chars ]]; then
    echo "Error: Invalid characters in target" >&2
    exit 65  # EX_DATAERR
fi

# Validate and sanitize note
validate_and_sanitize_note() {
    local note="$1"
    # Remove potential command injection sequences
    note="${note//;/\\;}"
    note="${note//\$/\\$}"
    # Use a safer approach for backtick replacement
    note="${note//\`/}"
    echo "$note"
}

NOTE=$(validate_and_sanitize_note "$NOTE")

# Create secure temp directory with proper cleanup
create_secure_note_file() {
    local tmpdir
    tmpdir=$(mktemp -d -t "orchestrator.XXXXXX") || {
        echo "Failed to create temp directory" >&2
        exit 73  # EX_CANTCREAT
    }
    
    # Set secure permissions
    chmod 700 "$tmpdir"
    
    echo "$tmpdir/note.txt"
}

NOTE_FILE=$(create_secure_note_file)

# Create a note file for the next check
{
    echo "=== Next Check Note ($(date)) ==="
    echo "Scheduled for: $MINUTES minutes"
    echo ""
    echo "$NOTE"
} > "$NOTE_FILE"

echo "Scheduling check in $MINUTES minutes with note: $NOTE"

# Calculate the exact time when the check will run
CURRENT_TIME=$(date +"%H:%M:%S")

# Detect and use appropriate date command for cross-platform compatibility
if date --version 2>&1 | grep -q GNU; then
    RUN_TIME=$(date -u -d "+${MINUTES} minutes" '+%H:%M:%S')
else
    RUN_TIME=$(date -u -v "+${MINUTES}M" '+%H:%M:%S')
fi

# Validate target session exists
if ! tmux has-session -t "${TARGET%%:*}" 2>/dev/null; then
    echo "Error: tmux session '${TARGET%%:*}' not found" >&2
    exit 65
fi

# Use bash arithmetic instead of bc for better performance
SECONDS_TO_WAIT=$((MINUTES * 60))

# Create scheduled task with proper error handling
execute_scheduled_check() {
    local target="$1"
    local note_file="$2"
    
    # Set cleanup trap inside the scheduled task
    trap 'rm -rf "$(dirname "$note_file")"' EXIT INT TERM
    
    # Send notification with proper escaping
    tmux send-keys -l -t "$target" "Time for orchestrator check! cat \"$note_file\"" || {
        logger -t "schedule_with_note" "Failed to send notification to $target"
        exit 70
    }
    
    sleep 1
    
    tmux send-keys -t "$target" Enter || {
        logger -t "schedule_with_note" "Failed to send Enter to $target"
        exit 70
    }
}

# Use systemd-run if available, otherwise use disown
if command -v systemd-run >/dev/null 2>&1; then
    # Direct execution without extra sleep - systemd handles the timing
    systemd-run --user --unit="orc-check-$(date +%s)" \
        --on-active="${MINUTES}m" \
        /bin/bash -c "$(declare -f execute_scheduled_check); execute_scheduled_check '$TARGET' '$NOTE_FILE'"
    SCHEDULE_PID=$!
else
    # Fallback to background process with sleep
    (
        sleep "$SECONDS_TO_WAIT"
        execute_scheduled_check "$TARGET" "$NOTE_FILE"
    ) & disown
    SCHEDULE_PID=$!
fi

# Log successful scheduling
logger -t "schedule_with_note" "Scheduled check for $TARGET in $MINUTES minutes (PID: $SCHEDULE_PID)"

echo "Scheduled successfully - process detached (PID: $SCHEDULE_PID)"
echo "SCHEDULED TO RUN AT: $RUN_TIME (in $MINUTES minutes from $CURRENT_TIME)"
echo "Note file: $NOTE_FILE"