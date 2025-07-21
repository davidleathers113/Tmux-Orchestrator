# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
The Tmux Orchestrator is an AI-powered session management system where Claude acts as the orchestrator for multiple Claude agents across tmux sessions, managing codebases and keeping development moving forward 24/7.

## 🔐 CRITICAL SECURITY NOTICE
**MANDATORY**: All agents MUST follow security protocols. See:
- `@docs/security/CLAUDE.md` - Complete security analysis and protocols
- Never expose API keys, tokens, or credentials
- Validate all inputs before processing
- Use secure communication channels only

## Quick Start Commands

### Essential Scripts
```bash
# Schedule tasks with notes (ALWAYS verify target window first)
./schedule_with_note.sh <minutes> "<note>" <target_window>

# Send messages to Claude agents (NEVER use manual tmux send-keys)
./send-claude-message.sh <session:window> "message"

# Monitor system status
python3 tmux_utils.py
```

### Orchestrator Startup Check
```bash
# MANDATORY on every orchestrator start/restart
CURRENT_WINDOW=$(tmux display-message -p "#{session_name}:#{window_index}")
./schedule_with_note.sh 1 "Test schedule for $CURRENT_WINDOW" "$CURRENT_WINDOW"
```

## 🚨 CRITICAL: Starting Agents as Orchestrator

### The Orchestrator's Active Role
As an orchestrator, you must ACTIVELY START agents. The scheduling system only sends reminders - it does NOT automatically start agents!

### Starting an Agent Workflow
```bash
# 1. First, start Claude in the agent window
./send-claude-message.sh "session:window" "claude"

# 2. Wait 5 seconds for Claude to initialize
sleep 5

# 3. Send the agent their task
./send-claude-message.sh "session:window" "You are the [role] agent. Please read agent-prompts/[agent]-agent.md and complete your specification tasks."
```

### Using the PM Oversight Command
```bash
# CORRECT syntax (no project: prefix!)
/pm-oversight agent-session SPEC: ~/project-spec.md

# This gives you project management capabilities:
# - Regular check-ins with agents
# - Monitor progress and quality
# - Ensure spec compliance
# - Track git commits
```

### Common Orchestrator Mistakes to Avoid
1. **❌ Waiting for scheduled agents to start themselves** - Schedules are just reminders!
2. **❌ Using wrong command syntax** - It's `/pm-oversight` NOT `/project:pm-oversight`
3. **❌ Not actively starting agents** - You must send "claude" then the task
4. **❌ Assuming one orchestrator manages multiple projects** - Each project needs its own

### Orchestrator Checklist
- [ ] Started all agent windows with Claude
- [ ] Sent each agent their specific task
- [ ] Activated PM oversight with correct syntax
- [ ] Set up monitoring schedule
- [ ] Verified agents are working (check with tmux capture-pane)

### See Also
- `.claude/commands/README.md` - Documentation of available commands
- `docs/ORCHESTRATOR_POSTMORTEM.md` - Lessons from DCE failure

## Project Structure

```
Tmux-Orchestrator/
├── adapted-scripts/      # Production-ready secure scripts
├── analysis-reports/     # Security and architecture research
├── docs/
│   ├── agent-deliverables/  # Orchestration patterns
│   ├── security/            # Security analyses
│   └── legacy/              # Historical documentation
├── Examples/             # Visual workflow demonstrations
└── ORIGINAL-CLAUDE.md    # Complete historical knowledge base
```

## Navigation Guide

### For Script Usage
- `@adapted-scripts/CLAUDE.md` - Secure script implementations

### For Security
- `@docs/security/CLAUDE.md` - Comprehensive security analysis
- `@analysis-reports/CLAUDE.md` - Research findings

### For Orchestration Patterns
- `@docs/agent-deliverables/CLAUDE.md` - Core patterns and templates
- `@Examples/CLAUDE.md` - Visual demonstrations

### For Deep Knowledge
- `@ORIGINAL-CLAUDE.md` - Complete historical context and lessons learned

## Core Principles

1. **Security First**: All operations must follow security protocols
2. **Git Discipline**: Commit every 30 minutes, meaningful messages
3. **Communication**: Use send-claude-message.sh exclusively
4. **Quality Standards**: No shortcuts, comprehensive testing
5. **Documentation**: Keep logs, update registry, maintain clarity

## Critical Reminders

- **NEVER** use regex for any purpose (security requirement)
- **ALWAYS** verify window existence before scheduling
- **ALWAYS** use absolute paths in tmux commands
- **NEVER** leave work uncommitted for >1 hour
- **ALWAYS** check outputs with `tmux capture-pane`

---

For complete documentation, see `@ORIGINAL-CLAUDE.md`
For security protocols, see `@docs/security/CLAUDE.md`