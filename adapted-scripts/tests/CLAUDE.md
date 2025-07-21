# adapted-scripts/tests/CLAUDE.md - Testing Framework

## Overview
Comprehensive test suite for validating the secure scheduling system. All tests focus on security boundaries, input validation, and error handling.

## Test Structure

### Test Categories
- **Security Tests** - Input validation, injection prevention
- **Functional Tests** - Core functionality verification  
- **Integration Tests** - Cross-script interactions
- **Performance Tests** - Load and stress testing
- **Regression Tests** - Previously identified issues

## Running Tests

### Full Test Suite
```bash
./run-tests.sh
```

### Specific Test Categories
```bash
./run-tests.sh --security    # Security tests only
./run-tests.sh --functional  # Functional tests only
./run-tests.sh --integration # Integration tests only
```

### Individual Tests
```bash
./test-input-validation.sh
./test-scheduling.sh
./test-message-delivery.sh
```

## Security Test Cases

### Input Validation Tests
```bash
# Command injection attempts
test_reject_semicolon
test_reject_pipe
test_reject_backticks
test_reject_dollar_parens

# Path traversal attempts
test_reject_dot_dot
test_reject_absolute_paths

# Time value validation
test_reject_negative_time
test_reject_huge_time
test_reject_non_numeric_time
```

### Target Validation Tests
```bash
# Format validation
test_valid_target_formats
test_invalid_target_formats

# Special character handling
test_reject_shell_metacharacters
test_handle_unicode_safely
```

## Functional Test Cases

### Scheduling Tests
```bash
# Basic scheduling
test_schedule_simple_reminder
test_schedule_with_target
test_schedule_minimum_time
test_schedule_maximum_time

# Error handling
test_missing_parameters
test_invalid_window
test_permission_errors
```

### Message Delivery Tests
```bash
# Message handling
test_simple_message
test_multiline_message
test_empty_message
test_maximum_length_message

# Target validation
test_window_exists
test_pane_exists
test_session_not_found
```

## Test Utilities

### Mock Environment
```bash
# Create test tmux session
setup_test_environment() {
    tmux new-session -d -s test-session
    tmux new-window -t test-session:1
}

# Cleanup
cleanup_test_environment() {
    tmux kill-session -t test-session 2>/dev/null || true
}
```

### Assertion Functions
```bash
# Check exit codes
assert_success() { test $? -eq 0; }
assert_failure() { test $? -ne 0; }

# Check output
assert_contains() { echo "$1" | grep -q "$2"; }
assert_not_contains() { ! echo "$1" | grep -q "$2"; }
```

## Writing New Tests

### Test Template
```bash
#!/bin/bash
source ./test-common.sh

test_description() {
    echo "Test: Verify specific behavior"
    
    # Setup
    setup_test_environment
    
    # Execute
    output=$(../script.sh "args" 2>&1)
    exit_code=$?
    
    # Verify
    assert_equals "$exit_code" "0"
    assert_contains "$output" "expected string"
    
    # Cleanup
    cleanup_test_environment
}

# Run test
test_description
```

### Best Practices
1. **Isolate tests** - Each test should be independent
2. **Clean up** - Always restore original state
3. **Test boundaries** - Focus on edge cases
4. **Document intent** - Clear test descriptions
5. **Verify security** - Always test validation

## Continuous Integration

### Pre-commit Hook
```bash
#!/bin/bash
# Run security tests before commit
cd adapted-scripts/tests/
./run-tests.sh --security --quick
```

### Full CI Pipeline
```bash
# Run all tests with coverage
./run-tests.sh --all --coverage

# Generate report
./generate-test-report.sh > test-report.txt
```

## Known Issues

### Timing Sensitive Tests
Some tests may fail due to system load. Retry with:
```bash
ORCHESTRATOR_TEST_DELAY=2 ./run-tests.sh
```

### Permission Tests
Require specific file system setup. Skip with:
```bash
./run-tests.sh --skip-permission-tests
```