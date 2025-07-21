# Safe Usage Patterns for Tmux Orchestration Scripts

This document provides secure coding patterns and examples for safely implementing tmux orchestration functionality.

## Table of Contents
1. [Input Validation Patterns](#input-validation-patterns)
2. [Safe Message Sending](#safe-message-sending)
3. [Secure Script Templates](#secure-script-templates)
4. [Authentication Patterns](#authentication-patterns)
5. [Audit Logging](#audit-logging)
6. [Error Handling](#error-handling)
7. [Resource Management](#resource-management)

## Input Validation Patterns

### Window/Session Validation
```bash
#!/bin/bash
# Safe pattern for validating tmux targets

validate_tmux_target() {
    local target="$1"
    
    # Check format: session:window or session:window.pane
    if [[ ! "$target" =~ ^[a-zA-Z0-9_-]+:[0-9]+(\.[0-9]+)?$ ]]; then
        echo "ERROR: Invalid target format: $target" >&2
        echo "Expected format: session:window or session:window.pane" >&2
        return 1
    fi
    
    # Extract session name
    local session="${target%%:*}"
    
    # Verify session exists
    if ! tmux has-session -t "$session" 2>/dev/null; then
        echo "ERROR: Session '$session' does not exist" >&2
        return 1
    fi
    
    # Verify window exists
    if ! tmux list-windows -t "$target" &>/dev/null; then
        echo "ERROR: Window '$target' does not exist" >&2
        return 1
    fi
    
    return 0
}

# Usage example
if validate_tmux_target "$1"; then
    echo "Target $1 is valid"
else
    exit 1
fi
```

### Message Sanitization
```bash
#!/bin/bash
# Safe pattern for sanitizing messages

sanitize_message() {
    local message="$1"
    local max_length="${2:-1000}"
    
    # Remove shell metacharacters and control characters
    # Allow only printable characters, spaces, and basic punctuation
    local sanitized
    sanitized=$(echo "$message" | \
        tr -d '\000-\037' | \
        tr -d ';&|`$(){}[]<>\\' | \
        sed 's/["'\'']//g' | \
        cut -c1-"$max_length")
    
    echo "$sanitized"
}

# Usage example
USER_INPUT="Hello; rm -rf /"
SAFE_MESSAGE=$(sanitize_message "$USER_INPUT")
echo "Sanitized: $SAFE_MESSAGE"  # Output: "Hello rm -rf /"
```

## Safe Message Sending

### Complete Safe Sending Function
```bash
#!/bin/bash
# secure_send.sh - Safe message sending to tmux windows

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="/var/log/tmux-orchestrator/messages.log"
readonly MAX_MESSAGE_LENGTH=1000
readonly SEND_DELAY=0.5

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) [$level] $message" >> "$LOG_FILE"
}

# Main sending function
send_message_safely() {
    local target="$1"
    local message="$2"
    
    # Validate target
    if [[ ! "$target" =~ ^[a-zA-Z0-9_-]+:[0-9]+(\.[0-9]+)?$ ]]; then
        log_message "ERROR" "Invalid target format: $target"
        return 1
    fi
    
    # Check target exists
    local session="${target%%:*}"
    if ! tmux has-session -t "$session" 2>/dev/null; then
        log_message "ERROR" "Session does not exist: $session"
        return 1
    fi
    
    # Sanitize message
    local safe_message
    safe_message=$(echo "$message" | \
        tr -d '\000-\037;&|`$(){}[]<>\\\"'\''' | \
        cut -c1-$MAX_MESSAGE_LENGTH)
    
    # Log the attempt
    log_message "INFO" "Sending to $target: ${safe_message:0:50}..."
    
    # Send using literal flag (-l)
    if tmux send-keys -t "$target" -l "$safe_message" 2>/dev/null; then
        sleep "$SEND_DELAY"
        tmux send-keys -t "$target" Enter
        log_message "INFO" "Message sent successfully to $target"
        return 0
    else
        log_message "ERROR" "Failed to send message to $target"
        return 1
    fi
}

# Main execution
main() {
    if [[ $# -lt 2 ]]; then
        echo "Usage: $0 <session:window> <message>" >&2
        exit 1
    fi
    
    local target="$1"
    shift
    local message="$*"
    
    if send_message_safely "$target" "$message"; then
        echo "Message sent successfully"
    else
        echo "Failed to send message" >&2
        exit 1
    fi
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

### Python Implementation
```python
#!/usr/bin/env python3
# secure_tmux_send.py - Safe tmux message sending in Python

import subprocess
import re
import logging
import argparse
import time
import sys
from typing import Optional

class SecureTmuxSender:
    def __init__(self, log_file: str = "/var/log/tmux-orchestrator/messages.log"):
        self.logger = self._setup_logging(log_file)
        self.max_message_length = 1000
        self.send_delay = 0.5
        
    def _setup_logging(self, log_file: str) -> logging.Logger:
        logger = logging.getLogger('secure_tmux_sender')
        handler = logging.FileHandler(log_file)
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        handler.setFormatter(formatter)
        logger.addHandler(handler)
        logger.setLevel(logging.INFO)
        return logger
    
    def validate_target(self, target: str) -> bool:
        """Validate tmux target format"""
        pattern = r'^[a-zA-Z0-9_-]+:[0-9]+(\.[0-9]+)?$'
        if not re.match(pattern, target):
            self.logger.error(f"Invalid target format: {target}")
            return False
            
        # Check if session exists
        session = target.split(':')[0]
        try:
            subprocess.run(
                ['tmux', 'has-session', '-t', session],
                check=True,
                capture_output=True,
                text=True
            )
            return True
        except subprocess.CalledProcessError:
            self.logger.error(f"Session does not exist: {session}")
            return False
    
    def sanitize_message(self, message: str) -> str:
        """Remove dangerous characters from message"""
        # Remove shell metacharacters and control characters
        dangerous_chars = ';|&`$(){}[]<>\\"\''
        control_chars = ''.join(chr(i) for i in range(32))
        
        sanitized = message.translate(
            str.maketrans('', '', dangerous_chars + control_chars)
        )
        
        # Limit length
        return sanitized[:self.max_message_length]
    
    def send_message(self, target: str, message: str) -> bool:
        """Send message safely to tmux window"""
        # Validate target
        if not self.validate_target(target):
            return False
        
        # Sanitize message
        safe_message = self.sanitize_message(message)
        
        # Log attempt
        self.logger.info(f"Sending to {target}: {safe_message[:50]}...")
        
        try:
            # Send message with literal flag
            subprocess.run(
                ['tmux', 'send-keys', '-t', target, '-l', safe_message],
                check=True,
                capture_output=True,
                text=True
            )
            
            # Wait and send Enter
            time.sleep(self.send_delay)
            subprocess.run(
                ['tmux', 'send-keys', '-t', target, 'Enter'],
                check=True
            )
            
            self.logger.info(f"Message sent successfully to {target}")
            return True
            
        except subprocess.CalledProcessError as e:
            self.logger.error(f"Failed to send message: {e}")
            return False

def main():
    parser = argparse.ArgumentParser(description='Send message safely to tmux window')
    parser.add_argument('target', help='Target window (session:window)')
    parser.add_argument('message', help='Message to send')
    parser.add_argument('--log-file', default='/var/log/tmux-orchestrator/messages.log',
                        help='Log file path')
    
    args = parser.parse_args()
    
    sender = SecureTmuxSender(args.log_file)
    if sender.send_message(args.target, args.message):
        print("Message sent successfully")
    else:
        print("Failed to send message", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
```

## Secure Script Templates

### Scheduling with Security
```bash
#!/bin/bash
# secure_schedule.sh - Safe scheduling with systemd timers

set -euo pipefail

# Validate inputs
validate_schedule_params() {
    local minutes="$1"
    local note="$2"
    local target="$3"
    
    # Validate minutes is a positive integer
    if ! [[ "$minutes" =~ ^[0-9]+$ ]] || [[ "$minutes" -eq 0 ]]; then
        echo "ERROR: Minutes must be a positive integer" >&2
        return 1
    fi
    
    # Validate note length
    if [[ ${#note} -gt 200 ]]; then
        echo "ERROR: Note too long (max 200 characters)" >&2
        return 1
    fi
    
    # Validate target format
    if [[ ! "$target" =~ ^[a-zA-Z0-9_-]+:[0-9]+$ ]]; then
        echo "ERROR: Invalid target format" >&2
        return 1
    fi
    
    return 0
}

# Create systemd timer unit
create_timer_unit() {
    local minutes="$1"
    local note="$2"
    local target="$3"
    local unit_name="tmux-orchestrator-check-$(date +%s).timer"
    local unit_file="/etc/systemd/user/${unit_name}"
    
    # Create timer unit file
    cat > "$unit_file" <<EOF
[Unit]
Description=Tmux Orchestrator Check: ${note}

[Timer]
OnActiveSec=${minutes}min
RemainAfterElapse=no

[Install]
WantedBy=timers.target
EOF

    # Create service unit file
    cat > "${unit_file%.timer}.service" <<EOF
[Unit]
Description=Tmux Orchestrator Check Service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/tmux-check.sh "${target}" "${note}"
StandardOutput=journal
StandardError=journal
EOF

    # Start the timer
    systemctl --user daemon-reload
    systemctl --user start "${unit_name}"
    
    echo "Scheduled check in ${minutes} minutes"
}

# Main function
main() {
    if [[ $# -ne 3 ]]; then
        echo "Usage: $0 <minutes> <note> <target>" >&2
        exit 1
    fi
    
    local minutes="$1"
    local note="$2"
    local target="$3"
    
    if validate_schedule_params "$minutes" "$note" "$target"; then
        create_timer_unit "$minutes" "$note" "$target"
    else
        exit 1
    fi
}

main "$@"
```

## Authentication Patterns

### HMAC-based Authentication
```python
#!/usr/bin/env python3
# authenticated_messaging.py - Secure inter-agent communication

import hmac
import hashlib
import json
import time
import secrets
from typing import Dict, Optional
from dataclasses import dataclass, asdict

@dataclass
class AuthenticatedMessage:
    sender_id: str
    recipient_id: str
    content: str
    timestamp: float
    nonce: str
    signature: str = ""
    
    def to_dict(self) -> Dict:
        return asdict(self)
    
    def compute_signature(self, shared_secret: str) -> str:
        """Compute HMAC signature for message"""
        # Create canonical representation
        message_data = {
            'sender_id': self.sender_id,
            'recipient_id': self.recipient_id,
            'content': self.content,
            'timestamp': self.timestamp,
            'nonce': self.nonce
        }
        
        # Sort keys for consistent hashing
        canonical = json.dumps(message_data, sort_keys=True)
        
        # Compute HMAC
        return hmac.new(
            shared_secret.encode('utf-8'),
            canonical.encode('utf-8'),
            hashlib.sha256
        ).hexdigest()
    
    def verify_signature(self, shared_secret: str) -> bool:
        """Verify message signature"""
        expected_signature = self.compute_signature(shared_secret)
        return hmac.compare_digest(self.signature, expected_signature)
    
    def is_expired(self, max_age_seconds: int = 300) -> bool:
        """Check if message is too old"""
        return time.time() - self.timestamp > max_age_seconds

class SecureMessaging:
    def __init__(self, agent_id: str, shared_secrets: Dict[str, str]):
        self.agent_id = agent_id
        self.shared_secrets = shared_secrets
        self.seen_nonces = set()
        
    def create_message(self, recipient_id: str, content: str) -> AuthenticatedMessage:
        """Create authenticated message"""
        if recipient_id not in self.shared_secrets:
            raise ValueError(f"No shared secret for recipient: {recipient_id}")
        
        message = AuthenticatedMessage(
            sender_id=self.agent_id,
            recipient_id=recipient_id,
            content=content,
            timestamp=time.time(),
            nonce=secrets.token_urlsafe(16)
        )
        
        # Sign the message
        message.signature = message.compute_signature(
            self.shared_secrets[recipient_id]
        )
        
        return message
    
    def verify_message(self, message: AuthenticatedMessage) -> bool:
        """Verify received message"""
        # Check if message is for us
        if message.recipient_id != self.agent_id:
            return False
        
        # Check if we have shared secret
        if message.sender_id not in self.shared_secrets:
            return False
        
        # Check signature
        if not message.verify_signature(self.shared_secrets[message.sender_id]):
            return False
        
        # Check expiration
        if message.is_expired():
            return False
        
        # Check nonce for replay protection
        if message.nonce in self.seen_nonces:
            return False
        
        self.seen_nonces.add(message.nonce)
        
        return True

# Usage example
if __name__ == '__main__':
    # Agent setup
    orchestrator = SecureMessaging('orchestrator', {
        'agent1': 'shared_secret_123',
        'agent2': 'shared_secret_456'
    })
    
    # Create and send message
    msg = orchestrator.create_message('agent1', 'Execute git status')
    print(f"Message: {json.dumps(msg.to_dict(), indent=2)}")
    
    # Agent1 receives and verifies
    agent1 = SecureMessaging('agent1', {
        'orchestrator': 'shared_secret_123'
    })
    
    if agent1.verify_message(msg):
        print("Message verified successfully!")
    else:
        print("Message verification failed!")
```

## Audit Logging

### Comprehensive Audit Logger
```python
#!/usr/bin/env python3
# audit_logger.py - Security audit logging for tmux orchestration

import json
import logging
import hashlib
import time
from datetime import datetime
from typing import Dict, Any, Optional
from pathlib import Path
import threading

class SecurityAuditLogger:
    def __init__(self, log_dir: str = "/var/log/tmux-orchestrator"):
        self.log_dir = Path(log_dir)
        self.log_dir.mkdir(parents=True, exist_ok=True)
        
        # Different log files for different event types
        self.loggers = {
            'auth': self._create_logger('authentication.log'),
            'command': self._create_logger('commands.log'),
            'error': self._create_logger('errors.log'),
            'security': self._create_logger('security.log')
        }
        
        # Thread-safe event counter
        self._event_counter = 0
        self._counter_lock = threading.Lock()
        
    def _create_logger(self, filename: str) -> logging.Logger:
        """Create a logger with specific formatter"""
        logger = logging.getLogger(f'audit_{filename}')
        handler = logging.FileHandler(self.log_dir / filename)
        
        # JSON formatter for structured logs
        formatter = logging.Formatter('%(message)s')
        handler.setFormatter(formatter)
        
        logger.addHandler(handler)
        logger.setLevel(logging.INFO)
        
        return logger
    
    def _get_event_id(self) -> str:
        """Generate unique event ID"""
        with self._counter_lock:
            self._event_counter += 1
            return f"{int(time.time())}_{self._event_counter}"
    
    def _create_event(self, event_type: str, **kwargs) -> Dict[str, Any]:
        """Create standard event structure"""
        event = {
            'event_id': self._get_event_id(),
            'timestamp': datetime.utcnow().isoformat(),
            'event_type': event_type,
            'host': socket.gethostname(),
            'pid': os.getpid()
        }
        event.update(kwargs)
        
        # Add integrity hash
        event_copy = event.copy()
        event_copy.pop('hash', None)
        event_json = json.dumps(event_copy, sort_keys=True)
        event['hash'] = hashlib.sha256(event_json.encode()).hexdigest()
        
        return event
    
    def log_authentication(self, agent_id: str, success: bool, 
                         method: str = 'token', reason: Optional[str] = None):
        """Log authentication attempts"""
        event = self._create_event(
            'authentication',
            agent_id=agent_id,
            success=success,
            method=method,
            reason=reason
        )
        
        logger = self.loggers['auth']
        if success:
            logger.info(json.dumps(event))
        else:
            logger.warning(json.dumps(event))
            # Also log to security log for failures
            self.loggers['security'].warning(json.dumps(event))
    
    def log_command_execution(self, agent_id: str, target: str, 
                            command: str, result: str, 
                            exit_code: Optional[int] = None):
        """Log command executions"""
        event = self._create_event(
            'command_execution',
            agent_id=agent_id,
            target=target,
            command=command[:200],  # Truncate long commands
            result=result,
            exit_code=exit_code
        )
        
        self.loggers['command'].info(json.dumps(event))
    
    def log_security_event(self, severity: str, event_desc: str, 
                         agent_id: Optional[str] = None, 
                         details: Optional[Dict] = None):
        """Log security-relevant events"""
        event = self._create_event(
            'security_event',
            severity=severity,
            description=event_desc,
            agent_id=agent_id,
            details=details or {}
        )
        
        logger = self.loggers['security']
        if severity == 'critical':
            logger.critical(json.dumps(event))
        elif severity == 'high':
            logger.error(json.dumps(event))
        elif severity == 'medium':
            logger.warning(json.dumps(event))
        else:
            logger.info(json.dumps(event))
    
    def log_error(self, agent_id: str, error_type: str, 
                  error_message: str, stack_trace: Optional[str] = None):
        """Log errors and exceptions"""
        event = self._create_event(
            'error',
            agent_id=agent_id,
            error_type=error_type,
            error_message=error_message,
            stack_trace=stack_trace
        )
        
        self.loggers['error'].error(json.dumps(event))

# Usage example
import socket
import os

if __name__ == '__main__':
    audit = SecurityAuditLogger()
    
    # Log authentication attempt
    audit.log_authentication('agent1', True, method='token')
    
    # Log command execution
    audit.log_command_execution(
        agent_id='orchestrator',
        target='project:0',
        command='git status',
        result='success',
        exit_code=0
    )
    
    # Log security event
    audit.log_security_event(
        severity='high',
        event_desc='Command injection attempt detected',
        agent_id='unknown',
        details={
            'payload': '; rm -rf /',
            'source_ip': '192.168.1.100'
        }
    )
```

## Error Handling

### Robust Error Handling Pattern
```bash
#!/bin/bash
# error_handling.sh - Proper error handling for tmux scripts

set -euo pipefail

# Error codes
readonly ERR_INVALID_ARGS=1
readonly ERR_TMUX_NOT_FOUND=2
readonly ERR_SESSION_NOT_FOUND=3
readonly ERR_COMMAND_FAILED=4
readonly ERR_TIMEOUT=5

# Trap handler for cleanup
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo "Script failed with exit code: $exit_code" >&2
    fi
    # Add cleanup operations here
    exit $exit_code
}

trap cleanup EXIT

# Error reporting function
report_error() {
    local error_code="$1"
    local error_message="$2"
    local context="${3:-}"
    
    # Log to syslog
    logger -t "tmux-orchestrator" -p user.err \
        "ERROR[$error_code]: $error_message ${context:+(Context: $context)}"
    
    # Log to file
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) ERROR[$error_code]: $error_message ${context:+(Context: $context)}" \
        >> /var/log/tmux-orchestrator/errors.log
    
    # Output to stderr
    echo "ERROR: $error_message" >&2
    
    return $error_code
}

# Check prerequisites
check_prerequisites() {
    # Check tmux is installed
    if ! command -v tmux &>/dev/null; then
        report_error $ERR_TMUX_NOT_FOUND "tmux is not installed"
        return $ERR_TMUX_NOT_FOUND
    fi
    
    # Check log directory exists
    local log_dir="/var/log/tmux-orchestrator"
    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir" || {
            report_error $ERR_COMMAND_FAILED "Cannot create log directory: $log_dir"
            return $ERR_COMMAND_FAILED
        }
    fi
    
    return 0
}

# Execute with timeout
execute_with_timeout() {
    local timeout="$1"
    shift
    local command=("$@")
    
    # Execute command with timeout
    if timeout "$timeout" "${command[@]}"; then
        return 0
    else
        local exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
            report_error $ERR_TIMEOUT "Command timed out after ${timeout}s" "${command[*]}"
            return $ERR_TIMEOUT
        else
            report_error $ERR_COMMAND_FAILED "Command failed with exit code $exit_code" "${command[*]}"
            return $ERR_COMMAND_FAILED
        fi
    fi
}

# Main function with error handling
main() {
    # Check prerequisites
    check_prerequisites || exit $?
    
    # Validate arguments
    if [[ $# -lt 2 ]]; then
        report_error $ERR_INVALID_ARGS "Invalid arguments. Usage: $0 <session:window> <command>"
        exit $ERR_INVALID_ARGS
    fi
    
    local target="$1"
    local command="$2"
    
    # Validate target exists
    if ! tmux list-windows -t "$target" &>/dev/null; then
        report_error $ERR_SESSION_NOT_FOUND "Target window does not exist: $target"
        exit $ERR_SESSION_NOT_FOUND
    fi
    
    # Execute command with timeout
    execute_with_timeout 30 tmux send-keys -t "$target" -l "$command" || exit $?
    
    echo "Command sent successfully to $target"
}

# Run main function
main "$@"
```

## Resource Management

### Process Limits and Resource Control
```bash
#!/bin/bash
# resource_manager.sh - Resource management for tmux agents

set -euo pipefail

# Resource limits configuration
readonly MAX_PROCESSES_PER_AGENT=10
readonly MAX_MEMORY_MB=512
readonly MAX_CPU_PERCENT=50
readonly MAX_OPEN_FILES=1024

# Apply resource limits to agent
apply_resource_limits() {
    local agent_name="$1"
    local agent_pid="$2"
    
    # Create cgroup for agent (requires root or proper permissions)
    local cgroup_path="/sys/fs/cgroup/tmux-orchestrator/${agent_name}"
    
    if [[ -w "/sys/fs/cgroup" ]]; then
        # Create cgroup
        mkdir -p "${cgroup_path}"
        
        # Set memory limit
        echo "${MAX_MEMORY_MB}M" > "${cgroup_path}/memory.limit_in_bytes"
        
        # Set CPU limit (in microseconds per 100ms)
        echo "$((MAX_CPU_PERCENT * 1000))" > "${cgroup_path}/cpu.cfs_quota_us"
        echo "100000" > "${cgroup_path}/cpu.cfs_period_us"
        
        # Add process to cgroup
        echo "$agent_pid" > "${cgroup_path}/cgroup.procs"
    fi
    
    # Set process limits using ulimit (applies to child processes)
    ulimit -u $MAX_PROCESSES_PER_AGENT  # Max processes
    ulimit -n $MAX_OPEN_FILES          # Max open files
    ulimit -v $((MAX_MEMORY_MB * 1024)) # Max virtual memory (KB)
}

# Monitor resource usage
monitor_agent_resources() {
    local agent_name="$1"
    local threshold_cpu=80
    local threshold_mem=90
    
    # Get all processes for agent
    local agent_pids
    agent_pids=$(pgrep -f "tmux.*${agent_name}" || true)
    
    if [[ -z "$agent_pids" ]]; then
        echo "No processes found for agent: $agent_name"
        return 0
    fi
    
    # Check each process
    for pid in $agent_pids; do
        if [[ -e "/proc/$pid" ]]; then
            # Get CPU usage
            local cpu_usage
            cpu_usage=$(ps -p "$pid" -o %cpu= | tr -d ' ')
            
            # Get memory usage
            local mem_usage
            mem_usage=$(ps -p "$pid" -o %mem= | tr -d ' ')
            
            # Alert if thresholds exceeded
            if (( $(echo "$cpu_usage > $threshold_cpu" | bc -l) )); then
                logger -t "tmux-orchestrator" -p user.warning \
                    "High CPU usage for $agent_name (PID: $pid): ${cpu_usage}%"
            fi
            
            if (( $(echo "$mem_usage > $threshold_mem" | bc -l) )); then
                logger -t "tmux-orchestrator" -p user.warning \
                    "High memory usage for $agent_name (PID: $pid): ${mem_usage}%"
            fi
        fi
    done
}

# Kill runaway processes
kill_runaway_processes() {
    local agent_name="$1"
    local max_runtime_minutes="${2:-60}"
    
    # Find processes older than max_runtime
    local old_processes
    old_processes=$(find /proc -maxdepth 1 -user "$(whoami)" -type d -mmin +"$max_runtime_minutes" \
        -exec bash -c 'grep -l "tmux.*'"$agent_name"'" {}/cmdline 2>/dev/null' \; | \
        grep -oE '[0-9]+' || true)
    
    for pid in $old_processes; do
        echo "Killing runaway process for $agent_name: PID $pid"
        kill -TERM "$pid" 2>/dev/null || true
        sleep 2
        kill -KILL "$pid" 2>/dev/null || true
    done
}

# Main monitoring loop
main() {
    local agent_name="${1:-all}"
    
    while true; do
        if [[ "$agent_name" == "all" ]]; then
            # Monitor all agents
            for session in $(tmux list-sessions -F "#{session_name}" 2>/dev/null || true); do
                monitor_agent_resources "$session"
                kill_runaway_processes "$session"
            done
        else
            # Monitor specific agent
            monitor_agent_resources "$agent_name"
            kill_runaway_processes "$agent_name"
        fi
        
        # Wait before next check
        sleep 60
    done
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

## Summary

These safe usage patterns provide a foundation for secure tmux orchestration:

1. **Always validate input** before passing to tmux commands
2. **Use literal flags** (`-l`) to prevent command interpretation
3. **Implement authentication** for inter-agent communication
4. **Log all operations** for audit trails
5. **Handle errors gracefully** with proper cleanup
6. **Apply resource limits** to prevent runaway processes
7. **Monitor continuously** for security anomalies

Remember: Security must be built in from the start, not added as an afterthought. These patterns help mitigate risks but cannot eliminate all security concerns inherent in tmux-based orchestration architectures.