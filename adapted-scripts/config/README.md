# Tmux Orchestrator Configuration Guide

## Overview

The `orchestrator.conf` file contains all configuration settings for the Tmux Orchestrator. This file controls security settings, paths, resource limits, and operational parameters.

## Critical Security Settings

### Command Whitelisting

**`ALLOWED_COMMANDS`** - Array of commands that can be executed through the orchestrator.

```bash
ALLOWED_COMMANDS=(
    "ls"      # List directory contents
    "pwd"     # Print working directory
    "echo"    # Output text
    # ... more commands
)
```

**Security Implications:**
- Only whitelisted commands can be executed
- Prevents arbitrary code execution
- Should only include necessary, safe commands
- NEVER include: `eval`, `exec`, `source`, `sudo`, `rm -rf`, etc.

### Path Restrictions

**`ORCHESTRATOR_HOME`** - Base directory for the orchestrator
- Must be an absolute path
- Should be owned by the user running the orchestrator
- Contains all orchestrator scripts and configurations

**`PROJECT_DIR`** - Directory where projects/sessions are managed
- Should be separate from system directories
- User must have read/write permissions

**`ALLOWED_FILE_PATHS`** - Restricts file operations to specific directories
```bash
ALLOWED_FILE_PATHS=(
    "${ORCHESTRATOR_HOME}"
    "${PROJECT_DIR}"
    "${LOG_DIR}"
    "${TEMP_DIR}"
)
```

### Execution Controls

**`DRY_RUN_DEFAULT`** - When `true`, commands are logged but not executed
- Set to `true` for initial testing
- Set to `false` only after verifying configuration

**`ALLOW_EXTERNAL_SCRIPTS`** - Controls execution of scripts outside the orchestrator
- **ALWAYS keep this `false`** in production
- Prevents execution of untrusted scripts

**`BLOCK_SUDO_COMMANDS`** - Prevents privilege escalation
- Should always be `true`
- Blocks any command containing `sudo`, `su`, `doas`

## Resource Limits

### Process Management

**`MAX_BACKGROUND_PROCESSES`** - Maximum concurrent background processes
- Default: 3 (conservative for testing)
- Increase cautiously based on system resources

**`PROCESS_TIMEOUT`** - Maximum execution time for processes (seconds)
- Default: 1800 (30 minutes)
- Prevents runaway processes

### Memory and CPU

**`MAX_MEMORY_MB`** - Memory limit per process
- Default: 512 MB
- Adjust based on system resources

**`MAX_CPU_PERCENT`** - CPU usage limit
- Default: 50%
- Prevents system overload

### Rate Limiting

**`MAX_COMMANDS_PER_MINUTE`** - Command execution rate limit
- Default: 20
- Prevents abuse and system overload

## Security Features

### Audit Logging

**`AUDIT_LOGGING`** - Enables command logging
- Should always be `true`
- Logs all executed commands with timestamps
- Essential for security monitoring

**`SECURITY_AUDIT_ENABLED`** - Enhanced security logging
- Logs security-relevant events
- Includes failed authentication, blocked commands

### Validation

**`VALIDATE_SESSIONS`** - Verifies tmux session exists before sending commands
- Prevents commands being sent to wrong context

**`VALIDATE_COMMANDS`** - Basic syntax checking before execution
- Catches obvious errors
- Prevents some injection attempts

**`ENABLE_SANITIZATION`** - Sanitizes command inputs
- Removes dangerous characters
- Prevents command injection

### Environment Protection

**`SANITIZE_ENV_VARS`** - Cleans environment variables
- Removes potentially dangerous variables

**`BLOCKED_ENV_VARS`** - List of forbidden environment variables
```bash
BLOCKED_ENV_VARS=(
    "LD_PRELOAD"              # Prevents library injection (Linux)
    "DYLD_INSERT_LIBRARIES"   # Prevents library injection (macOS)
    # ... more
)
```

## Customization Guide

### For Different Environments

1. **Development Environment:**
   ```bash
   DRY_RUN_DEFAULT=false
   DEBUG=true
   MAX_BACKGROUND_PROCESSES=5
   ```

2. **Production Environment:**
   ```bash
   DRY_RUN_DEFAULT=false
   DEBUG=false
   AUDIT_LOGGING=true
   SECURITY_AUDIT_ENABLED=true
   ```

3. **Restricted/Shared Environment:**
   ```bash
   ALLOWED_SESSIONS="project1,project2"
   ALLOWED_USERS=("user1" "user2")
   ALLOW_EXTERNAL_SCRIPTS=false
   BLOCK_SUDO_COMMANDS=true
   ```

### Adding New Commands

To safely add a new command to the whitelist:

1. Verify the command is necessary
2. Ensure it cannot be used for privilege escalation
3. Test in dry-run mode first
4. Add to `ALLOWED_COMMANDS` array
5. Document why it was added

Example:
```bash
# Safe to add - read-only file inspection
ALLOWED_COMMANDS+=("file")

# UNSAFE - can execute arbitrary code
# ALLOWED_COMMANDS+=("python")  # DON'T DO THIS
```

### Path Configuration

When adapting for a new system:

1. Update paths to use appropriate directories:
   ```bash
   # macOS example
   ORCHESTRATOR_HOME="/Users/${USER}/tmux-orchestrator"
   PROJECT_DIR="/Users/${USER}/projects"
   
   # Linux example
   ORCHESTRATOR_HOME="/home/${USER}/tmux-orchestrator"
   PROJECT_DIR="/home/${USER}/projects"
   ```

2. Ensure directories exist and have proper permissions:
   ```bash
   mkdir -p "${LOG_DIR}" "${TEMP_DIR}" "${BACKUP_DIR}"
   chmod 750 "${LOG_DIR}"  # Owner: rwx, Group: r-x, Others: none
   ```

## Security Best Practices

1. **Principle of Least Privilege**
   - Only enable features you need
   - Only whitelist necessary commands
   - Use most restrictive settings possible

2. **Regular Audits**
   - Review logs regularly
   - Check for unauthorized access attempts
   - Monitor resource usage

3. **Updates and Patches**
   - Keep the orchestrator updated
   - Review configuration after updates
   - Test changes in isolated environment first

4. **Backup Configuration**
   - Keep backups of working configurations
   - Document all changes
   - Use version control for config files

## Troubleshooting

### Common Issues

1. **Commands not executing:**
   - Check if `DRY_RUN_DEFAULT=true`
   - Verify command is in `ALLOWED_COMMANDS`
   - Check audit logs for blocked commands

2. **Permission errors:**
   - Verify directory permissions
   - Check file ownership
   - Ensure user has tmux access

3. **Resource limits:**
   - Check process/memory limits
   - Review rate limiting settings
   - Monitor system resources

### Debug Mode

Enable debug mode for detailed logging:
```bash
DEBUG=true
```

Check logs in:
- `${LOG_DIR}/orchestrator.log` - General logs
- `${AUDIT_LOG}` - Security audit logs
- `${HISTORY_FILE}` - Command history

## WARNING: Never Do This

1. **Never disable security features in production:**
   ```bash
   # DANGEROUS - Don't do this!
   ENABLE_SANITIZATION=false
   ALLOW_EXTERNAL_SCRIPTS=true
   BLOCK_SUDO_COMMANDS=false
   ```

2. **Never whitelist dangerous commands:**
   ```bash
   # DANGEROUS - These allow arbitrary code execution
   ALLOWED_COMMANDS+=("eval" "exec" "python" "bash" "sh")
   ```

3. **Never store sensitive data in config:**
   ```bash
   # WRONG - Use environment variables or secure key storage
   CLAUDE_API_KEY="sk-..." 
   ```

4. **Never use overly permissive paths:**
   ```bash
   # DANGEROUS - Allows access to system files
   ALLOWED_FILE_PATHS=("/")
   ```

## Environment Variables

The orchestrator respects these environment variables:

- `TMUX_ORCHESTRATOR_HOME` - Override `ORCHESTRATOR_HOME`
- `TMUX_ORCHESTRATOR_DEBUG` - Override `DEBUG` setting
- `TMUX_ORCHESTRATOR_DRY_RUN` - Override `DRY_RUN_DEFAULT`
- `TMPDIR` - System temporary directory (used for `TEMP_DIR`)

## Configuration Validation

Before using in production:

1. Run configuration check:
   ```bash
   ./validate_config.sh orchestrator.conf
   ```

2. Test in dry-run mode:
   ```bash
   DRY_RUN_DEFAULT=true ./orchestrator.sh test
   ```

3. Review audit logs after testing

4. Gradually enable features as needed

## Support and Documentation

- Configuration template: `orchestrator.conf.template`
- Security analysis: `../../SECURITY_ANALYSIS.md`
- Hardcoded paths: `../../HARDCODED_PATHS.md`
- Main documentation: `../../README.md`

Remember: Security is not optional. When in doubt, choose the more restrictive option.