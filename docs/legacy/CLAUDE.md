# Legacy Documentation - Learn from History

## ⚠️ Deprecated Patterns - DO NOT USE

### From BROKEN_FUNCTIONALITY.md:
1. **Manual tmux send-keys**: Replaced by send-claude-message.sh
2. **Direct window indexing**: Use named windows instead
3. **Synchronous agent communication**: Use async hub-and-spoke
4. **Global broadcast messages**: Target specific agents only

### From HARDCODED_PATHS.md:
```bash
# ❌ OLD (BROKEN):
/Users/jasonedward/scripts/schedule.sh  # User-specific path

# ✅ NEW (CORRECT):
./schedule_with_note.sh  # Relative to orchestrator directory
$(tmux display-message -p '#{pane_current_path}')/script.sh  # Dynamic resolution
```

## Historical Lessons

### From LEARNINGS.md:
1. **Window Management Disasters**:
   - Creating windows without -c flag → wrong directory
   - Not checking window contents → duplicate commands
   - Assuming window order → targeting wrong agents

2. **Communication Failures**:
   - N² message explosion without PMs
   - Lost context from agent churn
   - Timing issues with manual send-keys

3. **Security Incidents**:
   - Hardcoded credentials in scripts
   - Command injection through messages
   - Exposed scheduling tokens

## Migration Guides

### Updating Old Scripts
```bash
# Find deprecated patterns
grep -r "tmux send-keys.*Enter" ./
grep -r "/Users/jasonedward" ./

# Replace with modern equivalents
# Use send-claude-message.sh
# Use relative paths
# Add input validation
```

### Modern Best Practices
1. Always use provided utility scripts
2. Implement structured communication
3. Maintain audit logs
4. Test in isolated sessions first

## Remember: Those who ignore history are doomed to repeat it!