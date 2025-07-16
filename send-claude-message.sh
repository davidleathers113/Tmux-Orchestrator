#!/usr/bin/env bash
set -euo pipefail

# Send message to Claude agent in tmux window
# Usage: send-claude-message.sh <session:window> <message>

if [ $# -lt 2 ]; then
    echo "Usage: $0 <session:window> <message>" >&2
    echo "Example: $0 agentic-seek:3 'Hello Claude!'" >&2
    exit 64  # EX_USAGE
fi

WINDOW="$1"
shift  # Remove first argument, rest is the message

# Secure IFS handling
IFS=$'\n\t'

# Validate window format using tmux's own parser
if ! tmux list-windows -t "$WINDOW" -F '#{window_id}' >/dev/null 2>&1; then
    echo "Error: Invalid or non-existent window target: $WINDOW" >&2
    exit 64
fi

# Preserve spaces safely
MESSAGE="$*"

# Check message size to prevent buffer overflow
if (( ${#MESSAGE} > 250000 )); then
    echo "Warning: Message too large (${#MESSAGE} chars), may truncate" >&2
fi

# Function to wait for pane readiness with timeout
wait_for_pane_ready() {
    local target="$1"
    local timeout=30
    
    # Validate session exists
    if ! tmux has-session -t "${target%%:*}" 2>/dev/null; then
        echo "Error: tmux session '${target%%:*}' not found" >&2
        exit 65
    fi
    
    # Detect available timeout command
    local timeout_cmd
    timeout_cmd=$(command -v timeout || command -v gtimeout || echo "")
    
    # Try tmux wait-for with timeout if available
    if [[ -n $timeout_cmd ]]; then
        if "$timeout_cmd" "$timeout" tmux wait-for -L "ready-$target" 2>/dev/null; then
            return 0
        fi
    fi
    
    # Fallback: poll pane status without regex
    local count=0
    while (( count < timeout * 10 )); do  # 0.1s intervals
        local pane_mode
        pane_mode=$(tmux display -p -t "$target" '#{pane_in_mode}' 2>/dev/null)
        if [[ $pane_mode == "0" ]]; then
            return 0
        fi
        sleep 0.1
        ((count++))
    done
    
    return 1
}

# Wait for pane to be ready
if ! wait_for_pane_ready "$WINDOW"; then
    echo "Error: Pane $WINDOW not ready after timeout" >&2
    exit 70  # EX_SOFTWARE
fi

# Send the message with literal mode to preserve spaces
if ! tmux send-keys -t "$WINDOW" -l -- "$MESSAGE"; then
    echo "Error: Failed to send message to $WINDOW" >&2
    exit 70  # EX_SOFTWARE
fi

# Send Enter to submit
if ! tmux send-keys -t "$WINDOW" Enter; then
    echo "Error: Failed to send Enter to $WINDOW" >&2
    exit 70  # EX_SOFTWARE
fi

# Log successful message delivery
logger -t "send-claude-message" "Sent to $WINDOW: ${MESSAGE:0:50}..."

echo "Message sent to $WINDOW: $MESSAGE"