# adapted-scripts/config/CLAUDE.md - Configuration Management

## Overview
This directory contains configuration templates and examples for the secure scheduling system. All configuration files follow strict validation rules to prevent injection attacks.

## Configuration Files

### orchestrator.conf.template
Master configuration template with:
- Default time limits and constraints
- Logging configuration
- Security settings
- Path definitions

### Creating Your Configuration
```bash
# Copy template
cp orchestrator.conf.template orchestrator.conf

# Edit with your settings
vim orchestrator.conf

# Verify permissions (must be readable only by owner)
chmod 600 orchestrator.conf
```

## Configuration Parameters

### Time Limits
```bash
# Maximum scheduling time (minutes)
MAX_SCHEDULE_TIME=10080  # 7 days

# Minimum scheduling time (minutes)
MIN_SCHEDULE_TIME=1

# Default reminder window
DEFAULT_TARGET_WINDOW="tmux-orc:0"
```

### Security Settings
```bash
# Enable strict mode
STRICT_MODE=true

# Allowed target patterns (regex)
ALLOWED_TARGETS="^[a-zA-Z0-9_-]+:[0-9]+(\.[0-9]+)?$"

# Maximum message length
MAX_MESSAGE_LENGTH=1000
```

### Logging Configuration
```bash
# Log directory
LOG_DIR="${HOME}/.tmux-orchestrator/logs"

# Log retention (days)
LOG_RETENTION=7

# Debug logging
DEBUG_ENABLED=false
```

## Validation Rules

### Target Window Format
- Must match: `session:window` or `session:window.pane`
- Session names: alphanumeric, hyphens, underscores
- Window numbers: 0-99
- Pane numbers: 0-9

### Time Values
- Must be positive integers
- Range: 1-10080 (1 minute to 7 days)
- No decimal values allowed

### Message Content
- Maximum 1000 characters
- No shell metacharacters in certain contexts
- UTF-8 encoding required

## Security Considerations

1. **Never commit orchestrator.conf** - Add to .gitignore
2. **Restrict file permissions** - Use 600 for config files
3. **Validate all inputs** - Even from config files
4. **No shell expansion** - Treat all values as literals
5. **Regular audits** - Review config for suspicious changes

## Environment Variables

Override config file settings:
```bash
# Override log directory
ORCHESTRATOR_LOG_DIR=/tmp/orchestrator ./schedule-reminder.sh 10 "Test"

# Enable debug mode
ORCHESTRATOR_DEBUG=1 ./schedule-reminder.sh 5 "Debug test"
```

## Example Configurations

### Development Setup
```bash
DEBUG_ENABLED=true
LOG_RETENTION=1
MAX_SCHEDULE_TIME=1440  # 24 hours max
```

### Production Setup
```bash
DEBUG_ENABLED=false
LOG_RETENTION=30
STRICT_MODE=true
AUDIT_ENABLED=true
```

## Troubleshooting

### Config Not Loading
1. Check file permissions (must be readable)
2. Verify file path
3. Check for syntax errors
4. Run with debug mode enabled

### Validation Failures
1. Review parameter constraints
2. Check regex patterns
3. Verify character encoding
4. Test with simple values first