#!/bin/bash
# Safe reminder scheduler using 'at' command
# Usage: ./schedule-reminder.sh <minutes> "<note>" [reminder_type]

set -euo pipefail

# Script directory setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADAPTED_DIR="$SCRIPT_DIR"
LOGS_DIR="${ADAPTED_DIR}/logs"

# Simple logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$level] $timestamp - $message"
    mkdir -p "$LOGS_DIR"
    echo "[$level] $timestamp - $message" >> "$LOGS_DIR/schedule-reminder.log"
}

# Constants
REMINDERS_DIR="${ADAPTED_DIR}/reminders"
REMINDERS_LOG="${LOGS_DIR}/reminders.log"
MAX_MINUTES=10080  # 7 days
MIN_MINUTES=1

# Function to display usage
usage() {
    cat << EOF
Usage: $0 <minutes> "<note>" [reminder_type]

Arguments:
    minutes        - Time in minutes until reminder (1-10080)
    note          - Reminder message (max 500 chars)
    reminder_type - Type of reminder: file|log|display (default: file)

Examples:
    $0 30 "Check deployment status" file
    $0 60 "Review pull requests" log
    $0 15 "Take a break" display

EOF
    exit 1
}

# Validate minutes input
validate_minutes() {
    local minutes="$1"
    
    # Check if it's a number
    if ! [[ "$minutes" =~ ^[0-9]+$ ]]; then
        log "ERROR" "Minutes must be a positive integer"
        exit 1
    fi
    
    # Check range
    if (( minutes < MIN_MINUTES || minutes > MAX_MINUTES )); then
        log "ERROR" "Minutes must be between $MIN_MINUTES and $MAX_MINUTES"
        exit 1
    fi
}

# Validate note input
validate_note() {
    local note="$1"
    local note_length=${#note}
    
    if [[ -z "$note" ]]; then
        log "ERROR" "Note cannot be empty"
        exit 1
    fi
    
    if (( note_length > 500 )); then
        log "ERROR" "Note too long (${note_length} chars). Maximum is 500 characters"
        exit 1
    fi
    
    # Check for potentially dangerous characters
    if [[ "$note" =~ [\`\$\(\)\{\}\[\]\<\>\|] ]]; then
        log "ERROR" "Note contains invalid characters. Only alphanumeric and basic punctuation allowed"
        exit 1
    fi
}

# Create reminder script
create_reminder_script() {
    local note="$1"
    local reminder_type="$2"
    local reminder_id="$3"
    local script_path="${REMINDERS_DIR}/${reminder_id}.sh"
    
    cat > "$script_path" << 'EOF'
#!/bin/bash
# Auto-generated reminder script
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADAPTED_DIR="$(dirname "$SCRIPT_DIR")"
LOGS_DIR="${ADAPTED_DIR}/logs"
REMINDERS_DIR="${ADAPTED_DIR}/reminders"
REMINDERS_LOG="${LOGS_DIR}/reminders.log"

# Simple logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$level] $timestamp - $message"
    mkdir -p "$LOGS_DIR"
    echo "[$level] $timestamp - $message" >> "$LOGS_DIR/schedule-reminder.log"
}

EOF
    
    # Add reminder-specific code based on type
    case "$reminder_type" in
        file)
            cat >> "$script_path" << EOF
# Write reminder to file
REMINDER_FILE="${REMINDERS_DIR}/${reminder_id}.txt"
{
    echo "=== REMINDER ==="
    echo "Time: \$(date '+%Y-%m-%d %H:%M:%S')"
    echo "Note: ${note}"
    echo "================"
} > "\$REMINDER_FILE"

log "INFO" "Reminder saved to: \$REMINDER_FILE"
echo "Reminder: ${note}" | tee -a "${REMINDERS_LOG}"
EOF
            ;;
            
        log)
            cat >> "$script_path" << EOF
# Log reminder
log "REMINDER" "${note}"
echo "[\$(date '+%Y-%m-%d %H:%M:%S')] REMINDER: ${note}" >> "${REMINDERS_LOG}"
EOF
            ;;
            
        display)
            cat >> "$script_path" << EOF
# Display reminder (terminal notification if available)
log "REMINDER" "${note}"
echo "[\$(date '+%Y-%m-%d %H:%M:%S')] REMINDER: ${note}" >> "${REMINDERS_LOG}"

# Try to use terminal-notifier on macOS if available
if command -v terminal-notifier >/dev/null 2>&1; then
    terminal-notifier -title "Tmux Orchestrator Reminder" -message "${note}" 2>/dev/null || true
elif command -v osascript >/dev/null 2>&1; then
    # Fallback to osascript on macOS
    osascript -e "display notification \"${note}\" with title \"Tmux Orchestrator Reminder\"" 2>/dev/null || true
else
    # Just echo to terminal
    echo "================== REMINDER =================="
    echo "Time: \$(date '+%Y-%m-%d %H:%M:%S')"
    echo "Note: ${note}"
    echo "============================================="
fi
EOF
            ;;
    esac
    
    # Add cleanup
    cat >> "$script_path" << EOF

# Clean up this script after execution
rm -f "$script_path"
EOF
    
    chmod +x "$script_path"
}

# Schedule reminder using 'at' command
schedule_reminder() {
    local minutes="$1"
    local script_path="$2"
    local reminder_id="$3"
    
    # Calculate run time
    local run_time=$(date -v +${minutes}M '+%H:%M %m/%d/%y' 2>/dev/null || \
                     date -d "+${minutes} minutes" '+%H:%M %m/%d/%y' 2>/dev/null)
    
    # Schedule with at command
    local at_output
    if at_output=$(echo "$script_path" | at "now + ${minutes} minutes" 2>&1); then
        # Extract job ID from at output
        local job_id=$(echo "$at_output" | grep -o 'job [0-9]*' | awk '{print $2}' || echo "unknown")
        
        log "INFO" "Reminder scheduled successfully"
        echo "Reminder ID: $reminder_id"
        echo "AT Job ID: $job_id"
        echo "Scheduled for: $run_time (${minutes} minutes from now)"
        echo "Note: $2"
        
        # Save reminder info
        {
            echo "reminder_id=$reminder_id"
            echo "at_job_id=$job_id"
            echo "scheduled_time=$run_time"
            echo "minutes=$minutes"
            echo "note=$2"
            echo "type=$3"
            echo "created=$(date '+%Y-%m-%d %H:%M:%S')"
        } > "${REMINDERS_DIR}/${reminder_id}.info"
        
        return 0
    else
        log "ERROR" "Failed to schedule reminder: $at_output"
        rm -f "$script_path"
        return 1
    fi
}

# Main execution
main() {
    # Check arguments
    if [[ $# -lt 2 ]]; then
        usage
    fi
    
    local minutes="$1"
    local note="$2"
    local reminder_type="${3:-file}"
    
    # Validate inputs
    validate_minutes "$minutes"
    validate_note "$note"
    
    # Validate reminder type
    if [[ ! "$reminder_type" =~ ^(file|log|display)$ ]]; then
        log "ERROR" "Invalid reminder type: $reminder_type"
        echo "Valid types: file, log, display"
        exit 1
    fi
    
    # Create reminders directory if it doesn't exist
    mkdir -p "$REMINDERS_DIR"
    
    # Generate unique reminder ID
    local reminder_id="reminder_$(date +%s)_$$"
    
    # Create reminder script
    create_reminder_script "$note" "$reminder_type" "$reminder_id"
    
    # Schedule the reminder
    if schedule_reminder "$minutes" "${REMINDERS_DIR}/${reminder_id}.sh" "$reminder_id"; then
        log "INFO" "Reminder scheduled: ID=$reminder_id, Type=$reminder_type, Minutes=$minutes"
    else
        exit 1
    fi
}

# Run main function
main "$@"