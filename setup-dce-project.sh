#!/bin/bash
# Setup script for DCE Whiteboard project

set -euo pipefail

PROJECT_DIR="/Users/davidleathers/dce-whiteboard"

echo "Setting up DCE Whiteboard orchestration..."

# Create project manager session
if ! tmux has-session -t dce-pm 2>/dev/null; then
    tmux new-session -s dce-pm -d -c "$PROJECT_DIR"
    echo "Created dce-pm session"
fi

# Create engineer session
if ! tmux has-session -t dce-engineer -d -c "$PROJECT_DIR" 2>/dev/null; then
    tmux new-session -s dce-engineer -d -c "$PROJECT_DIR"
    echo "Created dce-engineer session"
fi

# Create server/monitoring session (optional)
if ! tmux has-session -t dce-server 2>/dev/null; then
    tmux new-session -s dce-server -d -c "$PROJECT_DIR"
    echo "Created dce-server session (for running dev server, tests, etc.)"
fi

echo ""
echo "Sessions created:"
tmux list-sessions | grep dce

echo ""
echo "Next steps:"
echo "1. Edit the spec file: ~/dce-whiteboard-spec.md"
echo "2. Attach to orchestrator: tmux attach -t orchestrator"
echo "3. Run PM oversight command:"
echo "   /pm-oversight dce-engineer SPEC: ~/dce-whiteboard-spec.md"
echo ""
echo "Optional: Run development server in dce-server session"
echo "   tmux send-keys -t dce-server:0 'npm run dev' Enter"