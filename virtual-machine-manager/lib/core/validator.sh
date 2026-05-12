#!/usr/bin/bash
# ============================================================================
# validator.sh - Input Validation Functions
# Dependencies: print_info.sh
# ============================================================================

# Source print_info if available
SCRIPT_DIR_VALIDATOR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR_VALIDATOR}/print_info.sh" ]; then
    source "${SCRIPT_DIR_VALIDATOR}/print_info.sh"
fi

# Validate non-empty string
validate_not_empty() {
    local value="$1"
    local field_name="${2:-Value}"
    
    if [ -z "$value" ]; then
        print_error "${field_name} cannot be empty"
        return 1
    fi
    print_success "${field_name} is valid"
    return 0
}

# Validate number (integer)
validate_number() {
    local value="$1"
    local field_name="${2:-Number}"
    
    if [[ "$value" =~ ^-?[0-9]+$ ]]; then
        print_success "${field_name} is valid number: $value"
        return 0
    else
        print_error "${field_name} must be a number (got: $value)"
        return 1
    fi
}

# Validate positive integer
validate_positive_int() {
    local value="$1"
    local field_name="${2:-Value}"
    
    if [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -gt 0 ]; then
        print_success "${field_name} is positive integer: $value"
        return 0
    else
        print_error "${field_name} must be positive integer (got: $value)"
        return 1
    fi
}

# Validate email format
validate_email() {
    local email="$1"
    local email_regex="^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"
    
    if [[ "$email" =~ $email_regex ]]; then
        print_success "Valid email: $email"
        return 0
    else
        print_error "Invalid email format: $email"
        return 1
    fi
}

# Validate file exists
validate_file_exists() {
    local file="$1"
    
    if [ -f "$file" ]; then
        print_success "File exists: $file"
        return 0
    else
        print_error "File not found: $file"
        return 1
    fi
}

# Validate directory exists
validate_dir_exists() {
    local dir="$1"
    
    if [ -d "$dir" ]; then
        print_success "Directory exists: $dir"
        return 0
    else
        print_error "Directory not found: $dir"
        return 1
    fi
}

# Validate is readable
validate_readable() {
    local file="$1"
    
    if [ -r "$file" ]; then
        print_success "File is readable: $file"
        return 0
    else
        print_error "File is not readable: $file"
        return 1
    fi
}

# Validate is writable
validate_writable() {
    local file="$1"
    
    if [ -w "$file" ]; then
        print_success "File is writable: $file"
        return 0
    else
        print_error "File is not writable: $file"
        return 1
    fi
}

# Validate IP address
validate_ip() {
    local ip="$1"
    
    if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        IFS='.' read -r -a octets <<< "$ip"
        valid=true
        for octet in "${octets[@]}"; do
            if [ "$octet" -gt 255 ] || [ "$octet" -lt 0 ]; then
                valid=false
                break
            fi
        done
        
        if [ "$valid" = true ]; then
            print_success "Valid IP address: $ip"
            return 0
        fi
    fi
    print_error "Invalid IP address: $ip"
    return 1
}

# Validate port number
validate_port() {
    local port="$1"
    
    if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ]; then
        print_success "Valid port: $port"
        return 0
    else
        print_error "Invalid port (1-65535): $port"
        return 1
    fi
}