# Tmux Orchestrator - Adapted Scripts

## Overview

The adapted scripts provide a secure, production-ready version of the Tmux Orchestrator system. These scripts have been enhanced with comprehensive security measures, input validation, and audit logging capabilities.

## Purpose

The original scripts were designed for rapid prototyping and demonstration. The adapted versions:
- Implement strict input validation and sanitization
- Add comprehensive logging and audit trails
- Enforce security boundaries and access controls
- Provide better error handling and recovery
- Support configuration-based customization
- Include rate limiting and resource management

## Security Improvements

### 1. Input Validation
- All user inputs are validated against whitelists
- Command injection prevention through proper escaping
- Path traversal protection
- Buffer overflow prevention

### 2. Access Control
- Whitelist-based command execution
- Session-level access restrictions
- Process isolation and sandboxing
- Resource usage limits

### 3. Audit Logging
- All commands are logged with timestamps
- User actions are tracked
- Error conditions are recorded
- Log rotation and retention policies

### 4. Safe Defaults
- Dry-run mode available
- Confirmation prompts for dangerous operations
- Timeouts for all operations
- Graceful error handling

## Configuration

1. Copy the template configuration:
   ```bash
   cp config/orchestrator.conf.template config/orchestrator.conf
   ```

2. Edit `config/orchestrator.conf` with your settings:
   - Set `ORCHESTRATOR_HOME` to your installation directory
   - Configure `ALLOWED_COMMANDS` with permitted commands
   - Adjust security settings as needed
   - Set appropriate log retention policies

3. Source the configuration in your scripts:
   ```bash
   source /path/to/adapted-scripts/config/orchestrator.conf
   ```

## Directory Structure

```
adapted-scripts/
├── config/
│   ├── orchestrator.conf.template  # Configuration template
│   └── orchestrator.conf          # Your configuration (not in git)
├── logs/
│   ├── audit.log                  # Command audit log
│   ├── error.log                  # Error log
│   ├── schedule-reminder.log      # Reminder scheduler log
│   └── simple-reminder.log        # Simple reminder system log
├── docs/
│   ├── security.md                # Security documentation
│   └── migration-notes.md         # Migration guide from original scripts
├── tests/
│   └── test-schedule-reminder.sh  # Test suite for reminder scripts
├── reminders/                     # Reminder storage directory (created at runtime)
├── common.sh                      # Shared functions library
├── schedule-reminder.sh           # Safe reminder scheduler using 'at' command
├── simple-reminder.sh             # Alternative reminder system (no 'at' required)
├── send-claude-message-secure.sh  # Secure tmux message sender
└── setup.sh                       # Setup and dependency checker
```

## Usage Instructions

### Basic Usage

1. **Sending Messages Securely**:
   ```bash
   ./send-claude-message-secure.sh "session:0" "Your message"
   ```

2. **Scheduling Reminders (with 'at' command)**:
   ```bash
   # Schedule a file reminder (default)
   ./schedule-reminder.sh 30 "Check deployment status"
   
   # Schedule a desktop notification
   ./schedule-reminder.sh 15 "Take a break" display
   
   # Schedule a log entry
   ./schedule-reminder.sh 60 "Review pull requests" log
   ```

3. **Simple Reminder System (no 'at' required)**:
   ```bash
   # Add a reminder
   ./simple-reminder.sh add 30 "Check deployment"
   
   # List pending reminders
   ./simple-reminder.sh list
   
   # Check for due reminders
   ./simple-reminder.sh check
   
   # Clear expired reminders
   ./simple-reminder.sh clear
   ```

### Advanced Features

- **Dry Run Mode**: Test commands without execution
  ```bash
  DRY_RUN=true ./send-message.sh -s test -w 0 -m "Test message"
  ```

- **Audit Trail**: View command history
  ```bash
  tail -f logs/audit.log
  ```

- **Rate Limiting**: Automatic throttling of rapid commands

## Migration Guide

To migrate from the original scripts:

1. **schedule_with_note.sh → schedule-reminder.sh**:
   - Replace tmux window targets with reminder types (file/log/display)
   - No longer executes tmux commands or Python scripts
   - Uses system 'at' command for proper scheduling
   - Example: `./schedule_with_note.sh 30 "Check" "tmux:0"` → `./schedule-reminder.sh 30 "Check" display`

2. **If 'at' command is unavailable**:
   - Use `simple-reminder.sh` as an alternative
   - Set up cron for automation: `./simple-reminder.sh cron`

3. **Security improvements**:
   - All inputs are validated (no shell injection)
   - No background processes with nohup
   - No hardcoded paths
   - Comprehensive logging

See `docs/migration-notes.md` for detailed migration instructions.

## Security Best Practices

1. **Principle of Least Privilege**: Only allow necessary commands
2. **Regular Audits**: Review logs weekly
3. **Update Whitelists**: Remove unused commands
4. **Monitor Resources**: Check for unusual activity
5. **Backup Configuration**: Keep secure copies of your config

## Troubleshooting

- Check `logs/error.log` for detailed error messages
- Verify configuration syntax with `./validate-config.sh`
- Use debug mode for verbose output: `DEBUG=true ./script.sh`
- Ensure proper permissions on log directory

## Contributing

When adding new adapted scripts:
1. Use `common.sh` for shared functionality
2. Implement all security checks
3. Add comprehensive logging
4. Update documentation
5. Include unit tests

## License

Same as the parent Tmux Orchestrator project.