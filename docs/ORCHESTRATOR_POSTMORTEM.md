# DCE Orchestrator Post-Mortem: Critical Lessons from a Failed Automation

**Date**: July 21, 2025  
**Author**: System Analysis Team  
**Project**: DCE Website Specification Orchestrator  
**Incident Duration**: July 18-21, 2025 (3 days)

## Executive Summary

On July 18, 2025, an automated orchestration system was deployed to coordinate seven AI agents for creating the Dependable Call Exchange (DCE) website specification. The system failed to start 6 out of 7 agents due to a combination of command syntax errors, incorrect assumptions about Claude's capabilities, and a fundamental misunderstanding between reminder systems and automation systems.

### Key Discovery
The `/pm-oversight` command exists as a legitimate Claude custom command in `.claude/commands/`, but was incorrectly invoked with a `project:` prefix, preventing the orchestrator from receiving proper project management instructions.

### Top 5 Lessons Learned
1. **Verify command syntax** - Custom Claude commands don't use category prefixes
2. **Automation must execute** - Reminder systems ≠ automation systems  
3. **Test shell commands** - Capital 'T' in "Time" caused bash to fail
4. **Document custom features** - Undocumented commands lead to assumptions
5. **Each project needs orchestration** - Don't assume orchestrators manage multiple projects

### Impact
- 3 days of idle time
- Only 1 of 7 agents completed work
- Manual intervention required for recovery
- Valuable lessons for future orchestration projects

## Incident Timeline

### July 18, 2025 - Initial Setup
- **12:52**: Project repository created
- **12:54**: Initial commit with directory structure
- **12:55**: Agent prompts created for all 7 specification agents
- **12:56**: Research agent manually started and began work
- **13:03**: Verification and monitoring scripts added
- **13:04**: ORCHESTRATOR_STATUS.md created
- **13:17**: Research agent completed work (8 files, comprehensive analysis)
- **13:19**: Orchestrator automation tools added
- **13:22**: Technical architecture specifications added (manually?)
- **13:24**: First orchestrator status report generated

### July 18-21, 2025 - The Silent Failure
- **16:59**: UX agent scheduled activation - FAILED
- **17:03**: Technical agent scheduled activation - FAILED  
- **17:24**: Security agent scheduled activation - FAILED
- **17:27**: Content agent scheduled activation - FAILED
- **17:31**: Business agent scheduled activation - FAILED
- **17:34**: Integration agent scheduled activation - FAILED
- **Days pass**: Auto-monitor continues logging, but no agents working

### July 21, 2025 - Discovery and Recovery
- **13:06**: Investigation begins
- **13:08**: Failed scheduling discovered ("Time: for: No such file or directory")
- **13:34**: Root cause identified - no orchestrator running for project
- **13:55**: `/pm-oversight` command discovered in `.claude/commands/`
- **14:00**: Manual recovery initiated
- **14:03**: All agents successfully started and working

## Root Cause Analysis

### A. The Custom Command Confusion

#### What We Thought
The system documentation referenced `/project:pm-oversight` which was assumed to be a non-existent "fantasy command" that someone imagined Claude supported.

#### The Reality
```bash
$ ls -la /Users/davidleathers/projects/Tmux-Orchestrator/.claude/commands/
-rw-r--r--@ 1 davidleathers  staff  1998 Jul 16 17:24 pm-oversight.md
```

The command exists as `/pm-oversight` (without the `project:` prefix). Claude automatically loads commands from:
- Project-specific: `.claude/commands/`
- Global: `~/.claude/commands/`

#### The Issue
```bash
# WRONG - What was documented
/project:pm-oversight dce-engineer SPEC: ~/spec.md

# CORRECT - How it should be used
/pm-oversight dce-engineer SPEC: ~/spec.md
```

#### Impact
The orchestrator window never received proper PM instructions because the command was never correctly invoked.

### B. The Schedule vs Execute Gap

#### Design Intent
The `schedule_with_note.sh` script was designed to schedule reminder messages for human operators or orchestrators to see and act upon.

#### Implementation Reality
```bash
# What the script did (line 96):
tmux send-keys -l -t "$target" "Time for orchestrator check! cat \"$note_file\""
```

This sends a literal command to bash, which interprets "Time" as a command (doesn't exist).

#### The Bug Cascade
1. `Time` is interpreted as a command by bash
2. Bash can't find command `Time`
3. Error: "Time: for: No such file or directory"
4. No Claude instance ever starts
5. No work gets done

#### What It Should Have Done
```bash
# Option 1: Start Claude and send task
if [[ "$NOTE" == START_AGENT:* ]]; then
    AGENT_PROMPT="${NOTE#START_AGENT: }"
    tmux send-keys -t "$target" "claude" Enter
    sleep 5
    tmux send-keys -t "$target" "Read agent-prompts/$AGENT_PROMPT and begin work" Enter
fi

# Option 2: Use the PM command correctly
tmux send-keys -t "$target" "claude" Enter
sleep 5
tmux send-keys -t "$target" "/pm-oversight $PROJECT_SPEC" Enter
```

### C. The Missing Orchestrator

#### The Assumption
The setup assumed an orchestrator would be running in `project2:1` to manage the agents.

#### The Reality
- `orchestrator:0` - Running Claude, but managing a different project (DCE Whiteboard)
- `project2:1` - Empty bash prompt, no Claude ever started

#### Why Research Agent Worked
Either:
1. Manual intervention at 12:56 started Claude correctly
2. Different setup process was used initially
3. Someone noticed and fixed just that one agent

#### The Communication Breakdown
No orchestrator meant:
- No one to see the scheduled reminders
- No one to start the agents
- No one to coordinate the work
- No progress for 3 days

## Technical Deep Dive

### How Claude Commands Actually Work

#### Discovery Process
Claude automatically scans for custom commands on startup:

```
~/.claude/commands/     # Global commands (all projects)
.claude/commands/       # Project-specific commands
```

#### Command Format
```yaml
---
description: Command description
allowedTools: ["Bash", "Read", "TodoWrite", "TodoRead", "Task"]
---

Command implementation...
```

#### Invocation
```bash
# Correct
/command-name arguments

# Incorrect (no category prefix)
/category:command-name arguments
```

### The Scheduling System Analysis

#### Original Implementation
```bash
#!/usr/bin/env bash
# schedule_with_note.sh - line 88-107

execute_scheduled_check() {
    local target="$1"
    local note_file="$2"
    
    # This is the problem line:
    tmux send-keys -l -t "$target" "Time for orchestrator check! cat \"$note_file\""
    
    sleep 1
    tmux send-keys -t "$target" Enter
}
```

#### Issues Identified
1. **Literal mode (-l)** preserves the command exactly, including capital T
2. **No command validation** before sending to bash
3. **No Claude startup** sequence
4. **No error handling** for failed commands

### The Tool That Worked But Wasn't Used

#### send-claude-message.sh
```bash
# This tool exists and works perfectly:
./send-claude-message.sh session:window "message"

# But scheduling never used it to start agents!
```

Features:
- Validates tmux target
- Handles message escaping
- Waits for pane readiness
- Includes error handling

## Lessons Learned

### Lesson 1: Verify Tool Capabilities Before Building

**Problem**: Assumed `/project:pm-oversight` syntax without verification  
**Solution**: Test all commands in isolation first  
**Implementation**:
```bash
# Test custom commands
ls -la .claude/commands/
cat .claude/commands/pm-oversight.md
# Try the command manually before automating
```

### Lesson 2: Automation Must Execute, Not Just Remind

**Problem**: Built a reminder system when full automation was needed  
**Solution**: Automation scripts should complete entire workflows  
**Implementation**:
```bash
# Bad: Just remind
tmux send-keys "Time to start agent"

# Good: Actually start agent
tmux send-keys "claude" Enter
sleep 5
tmux send-keys "/pm-oversight PROJECT SPEC: path/to/spec.md" Enter
```

### Lesson 3: Each Project Needs Dedicated Orchestration

**Problem**: Orchestrator in wrong session managing different project  
**Solution**: Clear project-to-orchestrator mapping  
**Implementation**:
```bash
# Project structure
project-name/
  ├── orchestrator (window 0 or 1)
  └── agents (windows 2-N)
```

### Lesson 4: Test All Automated Shell Commands

**Problem**: "Time for orchestrator" interpreted as shell command  
**Solution**: Validate command syntax before automation  
**Implementation**:
```bash
# Test command first
echo "Time for orchestrator check!" | bash  # This will fail!

# Use proper shell syntax
echo "echo 'Time for orchestrator check!'" | bash  # This works
```

### Lesson 5: Document Custom Extensions

**Problem**: Custom commands undocumented, leading to wrong assumptions  
**Solution**: Maintain comprehensive command documentation  
**Implementation Structure**:
```
.claude/
├── commands/
│   ├── README.md          # Command documentation
│   ├── pm-oversight.md    # PM command
│   └── other-command.md   # Other custom commands
└── docs/
    └── command-guide.md   # Usage examples
```

## Corrected Implementation

### Proper Orchestrator Initialization

```bash
#!/bin/bash
# start-orchestrator.sh

PROJECT_NAME="$1"
PROJECT_PATH="$2"
SPEC_PATH="$3"

# Create session if needed
tmux new-session -d -s "$PROJECT_NAME" -c "$PROJECT_PATH"

# Start orchestrator in window 0 or 1
ORCH_WINDOW="$PROJECT_NAME:1"
tmux send-keys -t "$ORCH_WINDOW" "claude" Enter
sleep 5

# Use the CORRECT command syntax
tmux send-keys -t "$ORCH_WINDOW" "/pm-oversight $PROJECT_NAME agents SPEC: $SPEC_PATH" Enter

echo "Orchestrator started in $ORCH_WINDOW"
```

### Fixed Scheduling System

```bash
#!/bin/bash
# schedule_with_note_v2.sh

ACTION="$1"
DELAY_MINUTES="$2"
TARGET="$3"
ARGS="$4"

schedule_action() {
    sleep $((DELAY_MINUTES * 60))
    
    case "$ACTION" in
        "START_PM")
            tmux send-keys -t "$TARGET" "claude" Enter
            sleep 5
            tmux send-keys -t "$TARGET" "/pm-oversight $ARGS" Enter
            ;;
            
        "START_AGENT")
            AGENT_PROMPT="$ARGS"
            tmux send-keys -t "$TARGET" "claude" Enter
            sleep 5
            tmux send-keys -t "$TARGET" "Read $AGENT_PROMPT and complete the specification" Enter
            ;;
            
        "REMINDER")
            tmux send-keys -t "$TARGET" "echo 'Reminder: $ARGS'" Enter
            ;;
    esac
}

schedule_action &
disown
```

### Batch Agent Starter

```bash
#!/bin/bash
# start-all-agents.sh

SESSION="project2"
AGENTS=(
    "3:ux:ux-agent.md"
    "4:technical:technical-agent.md"
    "5:security:security-agent.md"
    "6:content:content-agent.md"
    "7:business:business-agent.md"
)

for agent_config in "${AGENTS[@]}"; do
    IFS=':' read -r window name prompt <<< "$agent_config"
    
    echo "Starting $name agent in window $window..."
    
    # Start Claude
    ./send-claude-message.sh "$SESSION:$window" "claude"
    sleep 5
    
    # Send task
    ./send-claude-message.sh "$SESSION:$window" "You are the $name agent. Read agent-prompts/$prompt and complete your specification."
    
    sleep 2
done

echo "All agents started!"
```

## Prevention Strategies

### 1. Command Discovery and Documentation

```bash
#!/bin/bash
# discover-commands.sh

echo "=== Claude Custom Commands ==="
echo ""

echo "Global Commands (~/.claude/commands/):"
ls -la ~/.claude/commands/ 2>/dev/null || echo "  None found"
echo ""

echo "Project Commands (.claude/commands/):"
ls -la .claude/commands/ 2>/dev/null || echo "  None found"
echo ""

echo "Command Details:"
for cmd in ~/.claude/commands/*.md .claude/commands/*.md; do
    if [[ -f "$cmd" ]]; then
        echo "- $(basename $cmd .md): $(grep -m1 'description:' $cmd | cut -d: -f2-)"
    fi
done
```

### 2. Orchestrator Health Monitoring

```bash
#!/bin/bash
# check-orchestrator-health.sh

check_orchestrator() {
    local session="$1"
    local orch_window="$2"
    
    # Check if Claude is running
    if tmux capture-pane -t "$session:$orch_window" -p | grep -q ">" ; then
        echo "✅ Orchestrator active in $session:$orch_window"
        
        # Check last activity
        LAST_LINE=$(tmux capture-pane -t "$session:$orch_window" -p | tail -1)
        echo "   Last activity: $LAST_LINE"
    else
        echo "❌ Orchestrator NOT ACTIVE in $session:$orch_window"
        return 1
    fi
}

# Check all sessions
for session in $(tmux list-sessions -F "#{session_name}"); do
    echo "Checking $session..."
    check_orchestrator "$session" "0"
    check_orchestrator "$session" "1"
done
```

### 3. Integration Testing

```bash
#!/bin/bash
# test-orchestration-flow.sh

echo "Testing orchestration flow..."

# Test 1: Command availability
echo -n "Test 1 - PM command exists: "
if [[ -f ".claude/commands/pm-oversight.md" ]]; then
    echo "✅ PASS"
else
    echo "❌ FAIL - Missing .claude/commands/pm-oversight.md"
    exit 1
fi

# Test 2: Send message script
echo -n "Test 2 - send-claude-message.sh exists: "
if [[ -x "./send-claude-message.sh" ]]; then
    echo "✅ PASS"
else
    echo "❌ FAIL - Missing or not executable"
    exit 1
fi

# Test 3: Schedule script syntax
echo -n "Test 3 - Schedule script syntax: "
if bash -n ./schedule_with_note.sh 2>/dev/null; then
    echo "✅ PASS"
else
    echo "❌ FAIL - Syntax errors in script"
    exit 1
fi

echo ""
echo "All tests passed! Orchestration system ready."
```

## Recovery Procedures

### Identifying Stuck Orchestrators

```bash
# Quick status check
./check-agents.sh

# Look for patterns:
# - "No activity yet" for multiple agents
# - Bash prompts instead of Claude prompts
# - Old timestamps with no progress
```

### Recovery Checklist

1. **Check what's running**
   ```bash
   tmux ls
   tmux list-windows -t PROJECT_NAME
   ```

2. **Identify stuck agents**
   ```bash
   for i in {0..8}; do
       echo "Window $i:"
       tmux capture-pane -t project2:$i -p | tail -5
   done
   ```

3. **Start orchestrator if missing**
   ```bash
   ./send-claude-message.sh project2:1 "claude"
   sleep 5
   ./send-claude-message.sh project2:1 "/pm-oversight project2 SPEC: /path/to/spec"
   ```

4. **Unblock stuck agents**
   ```bash
   # For agents waiting for input
   ./send-claude-message.sh project2:8 "1"  # or appropriate response
   
   # For agents that need starting
   ./start-all-agents.sh
   ```

5. **Verify recovery**
   ```bash
   # Wait 2-3 minutes then check
   ./check-agents.sh
   git status  # Should see new/modified files
   ```

## Appendices

### Appendix A: Complete Command Reference

#### Global Commands
- `/scan-system-docs` - Scans system documentation (location: `~/.claude/commands/`)

#### Project Commands  
- `/pm-oversight` - Project manager oversight with regular check-ins
  ```
  Usage: /pm-oversight PROJECT_NAME SPEC: /path/to/spec.md
  Example: /pm-oversight frontend backend SPEC: ~/project-spec.md
  ```

### Appendix B: Updated Script Templates

See the Corrected Implementation section for:
- `start-orchestrator.sh`
- `schedule_with_note_v2.sh`  
- `start-all-agents.sh`
- `check-orchestrator-health.sh`
- `test-orchestration-flow.sh`

### Appendix C: Best Practices

1. **Always verify commands exist before using**
2. **Test automation scripts manually first**
3. **Include health checks in all orchestration**
4. **Document custom commands immediately**
5. **Use existing tools (send-claude-message.sh) rather than reinventing**
6. **Implement monitoring from day one**
7. **Plan for recovery, not just happy path**

## Conclusion

The DCE orchestrator failure provides valuable lessons about the importance of verifying assumptions, properly documenting custom features, and ensuring automation systems actually automate rather than just remind. The discovery of the `/pm-oversight` command highlights how undocumented features can lead to unnecessary workarounds and system failures.

By implementing the corrected approaches and prevention strategies outlined in this document, future orchestration projects can avoid these pitfalls and achieve true 24/7 automated development cycles.

---

*This post-mortem serves as both a historical record and a practical guide for improving AI agent orchestration systems.*