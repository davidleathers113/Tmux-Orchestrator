# 🚨 SECURITY - MANDATORY READING 🚨

## Critical Vulnerabilities - MUST AVOID

### From SECURITY_AUDIT_SUMMARY.md:
1. **Command Injection**: NEVER pass user input directly to shell commands
2. **Path Traversal**: ALWAYS validate file paths before access
3. **Exposed Credentials**: Use environment variables, not hardcoded values
4. **Insecure Defaults**: Change ALL default configurations

### From SEND_CLAUDE_MESSAGE_SECURITY.md:
- **Vulnerability**: Special characters in messages can break out of tmux
- **Mitigation**: send-claude-message.sh handles escaping - ALWAYS use it
- **Risk**: Direct tmux send-keys is DANGEROUS with untrusted input

## Defensive Practices - MANDATORY

### Input Validation
```bash
# BAD: Direct execution
tmux send-keys -t "$TARGET" "$USER_INPUT" # NEVER DO THIS

# GOOD: Use validated script
./send-claude-message.sh "$TARGET" "$MESSAGE"
```

### Authentication & Access
- No default passwords
- Session tokens expire in 15 minutes
- Audit all privileged operations
- Never store credentials in logs

### From SECURITY_RECOMMENDATIONS.md:
1. **Principle of Least Privilege**: Agents get minimal permissions
2. **Defense in Depth**: Multiple security layers
3. **Audit Everything**: Log all orchestrator actions
4. **Fail Secure**: Errors should deny access, not grant it

## Emergency Response
If security breach suspected:
1. Kill all tmux sessions immediately
2. Rotate all credentials
3. Audit recent commands: `history | grep -E 'tmux|claude'`
4. Check for unauthorized schedule jobs