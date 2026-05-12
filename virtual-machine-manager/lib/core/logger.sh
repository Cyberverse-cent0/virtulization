#!/usr/bin/bash
# ============================================================================
# logger.sh - Advanced Logging System with Rotation
# Depends on: print_info.sh
# ============================================================================

# Get script directory
SCRIPT_DIR_LOGGER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR_LOGGER="$(dirname "$SCRIPT_DIR_LOGGER")"
PROJECT_ROOT_LOGGER="$(dirname "$LIB_DIR_LOGGER")"

# Source configuration
if [ -f "${LIB_DIR_LOGGER}/config/settings.conf" ]; then
    source "${LIB_DIR_LOGGER}/config/settings.conf"
fi

# Source print_info if available
if [ -f "${SCRIPT_DIR_LOGGER}/print_info.sh" ]; then
    source "${SCRIPT_DIR_LOGGER}/print_info.sh"
fi

# Log rotation function
rotate_logs() {
    local log_file="$1"
    local max_size="${2:-10M}"
    
    if [ ! -f "$log_file" ]; then
        return 0
    fi
    
    # Get file size
    local file_size=$(stat -c%s "$log_file" 2>/dev/null || stat -f%z "$log_file" 2>/dev/null)
    local max_size_bytes=$(echo "$max_size" | awk '/M$/ {print $1 * 1024 * 1024} /K$/ {print $1 * 1024} /G$/ {print $1 * 1024 * 1024 * 1024} /^[0-9]+$/ {print $1}')
    
    if [ "$file_size" -gt "$max_size_bytes" ]; then
        print_info "Rotating log file: $log_file"
        
        # Rotate existing logs
        for i in $(seq $((LOG_MAX_FILES - 1)) -1 1); do
            if [ -f "${log_file}.${i}" ]; then
                mv "${log_file}.${i}" "${log_file}.$((i + 1))"
            fi
        done
        
        # Rotate current log
        mv "$log_file" "${log_file}.1"
        touch "$log_file"
        print_success "Log rotation completed"
    fi
}

# Log with specific level
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local formatted="[${level}] ${timestamp} - ${message}"
    
    # Ensure log directory exists
    mkdir -p "$LOG_DIR" 2>/dev/null
    
    # Write to log file
    echo "$formatted" >> "$LOG_FILE"
    
    # Rotate if needed
    rotate_logs "$LOG_FILE" "$LOG_MAX_SIZE"
}

# Export function to be used by print_info.sh
export -f log_message