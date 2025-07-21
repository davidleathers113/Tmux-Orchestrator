# Orchestrator Activation Guide

*A step-by-step guide for starting and managing AI agents in tmux sessions*

## Prerequisites

Before starting, ensure you have:
- [ ] Tmux installed and running
- [ ] Access to `send-claude-message.sh` script
- [ ] Agent prompt files in `agent-prompts/` directory
- [ ] Project specification document

## Step 1: Verify Your Orchestrator Role

First, confirm you're in the correct orchestrator window:

```bash
# Check your current window location
CURRENT_WINDOW=$(tmux display-message -p "#{session_name}:#{window_index}")
echo "You are orchestrating from: $CURRENT_WINDOW"

# Verify you're in the orchestrator directory
pwd  # Should show /Users/.../projects/Tmux-Orchestrator or similar
```

## Step 2: Review Available Sessions and Agents

```bash
# List all tmux sessions
tmux list-sessions

# List windows in a specific session
tmux list-windows -t project-name:

# Example output:
# 0: main
# 1: orchestrator
# 2: research
# 3: ux
# 4: technical
# 5: security
```

## Step 3: Activate PM Oversight (Optional but Recommended)

If you need project management capabilities:

```
/pm-oversight project-name SPEC: ~/path/to/project-spec.md
```

**Important**: This is a Claude command, not a bash command. Type it directly in your Claude interface.

### Common PM Oversight Examples:
```
# Single project
/pm-oversight dce-engineer SPEC: ~/dce-whiteboard-spec.md

# Multiple projects
/pm-oversight frontend and backend SPEC: ~/full-stack-spec.md

# Test projects
/pm-oversight test-frontend and test-backend SPEC: ~/test-spec.md
```

## Step 4: Start Each Agent

### The Three-Step Process for Each Agent:

#### Step 4.1: Start Claude
```bash
./send-claude-message.sh "session:window" "claude"
```

#### Step 4.2: Wait for Initialization
```bash
sleep 5  # Give Claude time to start
```

#### Step 4.3: Send the Task
```bash
./send-claude-message.sh "session:window" "You are the [role] agent. Please read agent-prompts/[agent]-agent.md and complete your assigned tasks."
```

### Complete Example for Research Agent:
```bash
# Start Claude
./send-claude-message.sh "project2:2" "claude"
sleep 5

# Send task
./send-claude-message.sh "project2:2" "You are the research agent. Please read agent-prompts/research-agent.md and complete the market analysis and competitor research."
```

### Batch Starting Multiple Agents:

```bash
# Define agents array
AGENTS=(
    "3:ux:UX design and user journey mapping"
    "4:technical:technical architecture and system design"
    "5:security:security requirements and compliance"
    "6:content:content strategy and SEO planning"
    "7:business:business logic and payment flows"
)

# Start all agents
for agent_info in "${AGENTS[@]}"; do
    IFS=':' read -r window name task <<< "$agent_info"
    
    echo "Starting $name agent in window $window..."
    ./send-claude-message.sh "project2:$window" "claude"
    sleep 5
    ./send-claude-message.sh "project2:$window" "You are the $name agent. Please read agent-prompts/${name}-agent.md and focus on $task."
    sleep 2
done
```

## Step 5: Verify Agent Activation

### Check Individual Agent Status:
```bash
# Capture last 20 lines from agent window
tmux capture-pane -t "session:window" -p | tail -20

# Look for:
# - Claude prompt (>)
# - Agent acknowledgment of task
# - Initial work output
```

### Check All Agents:
```bash
# Use monitoring script if available
./check-agents.sh

# Or manually check each window
for i in {2..8}; do
    echo "=== Window $i ==="
    tmux capture-pane -t "project2:$i" -p | tail -5
    echo ""
done
```

## Step 6: Set Up Monitoring

### Schedule Regular Check-ins:
```bash
# Schedule a reminder to check progress in 30 minutes
./schedule_with_note.sh 30 "Check agent progress and git commits" "$CURRENT_WINDOW"

# Schedule hourly status reviews
./schedule_with_note.sh 60 "Hourly agent status review" "$CURRENT_WINDOW"
```

### Monitor Git Activity:
```bash
# Check for recent commits
cd /path/to/project && git log --oneline -10

# Watch for file changes
watch -n 60 "git status --short"
```

## Understanding Scheduling vs Automation

### What Scheduling Does ✅
- Sends reminder messages at specified times
- Helps orchestrators remember to check on agents
- Creates a cadence for reviews

### What Scheduling Does NOT Do ❌
- Does NOT automatically start agents
- Does NOT execute commands
- Does NOT manage agents autonomously

### Your Active Role as Orchestrator
You must:
1. **Start agents manually** using send-claude-message.sh
2. **Monitor their progress** actively
3. **Coordinate between agents** when needed
4. **Ensure git commits** happen regularly
5. **Resolve blockers** and provide guidance

## Troubleshooting Common Issues

### Agent Not Starting
```bash
# Verify window exists
tmux list-windows -t session:

# Check if Claude is already running
tmux capture-pane -t session:window -p | grep ">"

# Try sending Enter first
tmux send-keys -t session:window Enter
sleep 1
./send-claude-message.sh session:window "claude"
```

### Agent Stuck or Unresponsive
```bash
# Check full pane content
tmux capture-pane -t session:window -p

# Send a gentle reminder
./send-claude-message.sh session:window "Please continue with your assigned tasks from agent-prompts/"
```

### Wrong Command Syntax
```
❌ WRONG: /project:pm-oversight
✅ CORRECT: /pm-oversight

❌ WRONG: Time for orchestrator check!
✅ CORRECT: echo "Time for orchestrator check!"
```

## Best Practices

1. **Start agents one at a time** initially to ensure each starts correctly
2. **Keep notes** on which agents are working on what
3. **Check git status** every 30 minutes for commits
4. **Use descriptive messages** when starting agents
5. **Document any issues** for future reference

## Quick Reference Card

```bash
# Start an agent
./send-claude-message.sh "session:window" "claude"
sleep 5
./send-claude-message.sh "session:window" "Task description"

# Check agent status
tmux capture-pane -t session:window -p | tail -20

# Schedule a reminder
./schedule_with_note.sh 30 "Check agents" "orchestrator:0"

# Monitor all agents
./check-agents.sh

# Activate PM oversight
/pm-oversight project SPEC: ~/spec.md
```

## See Also

- `CLAUDE.md` - Main orchestrator documentation
- `.claude/commands/README.md` - Custom command reference
- `docs/ORCHESTRATOR_POSTMORTEM.md` - Lessons from failures
- `COMMON_MISCONCEPTIONS.md` - Pitfalls to avoid

---

*Remember: You are the active coordinator. Agents need your guidance to start and succeed!*