# adapted-scripts/CLAUDE.md - Production-Ready Scheduling System

## Overview
This directory contains the secure, production-ready scripts that have replaced the vulnerable legacy implementations. All scripts enforce strict security protocols and follow defensive programming practices.

## Script Index

### Core Scheduling Scripts
- **schedule-reminder.sh** - Main scheduling interface with comprehensive validation
- **simple-reminder.sh** - Lightweight scheduler for basic reminders
- **send-claude-message-secure.sh** - Secure message delivery to Claude agents

### Support Scripts
- **common.sh** - Shared utilities and validation functions
- **setup.sh** - Environment setup and dependency verification

## Security Requirements Enforced

### Input Validation
- All user inputs sanitized through strict validation
- No direct command execution without validation
- Time inputs limited to reasonable ranges (1-10080 minutes)
- Target specifications validated against whitelist patterns

### Process Isolation
- Background processes properly detached
- No shell expansion vulnerabilities
- Secure handling of process IDs and cleanup

### Error Handling
- Comprehensive error checking at every stage
- Clear error messages without exposing internals
- Graceful degradation on failures

## Configuration

### Required Files
```bash
# Copy template and customize
cp config/orchestrator.conf.template config/orchestrator.conf

# Set proper permissions
chmod 600 config/orchestrator.conf
```

### Environment Variables
- `TMUX_ORCHESTRATOR_HOME` - Base directory (auto-detected)
- `ORCHESTRATOR_LOG_DIR` - Log storage location
- `ORCHESTRATOR_DEBUG` - Enable debug output

## Usage Patterns

### Basic Scheduling
```bash
# Schedule a reminder in 30 minutes
./schedule-reminder.sh 30 "Check deployment status"

# Schedule for specific window
./schedule-reminder.sh 15 "Review PR comments" "dev-session:2"
```

### Claude Agent Messaging
```bash
# Send secure message to agent
./send-claude-message-secure.sh "project:0" "Please run the test suite"

# With complex messages
./send-claude-message-secure.sh "backend:1" "$(cat instructions.txt)"
```

### Debug Mode
```bash
# Enable debug output
ORCHESTRATOR_DEBUG=1 ./schedule-reminder.sh 5 "Debug test"
```

## Migration Guide

For migrating from legacy scripts, see:
- @./docs/migration-notes.md - Detailed migration instructions
- @./config/orchestrator.conf.template - Configuration template

## Testing

Run the test suite before deployment:
```bash
cd tests/
./run-tests.sh
```

## Best Practices

1. **Always validate inputs** - Never trust user-provided data
2. **Use configuration files** - Don't hardcode values
3. **Check dependencies** - Ensure required tools are available
4. **Log appropriately** - Balance debugging needs with security
5. **Test thoroughly** - Run tests after any modifications

## Error Codes

- 0: Success
- 1: General error
- 2: Invalid arguments
- 3: Missing dependencies
- 4: Configuration error
- 5: Permission denied

## Support

For issues or questions:
1. Check logs in `$ORCHESTRATOR_LOG_DIR`
2. Run with `ORCHESTRATOR_DEBUG=1` for verbose output
3. Verify configuration in `config/orchestrator.conf`
4. Run test suite to identify problems