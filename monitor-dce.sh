#!/bin/bash
# Monitor DCE Whiteboard project sessions

echo "=== DCE Whiteboard Project Status ==="
echo "Time: $(date)"
echo ""

# Show project sessions
echo "=== Project Sessions ==="
tmux list-sessions | grep -E "(dce-|orchestrator)" || echo "No project sessions found"

# Show git status
echo ""
echo "=== Git Status in Project ==="
cd /Users/davidleathers/dce-whiteboard/ 2>/dev/null && git status -s || echo "Not in git repository"

# Show recent activity
echo ""
echo "=== Recent DCE Engineer Activity ==="
if tmux has-session -t dce-engineer 2>/dev/null; then
    tmux capture-pane -t dce-engineer:0 -p | tail -20
fi

echo ""
echo "=== Recent PM Activity ==="
if tmux has-session -t dce-pm 2>/dev/null; then
    tmux capture-pane -t dce-pm:0 -p | tail -20
fi

# Show scheduled tasks
echo ""
echo "=== Scheduled Check-ins ==="
ps aux | grep schedule_with_note | grep -v grep || echo "No scheduled tasks"