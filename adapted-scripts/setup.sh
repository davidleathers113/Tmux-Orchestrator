#!/bin/bash
# Setup script for Tmux Orchestrator Adapted Scripts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Tmux Orchestrator Adapted Scripts Setup ==="
echo

# Check for required commands
echo "Checking dependencies..."
for cmd in tmux bash python3; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: $cmd is required but not installed."
        exit 1
    fi
done
echo "✓ All dependencies found"
echo

# Create configuration from template
if [[ ! -f "${SCRIPT_DIR}/config/orchestrator.conf" ]]; then
    echo "Creating configuration file..."
    cp "${SCRIPT_DIR}/config/orchestrator.conf.template" "${SCRIPT_DIR}/config/orchestrator.conf"
    
    # Update ORCHESTRATOR_HOME in config
    sed -i.bak "s|ORCHESTRATOR_HOME=\"/path/to/tmux-orchestrator\"|ORCHESTRATOR_HOME=\"${SCRIPT_DIR}/..\"|g" "${SCRIPT_DIR}/config/orchestrator.conf"
    rm -f "${SCRIPT_DIR}/config/orchestrator.conf.bak"
    
    echo "✓ Configuration file created at: config/orchestrator.conf"
    echo "  Please review and customize the settings."
else
    echo "✓ Configuration file already exists"
fi
echo

# Set up log directory
echo "Setting up log directory..."
mkdir -p "${SCRIPT_DIR}/logs"
chmod 750 "${SCRIPT_DIR}/logs"
echo "✓ Log directory ready"
echo

# Set permissions
echo "Setting secure permissions..."
chmod 750 "${SCRIPT_DIR}"
chmod 640 "${SCRIPT_DIR}/config/orchestrator.conf" 2>/dev/null || true
chmod 750 "${SCRIPT_DIR}"/*.sh 2>/dev/null || true
chmod 640 "${SCRIPT_DIR}"/config/* 2>/dev/null || true
echo "✓ Permissions configured"
echo

# Create initial log files
touch "${SCRIPT_DIR}/logs/audit.log"
touch "${SCRIPT_DIR}/logs/error.log"
touch "${SCRIPT_DIR}/logs/scheduler.log"
chmod 640 "${SCRIPT_DIR}/logs"/*.log
echo "✓ Log files initialized"
echo

# Test configuration
echo "Testing configuration..."
if source "${SCRIPT_DIR}/common.sh" 2>/dev/null; then
    echo "✓ Configuration loads successfully"
else
    echo "⚠ Warning: Configuration may have issues"
fi
echo

echo "=== Setup Complete ==="
echo
echo "Next steps:"
echo "1. Edit config/orchestrator.conf to customize settings"
echo "2. Review the security documentation in docs/security.md"
echo "3. Check ADAPTATION_PLAN.md for script migration guidance"
echo "4. Run adapted scripts from the adapted-scripts/ directory"
echo
echo "Example usage:"
echo "  ./send-message.sh -s session_name -w 0 -m 'Hello'"
echo "  ./schedule-check.sh -m 5 -n 'Status check' -t 'session:0'"
echo
echo "For more information, see README.md"