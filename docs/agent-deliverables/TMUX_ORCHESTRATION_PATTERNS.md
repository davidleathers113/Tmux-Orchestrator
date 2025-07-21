# Tmux-Based Agent Orchestration Patterns

## Overview
This document captures the unique patterns and best practices specific to orchestrating multiple AI agents using tmux as the coordination layer.

## 1. Tmux as an Orchestration Platform

### Why Tmux?
- **Persistent Sessions**: Agents continue working even if orchestrator disconnects
- **Visual Monitoring**: Can see all agents' work in real-time
- **Direct Intervention**: Can manually assist stuck agents
- **Resource Efficient**: Minimal overhead compared to containers
- **Native Terminal**: Agents work in their natural environment

### Core Concepts
```
Session = Project
Window = Agent/Service
Pane = Split views within an agent
```

## 2. Window-Based Agent Architecture

### Standard Window Layout
```bash
project-name (session)
├── 0: Claude-Agent      # Primary developer
├── 1: Shell            # Manual commands
├── 2: Dev-Server       # Running application
├── 3: Project-Manager  # Quality oversight
├── 4: Claude-Backend   # Backend specialist
└── 5: Tests           # Test runner
```

### Window Naming Patterns
- **Role-Based**: `Claude-Frontend`, `Claude-Backend`
- **Service-Based**: `API-Server`, `Database`, `Redis`
- **Purpose-Based**: `Tests`, `Logs`, `Monitor`
- **Temporary**: `TEMP-Debug`, `TEMP-Review`

## 3. Agent Communication Patterns

### Direct Messaging via Tmux
```bash
# Using send-claude-message.sh script
./send-claude-message.sh session:window "message"

# Script handles:
# - Proper timing (0.5s delay before Enter)
# - Pane targeting (window.pane notation)
# - Message escaping
```

### Message Flow Patterns
```
1. Orchestrator → PM → Developers (Task Assignment)
2. Developer → PM → Orchestrator (Status Updates)
3. Developer → Developer (via PM) (Coordination)
4. Any → Orchestrator (Escalation)
```

### Async Communication Benefits
- No blocking/waiting for responses
- Agents work independently
- Natural audit trail in tmux history
- Can replay conversations

## 4. Agent Lifecycle in Tmux

### Starting an Agent
```bash
# 1. Create window with correct directory
tmux new-window -t session -n "Agent-Name" -c "/project/path"

# 2. Start Claude
tmux send-keys -t session:window "claude" Enter
sleep 5

# 3. Send role-specific briefing
./send-claude-message.sh session:window "You are a [role]..."
```

### Monitoring Agent Health
```bash
# Check if agent is responsive
tmux capture-pane -t session:window -p | tail -10

# Look for:
# - Claude prompt active
# - Recent activity
# - Error messages
# - Stuck processes
```

### Graceful Agent Shutdown
```bash
# 1. Notify agent to wrap up
./send-claude-message.sh session:window "Please complete current task and prepare for shutdown"

# 2. Capture conversation log
tmux capture-pane -t session:window -S - -E - > agent_log.txt

# 3. Kill window
tmux kill-window -t session:window
```

## 5. Multi-Agent Coordination Patterns

### Hub-and-Spoke Pattern
```
       Orchestrator
      /     |      \
   PM1     PM2     PM3
   /|\      |      /|\
 D1 D2 D3   D4   D5 D6 D7
```
Benefits:
- O(n) communication complexity
- Clear hierarchy
- Reduced message noise
- Easier debugging

### Specialist Team Pattern
```
Frontend Team          Backend Team
    PM-Frontend          PM-Backend
    /    |    \          /    |    \
  UI   State  Test    API   DB   Cache
```

### Pipeline Pattern
```
Researcher → Architect → Developer → QA → DevOps
```
Each agent completes their phase and hands off to the next.

## 6. Window Management Best Practices

### Directory Synchronization
```bash
# Problem: Windows inherit tmux start directory
# Solution: Always specify -c flag

# Get project path from existing window
PROJECT_PATH=$(tmux display-message -t session:0 -p '#{pane_current_path}')

# Use for new windows
tmux new-window -t session -n "name" -c "$PROJECT_PATH"
```

### Window Indexing Strategy
- 0: Primary agent (never kill)
- 1: Shell (manual intervention)
- 2: Main service/server
- 3+: Additional agents
- Last: Logs/monitoring

### Pane Usage
```bash
# Split for monitoring
tmux split-window -t session:window -h -p 30
tmux send-keys -t session:window.1 "tail -f app.log" Enter

# Agent in pane 0, logs in pane 1
```

## 7. Scheduling and Continuity

### Self-Scheduling Pattern
```bash
# Orchestrator schedules its own check-ins
CURRENT_WINDOW=$(tmux display-message -p "#{session_name}:#{window_index}")
./schedule_with_note.sh 15 "Orchestrator check-in" "$CURRENT_WINDOW"
```

### Handoff Pattern
```bash
# Before orchestrator ends shift
1. Create comprehensive status report
2. Schedule next orchestrator
3. Brief incoming orchestrator via note
4. Gracefully exit
```

## 8. Error Recovery Patterns

### Stuck Agent Recovery
```bash
# 1. Detect stuck agent (no output for >10 min)
# 2. Try gentle prompt
./send-claude-message.sh session:window "Are you still working on the task?"

# 3. If no response, check for system issues
tmux send-keys -t session:window C-c  # Interrupt
tmux send-keys -t session:window "claude" Enter  # Restart

# 4. Re-brief with current context
```

### Lost Window Recovery
```bash
# If window accidentally closed
# 1. Recreate with same name/index
tmux new-window -t session:3 -n "Lost-Agent" -c "/project"

# 2. Start new agent
# 3. Brief with context from logs
```

## 9. Tmux-Specific Advantages

### Real-Time Observation
- Watch agents think and work
- Spot problems immediately
- Learn from agent approaches
- Manual intervention when needed

### Persistent State
- Agents continue during connection loss
- Can attach from anywhere
- Work proceeds 24/7
- Natural disaster recovery

### Resource Efficiency
- No container overhead
- Shared system resources
- Fast agent startup
- Minimal memory usage

## 10. Anti-Patterns in Tmux Orchestration

### ❌ Window Sprawl
Too many windows becomes unmanageable
- **Solution**: Hierarchical organization, temporary windows

### ❌ Message Storms
Broadcasting to all windows creates noise
- **Solution**: Hub-and-spoke communication

### ❌ Manual Coordination
Orchestrator manually copying between windows
- **Solution**: Agents communicate directly via scripts

### ❌ Synchronous Waiting
Blocking on agent responses
- **Solution**: Async patterns, status polling

### ❌ Window Hijacking
Taking over agent windows for manual work
- **Solution**: Dedicated shell windows

## 11. Advanced Patterns

### Multi-Session Orchestration
```bash
# Orchestrator manages multiple project sessions
tmux ls | grep -v "attached"
# Switch between and coordinate projects
```

### Agent Pools
```bash
# Maintain pool of idle agents
# Assign to projects as needed
# Return to pool when done
```

### Distributed Orchestration
```bash
# Multiple orchestrators on different machines
# Coordinate via shared git repo
# Each manages subset of projects
```

## 12. Tmux Commands Cheat Sheet

### Essential Commands for Orchestrators
```bash
# List all sessions
tmux ls

# List windows in session
tmux list-windows -t session

# Capture pane output
tmux capture-pane -t session:window -p

# Send keys
tmux send-keys -t session:window "text" Enter

# Create window
tmux new-window -t session -n "name" -c "/path"

# Kill window
tmux kill-window -t session:window

# Rename window
tmux rename-window -t session:window "new-name"

# Display window info
tmux display-message -t session:window -p '#{pane_current_path}'
```

## Conclusion

Tmux provides a unique and powerful platform for AI agent orchestration by leveraging:
- Terminal-native environment
- Visual monitoring capabilities  
- Persistent sessions
- Efficient resource usage
- Simple but effective communication

The patterns documented here enable scalable, reliable multi-agent systems that can work continuously with minimal human oversight.