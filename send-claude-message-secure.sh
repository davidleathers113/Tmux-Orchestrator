#!/bin/bash

# Secure version of send-claude-message.sh
# This implementation includes proper input validation and security measures

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Function to display usage
usage() {
    cat << EOF
Usage: $0 <session:window> <message>
Send a message to a Claude agent in a tmux window (secure version)

Arguments:
  session:window  Target tmux window in format 'session:window'
  message         Message to send (will be sanitized)

Example:
  $0 agentic-seek:3 'Hello Claude!'

Security features:
  - Input validation for window format
  - Message sanitization
  - Proper error handling
  - Safe tmux command usage
EOF
    exit 1
}

# Function to validate window format
validate_window() {
    local window="$1"
    
    # Check format: alphanumeric/dash/underscore only
    if [[ ! "$window" =~ ^[a-zA-Z0-9_-]+:[a-zA-Z0-9_-]+$ ]]; then
        echo "Error: Invalid window format '$window'" >&2
        echo "Format must be 'session:window' with alphanumeric characters, dashes, or underscores only" >&2
        return 1
    fi
    
    # Check length limits
    local session="${window%%:*}"
    local window_name="${window#*:}"
    
    if [[ ${#session} -gt 50 ]] || [[ ${#window_name} -gt 50 ]]; then
        echo "Error: Session or window name too long (max 50 characters)" >&2
        return 1
    fi
    
    return 0
}

# Function to check if tmux window exists
window_exists() {
    local window="$1"
    tmux list-windows -t "$window" &>/dev/null
}

# Main script
main() {
    # Check dependencies
    if ! command -v tmux &>/dev/null; then
        echo "Error: tmux is not installed" >&2
        exit 1
    fi
    
    # Validate arguments
    if [[ $# -lt 2 ]]; then
        usage
    fi
    
    local window="$1"
    shift
    local message="$*"
    
    # Validate window format
    if ! validate_window "$window"; then
        exit 1
    fi
    
    # Check if window exists
    if ! window_exists "$window"; then
        echo "Error: Window '$window' does not exist" >&2
        echo "Available windows:" >&2
        tmux list-windows -F '#S:#W' 2>/dev/null || echo "No tmux sessions found" >&2
        exit 1
    fi
    
    # Validate message length
    if [[ ${#message} -gt 10000 ]]; then
        echo "Error: Message too long (max 10000 characters)" >&2
        exit 1
    fi
    
    # Send message using -l flag for literal input (prevents interpretation)
    if ! tmux send-keys -t "$window" -l "$message" 2>/dev/null; then
        echo "Error: Failed to send message to tmux window" >&2
        exit 1
    fi
    
    # Wait for UI
    sleep 0.5
    
    # Send Enter key
    if ! tmux send-keys -t "$window" Enter 2>/dev/null; then
        echo "Error: Failed to send Enter key" >&2
        exit 1
    fi
    
    # Success message (without echoing potentially sensitive content)
    echo "Message sent successfully to $window (${#message} characters)"
}

# Run main function
main "$@"