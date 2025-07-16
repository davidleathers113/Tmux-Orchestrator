#!/bin/bash
# Test suite for schedule-reminder.sh

set -euo pipefail

# Test setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADAPTED_DIR="$(dirname "$SCRIPT_DIR")"
SCHEDULE_SCRIPT="${ADAPTED_DIR}/schedule-reminder.sh"
TEST_LOG="${ADAPTED_DIR}/logs/test-schedule-reminder.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Test functions
log_test() {
    echo -e "${YELLOW}[TEST]${NC} $1" | tee -a "$TEST_LOG"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1" | tee -a "$TEST_LOG"
    ((TESTS_PASSED++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1" | tee -a "$TEST_LOG"
    ((TESTS_FAILED++))
}

# Clean up function
cleanup() {
    # Cancel any test at jobs
    if command -v atq >/dev/null 2>&1; then
        # Get list of our test jobs and remove them
        atq 2>/dev/null | while read -r job_info; do
            job_id=$(echo "$job_info" | awk '{print $1}')
            if [[ -n "$job_id" ]]; then
                atrm "$job_id" 2>/dev/null || true
            fi
        done
    fi
    
    # Clean test reminders
    rm -rf "${ADAPTED_DIR}/reminders/reminder_test_"* 2>/dev/null || true
}

# Test 1: Script exists and is executable
test_script_exists() {
    log_test "Checking if schedule-reminder.sh exists and is executable"
    
    if [[ -f "$SCHEDULE_SCRIPT" && -x "$SCHEDULE_SCRIPT" ]]; then
        log_pass "Script exists and is executable"
    else
        log_fail "Script not found or not executable"
        return 1
    fi
}

# Test 2: Usage information
test_usage() {
    log_test "Testing usage information display"
    
    local output
    output=$("$SCHEDULE_SCRIPT" 2>&1 || true)
    
    if [[ "$output" =~ "Usage:" ]]; then
        log_pass "Usage information displayed correctly"
    else
        log_fail "Usage information not displayed"
        return 1
    fi
}

# Test 3: Invalid minutes validation
test_invalid_minutes() {
    log_test "Testing invalid minutes validation"
    
    # Test non-numeric
    local output
    output=$("$SCHEDULE_SCRIPT" "abc" "test note" 2>&1 || true)
    if [[ "$output" =~ "must be a positive integer" ]]; then
        log_pass "Non-numeric minutes rejected"
    else
        log_fail "Non-numeric minutes not properly validated"
    fi
    
    # Test negative
    output=$("$SCHEDULE_SCRIPT" "-5" "test note" 2>&1 || true)
    if [[ "$output" =~ "must be between" ]]; then
        log_pass "Negative minutes rejected"
    else
        log_fail "Negative minutes not properly validated"
    fi
    
    # Test too large
    output=$("$SCHEDULE_SCRIPT" "20000" "test note" 2>&1 || true)
    if [[ "$output" =~ "must be between" ]]; then
        log_pass "Excessive minutes rejected"
    else
        log_fail "Excessive minutes not properly validated"
    fi
}

# Test 4: Invalid note validation
test_invalid_note() {
    log_test "Testing invalid note validation"
    
    # Test empty note
    local output
    output=$("$SCHEDULE_SCRIPT" "5" "" 2>&1 || true)
    if [[ "$output" =~ "Note cannot be empty" ]]; then
        log_pass "Empty note rejected"
    else
        log_fail "Empty note not properly validated"
    fi
    
    # Test dangerous characters
    output=$("$SCHEDULE_SCRIPT" "5" 'test $(rm -rf /)' 2>&1 || true)
    if [[ "$output" =~ "invalid characters" ]]; then
        log_pass "Dangerous characters rejected"
    else
        log_fail "Dangerous characters not properly validated"
    fi
    
    # Test very long note
    local long_note=$(printf 'a%.0s' {1..600})
    output=$("$SCHEDULE_SCRIPT" "5" "$long_note" 2>&1 || true)
    if [[ "$output" =~ "Note too long" ]]; then
        log_pass "Long note rejected"
    else
        log_fail "Long note not properly validated"
    fi
}

# Test 5: Valid reminder scheduling
test_valid_scheduling() {
    log_test "Testing valid reminder scheduling"
    
    # Test file type reminder
    local output
    output=$("$SCHEDULE_SCRIPT" "2" "Test reminder for file" "file" 2>&1)
    
    if [[ "$output" =~ "Reminder scheduled successfully" ]] && [[ "$output" =~ "Reminder ID:" ]]; then
        log_pass "File reminder scheduled successfully"
        
        # Extract reminder ID for cleanup
        local reminder_id=$(echo "$output" | grep "Reminder ID:" | awk '{print $3}')
        if [[ -n "$reminder_id" ]]; then
            # Check if info file was created
            if [[ -f "${ADAPTED_DIR}/reminders/${reminder_id}.info" ]]; then
                log_pass "Reminder info file created"
            else
                log_fail "Reminder info file not created"
            fi
        fi
    else
        log_fail "File reminder scheduling failed"
    fi
    
    # Test log type reminder
    output=$("$SCHEDULE_SCRIPT" "2" "Test reminder for log" "log" 2>&1)
    if [[ "$output" =~ "Reminder scheduled successfully" ]]; then
        log_pass "Log reminder scheduled successfully"
    else
        log_fail "Log reminder scheduling failed"
    fi
}

# Test 6: Invalid reminder type
test_invalid_type() {
    log_test "Testing invalid reminder type validation"
    
    local output
    output=$("$SCHEDULE_SCRIPT" "5" "test note" "invalid_type" 2>&1 || true)
    
    if [[ "$output" =~ "Invalid reminder type" ]]; then
        log_pass "Invalid reminder type rejected"
    else
        log_fail "Invalid reminder type not properly validated"
    fi
}

# Test 7: AT command availability
test_at_command() {
    log_test "Testing 'at' command availability"
    
    if command -v at >/dev/null 2>&1; then
        log_pass "'at' command is available"
        
        # Test if we can list at jobs
        if atq >/dev/null 2>&1; then
            log_pass "'atq' command works"
        else
            log_fail "'atq' command not working"
        fi
    else
        log_fail "'at' command not available"
        return 1
    fi
}

# Test 8: Directory creation
test_directory_creation() {
    log_test "Testing reminders directory creation"
    
    # Remove reminders directory if it exists
    rm -rf "${ADAPTED_DIR}/reminders" 2>/dev/null || true
    
    # Schedule a reminder
    "$SCHEDULE_SCRIPT" "2" "Test directory creation" "file" >/dev/null 2>&1
    
    if [[ -d "${ADAPTED_DIR}/reminders" ]]; then
        log_pass "Reminders directory created automatically"
    else
        log_fail "Reminders directory not created"
    fi
}

# Main test execution
main() {
    echo "=== Schedule Reminder Test Suite ===" | tee "$TEST_LOG"
    echo "Date: $(date)" | tee -a "$TEST_LOG"
    echo "" | tee -a "$TEST_LOG"
    
    # Ensure logs directory exists
    mkdir -p "${ADAPTED_DIR}/logs"
    
    # Run tests
    test_script_exists
    test_usage
    test_invalid_minutes
    test_invalid_note
    test_valid_scheduling
    test_invalid_type
    test_at_command
    test_directory_creation
    
    # Clean up
    cleanup
    
    # Summary
    echo "" | tee -a "$TEST_LOG"
    echo "=== Test Summary ===" | tee -a "$TEST_LOG"
    echo "Tests Passed: $TESTS_PASSED" | tee -a "$TEST_LOG"
    echo "Tests Failed: $TESTS_FAILED" | tee -a "$TEST_LOG"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}All tests passed!${NC}" | tee -a "$TEST_LOG"
        exit 0
    else
        echo -e "${RED}Some tests failed!${NC}" | tee -a "$TEST_LOG"
        exit 1
    fi
}

# Run main function
main "$@"