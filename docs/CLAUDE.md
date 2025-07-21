# Documentation Hub - Tmux Orchestrator

## Quick Navigation

### 📁 [Agent Deliverables](./agent-deliverables/CLAUDE.md)
Orchestration patterns, templates, and practical usage guides for managing Claude agents across tmux sessions.

### 🔒 [Security](./security/CLAUDE.md)
**CRITICAL**: Mandatory security warnings, vulnerability assessments, and defensive practices. Read before deployment.

### 📚 [Legacy](./legacy/CLAUDE.md)
Historical lessons, deprecated patterns, and migration guides. Learn from past mistakes.

## Essential Commands

```bash
# Send messages to agents (ALWAYS use this)
./send-claude-message.sh <target> "message"

# Schedule orchestrator checks
./schedule_with_note.sh 15 "PM oversight check" "$(tmux display-message -p '#{session_name}:#{window_index}')"

# Monitor agent status
tmux capture-pane -t session:window -p | tail -50
```

## Key Principles

1. **Git Discipline**: Commit every 30 minutes
2. **Communication**: Use hub-and-spoke model through PMs
3. **Security First**: Never expose sensitive data
4. **Quality Standards**: No compromises on testing