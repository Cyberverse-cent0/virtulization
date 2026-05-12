#!/usr/bin/bash
# ============================================================================
# print_and_log.sh - Demo Script showing all functionality
# ============================================================================

# Source the main library
source "lib/main_lib.sh"

# Demo function
demo_all_features() {
    print_header "PRINT_AND_LOG Demo"
    
    # Basic printing
    print_info "This is an info message (screen + log)"
    print_success "Operation successful!"
    print_warning "This is a warning message"
    print_error "This is an error message"
    
    # Enable debug mode
    DEBUG_MODE=1
    print_debug "Debug message (only shows when DEBUG_MODE=1)"
    
    # Validator demo
    echo
    print_header "Validator Demo"
    validate_not_empty "Hello" "Test String"
    validate_number "42" "Age"
    validate_email "test@example.com"
    validate_ip "192.168.1.1"
    
    # File operations demo
    echo
    print_header "File Operations Demo"
    create_directory "/tmp/test_dir"
    
    # System info demo
    echo
    print_header "System Information"
    get_system_info
    
    # Network demo
    echo
    print_header "Network Demo"
    check_internet
    get_public_ip
    
    # Text utils demo
    echo
    print_header "Text Utils Demo"
    local upper=$(to_uppercase "hello world")
    print_info "Uppercase: $upper"
    
    # Show log location
    echo
    print_separator "-"
    print_info "All messages have been logged to: $LOG_FILE"
    print_info "View logs with: tail -f $LOG_FILE"
}

# Run demo if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    demo_all_features
fi