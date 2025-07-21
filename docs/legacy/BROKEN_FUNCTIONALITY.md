# Tmux-Orchestrator Broken Functionality Report

## Critical Issues Found

### 1. Missing Python Files
The following files were deleted in commit 5db52bd but are still referenced:

- **claude_control.py** - Referenced in `schedule_with_note.sh` line 24
  - Used for: `python3 claude_control.py status detailed`
  - This breaks the entire scheduling functionality
  
- **claude_agent.py** - Deleted
- **orchestrator.py** - Deleted  
- **session_registry.py** - Deleted
- **github_integration.py** - Deleted
- **project_startup.py** - Deleted

### 2. Orphaned File Reference
- **orchestrator_integration.py** - Was added in the same commit but then also deleted
- The commit message mentions adding this file but it doesn't exist in the current repo

### 3. Schedule Script Broken
The `schedule_with_note.sh` script cannot function because:
```bash
# Line 24 references non-existent file:
python3 claude_control.py status detailed
```

### 4. Hardcoded Paths Issues
Multiple hardcoded paths that will fail on any system except the original:
- `/Users/jasonedward/Coding/Tmux\ orchestrator/next_check_note.txt`
- References to `~/Coding/` throughout documentation

### 5. No Error Handling
The scripts will fail silently due to:
- `nohup` redirecting errors to /dev/null
- No validation that referenced files exist
- No checks for tmux session/window existence

## Impact Assessment

1. **Scheduling System**: Completely non-functional
2. **Python Integration**: Most Python functionality removed
3. **Portability**: Scripts won't work on other systems without modification
4. **Reliability**: Silent failures make debugging difficult

## Required Fixes

1. Either restore the deleted Python files or remove references to them
2. Replace hardcoded paths with configurable variables
3. Add error handling and validation
4. Update documentation to match current codebase
5. Consider if the simplified version (just shell scripts) is the intended design