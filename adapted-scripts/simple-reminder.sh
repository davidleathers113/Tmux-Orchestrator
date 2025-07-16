#!/bin/bash
# Simple reminder system without 'at' command
# Usage: ./simple-reminder.sh <action> [arguments]

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
    echo "[$level] $timestamp - $message" >> "$LOGS_DIR/simple-reminder.log"
}

# Constants
REMINDERS_FILE="${ADAPTED_DIR}/reminders/simple-reminders.txt"
REMINDERS_DIR="${ADAPTED_DIR}/reminders"

# Function to display usage
usage() {
    cat << EOF
Simple Reminder System (no 'at' command required)

Usage: $0 <action> [arguments]

Actions:
    add <minutes> "<note>"    - Add a reminder
    list                      - List all pending reminders
    check                     - Check and display due reminders
    clear                     - Clear all expired reminders
    
Examples:
    $0 add 30 "Check deployment status"
    $0 list
    $0 check
    $0 clear

Note: This is a manual system. You need to run 'check' periodically
      to see due reminders. Consider adding to cron for automation.

EOF
    exit 1
}

# Add a reminder
add_reminder() {
    local minutes="$1"
    local note="$2"
    
    # Validate inputs
    if ! [[ "$minutes" =~ ^[0-9]+$ ]] || (( minutes < 1 || minutes > 10080 )); then
        log "ERROR" "Minutes must be between 1 and 10080"
        exit 1
    fi
    
    if [[ -z "$note" ]] || (( ${#note} > 500 )); then
        log "ERROR" "Note must be 1-500 characters"
        exit 1
    fi
    
    # Check for dangerous characters
    if [[ "$note" =~ [\`\$\(\)\{\}\[\]\<\>\|] ]]; then
        log "ERROR" "Note contains invalid characters"
        exit 1
    fi
    
    # Calculate due time
    local due_timestamp=$(($(date +%s) + (minutes * 60)))
    local due_time=$(date -r "$due_timestamp" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || \
                     date -d "@$due_timestamp" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)
    
    # Create reminders directory if needed
    mkdir -p "$REMINDERS_DIR"
    
    # Add reminder to file
    echo "${due_timestamp}|${due_time}|${note}" >> "$REMINDERS_FILE"
    
    log "INFO" "Reminder added"
    echo "Reminder will be due at: $due_time ($minutes minutes from now)"
    echo "Note: $note"
    echo ""
    echo "Remember to run '$0 check' to see due reminders"
}

# List all reminders
list_reminders() {
    if [[ ! -f "$REMINDERS_FILE" ]]; then
        echo "No reminders found."
        return
    fi
    
    local current_time=$(date +%s)
    local count=0
    
    echo "=== Pending Reminders ==="
    echo ""
    
    while IFS='|' read -r timestamp due_time note; do
        if [[ -n "$timestamp" ]]; then
            local remaining=$((timestamp - current_time))
            
            if (( remaining > 0 )); then
                local mins=$((remaining / 60))
                local hours=$((mins / 60))
                local days=$((hours / 24))
                
                ((count++))
                
                echo "[$count] Due: $due_time"
                if (( days > 0 )); then
                    echo "     Time remaining: $days days, $((hours % 24)) hours"
                elif (( hours > 0 )); then
                    echo "     Time remaining: $hours hours, $((mins % 60)) minutes"
                else
                    echo "     Time remaining: $mins minutes"
                fi
                echo "     Note: $note"
                echo ""
            fi
        fi
    done < "$REMINDERS_FILE"
    
    if (( count == 0 )); then
        echo "No pending reminders."
    else
        echo "Total: $count reminder(s)"
    fi
}

# Check for due reminders
check_reminders() {
    if [[ ! -f "$REMINDERS_FILE" ]]; then
        echo "No reminders to check."
        return
    fi
    
    local current_time=$(date +%s)
    local due_count=0
    local temp_file="${REMINDERS_FILE}.tmp"
    
    > "$temp_file"
    
    while IFS='|' read -r timestamp due_time note; do
        if [[ -n "$timestamp" ]]; then
            if (( timestamp <= current_time )); then
                # Reminder is due
                ((due_count++))
                
                echo "==================== REMINDER ===================="
                echo "Due Time: $due_time"
                echo "Note: $note"
                echo "================================================="
                echo ""
                
                # Log the reminder
                log "REMINDER" "$note (was due at $due_time)"
                
                # Try to show desktop notification on macOS
                if command -v osascript >/dev/null 2>&1; then
                    osascript -e "display notification \"$note\" with title \"Reminder Due\"" 2>/dev/null || true
                fi
            else
                # Keep future reminders
                echo "${timestamp}|${due_time}|${note}" >> "$temp_file"
            fi
        fi
    done < "$REMINDERS_FILE"
    
    # Replace reminders file with updated version
    mv "$temp_file" "$REMINDERS_FILE"
    
    if (( due_count == 0 )); then
        echo "No reminders are due at this time."
        list_reminders
    else
        echo "Displayed $due_count due reminder(s)."
    fi
}

# Clear expired reminders
clear_reminders() {
    if [[ ! -f "$REMINDERS_FILE" ]]; then
        echo "No reminders to clear."
        return
    fi
    
    local current_time=$(date +%s)
    local temp_file="${REMINDERS_FILE}.tmp"
    local cleared_count=0
    
    > "$temp_file"
    
    while IFS='|' read -r timestamp due_time note; do
        if [[ -n "$timestamp" ]]; then
            if (( timestamp > current_time )); then
                # Keep future reminders
                echo "${timestamp}|${due_time}|${note}" >> "$temp_file"
            else
                ((cleared_count++))
            fi
        fi
    done < "$REMINDERS_FILE"
    
    mv "$temp_file" "$REMINDERS_FILE"
    
    echo "Cleared $cleared_count expired reminder(s)."
    
    # Show remaining reminders
    list_reminders
}

# Setup cron helper
setup_cron() {
    echo "To automatically check reminders, add this to your crontab:"
    echo ""
    echo "# Check reminders every 5 minutes"
    echo "*/5 * * * * $SCRIPT_DIR/simple-reminder.sh check >> $LOGS_DIR/reminder-checks.log 2>&1"
    echo ""
    echo "Run 'crontab -e' to edit your crontab."
}

# Main execution
main() {
    if [[ $# -lt 1 ]]; then
        usage
    fi
    
    local action="$1"
    
    case "$action" in
        add)
            if [[ $# -lt 3 ]]; then
                echo "Error: 'add' requires minutes and note"
                usage
            fi
            add_reminder "$2" "$3"
            ;;
            
        list)
            list_reminders
            ;;
            
        check)
            check_reminders
            ;;
            
        clear)
            clear_reminders
            ;;
            
        cron)
            setup_cron
            ;;
            
        *)
            echo "Error: Unknown action '$action'"
            usage
            ;;
    esac
}

# Run main function
main "$@"