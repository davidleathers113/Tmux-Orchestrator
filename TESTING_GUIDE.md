# Tmux Orchestrator Testing Guide

## Prerequisites

1. **Install tmux** (if not already installed):
   ```bash
   brew install tmux
   ```

2. **Navigate to the project directory**:
   ```bash
   cd /Users/davidleathers/projects/Tmux-Orchestrator
   ```

## Quick Start Testing

### 1. Run the Setup Script
```bash
./test-setup.sh
```

This will:
- Clean up any existing test sessions
- Create test-frontend and test-backend sessions
- Create an orchestrator session if needed
- Display all active sessions

### 2. Attach to the Orchestrator
```bash
tmux attach -t orchestrator
```

### 3. Start PM Oversight Mode

Once in the orchestrator session, start Claude and give it the PM oversight command:

```
/pm-oversight test-frontend and test-backend SPEC: ~/tmux-test-spec.md
```

### 4. Monitor Activity

In a separate terminal, run:
```bash
./check-status.sh
```

This shows:
- All tmux sessions
- Scheduled tasks (systemd/at)
- Background processes
- Recent activity from all sessions

## Expected Behavior

### Initial Setup
1. Claude reads the spec file
2. Creates a management plan
3. Schedules first check-in (5 minutes)

### During Operation
1. Claude schedules regular check-ins using `schedule_with_note.sh`
2. Sends messages between sessions using `send-claude-message.sh`
3. Monitors both test sessions
4. Reports status updates

### Success Indicators
- ✅ "Scheduled successfully" messages appear
- ✅ Check-ins occur at specified intervals
- ✅ Messages appear in target windows
- ✅ No error messages in output

## Testing Individual Components

### Test Scheduling
```bash
./schedule_with_note.sh 1 "Test reminder" "orchestrator:0"
```
Wait 1 minute and check if reminder appears.

### Test Messaging
```bash
./send-claude-message.sh "test-frontend:0" "Hello from orchestrator"
```
Check if message appears in frontend window.

### Test Monitoring
```bash
python3 tmux_utils.py
```
Should display JSON with all session information.

## Troubleshooting

### Common Issues

1. **"tmux: command not found"**
   - Install tmux: `brew install tmux`

2. **"Session not found"**
   - Run `./test-setup.sh` to create sessions
   - Check sessions: `tmux list-sessions`

3. **Schedule not working**
   - Check if systemd is available: `command -v systemctl`
   - Check if at is available: `command -v at`
   - Look for background processes: `ps aux | grep schedule_with_note`

4. **Messages not appearing**
   - Verify target window exists: `tmux list-windows -t test-frontend`
   - Check script permissions: `ls -la send-claude-message.sh`

### Debug Commands

```bash
# View all tmux sessions and windows
tmux list-sessions
tmux list-windows -a

# Check specific window content
tmux capture-pane -t test-frontend:0 -p

# Monitor scheduling
watch -n 5 './check-status.sh'

# Check system logs
tail -f /var/log/system.log | grep -E "(schedule_with_note|send-claude-message)"
```

## Clean Up

To remove all test sessions:
```bash
tmux kill-session -t test-frontend
tmux kill-session -t test-backend
tmux kill-session -t orchestrator
```

## Advanced Testing

### Multiple Projects
Create additional spec files and sessions:
```bash
tmux new-session -s project-a -d
tmux new-session -s project-b -d
```

Then use:
```
/pm-oversight project-a and project-b SPEC: ~/project-ab-spec.md
```

### Long-Running Test
Modify the spec file to schedule check-ins every hour and let it run overnight to test stability.

### Error Injection
Test error handling by:
- Killing a session mid-operation
- Providing invalid window targets
- Creating very long messages

## Tips

1. **Use multiple terminals**: One for orchestrator, one for monitoring
2. **Check timestamps**: Verify scheduling accuracy
3. **Save logs**: `./check-status.sh > test-log-$(date +%Y%m%d-%H%M%S).txt`
4. **Be patient**: Some operations have built-in delays for safety

## Next Steps

Once basic testing is complete:
1. Try more complex orchestration patterns
2. Test with real project specifications
3. Monitor resource usage during long runs
4. Document any issues or improvements