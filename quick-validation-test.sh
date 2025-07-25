#!/bin/bash
# Quick validation test for Tmux Orchestrator fixes

set -euo pipefail

echo "=== Tmux Orchestrator Quick Validation Test ==="
echo "Running critical tests to verify system fixes..."
echo ""

# Test 1: Check syntax fixes
echo "TEST 1: Checking command syntax fixes..."
echo "----------------------------------------"
if grep -q "/project:pm-oversight" setup-dce-orchestrator.sh 2>/dev/null; then
    echo "❌ FAIL: Found incorrect /project:pm-oversight syntax"
else
    echo "✅ PASS: No /project:pm-oversight syntax found"
fi

# Test 2: Create test environment
echo ""
echo "TEST 2: Creating test environment..."
echo "------------------------------------"
tmux kill-session -t test-validation 2>/dev/null || true
tmux new-session -s test-validation -d 'echo "Test session ready"; bash'
sleep 1

if tmux has-session -t test-validation 2>/dev/null; then
    echo "✅ PASS: Test session created successfully"
else
    echo "❌ FAIL: Could not create test session"
    exit 1
fi

# Test 3: Test scheduling
echo ""
echo "TEST 3: Testing scheduling system..."
echo "-----------------------------------"
./schedule_with_note.sh 1 "Automated test message $(date)" "test-validation:0"
if [ $? -eq 0 ]; then
    echo "✅ PASS: Schedule command executed successfully"
else
    echo "❌ FAIL: Schedule command failed"
fi

# Test 4: Check for Time error after 65 seconds
echo ""
echo "TEST 4: Waiting 65 seconds to check for 'Time' error..."
echo "------------------------------------------------------"
sleep 65

ERROR_CHECK=$(tmux capture-pane -t test-validation:0 -p | grep -i "Time:.*No such file" || true)
if [ -z "$ERROR_CHECK" ]; then
    echo "✅ PASS: No 'Time: command not found' error"
else
    echo "❌ FAIL: Found Time command error: $ERROR_CHECK"
fi

# Test 5: Test messaging
echo ""
echo "TEST 5: Testing message sending..."
echo "---------------------------------"
./send-claude-message.sh "test-validation:0" "Validation test message"
sleep 2

if tmux capture-pane -t test-validation:0 -p | grep -q "Validation test message"; then
    echo "✅ PASS: Message delivered successfully"
else
    echo "❌ FAIL: Message not found in target window"
fi

# Test 6: Check documentation
echo ""
echo "TEST 6: Checking documentation updates..."
echo "---------------------------------------"
if [ -f ".claude/commands/README.md" ]; then
    echo "✅ PASS: Command documentation exists"
else
    echo "❌ FAIL: .claude/commands/README.md not found"
fi

if grep -q "Starting Agents as Orchestrator" CLAUDE.md 2>/dev/null; then
    echo "✅ PASS: CLAUDE.md contains orchestrator instructions"
else
    echo "❌ FAIL: CLAUDE.md missing orchestrator instructions"
fi

# Cleanup
echo ""
echo "Cleaning up test session..."
tmux kill-session -t test-validation 2>/dev/null || true

# Summary
echo ""
echo "=== Test Summary ==="
echo "All critical tests completed. Check for any ❌ FAIL markers above."
echo ""
echo "For detailed testing, run:"
echo "  cat SYSTEM_VALIDATION_TEST.md"
echo ""
echo "Recent output from test session:"
echo "--------------------------------"
tmux capture-pane -t test-validation:0 -p 2>/dev/null | tail -20 || echo "(Session already cleaned up)"