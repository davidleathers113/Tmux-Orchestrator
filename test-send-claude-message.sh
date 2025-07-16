#!/bin/bash

# Test script for send-claude-message.sh security analysis
# This script creates a safe tmux test environment and tests various inputs

echo "=== Security Test Suite for send-claude-message.sh ==="
echo "Testing in safe environment..."

# Check if tmux is available
if ! command -v tmux &> /dev/null; then
    echo "tmux not found. Cannot run live tests."
    echo "Proceeding with theoretical analysis only."
    exit 0
fi

# Create a test tmux session
TEST_SESSION="security-test-$$"
TEST_WINDOW="test-window"

# Clean up function
cleanup() {
    echo "Cleaning up test session..."
    tmux kill-session -t "$TEST_SESSION" 2>/dev/null
}

# Set up cleanup on exit
trap cleanup EXIT

# Create test session
echo "Creating test tmux session: $TEST_SESSION"
tmux new-session -d -s "$TEST_SESSION" -n "$TEST_WINDOW" 'echo "Test window ready"; read'

# Test cases
echo -e "\n=== Test Case 1: Normal Usage ==="
echo "Command: ./send-claude-message.sh $TEST_SESSION:$TEST_WINDOW 'Hello Claude!'"
./send-claude-message.sh "$TEST_SESSION:$TEST_WINDOW" "Hello Claude!"

echo -e "\n=== Test Case 2: Empty Message ==="
echo "Command: ./send-claude-message.sh $TEST_SESSION:$TEST_WINDOW ''"
./send-claude-message.sh "$TEST_SESSION:$TEST_WINDOW" ""

echo -e "\n=== Test Case 3: Special Characters (Safe) ==="
echo "Command: ./send-claude-message.sh $TEST_SESSION:$TEST_WINDOW 'Message with $pecial ch@rs!'"
./send-claude-message.sh "$TEST_SESSION:$TEST_WINDOW" "Message with \$pecial ch@rs!"

echo -e "\n=== Test Case 4: Command Injection Attempt (Documentation Only) ==="
echo "DANGEROUS INPUT: '; rm -rf /' - DO NOT EXECUTE"
echo "This would be passed directly to tmux send-keys without validation"

echo -e "\n=== Test Case 5: Newline Injection ==="
echo "Testing message with newline character"
./send-claude-message.sh "$TEST_SESSION:$TEST_WINDOW" $'First line\nSecond line'

echo -e "\n=== Test Case 6: Tmux Command Injection ==="
echo "DANGEROUS INPUT: '-t other-session:window' - Could target wrong session"
echo "This demonstrates parameter injection vulnerability"

echo -e "\n=== Test Case 7: Unicode and UTF-8 ==="
echo "Command: ./send-claude-message.sh $TEST_SESSION:$TEST_WINDOW '你好 🔒 Security Test'"
./send-claude-message.sh "$TEST_SESSION:$TEST_WINDOW" "你好 🔒 Security Test"

echo -e "\n=== Test Case 8: Very Long Message ==="
LONG_MSG=$(printf 'A%.0s' {1..1000})
echo "Command: ./send-claude-message.sh $TEST_SESSION:$TEST_WINDOW '[1000 A characters]'"
./send-claude-message.sh "$TEST_SESSION:$TEST_WINDOW" "$LONG_MSG"

echo -e "\n=== Test Case 9: Missing Parameters ==="
echo "Command: ./send-claude-message.sh"
./send-claude-message.sh

echo -e "\n=== Test Case 10: Invalid Window Target ==="
echo "Command: ./send-claude-message.sh 'nonexistent:window' 'Test message'"
./send-claude-message.sh "nonexistent:window" "Test message" 2>&1

echo -e "\n=== Checking tmux buffer contents ==="
echo "Capturing what was actually sent to the test window..."
tmux capture-pane -t "$TEST_SESSION:$TEST_WINDOW" -p | tail -20

echo -e "\n=== Test complete ==="