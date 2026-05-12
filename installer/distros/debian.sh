#!/bin/bash
# Debian-specific setup for KVM/QEMU
set -euo pipefail

# Source main library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../lib" && pwd)"
source "${SCRIPT_DIR}/main_lib.sh"

main() {
    print_info "Starting Debian KVM/QEMU installation"

    # Check virtualization support
    if ! check_virtualization_support; then
        print_error "Hardware virtualization not supported"
        exit 1
    fi

    # Install virtualization packages
    print_info "Installing virtualization packages..."
    install_virt_packages

    # Enable and start libvirtd service
    print_info "Enabling libvirtd service..."
    enable_service libvirtd

    # Add current user to libvirt group
    print_info "Adding user to libvirt group..."
    add_user_to_libvirt

    # Create default network
    print_info "Setting up default network..."
    create_default_network

    # Verify installation
    if is_service_running libvirtd; then
        print_success "KVM/QEMU installation completed successfully"
        print_info "Please log out and back in for group changes to take effect"
    else
        print_error "Service libvirtd is not running"
        exit 1
    fi
}

main "$@"
