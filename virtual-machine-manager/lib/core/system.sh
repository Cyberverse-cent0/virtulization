#!/usr/bin/bash
# ============================================================================
# system.sh - System Information and Utilities
# Dependencies: print_info.sh
# ============================================================================

# Source print_info
SCRIPT_DIR_SYSTEM="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR_SYSTEM}/print_info.sh" ]; then
    source "${SCRIPT_DIR_SYSTEM}/print_info.sh"
fi

# Check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        print_success "Running as root"
        return 0
    else
        print_error "This operation requires root privileges"
        return 1
    fi
}

# Check if running as specific user
check_user() {
    local expected_user="$1"
    local current_user=$(whoami)
    
    if [ "$current_user" = "$expected_user" ]; then
        print_success "Running as expected user: $current_user"
        return 0
    else
        print_error "Expected user: $expected_user, Current user: $current_user"
        return 1
    fi
}

# Get system information
get_system_info() {
    print_info "=== System Information ==="
    echo "Hostname: $(hostname)"
    echo "OS: $(uname -s)"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo "CPU Cores: $(nproc)"
    echo "Memory: $(free -h | awk '/^Mem:/ {print $2}')"
    echo "Disk Usage: $(df -h / | awk 'NR==2 {print $5}')"
    echo "Uptime: $(uptime -p)"
    echo "Current User: $(whoami)"
    echo "Current Directory: $(pwd)"
}

# Get CPU usage
get_cpu_usage() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    echo "$cpu_usage"
}

# Get memory usage
get_memory_usage() {
    local mem_usage=$(free | grep Mem | awk '{print ($3/$2) * 100.0}')
    echo "${mem_usage%.*}"  # Return as integer
}

# Get disk usage
get_disk_usage() {
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    echo "$disk_usage"
}

# Check system health
check_system_health() {
    print_info "Checking system health..."
    
    local cpu=$(get_cpu_usage)
    local mem=$(get_memory_usage)
    local disk=$(get_disk_usage)
    
    echo "CPU Usage: ${cpu}%"
    echo "Memory Usage: ${mem}%"
    echo "Disk Usage: ${disk}%"
    
    if [ "${cpu%.*}" -gt 90 ]; then
        print_warning "High CPU usage: ${cpu}%"
    fi
    
    if [ "${mem%.*}" -gt 90 ]; then
        print_warning "High memory usage: ${mem}%"
    fi
    
    if [ "$disk" -gt 90 ]; then
        print_warning "High disk usage: ${disk}%"
    fi
    
    print_success "System health check completed"
}

# Wait with progress indicator
wait_with_progress() {
    local seconds="$1"
    local message="${2:-Waiting}"
    
    print_info "$message"
    for i in $(seq 1 "$seconds"); do
        printf "."
        sleep 1
    done
    echo
    print_success "Wait completed"
}