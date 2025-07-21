# Safe Tmux Patterns for Multi-Agent Claude Coordination

## ⚠️ SECURITY WARNING

The Tmux-Orchestrator project contains **CRITICAL SECURITY VULNERABILITIES** including:
- Arbitrary command execution without validation
- No authentication or authorization mechanisms
- Uncontrolled process creation
- Command injection vulnerabilities

**DO NOT USE** the automation scripts (schedule_with_note.sh, send-claude-message.sh, tmux_utils.py) in any production or security-sensitive environment.

This appendix provides ONLY safe, manual patterns for coordinating multiple Claude instances.

## Safe Manual Tmux Navigation

### Basic Tmux Commands (Manual Use Only)
```bash
# Session management
tmux new-session -s project-name    # Create new session
tmux attach -t project-name          # Attach to existing session
tmux list-sessions                   # List all sessions
tmux kill-session -t project-name    # End a session

# Window management (within a session)
Ctrl+b c        # Create new window
Ctrl+b n        # Next window
Ctrl+b p        # Previous window
Ctrl+b [0-9]    # Switch to window number
Ctrl+b ,        # Rename current window
Ctrl+b &        # Kill current window (with confirmation)

# Pane management
Ctrl+b %        # Split vertically
Ctrl+b "        # Split horizontally
Ctrl+b arrow    # Move between panes
Ctrl+b x        # Kill current pane
```

### Safe Window Naming Convention
When organizing multiple Claude instances, use descriptive names:
```bash
# After creating a window, rename it
Ctrl+b ,
# Then type a descriptive name like:
# - Claude-Frontend
# - Claude-Backend
# - Claude-Testing
# - Dev-Server
# - Shell-Utils
```

## Manual Multi-Agent Coordination Patterns

### 1. Hub-and-Spoke Communication
Instead of automated messaging, use manual copy-paste between windows:

```
Orchestrator (You in window 0)
    |
    +-- Project Manager (window 1)
    |       |
    |       +-- Developer 1 (window 2)
    |       +-- Developer 2 (window 3)
    |
    +-- Project Manager 2 (window 4)
            |
            +-- Developer 3 (window 5)
```

**Manual Process:**
1. Read output from one Claude: `Ctrl+b [` then navigate and copy
2. Switch windows: `Ctrl+b 1` (or appropriate number)
3. Paste question/update to next Claude manually

### 2. Status Check Pattern
Create a manual routine for checking agent progress:

1. **Morning Review Checklist:**
   - [ ] Check each Claude window for overnight progress
   - [ ] Read any error messages in dev server windows
   - [ ] Note completed tasks
   - [ ] Identify blockers

2. **Manual Status Request Template:**
   ```
   STATUS UPDATE REQUEST:
   1. What have you completed since last check?
   2. What are you currently working on?
   3. Are there any blockers?
   4. ETA for current task?
   ```

3. **Copy this template and paste into each Claude window manually**

### 3. Safe Project Startup Sequence

**Manual Steps (No Automation):**

1. **Create Session:**
   ```bash
   tmux new-session -s project-name
   ```

2. **Set Up Windows Manually:**
   - Window 0: Your orchestrator view
   - Window 1: Claude agent
   - Window 2: Dev server
   - Window 3: Shell for manual commands

3. **Start Claude Manually:**
   - Switch to window 1: `Ctrl+b 1`
   - Type: `claude`
   - Wait for it to load
   - Paste initial instructions

4. **Manual Agent Briefing Template:**
   ```
   You are responsible for [project-name]. Your duties:
   1. Analyze the codebase structure
   2. Identify and work on priority tasks
   3. Follow git best practices (commit every 30 mins)
   4. Report progress when asked
   
   Start by examining the project files and package.json/requirements.txt
   ```

### 4. Cross-Window Intelligence Gathering

**Safe Manual Process:**
1. Use `Ctrl+b [` to enter copy mode in any window
2. Navigate with arrow keys to find relevant information
3. Copy text manually
4. Switch windows and share context by pasting

**What to Look For:**
- Error messages in dev server windows
- Progress updates from Claude agents
- Git status in shell windows
- Test results

### 5. Manual Scheduling Alternative

Instead of automated scheduling, use:

1. **Personal reminders** (phone, calendar, etc.) to check on agents
2. **Time-boxed work sessions** where you actively coordinate
3. **Manual check-in routine** every 30-60 minutes during active development

## Safe Git Practices (Manual Enforcement)

### Manual Git Safety Checklist
Every 30 minutes, manually check each developer window:

```bash
# Switch to developer window
Ctrl+b 2

# Ask Claude to show git status
"Please run: git status"

# If there are changes, ask Claude to commit
"Please commit your changes with a descriptive message"
```

### Manual Backup Commands
Periodically run these yourself in shell windows:
```bash
git branch backup-$(date +%Y%m%d-%H%M%S)
git push origin --all
```

## What NOT to Do

❌ **Never create scripts** that automatically send commands to tmux sessions
❌ **Never use nohup** or background processes for scheduling
❌ **Never pipe user input** directly to tmux send-keys
❌ **Never store credentials** in tmux session names or commands
❌ **Never create "automation helpers"** that bypass manual verification

## Safe Alternatives for Automation Needs

If you need actual automation for multi-agent coordination:

1. **Use established tools:**
   - GitHub Actions for CI/CD
   - Kubernetes Jobs for isolated task execution
   - Ansible with proper authentication
   - Jenkins with security plugins

2. **For Claude coordination specifically:**
   - Use the official Claude API with proper authentication
   - Implement rate limiting and access controls
   - Log all API calls for audit trails
   - Never pass raw user input to API calls

## Summary

The Tmux-Orchestrator's concept of coordinating multiple Claude instances has merit, but the implementation has critical security flaws. Use these manual patterns for safe multi-agent coordination:

1. **Manual tmux navigation** - No automated sending of commands
2. **Copy-paste communication** - Human verification of all messages
3. **Personal scheduling** - Use external reminders, not shell scripts
4. **Direct supervision** - Always maintain human oversight
5. **Established tools** - Use proper DevOps tools for actual automation needs

Remember: In defensive security, manual verification and human oversight are features, not bugs. The extra effort ensures commands are intentional and validated.