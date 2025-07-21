# Agent Deliverables - Quick Reference

## Core Orchestration Patterns

### Agent Deployment
```bash
# Create session and deploy agent
tmux new-session -d -s project-name -c "/path/to/project"
tmux rename-window -t project-name:0 "Claude-Agent"
tmux send-keys -t project-name:0 "claude" Enter
sleep 5
./send-claude-message.sh project-name:0 "Your briefing..."
```

### Project Manager Creation
```bash
# Add PM to existing session
tmux new-window -t session -n "Project-Manager" -c "$(tmux display-message -t session:0 -p '#{pane_current_path}')"
# Use send-claude-message.sh for briefing
```

## Essential Templates

- **[CLAUDE_TEMPLATES.md](./CLAUDE_TEMPLATES.md)**: Message formats, status updates
- **[TMUX_ORCHESTRATION_PATTERNS.md](./TMUX_ORCHESTRATION_PATTERNS.md)**: Window management, communication protocols
- **[SAFE_USAGE_PATTERNS.md](./SAFE_USAGE_PATTERNS.md)**: Best practices for agent coordination

## Key Summaries

### From ORCHESTRATION_KNOWLEDGE_SUMMARY.md:
- Always use hub-and-spoke communication
- PMs enforce git discipline (30-min commits)
- Verify window paths before deploying agents
- Use structured message templates

### From DEFENSIVE_SECURITY_PRACTICES.md:
- Never hardcode credentials
- Validate all inputs
- Use send-claude-message.sh exclusively
- Monitor for suspicious patterns

## Critical Reminders
1. **ALWAYS** check current window: `tmux display-message -p "#{session_name}:#{window_index}"`
2. **NEVER** send commands without checking window contents first
3. **USE** send-claude-message.sh for ALL agent communication