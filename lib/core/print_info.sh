#!/usr/bin/bash
# ============================================================================
# print_info.sh - Dual Output Function (Screen + Logger)
# Description: Prints to screen AND pipes to log file simultaneously
# ============================================================================

# Get the directory where this script resides
get_script_dir() {
    local source="${BASH_SOURCE[0]}"
    while [ -h "$source" ]; do
        local dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ $source != /* ]] && source="$dir/$source"
    done
    cd -P "$(dirname "$source")" && pwd
}

# Set up paths
if [ -z "${SCRIPT_DIR:-}" ]; then
    readonly SCRIPT_DIR="$(get_script_dir)"
fi
if [ -z "${LIB_DIR:-}" ]; then
    readonly LIB_DIR="$(dirname "$SCRIPT_DIR")"
fi
if [ -z "${PROJECT_ROOT:-}" ]; then
    readonly PROJECT_ROOT="$(dirname "$LIB_DIR")"
fi
if [ -z "${LOG_DIR:-}" ]; then
    readonly LOG_DIR="${PROJECT_ROOT}/logs"
fi
if [ -z "${LOG_FILE:-}" ]; then
    readonly LOG_FILE="${LOG_DIR}/app.log"
fi

# Create log directory and file if they don't exist
ensure_log_system() {
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR" 2>/dev/null || {
            echo "ERROR: Cannot create log directory: $LOG_DIR" >&2
            return 1
        }
    fi
    
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE" 2>/dev/null || {
            echo "ERROR: Cannot create log file: $LOG_FILE" >&2
            return 1
        }
    fi
}

# Core function: Print to screen AND log to file
print_info() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local formatted_message="[INFO] ${timestamp} - ${message}"
    
    # Print to screen (stdout)
    echo -e "\033[0;34m${formatted_message}\033[0m"
    
    # Append to log file
    ensure_log_system && echo "$formatted_message" >> "$LOG_FILE"
}

# Additional print functions with dual output
print_error() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local formatted_message="[ERROR] ${timestamp} - ${message}"
    
    # Print to stderr (screen)
    echo -e "\033[0;31m${formatted_message}\033[0m" >&2
    
    # Append to log file
    ensure_log_system && echo "$formatted_message" >> "$LOG_FILE"
}

print_success() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local formatted_message="[SUCCESS] ${timestamp} - ${message}"
    
    # Print to screen
    echo -e "\033[0;32m${formatted_message}\033[0m"
    
    # Append to log file
    ensure_log_system && echo "$formatted_message" >> "$LOG_FILE"
}

print_warning() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local formatted_message="[WARNING] ${timestamp} - ${message}"
    
    # Print to stderr (screen)
    echo -e "\033[1;33m${formatted_message}\033[0m" >&2
    
    # Append to log file
    ensure_log_system && echo "$formatted_message" >> "$LOG_FILE"
}

print_debug() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local formatted_message="[DEBUG] ${timestamp} - ${message}"
    
    # Only print if DEBUG mode is on
    if [ "${DEBUG_MODE:-0}" = "1" ]; then
        echo -e "\033[0;36m${formatted_message}\033[0m"
    fi
    
    # Always log debug messages
    ensure_log_system && echo "$formatted_message" >> "$LOG_FILE"
}

# Function to view logs
view_logs() {
    local lines="${1:-50}"
    if [ -f "$LOG_FILE" ]; then
        echo "=== Last $lines lines from $LOG_FILE ==="
        tail -n "$lines" "$LOG_FILE"
    else
        print_error "Log file not found: $LOG_FILE"
    fi
}

# Function to clear logs
clear_logs() {
    if confirm_action "Clear all logs?" "no"; then
        > "$LOG_FILE"
        print_success "Logs cleared"
    fi
}

# Simple confirmation function
confirm_action() {
    local message="${1:-Are you sure?}"
    local default="${2:-no}"
    
    local prompt="$message [y/N]: "
    if [ "$default" = "yes" ]; then
        prompt="$message [Y/n]: "
    fi
    
    read -r -p "$prompt" response
    response=${response:-$default}
    
    case "$response" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}

# Auto-initialize when sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Being sourced, initialize quietly
    ensure_log_system 2>/dev/null
fi

# If script is executed directly, demo mode
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "=== print_info.sh Demo ==="
    print_info "This is an info message (goes to screen and log)"
    print_success "Operation completed successfully!"
    print_warning "This is a warning message"
    print_error "This is an error message"
    print_debug "Debug message (only if DEBUG_MODE=1)"
    
    echo -e "\n=== Log file location: $LOG_FILE ==="
    view_logs 5
fi