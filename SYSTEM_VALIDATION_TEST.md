# Tmux Orchestrator System Validation Test

*Step-by-step testing procedure to validate all system fixes*

## Test Overview
This document provides a comprehensive test procedure to validate that all orchestrator fixes are working correctly. Copy and paste the command outputs back for verification.

## Pre-Test Checklist
- [ ] You're in the Tmux-Orchestrator directory
- [ ] You have tmux installed
- [ ] You have access to a terminal

## Test 1: Verify Fixed Scripts

### 1.1 Check Command Syntax Fixes
```bash
# Check if setup scripts have correct syntax (no /project: prefix)
grep -n "pm-oversight" setup-dce-orchestrator.sh | head -5
```

**Expected Output**: Should show `/pm-oversight` WITHOUT `/project:` prefix

### 1.2 Verify Scheduling Script
```bash
# Check the problematic line that caused "Time: command not found"
sed -n '96p' schedule_with_note.sh
```

**Expected Output**: Should show the tmux send-keys command

## Test 2: Test Session Creation

### 2.1 Clean Environment
```bash
# Kill any existing test sessions
tmux kill-session -t test-orch 2>/dev/null || echo "No test-orch session to kill"
tmux kill-session -t test-agent 2>/dev/null || echo "No test-agent session to kill"
```

### 2.2 Create Test Sessions
```bash
# Create a test orchestrator and agent session
tmux new-session -s test-orch -d 'echo "Test orchestrator ready"; bash'
tmux new-session -s test-agent -d 'echo "Test agent ready"; bash'

# List sessions to confirm
tmux list-sessions | grep test
```

**Expected Output**: Should show both test-orch and test-agent sessions

## Test 3: Test Scheduling System

### 3.1 Test Schedule Command
```bash
# Schedule a test message for 1 minute
./schedule_with_note.sh 1 "Validation test message" "test-orch:0"

# Capture the output
echo "Exit code: $?"
```

**Expected Output**: 
- "Scheduled successfully" message
- Exit code: 0

### 3.2 Wait and Check Result
```bash
# Wait 65 seconds for the scheduled message
echo "Waiting 65 seconds for scheduled message..."
sleep 65

# Check if message appeared (without errors)
tmux capture-pane -t test-orch:0 -p | tail -10
```

**Expected Output**: 
- Should show the scheduled message
- NO "Time: for: No such file or directory" error
- NO "command not found" errors

## Test 4: Test Message Sending

### 4.1 Send Test Message
```bash
# Test the send-claude-message script
./send-claude-message.sh "test-agent:0" "Test message from orchestrator"

# Check if it arrived
sleep 2
tmux capture-pane -t test-agent:0 -p | tail -5
```

**Expected Output**: Should show "Test message from orchestrator"

## Test 5: Test PM Oversight Command

### 5.1 Attach to Test Orchestrator
```bash
# First, send instructions to test orchestrator window
tmux send-keys -t test-orch:0 "claude" Enter
sleep 5

# Send PM oversight command with CORRECT syntax
tmux send-keys -t test-orch:0 "/pm-oversight test-agent SPEC: ~/test-spec.md" Enter
sleep 3

# Capture the result
tmux capture-pane -t test-orch:0 -p | tail -20
```

**Expected Output**: 
- Should show Claude's response to the PM oversight command
- NO errors about "project:" prefix
- NO "command not found" errors

## Test 6: Verify Documentation

### 6.1 Check CLAUDE.md Updates
```bash
# Check for orchestrator instructions
grep -A 5 "Starting Agents as Orchestrator" CLAUDE.md
```

**Expected Output**: Should show the new orchestrator activation instructions

### 6.2 Check Command Documentation
```bash
# Verify .claude/commands/README.md exists
head -20 .claude/commands/README.md
```

**Expected Output**: Should show command documentation with correct syntax examples

## Test 7: Test Agent Activation Workflow

### 7.1 Start Claude in Agent Window
```bash
# Clear the agent window first
tmux send-keys -t test-agent:0 "clear" Enter

# Start Claude
./send-claude-message.sh "test-agent:0" "claude"
sleep 5

# Send task
./send-claude-message.sh "test-agent:0" "You are a test agent. Please confirm you received this message."

# Check response
sleep 3
tmux capture-pane -t test-agent:0 -p | tail -15
```

**Expected Output**: 
- Claude prompt (">") 
- Acknowledgment of the test message

## Test 8: Comprehensive Monitoring

### 8.1 Run Status Check
```bash
# If check-status.sh exists
if [ -f "./check-status.sh" ]; then
    ./check-status.sh
else
    echo "check-status.sh not found, using tmux_utils.py"
    python3 tmux_utils.py
fi
```

**Expected Output**: JSON or formatted output showing all sessions and their status

## Test 9: Error Handling

### 9.1 Test Invalid Window Target
```bash
# Try scheduling to non-existent window
./schedule_with_note.sh 1 "Error test" "nonexistent:99" 2>&1
```

**Expected Output**: Should show an error message (not a crash)

### 9.2 Test Command Error Recovery
```bash
# Send a message that would have failed before
tmux send-keys -t test-orch:0 'echo "Time for orchestrator check!"' Enter
sleep 1
tmux capture-pane -t test-orch:0 -p | tail -3
```

**Expected Output**: Should echo the message, not try to execute "Time" as command

## Test 10: Final Validation

### 10.1 Clean Up Test Sessions
```bash
# Clean up
tmux kill-session -t test-orch
tmux kill-session -t test-agent

# Verify cleanup
tmux list-sessions | grep test || echo "Test sessions successfully removed"
```

## Results Summary

Please run each test section and paste the outputs back. Key things to verify:

✅ **NO** "Time: for: No such file or directory" errors  
✅ **NO** "/project:pm-oversight" syntax (should be "/pm-oversight")  
✅ Scheduling creates reminders without errors  
✅ Messages send successfully between windows  
✅ PM oversight command works with correct syntax  
✅ Documentation reflects all fixes  

## Quick All-in-One Test

If you want to run all tests quickly:
```bash
# Save this as run-all-tests.sh and execute
./test-setup.sh
sleep 2
./schedule_with_note.sh 1 "Quick test" "orchestrator:0"
sleep 65
tmux capture-pane -t orchestrator:0 -p | tail -10
```

---

*Copy and paste the output from each test section for verification*