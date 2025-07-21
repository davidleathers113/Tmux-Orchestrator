# Common Misconceptions in Tmux Orchestrator

*Learn from past failures to build better orchestration systems*

## 1. Command Syntax Confusion

### The Misconception
"Claude commands need category prefixes like `/project:` or `/system:`"

### The Reality
Claude commands use simple syntax without prefixes:
- ✅ CORRECT: `/pm-oversight`
- ❌ WRONG: `/project:pm-oversight`

### Why This Happens
- Pattern matching from other command systems
- Assumption that commands need categorization
- Lack of documentation about `.claude/commands/`

### How to Avoid
1. Check `.claude/commands/README.md` for available commands
2. Remember: command name = `/` + filename (without .md)
3. Never add prefixes unless explicitly documented

### Real Example from DCE Failure
```bash
# What was in setup scripts (WRONG)
echo "/project:pm-oversight dce-engineer SPEC: ~/spec.md"

# What it should have been (CORRECT)
echo "/pm-oversight dce-engineer SPEC: ~/spec.md"
```

## 2. Scheduling as Automation

### The Misconception
"If I schedule an agent to start at 5:00 PM, it will automatically start working"

### The Reality
Scheduling systems create REMINDERS, not automated execution:
- `schedule_with_note.sh` sends a message at the scheduled time
- That message appears in a tmux pane
- Someone (or something) must act on that message

### Why This Happens
- Naming confusion ("schedule" implies automation)
- Expectation from cron-like systems
- Missing documentation about orchestrator responsibilities

### How to Avoid
Think of scheduling as setting an alarm clock:
- The alarm reminds you to do something
- You still have to get up and do it

### Correct Workflow
```bash
# Step 1: Schedule a reminder for yourself
./schedule_with_note.sh 30 "Start the technical agent" "orchestrator:0"

# Step 2: When reminded, actually start the agent
./send-claude-message.sh "project:4" "claude"
sleep 5
./send-claude-message.sh "project:4" "Start technical specification work"
```

## 3. Passive vs Active Orchestration

### The Misconception
"The orchestrator will automatically manage all agents once I give it a project"

### The Reality
Orchestrators must actively:
1. Start each agent with `send-claude-message.sh`
2. Send specific tasks to each agent
3. Monitor progress regularly
4. Coordinate between agents
5. Ensure git commits happen

### Why This Happens
- "Orchestrator" name implies automatic coordination
- Expectation from container orchestration systems
- Incomplete mental model of agent management

### How to Avoid
Think of yourself as a project manager, not a scheduler:
- PMs assign tasks (start agents)
- PMs check progress (monitor output)
- PMs coordinate team members (agent communication)
- PMs ensure deliverables (git commits)

## 4. Shell Command Interpretation

### The Misconception
"I can send natural language commands directly to bash"

### The Reality
Bash interprets the first word as a command to execute:

```bash
# WRONG - Bash tries to run command "Time"
tmux send-keys "Time for orchestrator check!"
# Error: Time: command not found

# CORRECT - Use echo or quotes
tmux send-keys "echo 'Time for orchestrator check!'"
```

### Why This Happens
- Forgetting we're sending to a shell, not a human
- Capital letters look like proper English
- Missing understanding of shell parsing

### How to Avoid
1. Always consider how bash will interpret your message
2. Use `echo` for messages
3. Test commands manually first
4. Be careful with special characters

### The DCE Example
```bash
# The script sent this (WRONG)
"Time for orchestrator check! cat /tmp/note.txt"

# Bash saw:
# Command: Time
# Arguments: for orchestrator check! cat /tmp/note.txt
# Result: "Time: for: No such file or directory"
```

## 5. One Orchestrator for Multiple Projects

### The Misconception
"I can have one orchestrator managing multiple unrelated projects"

### The Reality
Each project typically needs its own orchestrator because:
- Different specs and requirements
- Different agent teams
- Different timelines
- Context switching is difficult

### Why This Happens
- Trying to maximize efficiency
- Misunderstanding orchestrator scope
- Assuming human-like multitasking

### How to Avoid
- One orchestrator per project
- Clear session naming: `project1-orch`, `project2-orch`
- Separate workspaces for each project

## 6. Custom Commands are Fantasy Features

### The Misconception
"References to commands like `/pm-oversight` are wishful thinking"

### The Reality
Claude supports custom commands via:
- `.claude/commands/` in project root (project-specific)
- `~/.claude/commands/` in home directory (global)

### Why This Happens
- Undocumented features
- No README in command directories
- Assumptions based on limitation

### How to Avoid
```bash
# Check for custom commands
ls -la .claude/commands/
ls -la ~/.claude/commands/

# Read command documentation
cat .claude/commands/README.md

# Try commands in Claude directly
/pm-oversight --help  # If implemented
```

## 7. Git Commits are Optional

### The Misconception
"Agents will commit when they're done with everything"

### The Reality
- Commits must happen every 30 minutes
- Work can be lost without commits
- Orchestrators must enforce this discipline

### Why This Happens
- Agents focus on task completion
- No automatic commit triggers
- Missing reminders from orchestrator

### How to Avoid
1. Set 30-minute reminders for git checks
2. Include commit reminders in agent briefings
3. Monitor git status regularly
4. Make commits part of success criteria

## 8. Error Messages Don't Matter

### The Misconception
"Small errors like 'command not found' can be ignored"

### The Reality
Error messages often indicate fundamental problems:
- "Time: for: No such file or directory" = scheduling system broken
- "No such session" = agents not created properly
- Silent failures = agents sitting idle

### Why This Happens
- Errors seem non-critical
- System appears to continue
- Missing understanding of cascading failures

### How to Avoid
1. Investigate every error message
2. Test commands manually when errors occur
3. Check agent output regularly
4. Don't assume "it's probably fine"

## Quick Reference: Reality Check

| Misconception | Reality |
|--------------|---------|
| `/project:pm-oversight` | `/pm-oversight` |
| Scheduling starts agents | Scheduling sends reminders |
| Orchestrators auto-manage | Orchestrators must actively control |
| "Time for X" works in bash | Use `echo "Time for X"` |
| One orchestrator for all | One orchestrator per project |
| Custom commands don't exist | Check `.claude/commands/` |
| Commits happen eventually | Enforce 30-minute commits |
| Errors will resolve themselves | Every error needs investigation |

## Preventing Future Failures

1. **Document Everything**: Especially custom features
2. **Test Manually First**: Before automating
3. **Read Error Messages**: They contain valuable clues
4. **Verify Assumptions**: Check if features actually exist
5. **Monitor Actively**: Don't assume agents are working
6. **Commit Frequently**: Enforce the 30-minute rule
7. **Learn from Failures**: Update documentation immediately

## See Also

- `docs/ORCHESTRATOR_POSTMORTEM.md` - The DCE failure analysis
- `.claude/commands/README.md` - Custom command documentation
- `ORCHESTRATOR_ACTIVATION_GUIDE.md` - Correct activation process
- `CLAUDE.md` - Main orchestrator instructions

---

*"The best orchestrator is an active orchestrator" - Learned from the DCE Incident, July 2025*