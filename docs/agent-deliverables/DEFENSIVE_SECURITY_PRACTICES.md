# Defensive Security Practices for Tmux Orchestration

## Executive Summary

This document provides defensive security practices extracted from security analyses of the Tmux-Orchestrator project. These practices are designed to help security professionals understand and mitigate risks when using tmux-based orchestration systems.

## Critical Security Principles

### 1. Never Trust User Input
- **All input must be validated** before being passed to tmux commands
- **Sanitize special characters** that could be interpreted as shell commands
- **Use allowlists, not denylists** for permitted characters and patterns
- **Implement length limits** to prevent buffer overflow attempts

### 2. Command Injection Prevention

#### Dangerous Patterns to Avoid
```bash
# ❌ NEVER DO THIS
tmux send-keys -t "$WINDOW" "$MESSAGE"  # Direct user input
tmux send-keys -t session:window "; malicious command"

# ✅ SAFE APPROACH
tmux send-keys -t "$WINDOW" -l "$SANITIZED_MESSAGE"  # Use -l flag for literal
```

#### Input Validation Template
```bash
validate_window() {
    local window="$1"
    # Only allow alphanumeric, hyphens, underscores, and single colon
    if [[ ! "$window" =~ ^[a-zA-Z0-9_-]+:[a-zA-Z0-9_-]+(\.[0-9]+)?$ ]]; then
        echo "Error: Invalid window format" >&2
        return 1
    fi
}

sanitize_message() {
    local message="$1"
    # Remove shell metacharacters
    echo "$message" | tr -d ';&|`$(){}[]<>\"\''
}
```

### 3. Authentication and Authorization

#### Required Controls
- **Agent Identity Verification**: Every agent must have a unique, cryptographically secure token
- **Message Authentication**: Use HMAC signatures for inter-agent communication
- **Permission Checking**: Validate that agents can only perform allowed operations
- **Session Isolation**: Agents should not access sessions they don't own

#### Example Authentication Implementation
```python
import hmac
import hashlib
import secrets

class SecureAgent:
    def __init__(self, agent_id):
        self.agent_id = agent_id
        self.token = secrets.token_urlsafe(32)
        
    def sign_message(self, message, shared_secret):
        data = f"{self.agent_id}:{message}:{time.time()}"
        return hmac.new(
            shared_secret.encode(),
            data.encode(),
            hashlib.sha256
        ).hexdigest()
```

### 4. Audit Logging Requirements

#### Mandatory Logging Events
- All command executions with full parameters
- Authentication attempts (successful and failed)
- Agent lifecycle events (creation, termination)
- Error conditions and security violations
- Message passing between agents

#### Audit Log Format
```json
{
    "timestamp": "2024-01-15T10:30:45.123Z",
    "event_type": "command_execution",
    "agent_id": "orchestrator-001",
    "target": "project:0",
    "command": "git status",
    "result": "success",
    "signature": "abc123...",
    "source_ip": "127.0.0.1"
}
```

### 5. Process Isolation

#### Isolation Requirements
- Run each agent under a separate user account
- Use systemd security features or containers
- Apply strict file system permissions
- Limit network access per agent
- Use resource limits (CPU, memory, process count)

#### Systemd Security Configuration
```ini
[Service]
User=tmux-agent
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
NoNewPrivileges=true
CapabilityBoundingSet=
RestrictNamespaces=true
RestrictRealtime=true
MemoryLimit=512M
TasksMax=10
```

### 6. Safe Message Passing Patterns

#### Secure Message Sending Script Template
```bash
#!/bin/bash
set -euo pipefail

# Configuration
readonly MAX_MESSAGE_LENGTH=1000
readonly ALLOWED_SESSIONS_PATTERN="^[a-zA-Z0-9_-]+$"
readonly LOG_FILE="/var/log/tmux-orchestrator/messages.log"

# Validate and send message
send_secure_message() {
    local target="$1"
    local message="$2"
    
    # Validate target format
    if [[ ! "$target" =~ ^[a-zA-Z0-9_-]+:[0-9]+(\.[0-9]+)?$ ]]; then
        log_error "Invalid target format: $target"
        return 1
    fi
    
    # Check target exists
    if ! tmux list-windows -t "$target" &>/dev/null; then
        log_error "Target window does not exist: $target"
        return 1
    fi
    
    # Sanitize and truncate message
    local safe_message
    safe_message=$(echo "$message" | tr -cd '[:print:]' | cut -c1-"$MAX_MESSAGE_LENGTH")
    
    # Log the attempt
    log_info "Sending message to $target"
    
    # Send using literal flag
    tmux send-keys -t "$target" -l "$safe_message"
    sleep 0.5
    tmux send-keys -t "$target" Enter
    
    return 0
}
```

### 7. Vulnerability Warnings

#### Known Attack Vectors
1. **Command Injection through messages** - Attackers can inject shell commands
2. **Session hijacking** - Without auth, any process can control any session
3. **Privilege escalation** - Background processes run with user's full permissions
4. **Information disclosure** - Hardcoded paths reveal system structure
5. **Resource exhaustion** - Unlimited process creation via nohup

#### Common Exploitation Techniques
```bash
# Examples of malicious inputs to watch for:
"; rm -rf /"              # Command chaining
"$(malicious_command)"    # Command substitution
"`malicious_command`"     # Legacy command substitution
"&& malicious_command"    # Conditional execution
"| malicious_command"     # Pipe to malicious command
"> /etc/passwd"          # File overwrite
"../../etc/passwd"       # Path traversal
```

### 8. Security Monitoring

#### Key Metrics to Monitor
- Failed authentication attempts
- Unusual command patterns
- Message volume spikes
- New session creation rate
- Error rate increases
- Resource usage anomalies

#### Alert Conditions
```yaml
alerts:
  - name: command_injection_attempt
    condition: message contains [";", "&&", "||", "|", "$", "`"]
    severity: critical
    
  - name: authentication_failure_spike
    condition: auth_failures > 5 in 1 minute
    severity: high
    
  - name: resource_exhaustion
    condition: process_count > 100 per agent
    severity: high
```

### 9. Secure Configuration Management

#### Environment Variables
```bash
# Never hardcode sensitive values
export TMUX_ORCHESTRATOR_SECRET_KEY="${TMUX_ORCHESTRATOR_SECRET_KEY:?Error: Secret key not set}"
export TMUX_ORCHESTRATOR_LOG_DIR="${TMUX_ORCHESTRATOR_LOG_DIR:-/var/log/tmux-orchestrator}"
export TMUX_ORCHESTRATOR_MAX_AGENTS="${TMUX_ORCHESTRATOR_MAX_AGENTS:-10}"
```

#### Configuration File Security
```yaml
# /etc/tmux-orchestrator/config.yml
security:
  authentication_required: true
  audit_logging: true
  command_whitelist_only: true
  max_message_length: 1000
  session_timeout: 3600
  
permissions:
  file_mode: "0600"
  directory_mode: "0700"
  run_as_user: "tmux-orchestrator"
  run_as_group: "tmux-orchestrator"
```

### 10. Incident Response

#### Security Incident Checklist
- [ ] Immediately isolate affected systems
- [ ] Capture tmux session contents: `tmux capture-pane -S -`
- [ ] Preserve audit logs before they rotate
- [ ] Check for unauthorized processes
- [ ] Review command history in all sessions
- [ ] Look for persistence mechanisms
- [ ] Document timeline of events

#### Evidence Collection Commands
```bash
# Capture all tmux sessions
for session in $(tmux list-sessions -F "#{session_name}"); do
    tmux capture-pane -t "$session" -S - > "evidence_${session}_$(date +%s).log"
done

# Check for suspicious processes
ps aux | grep -E "(nohup|tmux|at|cron)" > suspicious_processes.log

# Audit command history
find /home -name ".bash_history" -exec cp {} evidence_bash_history_{} \;
```

## Security Templates for CLAUDE.md

### Root Directory CLAUDE.md Security Section
```markdown
## 🔐 Security Requirements

### MANDATORY Security Checks
- [ ] All scripts validate input before passing to tmux
- [ ] No hardcoded paths or credentials in any file
- [ ] Audit logging enabled for all operations
- [ ] Agent authentication required for all actions
- [ ] Resource limits applied to all processes

### Prohibited Patterns
- ❌ Direct execution of user input: `tmux send-keys -t window "$USER_INPUT"`
- ❌ Shell command construction: `cmd="tmux $operation"; $cmd`
- ❌ Unvalidated window targets: `tmux send-keys -t "$1"`
- ❌ Background processes without limits: `nohup command &`
```

### Script Directory CLAUDE.md Security Section
```markdown
## 🛡️ Script Security Guidelines

### Input Validation Requirements
Every script MUST:
1. Validate all arguments before use
2. Sanitize special characters from user input
3. Use tmux send-keys with -l flag for literal strings
4. Check target window exists before sending
5. Log all operations with timestamps

### Security Review Checklist
Before committing any script:
- [ ] Run shellcheck for basic issues
- [ ] Test with malicious inputs
- [ ] Verify no command injection possible
- [ ] Ensure proper error handling
- [ ] Confirm audit logging works
```

## Conclusion

The Tmux-Orchestrator system, while powerful for automation, presents significant security challenges. These defensive practices provide a foundation for understanding and mitigating risks. However, for production security-sensitive environments, purpose-built orchestration platforms with security-first design principles are strongly recommended over tmux-based solutions.

Remember: **Security is not a feature to be added; it must be designed in from the beginning.**