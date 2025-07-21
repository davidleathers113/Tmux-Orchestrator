# Hardcoded Paths in Tmux Orchestrator Repository

This document lists all hardcoded paths found in the repository that need to be replaced with configurable variables.

## Critical Hardcoded Paths

### 1. User-Specific Home Directory References

#### `/Users/jasonedward/` paths

**File: CLAUDE.md**
- Line 156: `PROJECT_PATH="/Users/jasonedward/Coding/$PROJECT_NAME"`
  - **Purpose**: Setting project path for new sessions
  - **Suggested replacement**: `PROJECT_PATH="${PROJECT_BASE_DIR}/$PROJECT_NAME"`

- Line 256: `tmux new-session -d -s task-templates -c "/Users/jasonedward/Coding/task-templates"`
  - **Purpose**: Creating tmux session with specific directory
  - **Suggested replacement**: `tmux new-session -d -s task-templates -c "${PROJECT_BASE_DIR}/task-templates"`

- Lines 260-261: Multiple tmux window creation commands with `/Users/jasonedward/Coding/task-templates`
  - **Purpose**: Creating tmux windows in specific directory
  - **Suggested replacement**: Use `${PROJECT_BASE_DIR}/task-templates`

- Lines 625, 629, 632, 635, 638, 649, 664, 670, 673, 679, 682, 688, 691, 702, 709: References to `/Users/jasonedward/Coding/Tmux orchestrator/send-claude-message.sh`
  - **Purpose**: Examples and documentation for using the send-claude-message.sh script
  - **Suggested replacement**: `${ORCHESTRATOR_HOME}/send-claude-message.sh`

**File: schedule_with_note.sh**
- Lines 10-13: Writing to `/Users/jasonedward/Coding/Tmux orchestrator/next_check_note.txt`
  - **Purpose**: Storing scheduled check notes
  - **Suggested replacement**: `${ORCHESTRATOR_HOME}/next_check_note.txt` or `${TEMP_DIR}/next_check_note.txt`

- Line 24: Command referencing `/Users/jasonedward/Coding/Tmux orchestrator/next_check_note.txt`
  - **Purpose**: Reading the note file during scheduled check
  - **Suggested replacement**: Same as above

#### `~/Coding/` paths

**File: CLAUDE.md**
- Lines 145-146, 149, 252: Commands using `~/Coding/` for listing projects
  - **Purpose**: Finding projects in the coding directory
  - **Suggested replacement**: `${PROJECT_BASE_DIR}/`

- Line 382, 385: Example commands with `~/Coding/[project-name]`
  - **Purpose**: Documentation examples
  - **Suggested replacement**: `${PROJECT_BASE_DIR}/[project-name]`

- Line 412: `~/Coding/Tmux orchestrator/registry/logs/[session]_[role]_$(date +%Y%m%d_%H%M%S).log`
  - **Purpose**: Log file path pattern
  - **Suggested replacement**: `${LOG_DIR}/[session]_[role]_$(date +%Y%m%d_%H%M%S).log`

- Line 426: `~/Coding/Tmux orchestrator/registry/`
  - **Purpose**: Registry directory reference
  - **Suggested replacement**: `${ORCHESTRATOR_HOME}/registry/`

### 2. Python Script References

**File: schedule_with_note.sh**
- Line 24: `python3 claude_control.py status detailed`
  - **Purpose**: Calling Python control script
  - **Suggested replacement**: `${ORCHESTRATOR_HOME}/claude_control.py status detailed` or ensure script is in PATH

**File: adapted-scripts/config/orchestrator.conf.template**
- Line 16: `"python3 claude_control.py"`
  - **Purpose**: Whitelisted command
  - **Suggested replacement**: Keep as is but document that script should be in project directory or PATH

### 3. Temporary Files

**File: adapted-scripts/config/orchestrator.conf.template**
- Line 55: `TEMP_DIR="/tmp/tmux-orchestrator"`
  - **Purpose**: Template for temporary directory
  - **Note**: This is already a template variable, good practice

## Recommendations

1. **Create a central configuration file** that defines:
   ```bash
   ORCHESTRATOR_HOME="/path/to/tmux-orchestrator"
   PROJECT_BASE_DIR="${HOME}/Coding"  # or user-specified
   LOG_DIR="${ORCHESTRATOR_HOME}/logs"
   TEMP_DIR="${TMPDIR:-/tmp}/tmux-orchestrator"
   ```

2. **Update all scripts** to source this configuration:
   ```bash
   source "${SCRIPT_DIR}/config/orchestrator.conf"
   ```

3. **Use relative paths** where possible:
   - For Python scripts called from shell scripts
   - For documentation references

4. **Environment variables** for user-specific paths:
   - `TMUX_ORCHESTRATOR_HOME`
   - `TMUX_ORCHESTRATOR_PROJECT_DIR`
   - `TMUX_ORCHESTRATOR_LOG_DIR`

5. **Update documentation** to use placeholders:
   - Replace `/Users/jasonedward/` with `${USER_HOME}/` or similar
   - Use generic examples like `/path/to/project`

## Personal Information Found

- **Username**: "jasonedward" appears throughout the codebase
  - Should be replaced with generic examples or environment variables

- **Directory structure**: Assumes macOS-style home directories (`/Users/`)
  - Should support Linux (`/home/`) and other systems

## System-Specific Assumptions

1. **Python executable**: Uses `python3` directly
   - Consider using `${PYTHON_BIN:-python3}` for flexibility

2. **Shell**: Assumes bash is available at `/bin/bash`
   - Scripts use bash-specific features

3. **Tmux**: Assumes tmux is installed and in PATH
   - No version checking or fallback behavior

## Priority Fixes

1. **HIGH**: Update `schedule_with_note.sh` to use configurable paths
2. **HIGH**: Remove all `/Users/jasonedward/` references
3. **MEDIUM**: Create central configuration system
4. **MEDIUM**: Update documentation to use generic examples
5. **LOW**: Add environment variable support for all paths