# Migration Notes: schedule-reminder.sh

## Overview

The `schedule-reminder.sh` script is a safe replacement for the original `schedule_with_note.sh`. This document outlines the key differences and migration considerations.

## Key Differences from Original

### 1. Security Improvements

#### Original Issues:
- Used `nohup` with background processes that could persist indefinitely
- Executed arbitrary tmux commands with user input
- Referenced hardcoded paths (`/Users/jasonedward/Coding/Tmux\ orchestrator/`)
- Depended on missing `claude_control.py` file
- No input validation
- Used potentially unsafe command substitution with `bc`

#### New Implementation:
- Uses the system's `at` command for proper job scheduling
- All inputs are strictly validated
- No arbitrary command execution
- No hardcoded paths - uses relative paths from script location
- No external Python dependencies
- Comprehensive input sanitization

### 2. Feature Changes

#### Removed Features:
- Direct tmux window interaction (security risk)
- Automatic execution of Python scripts
- Real-time process tracking via PID
- Floating-point minute calculations

#### New Features:
- Three reminder types: `file`, `log`, and `display`
- Proper job scheduling with `at` command
- Reminder persistence in info files
- Optional desktop notifications (macOS)
- Automatic cleanup of executed reminder scripts
- Comprehensive logging

### 3. Usage Differences

#### Original Usage:
```bash
./schedule_with_note.sh <minutes> "<note>" [target_window]
```

#### New Usage:
```bash
./schedule-reminder.sh <minutes> "<note>" [reminder_type]
```

### 4. Reminder Types

The new script supports three reminder types instead of tmux window targeting:

1. **file** (default): Saves reminder to a text file in `reminders/` directory
2. **log**: Logs reminder to the system log file
3. **display**: Shows desktop notification (if available) and logs

### 5. Input Validation

The new script validates:
- Minutes must be between 1 and 10,080 (7 days)
- Notes cannot exceed 500 characters
- Notes cannot contain shell metacharacters or command substitutions
- Reminder type must be one of: file, log, display

### 6. File Structure

#### Original Structure:
```
/Users/jasonedward/Coding/Tmux orchestrator/
├── next_check_note.txt
├── claude_control.py
└── schedule_with_note.sh
```

#### New Structure:
```
adapted-scripts/
├── schedule-reminder.sh
├── reminders/           # Created automatically
│   ├── reminder_*.txt   # Reminder content files
│   ├── reminder_*.info  # Reminder metadata
│   └── reminder_*.sh    # Temporary execution scripts
└── logs/
    └── reminders.log    # Reminder activity log
```

## Migration Guide

### For Users

1. **Update Scripts**: Replace calls to `schedule_with_note.sh` with `schedule-reminder.sh`

2. **Adjust Parameters**: 
   - Replace tmux window targets with reminder types
   - Example: `./schedule_with_note.sh 30 "Check status" "tmux-orc:0"`
   - Becomes: `./schedule-reminder.sh 30 "Check status" "display"`

3. **Check Reminders**: 
   - File reminders: Check `adapted-scripts/reminders/` directory
   - Log reminders: Check `adapted-scripts/logs/reminders.log`
   - Display reminders: Will show as desktop notifications

4. **View Scheduled Jobs**: Use `atq` command to see pending reminders

5. **Cancel Reminders**: Use `atrm <job_id>` to cancel scheduled reminders

### For Developers

1. **No Python Dependencies**: The new script is pure Bash, removing the `claude_control.py` dependency

2. **Error Handling**: All errors are logged with proper error codes

3. **Testing**: Use `tests/test-schedule-reminder.sh` to verify functionality

4. **Extension**: Add new reminder types by modifying the `create_reminder_script` function

## Limitations

1. **AT Command Required**: The script requires the `at` daemon to be running
   - On macOS: May need to enable in System Preferences
   - On Linux: Usually available by default

2. **No Real-time Tracking**: Unlike the original's PID tracking, you must use `atq` to see scheduled jobs

3. **No Direct tmux Integration**: For security, the script doesn't interact with tmux sessions

## Security Considerations

1. **Input Sanitization**: All user input is validated and sanitized
2. **No Command Injection**: Shell metacharacters are blocked in notes
3. **Temporary Files**: Reminder scripts are automatically deleted after execution
4. **Logging**: All operations are logged for audit purposes

## Troubleshooting

### AT Command Not Working

If you get errors about the `at` command:

1. **macOS**: Enable in System Preferences → Security & Privacy → Privacy → Full Disk Access
2. **Linux**: Ensure `atd` service is running: `sudo systemctl start atd`

### Reminders Not Executing

1. Check if `atd` is running: `ps aux | grep atd`
2. Check at queue: `atq`
3. Check logs: `adapted-scripts/logs/reminders.log`

### Permission Issues

Ensure the script has execute permissions:
```bash
chmod +x adapted-scripts/schedule-reminder.sh
```

## Alternative If AT Is Unavailable

If the `at` command is not available or cannot be enabled, use the included `simple-reminder.sh` script:

### Simple Reminder System

The `simple-reminder.sh` script provides a manual reminder system that doesn't require the `at` daemon:

#### Usage:
```bash
# Add a reminder
./simple-reminder.sh add 30 "Check deployment status"

# List all pending reminders
./simple-reminder.sh list

# Check for due reminders (run this periodically)
./simple-reminder.sh check

# Clear expired reminders
./simple-reminder.sh clear

# Get cron setup instructions
./simple-reminder.sh cron
```

#### Features:
- Stores reminders in a simple text file
- No daemon dependencies
- Manual checking required (or use cron)
- Desktop notifications on macOS (if available)
- Safe input validation

#### Automation with Cron:
To automatically check reminders every 5 minutes:
```bash
# Add to crontab (run 'crontab -e')
*/5 * * * * /path/to/adapted-scripts/simple-reminder.sh check >> /path/to/logs/reminder-checks.log 2>&1
```

This approach is less sophisticated than the `at`-based system but works reliably without system daemon requirements.