#!/bin/bash
# Quick setup for testing PM oversight

set -euo pipefail

echo "Setting up Tmux Orchestrator test environment..."

# Kill existing test sessions
tmux kill-session -t test-frontend 2>/dev/null || true
tmux kill-session -t test-backend 2>/dev/null || true

# Create new test sessions
tmux new-session -s test-frontend -d 'echo "Frontend ready - $(date)"; bash'
tmux new-session -s test-backend -d 'echo "Backend ready - $(date)"; bash'

# Create orchestrator session if it doesn't exist
if ! tmux has-session -t orchestrator 2>/dev/null; then
    echo "Creating orchestrator session..."
    tmux new-session -s orchestrator -d
fi

echo ""
echo "Test sessions created:"
tmux list-sessions

echo ""
echo "To start testing, run:"
echo "  tmux attach -t orchestrator"
echo ""
echo "Then use PM oversight command:"
echo "  /pm-oversight test-frontend and test-backend SPEC: ~/tmux-test-spec.md"
echo ""
echo "To monitor activity, run in another terminal:"
echo "  ./check-status.sh"