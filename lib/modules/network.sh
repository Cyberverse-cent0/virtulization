#!/usr/bin/bash
# ============================================================================
# network.sh - Network Operations Module
# Dependencies: print_info.sh, validator.sh
# ============================================================================

# Get directories
SCRIPT_DIR_NETWORK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR_NETWORK="$(dirname "$SCRIPT_DIR_NETWORK")"
CORE_DIR_NETWORK="${LIB_DIR_NETWORK}/core"

# Source dependencies
source "${CORE_DIR_NETWORK}/print_info.sh"
source "${CORE_DIR_NETWORK}/validator.sh"

# Check internet connectivity
check_internet() {
    local test_host="${1:-8.8.8.8}"
    
    print_info "Checking internet connectivity..."
    
    if ping -c 1 -W 2 "$test_host" &>/dev/null; then
        print_success "Internet connection available"
        return 0
    else
        print_error "No internet connection"
        return 1
    fi
}

# Get public IP address
get_public_ip() {
    print_info "Fetching public IP address..."
    
    local public_ip=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null)
    
    if [ -n "$public_ip" ]; then
        print_success "Public IP: $public_ip"
        echo "$public_ip"
        return 0
    else
        print_error "Failed to fetch public IP"
        return 1
    fi
}

# Get local IP address
get_local_ip() {
    local interface="${1:-}"
    
    if [ -n "$interface" ]; then
        ip -4 addr show "$interface" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1
    else
        # Get default interface IP
        ip -4 route get 1 2>/dev/null | grep -oP 'src \K\S+' | head -1
    fi
}

# Ping host and check response
ping_host() {
    local host="$1"
    local count="${2:-4}"
    
    print_info "Pinging $host..."
    
    if ping -c "$count" "$host" &>/dev/null; then
        print_success "Host $host is reachable"
        return 0
    else
        print_error "Host $host is not reachable"
        return 1
    fi
}

# Check if port is open
check_port() {
    local host="$1"
    local port="$2"
    local timeout="${3:-3}"
    
    validate_ip "$host" || return 1
    validate_port "$port" || return 1
    
    print_info "Checking if port $port is open on $host..."
    
    if timeout "$timeout" bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
        print_success "Port $port is open on $host"
        return 0
    else
        print_error "Port $port is closed on $host"
        return 1
    fi
}

# DNS lookup
dns_lookup() {
    local domain="$1"
    
    print_info "Performing DNS lookup for $domain..."
    
    local ip=$(dig +short "$domain" | head -1)
    
    if [ -n "$ip" ]; then
        print_success "$domain resolves to $ip"
        echo "$ip"
        return 0
    else
        print_error "Failed to resolve $domain"
        return 1
    fi
}

# Download file with progress
download_file() {
    local url="$1"
    local output_file="$2"
    
    print_info "Downloading $url to $output_file"
    
    if curl -L --progress-bar -o "$output_file" "$url"; then
        print_success "Download completed: $output_file"
        return 0
    else
        print_error "Download failed: $url"
        return 1
    fi
}