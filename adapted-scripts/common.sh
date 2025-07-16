#!/bin/bash
# Common functions for Tmux Orchestrator adapted scripts
# This file should be sourced by all adapted scripts

# Set strict mode
set -euo pipefail

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config/orchestrator.conf"

# Default configuration values
ORCHESTRATOR_HOME="${SCRIPT_DIR}/.."
LOG_DIR="${SCRIPT_DIR}/logs"
AUDIT_LOGGING=true
DRY_RUN_DEFAULT=false
USE_COLORS=true
DEBUG=false
STRICT_MODE=true
MAX_COMMANDS_PER_MINUTE=30
VALIDATE_SESSIONS=true
VALIDATE_COMMANDS=true

# Load user configuration if exists
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "Warning: Configuration file not found at $CONFIG_FILE"
    echo "Using default values. Copy config/orchestrator.conf.template to config/orchestrator.conf"
fi

# Color codes (if enabled)
if [[ "$USE_COLORS" == "true" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Initialize rate limiting
COMMAND_COUNT_FILE="${LOG_DIR}/.command_count"
LAST_MINUTE_FILE="${LOG_DIR}/.last_minute"

# Logging functions
log_info() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[INFO]${NC} ${timestamp} - ${message}"
    if [[ "$AUDIT_LOGGING" == "true" ]]; then
        echo "[INFO] ${timestamp} - ${message}" >> "${LOG_DIR}/audit.log"
    fi
}

log_error() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[ERROR]${NC} ${timestamp} - ${message}" >&2
    echo "[ERROR] ${timestamp} - ${message}" >> "${LOG_DIR}/error.log"
}

log_warning() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[WARN]${NC} ${timestamp} - ${message}"
    if [[ "$AUDIT_LOGGING" == "true" ]]; then
        echo "[WARN] ${timestamp} - ${message}" >> "${LOG_DIR}/audit.log"
    fi
}

log_debug() {
    local message="$1"
    if [[ "$DEBUG" == "true" ]]; then
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo -e "${GREEN}[DEBUG]${NC} ${timestamp} - ${message}"
    fi
}

log_command() {
    local command="$1"
    local target="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    if [[ "$AUDIT_LOGGING" == "true" ]]; then
        echo "[COMMAND] ${timestamp} - Target: ${target} - Command: ${command}" >> "${LOG_DIR}/audit.log"
    fi
}

# Input validation functions
validate_session_window() {
    local target="$1"
    
    # Check format (session:window)
    if ! [[ "$target" =~ ^[a-zA-Z0-9_-]+:[0-9]+$ ]]; then
        log_error "Invalid target format: $target. Expected format: session:window"
        return 1
    fi
    
    # Extract session and window
    local session="${target%%:*}"
    local window="${target##*:}"
    
    # Check if session is in allowed list (if configured)
    if [[ -n "${ALLOWED_SESSIONS:-}" ]]; then
        local allowed=false
        IFS=',' read -ra ALLOWED_ARRAY <<< "$ALLOWED_SESSIONS"
        for allowed_session in "${ALLOWED_ARRAY[@]}"; do
            if [[ "$session" == "$allowed_session" ]]; then
                allowed=true
                break
            fi
        done
        if [[ "$allowed" == "false" ]]; then
            log_error "Session '$session' is not in allowed sessions list"
            return 1
        fi
    fi
    
    # Validate session exists (if enabled)
    if [[ "$VALIDATE_SESSIONS" == "true" ]]; then
        if ! tmux has-session -t "$session" 2>/dev/null; then
            log_error "Session '$session' does not exist"
            return 1
        fi
        
        # Check if window exists
        if ! tmux list-windows -t "$session" -F '#{window_index}' | grep -q "^${window}$"; then
            log_error "Window '$window' does not exist in session '$session'"
            return 1
        fi
    fi
    
    return 0
}

validate_command() {
    local command="$1"
    
    # Check if command is in allowed list
    if [[ -n "${ALLOWED_COMMANDS[@]:-}" ]]; then
        local allowed=false
        for allowed_cmd in "${ALLOWED_COMMANDS[@]}"; do
            # Check if command starts with allowed command
            if [[ "$command" == "$allowed_cmd"* ]]; then
                allowed=true
                break
            fi
        done
        if [[ "$allowed" == "false" ]]; then
            log_error "Command not in allowed list: $command"
            return 1
        fi
    fi
    
    # Basic command injection prevention
    if [[ "$command" =~ [;\|&] ]]; then
        log_warning "Command contains potentially dangerous characters: $command"
        if [[ "${ENABLE_SANITIZATION:-true}" == "true" ]]; then
            log_error "Command rejected due to dangerous characters"
            return 1
        fi
    fi
    
    return 0
}

sanitize_input() {
    local input="$1"
    # Remove potentially dangerous characters
    local sanitized="${input//[;\|&\`\$]/}"
    # Remove newlines and carriage returns
    sanitized="${sanitized//$'\n'/ }"
    sanitized="${sanitized//$'\r'/}"
    echo "$sanitized"
}

# Rate limiting function
check_rate_limit() {
    local current_minute=$(date '+%Y%m%d%H%M')
    local count=0
    
    # Read last minute and count
    if [[ -f "$LAST_MINUTE_FILE" ]]; then
        local last_minute=$(cat "$LAST_MINUTE_FILE")
        if [[ "$last_minute" == "$current_minute" ]] && [[ -f "$COMMAND_COUNT_FILE" ]]; then
            count=$(cat "$COMMAND_COUNT_FILE")
        fi
    fi
    
    # Check if limit exceeded
    if [[ $count -ge $MAX_COMMANDS_PER_MINUTE ]]; then
        log_error "Rate limit exceeded: $MAX_COMMANDS_PER_MINUTE commands per minute"
        return 1
    fi
    
    # Update count
    ((count++))
    echo "$count" > "$COMMAND_COUNT_FILE"
    echo "$current_minute" > "$LAST_MINUTE_FILE"
    
    return 0
}

# Process management functions
check_background_processes() {
    local count=$(jobs -p | wc -l)
    if [[ $count -ge ${MAX_BACKGROUND_PROCESSES:-5} ]]; then
        log_error "Maximum background processes limit reached: $count"
        return 1
    fi
    return 0
}

cleanup_old_logs() {
    if [[ -n "${LOG_RETENTION_DAYS:-}" ]] && [[ "$LOG_RETENTION_DAYS" -gt 0 ]]; then
        log_debug "Cleaning up logs older than $LOG_RETENTION_DAYS days"
        find "$LOG_DIR" -name "*.log" -type f -mtime +$LOG_RETENTION_DAYS -delete 2>/dev/null || true
    fi
}

# Dry run wrapper
execute_command() {
    local command="$1"
    local description="${2:-Command execution}"
    
    if [[ "${DRY_RUN:-$DRY_RUN_DEFAULT}" == "true" ]]; then
        log_info "[DRY RUN] Would execute: $command"
        return 0
    else
        log_debug "Executing: $command"
        eval "$command"
        return $?
    fi
}

# Confirmation prompt
confirm_action() {
    local message="$1"
    local default="${2:-no}"
    
    if [[ "${FORCE:-false}" == "true" ]]; then
        return 0
    fi
    
    local prompt="$message [yes/no]"
    if [[ "$default" == "yes" ]]; then
        prompt="$message [YES/no]"
    else
        prompt="$message [yes/NO]"
    fi
    
    read -p "$prompt: " response
    response=${response:-$default}
    
    if [[ "${response,,}" == "yes" ]] || [[ "${response,,}" == "y" ]]; then
        return 0
    else
        return 1
    fi
}

# Signal handlers
cleanup_on_exit() {
    log_debug "Cleaning up..."
    # Add any cleanup tasks here
    exit 0
}

trap cleanup_on_exit EXIT

# Error handler
handle_error() {
    local line_no=$1
    local error_code=$2
    log_error "Error on line $line_no: exit code $error_code"
    if [[ "${NOTIFY_ON_ERROR:-true}" == "true" ]]; then
        # Add notification logic here if needed
        :
    fi
    exit $error_code
}

if [[ "$STRICT_MODE" == "true" ]]; then
    trap 'handle_error ${LINENO} $?' ERR
fi

# Initialize
log_debug "Common functions loaded from $SCRIPT_DIR"
cleanup_old_logs

# Export functions for use in subshells
export -f log_info log_error log_warning log_debug log_command
export -f validate_session_window validate_command sanitize_input
export -f check_rate_limit check_background_processes
export -f execute_command confirm_action