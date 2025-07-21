# Tmux Orchestrator Knowledge Summary

## Overview
This document summarizes the key orchestration patterns and domain knowledge extracted from the original CLAUDE.md file created by Jason Edward for the Tmux Orchestrator project.

## Core Concept
The Tmux Orchestrator implements an AI-powered session management system where Claude acts as the orchestrator for multiple Claude agents across tmux sessions, managing codebases and enabling 24/7 development.

## 1. Agent System Architecture

### Hierarchical Structure
```
                    Orchestrator
                    /              \
            Project Manager    Project Manager
           /      |       \         |
    Developer    QA    DevOps   Developer
```

### Agent Roles
- **Orchestrator**: High-level oversight, deployment, architectural decisions
- **Project Manager**: Quality control, team coordination, progress tracking
- **Developer**: Implementation and technical decisions
- **QA Engineer**: Testing and verification
- **DevOps**: Infrastructure and deployment
- **Code Reviewer**: Security and best practices
- **Researcher**: Technology evaluation
- **Documentation Writer**: Technical documentation

## 2. Critical Git Discipline Rules

### Core Safety Practices
1. **Auto-commit every 30 minutes** - Prevents work loss
2. **Commit before task switches** - Never leave uncommitted changes
3. **Feature branch workflow** - Isolate work, tag stable versions
4. **Meaningful commit messages** - Describe the "why" not just "what"
5. **Never work >1 hour without committing** - Even WIP commits

### Git Emergency Recovery
```bash
git stash  # Save uncommitted changes
git reset --hard HEAD  # Return to last commit
git stash pop  # Restore if needed
```

## 3. Tmux Window Management Patterns

### Window Naming Conventions
- **Claude Agents**: `Claude-Frontend`, `Claude-Backend`, `Claude-Convex`
- **Dev Servers**: `NextJS-Dev`, `Frontend-Dev`, `Uvicorn-API`
- **Shells/Utilities**: `Backend-Shell`, `Frontend-Shell`
- **Services**: `Convex-Server`, `Orchestrator`
- **Temporary**: `TEMP-CodeReview`, `TEMP-BugFix`

### Project Startup Sequence
1. Find project in ~/Coding/
2. Create tmux session with project name
3. Set up standard windows (Claude-Agent, Shell, Dev-Server)
4. Brief the Claude agent with responsibilities
5. Agent detects project type and starts appropriate server
6. Agent checks GitHub issues for priorities
7. Orchestrator monitors progress

## 4. Communication Protocols

### Hub-and-Spoke Model
- Developers report to PM only
- PM aggregates and reports to Orchestrator
- Cross-functional communication through PM
- Emergency escalation directly to Orchestrator

### Message Templates
```
STATUS [AGENT_NAME] [TIMESTAMP]
Completed: 
- [Specific task 1]
- [Specific task 2]
Current: [What working on now]
Blocked: [Any blockers]
ETA: [Expected completion]
```

### Critical: Use send-claude-message.sh Script
```bash
# ALWAYS use this script for agent communication
./send-claude-message.sh <target> "message"

# NOT manual tmux send-keys commands
```

## 5. Critical Self-Scheduling Protocol

### Mandatory Startup Check
Every orchestrator MUST verify scheduling works:
```bash
CURRENT_WINDOW=$(tmux display-message -p "#{session_name}:#{window_index}")
./schedule_with_note.sh 1 "Test schedule" "$CURRENT_WINDOW"
```

### Why This Matters
- Ensures continuous oversight without gaps
- Prevents scheduling to wrong windows
- Enables orchestrator self-recovery

## 6. Quality Assurance Protocols

### PM Verification Checklist
- [ ] All code has tests
- [ ] Error handling is comprehensive
- [ ] Performance is acceptable
- [ ] Security best practices followed
- [ ] Documentation is updated
- [ ] No technical debt introduced

### Continuous Verification
1. Code review before any merge
2. Test coverage monitoring
3. Performance benchmarking
4. Security scanning
5. Documentation audits

## 7. Common Mistakes and Solutions

### Window Directory Issues
**Problem**: New windows inherit tmux start directory, not session directory
**Solution**: Always use `-c` flag when creating windows
```bash
tmux new-window -t session -n "name" -c "/correct/path"
```

### Command Verification
**Problem**: Assuming commands succeed without checking
**Solution**: Always capture and verify output
```bash
tmux send-keys -t session:window "command" Enter
sleep 2
tmux capture-pane -t session:window -p | tail -50
```

### Agent Communication Timing
**Problem**: Enter key sent too quickly after message
**Solution**: Use send-claude-message.sh script which handles timing

## 8. Agent Lifecycle Management

### Creating Agents
- Use descriptive window names
- Provide role-specific briefings
- Set correct working directories

### Ending Agents
1. Capture complete conversation logs
2. Create work summary
3. Document handoff notes
4. Close window properly

### Logging Structure
```
~/Coding/Tmux orchestrator/registry/
├── logs/            # Agent conversation logs
├── sessions.json    # Active session tracking
└── notes/           # Orchestrator notes and summaries
```

## 9. Anti-Patterns to Avoid

- ❌ **Meeting Hell**: Use async updates only
- ❌ **Endless Threads**: Max 3 exchanges, then escalate
- ❌ **Broadcast Storms**: No "FYI to all" messages
- ❌ **Micromanagement**: Trust agents to work
- ❌ **Quality Shortcuts**: Never compromise standards
- ❌ **Blind Scheduling**: Never schedule without verifying target window

## 10. Key Success Factors

1. **Strict Git Discipline**: Prevents catastrophic work loss
2. **Clear Communication**: Templates and structured messages
3. **Window Management**: Correct directories and naming
4. **Quality Focus**: PMs enforce high standards
5. **Automation**: Use scripts for complex operations
6. **Verification**: Always check, never assume
7. **Documentation**: Capture knowledge for future agents