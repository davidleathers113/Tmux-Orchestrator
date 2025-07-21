#!/bin/bash
# Check orchestrator status

echo "=== Tmux Orchestrator Status Check ==="
echo "Time: $(date)"
echo ""

echo "=== Tmux Sessions ==="
tmux list-sessions 2>/dev/null || echo "No tmux sessions found"

echo ""
echo "=== Scheduled Tasks (systemd) ==="
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user list-timers | grep -E "(orc-check|TIMERS)" || echo "No systemd timers found"
else
    echo "systemd not available"
fi

echo ""
echo "=== Scheduled Tasks (at) ==="
if command -v atq >/dev/null 2>&1; then
    atq 2>/dev/null || echo "No at jobs found"
else
    echo "at command not available"
fi

echo ""
echo "=== Background Processes ==="
ps aux | grep -E "(schedule_with_note|send-claude-message)" | grep -v grep || echo "No background processes found"

echo ""
echo "=== Recent Orchestrator Activity ==="
if tmux has-session -t orchestrator 2>/dev/null; then
    echo "Last 20 lines from orchestrator window:"
    echo "----------------------------------------"
    tmux capture-pane -t orchestrator:0 -p | tail -20
else
    echo "Orchestrator session not found"
fi

echo ""
echo "=== Test Frontend Activity ==="
if tmux has-session -t test-frontend 2>/dev/null; then
    echo "Last 10 lines from test-frontend:"
    echo "----------------------------------------"
    tmux capture-pane -t test-frontend:0 -p | tail -10
else
    echo "test-frontend session not found"
fi

echo ""
echo "=== Test Backend Activity ==="
if tmux has-session -t test-backend 2>/dev/null; then
    echo "Last 10 lines from test-backend:"
    echo "----------------------------------------"
    tmux capture-pane -t test-backend:0 -p | tail -10
else
    echo "test-backend session not found"
fi

echo ""
echo "=== Quick Actions ==="
echo "- Attach to orchestrator: tmux attach -t orchestrator"
echo "- View frontend: tmux attach -t test-frontend"
echo "- View backend: tmux attach -t test-backend"
echo "- Kill all test sessions: tmux kill-session -t test-frontend; tmux kill-session -t test-backend"