# Security Recommendations: Tmux-Orchestrator System

## Immediate Mitigations Required

### 1. Disable in Production (IMMEDIATE)
- **Action**: Do not run this system on any production or security-sensitive machines
- **Rationale**: Critical vulnerabilities cannot be patched without complete redesign
- **Alternative**: Use established orchestration tools with security built-in

### 2. Isolate Existing Deployments (URGENT)
If already running:
- **Network Isolation**: Move to isolated network segment
- **User Isolation**: Run under dedicated low-privilege user
- **Resource Limits**: Apply strict ulimits and cgroups
- **Access Control**: Restrict tmux socket permissions

### 3. Emergency Security Wrapper (TEMPORARY)
Create minimal security wrapper:
```bash
#!/bin/bash
# security_wrapper.sh - Temporary mitigation only

# Validate session name
if [[ ! "$1" =~ ^[a-zA-Z0-9_-]+:[0-9]+$ ]]; then
    echo "Invalid session format" >&2
    exit 1
fi

# Sanitize message - remove dangerous characters
MESSAGE=$(echo "$2" | tr -d ';&|`$(){}[]<>' | cut -c1-500)

# Log attempt
echo "$(date) - Session: $1, Message: $MESSAGE" >> /var/log/tmux_orchestrator_audit.log

# Send with timeout
timeout 5 tmux send-keys -t "$1" "$MESSAGE"
```

## Long-term Security Improvements

### 1. Authentication & Authorization System

#### Implement Agent Identity
```python
class AgentIdentity:
    def __init__(self, agent_id, role, permissions):
        self.agent_id = agent_id
        self.role = role
        self.permissions = permissions
        self.token = self.generate_token()
    
    def generate_token(self):
        # Use cryptographically secure token generation
        return secrets.token_urlsafe(32)
    
    def verify_permission(self, action):
        return action in self.permissions
```

#### Add Message Authentication
```python
import hmac
import hashlib

class SecureMessage:
    def __init__(self, sender_id, recipient_id, content, shared_secret):
        self.sender_id = sender_id
        self.recipient_id = recipient_id
        self.content = content
        self.timestamp = time.time()
        self.signature = self.sign_message(shared_secret)
    
    def sign_message(self, secret):
        message = f"{self.sender_id}:{self.recipient_id}:{self.content}:{self.timestamp}"
        return hmac.new(secret.encode(), message.encode(), hashlib.sha256).hexdigest()
```

### 2. Input Validation Framework

#### Command Validation
```python
import re
from typing import List, Optional

class CommandValidator:
    # Whitelist of allowed commands
    ALLOWED_COMMANDS = {
        'status': r'^status\s+(update|check|report)$',
        'git': r'^git\s+(status|log|diff)$',
        'list': r'^ls\s+-la\s+[\w/.-]+$'
    }
    
    @classmethod
    def validate_command(cls, command: str) -> Optional[str]:
        """Validate command against whitelist patterns"""
        command = command.strip()
        
        for cmd_type, pattern in cls.ALLOWED_COMMANDS.items():
            if re.match(pattern, command):
                return command
        
        raise ValueError(f"Command not allowed: {command}")
```

#### Message Sanitization
```python
def sanitize_message(message: str) -> str:
    """Remove potentially dangerous characters and limit length"""
    # Remove shell metacharacters
    dangerous_chars = ';|&$`(){}[]<>\\"\''
    sanitized = ''.join(c for c in message if c not in dangerous_chars)
    
    # Limit length
    max_length = 1000
    if len(sanitized) > max_length:
        sanitized = sanitized[:max_length]
    
    return sanitized
```

### 3. Secure Communication Architecture

#### Message Queue Approach
Replace direct tmux communication with secure message queue:

```python
import pika
import json
import ssl

class SecureMessageQueue:
    def __init__(self, host, port, ssl_context):
        self.connection = pika.BlockingConnection(
            pika.ConnectionParameters(
                host=host,
                port=port,
                ssl_options=pika.SSLOptions(ssl_context)
            )
        )
        self.channel = self.connection.channel()
    
    def send_message(self, agent_id, message, signature):
        """Send authenticated message through secure channel"""
        payload = {
            'agent_id': agent_id,
            'message': message,
            'signature': signature,
            'timestamp': time.time()
        }
        
        self.channel.basic_publish(
            exchange='agent_exchange',
            routing_key=f'agent.{agent_id}',
            body=json.dumps(payload)
        )
```

### 4. Audit Logging System

#### Comprehensive Audit Trail
```python
import logging
import json
from datetime import datetime

class SecurityAuditLogger:
    def __init__(self, log_file='/var/log/orchestrator_security.log'):
        self.logger = logging.getLogger('orchestrator_security')
        handler = logging.FileHandler(log_file)
        handler.setFormatter(logging.Formatter(
            '%(asctime)s - %(levelname)s - %(message)s'
        ))
        self.logger.addHandler(handler)
        self.logger.setLevel(logging.INFO)
    
    def log_command_execution(self, agent_id, command, result, error=None):
        event = {
            'event_type': 'command_execution',
            'timestamp': datetime.utcnow().isoformat(),
            'agent_id': agent_id,
            'command': command,
            'result': result,
            'error': error
        }
        self.logger.info(json.dumps(event))
    
    def log_authentication_attempt(self, agent_id, success, reason=None):
        event = {
            'event_type': 'authentication',
            'timestamp': datetime.utcnow().isoformat(),
            'agent_id': agent_id,
            'success': success,
            'reason': reason
        }
        self.logger.warning(json.dumps(event)) if not success else self.logger.info(json.dumps(event))
```

### 5. Process Isolation

#### Containerized Agents
```dockerfile
# Dockerfile for isolated agent
FROM python:3.11-slim

# Create non-root user
RUN useradd -m -s /bin/bash agent

# Install only required packages
RUN apt-get update && apt-get install -y \
    tmux \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set security restrictions
USER agent
WORKDIR /home/agent

# Copy only necessary files
COPY --chown=agent:agent requirements.txt .
RUN pip install --user -r requirements.txt

# Run with minimal capabilities
ENTRYPOINT ["python", "-u", "agent.py"]
```

#### Systemd Security Hardening
```ini
[Service]
# Run as non-root
User=orchestrator
Group=orchestrator

# Filesystem protections
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
ReadWritePaths=/var/lib/orchestrator

# Network restrictions
PrivateNetwork=false
RestrictAddressFamilies=AF_INET AF_INET6

# Process restrictions
NoNewPrivileges=true
MemoryLimit=1G
TasksMax=50

# Capabilities
CapabilityBoundingSet=
AmbientCapabilities=
```

## Alternative Secure Architectures

### Option 1: Kubernetes Jobs Architecture
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: agent-task
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      containers:
      - name: agent
        image: orchestrator/agent:latest
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        resources:
          limits:
            memory: "1Gi"
            cpu: "1"
        env:
        - name: AGENT_TOKEN
          valueFrom:
            secretKeyRef:
              name: agent-credentials
              key: token
```

### Option 2: Celery with Security
```python
from celery import Celery
from kombu import Queue

app = Celery('orchestrator')
app.conf.update(
    broker_url='rediss://localhost:6379/0',  # TLS Redis
    result_backend='rediss://localhost:6379/0',
    broker_use_ssl={
        'ssl_cert_reqs': ssl.CERT_REQUIRED,
        'ssl_ca_certs': '/path/to/ca.pem',
        'ssl_certfile': '/path/to/cert.pem',
        'ssl_keyfile': '/path/to/key.pem'
    },
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    timezone='UTC',
    enable_utc=True,
    task_time_limit=300,  # 5 minute timeout
    task_soft_time_limit=240
)

@app.task(bind=True, name='execute_safe_command')
def execute_safe_command(self, agent_id, command):
    """Execute validated commands with security controls"""
    # Validate agent permissions
    if not validate_agent_permissions(agent_id, command):
        raise PermissionError(f"Agent {agent_id} lacks permission")
    
    # Validate command
    validated_cmd = CommandValidator.validate_command(command)
    
    # Execute with timeout and capture
    result = subprocess.run(
        validated_cmd,
        shell=False,  # Never use shell=True
        capture_output=True,
        text=True,
        timeout=30
    )
    
    # Audit log
    audit_logger.log_command_execution(
        agent_id=agent_id,
        command=validated_cmd,
        result=result.returncode
    )
    
    return result.stdout
```

### Option 3: HashiCorp Nomad Approach
```hcl
job "orchestrator" {
  datacenters = ["dc1"]
  type = "service"

  group "agents" {
    count = 3

    task "agent" {
      driver = "docker"
      
      config {
        image = "orchestrator/agent:latest"
        network_mode = "bridge"
        cap_drop = ["ALL"]
        readonly_rootfs = true
      }

      template {
        data = <<EOH
AGENT_ID={{ env "NOMAD_ALLOC_ID" }}
VAULT_TOKEN={{ with secret "orchestrator/agent" }}{{ .Data.token }}{{ end }}
EOH
        destination = "secrets/env"
        env = true
      }

      resources {
        cpu    = 500
        memory = 512
      }

      vault {
        policies = ["orchestrator-agent"]
      }
    }
  }
}
```

## Specific Code Changes Needed

### 1. Replace schedule_with_note.sh
```bash
#!/bin/bash
# secure_schedule.sh - Secure scheduling with validation

set -euo pipefail

# Input validation
MINUTES="${1:?Error: Minutes parameter required}"
NOTE="${2:?Error: Note parameter required}"
TARGET="${3:-tmux-orc:0}"

# Validate minutes is a number
if ! [[ "$MINUTES" =~ ^[0-9]+$ ]]; then
    echo "Error: Minutes must be a positive integer" >&2
    exit 1
fi

# Validate target format
if ! [[ "$TARGET" =~ ^[a-zA-Z0-9_-]+:[0-9]+$ ]]; then
    echo "Error: Invalid target format" >&2
    exit 1
fi

# Sanitize note - remove shell metacharacters
NOTE_SANITIZED=$(echo "$NOTE" | tr -d ';&|`$(){}[]<>' | cut -c1-200)

# Create secure note file with restricted permissions
NOTE_FILE="/var/lib/orchestrator/notes/$(date +%s)_$(openssl rand -hex 4).txt"
mkdir -p "$(dirname "$NOTE_FILE")"
echo "Scheduled: $(date)" > "$NOTE_FILE"
echo "Note: $NOTE_SANITIZED" >> "$NOTE_FILE"
chmod 600 "$NOTE_FILE"

# Log scheduling attempt
logger -t orchestrator "Scheduling check in $MINUTES minutes for $TARGET"

# Use systemd timer instead of nohup
systemctl --user start "orchestrator-check@${MINUTES}.timer"

echo "Scheduled securely via systemd timer"
```

### 2. Replace send-claude-message.sh
```python
#!/usr/bin/env python3
# secure_send_message.py - Secure message sending with authentication

import argparse
import hmac
import hashlib
import json
import logging
import re
import subprocess
import sys
from datetime import datetime

class SecureMessageSender:
    def __init__(self, agent_id, secret_key):
        self.agent_id = agent_id
        self.secret_key = secret_key
        self.logger = self._setup_logging()
    
    def _setup_logging(self):
        logger = logging.getLogger('secure_message')
        handler = logging.FileHandler('/var/log/orchestrator/messages.log')
        handler.setFormatter(logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        ))
        logger.addHandler(handler)
        logger.setLevel(logging.INFO)
        return logger
    
    def validate_target(self, target):
        """Validate target format"""
        pattern = r'^[a-zA-Z0-9_-]+:[0-9]+(\.[0-9]+)?$'
        if not re.match(pattern, target):
            raise ValueError(f"Invalid target format: {target}")
        return target
    
    def sanitize_message(self, message):
        """Remove dangerous characters"""
        dangerous = ';|&$`(){}[]<>\\"\''
        sanitized = ''.join(c for c in message if c not in dangerous)
        return sanitized[:1000]  # Limit length
    
    def sign_message(self, target, message):
        """Create HMAC signature"""
        data = f"{self.agent_id}:{target}:{message}:{datetime.utcnow().isoformat()}"
        signature = hmac.new(
            self.secret_key.encode(),
            data.encode(),
            hashlib.sha256
        ).hexdigest()
        return signature
    
    def send_message(self, target, message):
        """Send authenticated message"""
        try:
            # Validate inputs
            target = self.validate_target(target)
            message = self.sanitize_message(message)
            
            # Create signature
            signature = self.sign_message(target, message)
            
            # Log attempt
            self.logger.info(f"Sending message from {self.agent_id} to {target}")
            
            # Send via tmux (would be replaced with secure channel in production)
            cmd = ['tmux', 'send-keys', '-t', target, f"[{self.agent_id}:{signature[:8]}] {message}"]
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
            
            if result.returncode != 0:
                raise RuntimeError(f"Failed to send message: {result.stderr}")
            
            # Send Enter key
            subprocess.run(['tmux', 'send-keys', '-t', target, 'Enter'], timeout=5)
            
            self.logger.info(f"Message sent successfully to {target}")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to send message: {e}")
            raise

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Send secure message to agent')
    parser.add_argument('target', help='Target window (session:window)')
    parser.add_argument('message', help='Message to send')
    parser.add_argument('--agent-id', default='orchestrator', help='Sender agent ID')
    parser.add_argument('--secret', required=True, help='Shared secret for signing')
    
    args = parser.parse_args()
    
    sender = SecureMessageSender(args.agent_id, args.secret)
    try:
        sender.send_message(args.target, args.message)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
```

### 3. Secure tmux_utils.py Replacement
```python
#!/usr/bin/env python3
# secure_tmux_utils.py - Secure tmux orchestration utilities

import subprocess
import json
import logging
import re
import secrets
from typing import List, Dict, Optional
from dataclasses import dataclass
from datetime import datetime
import shlex

@dataclass
class SecureWindow:
    session_name: str
    window_index: int
    window_name: str
    agent_token: Optional[str] = None
    permissions: List[str] = None

class SecureOrchestrator:
    def __init__(self, orchestrator_token: str):
        self.orchestrator_token = orchestrator_token
        self.logger = self._setup_logging()
        self.command_whitelist = self._load_command_whitelist()
        
    def _setup_logging(self):
        logger = logging.getLogger('secure_orchestrator')
        handler = logging.FileHandler('/var/log/orchestrator/orchestrator.log')
        handler.setFormatter(logging.Formatter(
            '%(asctime)s - %(levelname)s - %(funcName)s - %(message)s'
        ))
        logger.addHandler(handler)
        logger.setLevel(logging.INFO)
        return logger
    
    def _load_command_whitelist(self):
        """Load allowed commands from configuration"""
        return {
            'status': re.compile(r'^(status|health|check)$'),
            'git': re.compile(r'^git (status|log|diff)$'),
            'info': re.compile(r'^(pwd|whoami|date)$')
        }
    
    def validate_session_name(self, name: str) -> bool:
        """Validate session name format"""
        return bool(re.match(r'^[a-zA-Z0-9_-]+$', name))
    
    def validate_command(self, command: str) -> bool:
        """Validate command against whitelist"""
        command = command.strip()
        for category, pattern in self.command_whitelist.items():
            if pattern.match(command):
                return True
        return False
    
    def get_secure_sessions(self) -> List[Dict]:
        """Get tmux sessions with security checks"""
        try:
            cmd = ["tmux", "list-sessions", "-F", "#{session_name}:#{session_attached}"]
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                check=True,
                timeout=5
            )
            
            sessions = []
            for line in result.stdout.strip().split('\n'):
                if not line:
                    continue
                    
                session_name, attached = line.split(':')
                if self.validate_session_name(session_name):
                    sessions.append({
                        'name': session_name,
                        'attached': attached == '1'
                    })
                else:
                    self.logger.warning(f"Invalid session name detected: {session_name}")
            
            return sessions
            
        except subprocess.TimeoutExpired:
            self.logger.error("Timeout getting tmux sessions")
            raise
        except subprocess.CalledProcessError as e:
            self.logger.error(f"Error getting sessions: {e}")
            raise
    
    def send_secure_command(self, session: str, window: int, command: str, 
                          agent_token: str) -> bool:
        """Send command with validation and authentication"""
        
        # Validate inputs
        if not self.validate_session_name(session):
            raise ValueError("Invalid session name")
        
        if not isinstance(window, int) or window < 0:
            raise ValueError("Invalid window index")
        
        if not self.validate_command(command):
            raise ValueError(f"Command not allowed: {command}")
        
        # Verify agent token (would check against secure store in production)
        if not self._verify_agent_token(agent_token):
            self.logger.error(f"Invalid agent token for {session}:{window}")
            raise PermissionError("Invalid agent token")
        
        # Log the attempt
        self.logger.info(f"Sending command to {session}:{window}: {command[:50]}...")
        
        try:
            # Use shlex to properly escape the command
            escaped_command = shlex.quote(command)
            cmd = ["tmux", "send-keys", "-t", f"{session}:{window}", escaped_command]
            
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                check=True,
                timeout=5
            )
            
            # Send Enter key
            subprocess.run(
                ["tmux", "send-keys", "-t", f"{session}:{window}", "Enter"],
                timeout=5
            )
            
            self.logger.info(f"Command sent successfully to {session}:{window}")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to send command: {e}")
            raise
    
    def _verify_agent_token(self, token: str) -> bool:
        """Verify agent token (simplified for demo)"""
        # In production, check against secure token store
        return len(token) == 64 and token.isalnum()
    
    def create_secure_snapshot(self) -> Dict:
        """Create security-aware snapshot"""
        snapshot = {
            'timestamp': datetime.utcnow().isoformat(),
            'orchestrator_id': self.orchestrator_token[:8],  # Show only prefix
            'sessions': []
        }
        
        sessions = self.get_secure_sessions()
        for session in sessions:
            # Only capture limited, sanitized information
            session_data = {
                'name': session['name'],
                'attached': session['attached'],
                'window_count': self._get_window_count(session['name'])
            }
            snapshot['sessions'].append(session_data)
        
        return snapshot
    
    def _get_window_count(self, session_name: str) -> int:
        """Safely get window count for session"""
        try:
            cmd = ["tmux", "list-windows", "-t", session_name, "-F", "#{window_index}"]
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                check=True,
                timeout=5
            )
            return len(result.stdout.strip().split('\n'))
        except:
            return 0

# Example usage with security
if __name__ == "__main__":
    # Generate secure token for orchestrator
    orchestrator_token = secrets.token_urlsafe(48)
    
    orchestrator = SecureOrchestrator(orchestrator_token)
    
    # Example: Send secure command
    try:
        agent_token = secrets.token_urlsafe(48)
        orchestrator.send_secure_command(
            session="project-1",
            window=0,
            command="git status",
            agent_token=agent_token
        )
    except (ValueError, PermissionError) as e:
        print(f"Security error: {e}")
```

## Deployment Security Checklist

Before deploying even with security improvements:

- [ ] Run as dedicated non-root user
- [ ] Apply SELinux/AppArmor policies
- [ ] Configure firewall rules
- [ ] Enable audit logging
- [ ] Set up intrusion detection
- [ ] Implement rate limiting
- [ ] Configure fail2ban rules
- [ ] Set up log rotation
- [ ] Enable TLS for all communication
- [ ] Implement secret rotation
- [ ] Set up monitoring alerts
- [ ] Create incident response plan
- [ ] Test security controls
- [ ] Perform penetration testing
- [ ] Document security procedures

## Final Recommendation

Even with all recommended security improvements, the fundamental architecture of using tmux for orchestration presents inherent security challenges. For defensive security work, consider using purpose-built orchestration platforms with security as a core design principle:

1. **Kubernetes**: Built-in RBAC, network policies, security contexts
2. **HashiCorp Nomad**: Integrated with Vault for secrets, strong isolation
3. **Apache Airflow**: DAG-based workflows with authentication
4. **Ansible Tower/AWX**: Role-based access, audit trails, encrypted communication

The Tmux-Orchestrator should be considered a proof-of-concept for development environments only, never for production or security-sensitive operations.