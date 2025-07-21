# Claude Custom Commands Documentation

## Overview
This directory contains custom commands that Claude can use. Commands are automatically loaded when Claude starts in a project with a `.claude/commands/` directory.

## Available Commands

### `/pm-oversight`
**Purpose**: Project management oversight for coordinating multiple agents  
**Location**: `pm-oversight.md`  
**Syntax**: `/pm-oversight <agent-names> SPEC: <spec-file-path>`  
**Allowed Tools**: Bash, Read, TodoWrite, TodoRead, Task

**Examples**:
```
/pm-oversight dce-engineer SPEC: ~/dce-whiteboard-spec.md
/pm-oversight frontend and backend SPEC: /path/to/project-spec.md
/pm-oversight test-frontend and test-backend SPEC: ~/tmux-test-spec.md
```

**What it does**:
- Creates a LOCK on specified projects
- Enables PM oversight capabilities
- Schedules regular check-ins with engineers
- Monitors server logs and errors
- Ensures spec compliance

**Important Notes**:
- ✅ CORRECT: `/pm-oversight` (no prefix)
- ❌ WRONG: `/project:pm-oversight` (no category prefixes!)
- The command expects "SPEC:" to separate project names from spec file path
- Multiple projects can be specified with "and" between them

## How Commands Work

1. **Automatic Loading**: Claude scans `.claude/commands/` on startup
2. **Command Format**: `/` + filename (without .md extension)
3. **No Prefixes**: Commands don't use category prefixes like `project:` or `command:`
4. **Metadata**: Each command file includes allowed tools in YAML frontmatter

## Common Mistakes to Avoid

### ❌ Using Category Prefixes
```
# WRONG - This will not work
/project:pm-oversight ...
/command:pm-oversight ...
/system:pm-oversight ...

# CORRECT - Just the command name
/pm-oversight ...
```

### ❌ Forgetting the SPEC Separator
```
# WRONG - Missing SPEC:
/pm-oversight dce-engineer ~/spec.md

# CORRECT - Include SPEC:
/pm-oversight dce-engineer SPEC: ~/spec.md
```

### ❌ Wrong Path Assumptions
```
# WRONG - Assuming commands are global
~/.claude/commands/pm-oversight  # This is for global commands

# CORRECT - Project-specific commands
.claude/commands/pm-oversight.md  # In project root
```

## Creating New Commands

To add a new command:

1. Create a `.md` file in this directory
2. Add YAML frontmatter with description and allowedTools
3. Write the command implementation
4. The command will be available as `/filename` (without .md)

Example structure:
```markdown
---
description: Brief description of what the command does
allowedTools: ["Bash", "Read", "Write", "Edit"]
---

Command implementation and instructions...
```

## Global vs Project Commands

- **Project Commands** (this directory): `.claude/commands/`
  - Only available in this project
  - Override global commands with same name
  
- **Global Commands**: `~/.claude/commands/`
  - Available in all projects
  - Examples: `/scan-system-docs`

## Troubleshooting

### Command Not Found
1. Check spelling - must match filename exactly
2. Verify file exists in `.claude/commands/`
3. Ensure no category prefix is used
4. Restart Claude to reload commands

### Command Not Working as Expected
1. Check the command file for correct syntax
2. Verify allowed tools include what you need
3. Check for typos in arguments (especially SPEC:)
4. Review the command's implementation

## Best Practices

1. **Document Commands**: Always include examples in command files
2. **Version Control**: Commit `.claude/commands/` to git
3. **Test Commands**: Try commands manually before automation
4. **Clear Naming**: Use descriptive command names
5. **Update Documentation**: Keep this README current

---

*Last Updated: July 21, 2025 - After DCE Orchestrator Post-Mortem*