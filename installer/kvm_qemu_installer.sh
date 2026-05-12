#!/bin/bash
# Main KVM/QEMU installer
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source main library
source "${SCRIPT_DIR}/../lib/main_lib.sh"

# Detect distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    elif [ -f /etc/redhat-release ]; then
        echo "rhel"
    elif [ -f /etc/arch-release ]; then
        echo "arch"
    else
        echo "unknown"
    fi
}

main() {
    local dry_run=false
    if [ "${1:-}" = "--dry-run" ]; then
        dry_run=true
    fi

    print_info "KVM/QEMU Universal Installer"
    print_info "============================"

    local distro=$(detect_distro)
    print_info "Detected distribution: $distro"

    if $dry_run; then
        print_info "Dry run mode - would run setup for $distro"
        return
    fi

    case $distro in
        ubuntu)
            print_info "Running Ubuntu setup..."
            bash "${SCRIPT_DIR}/distros/ubuntu.sh"
            ;;
        debian)
            print_info "Running Debian setup..."
            bash "${SCRIPT_DIR}/distros/debian.sh"
            ;;
        centos|rhel|almalinux|rocky)
            print_info "Running CentOS/RHEL setup..."
            bash "${SCRIPT_DIR}/distros/centos.sh"
            ;;
        fedora)
            print_info "Running Fedora setup..."
            bash "${SCRIPT_DIR}/distros/fedora.sh"
            ;;
        arch|manjaro)
            print_info "Running Arch Linux setup..."
            bash "${SCRIPT_DIR}/distros/arch.sh"
            ;;
        *)
            print_error "Unsupported distribution: $distro"
            print_info "Supported distributions: Ubuntu, Debian, CentOS, Fedora, Arch"
            exit 1
            ;;
    esac

    print_success "Installation completed!"
    print_info "You can now use virt-manager or virsh to manage VMs"
}

main "$@"
