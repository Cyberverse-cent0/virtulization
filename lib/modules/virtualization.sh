#!/bin/bash
# Virtualization helper module
# Provides universal functions for virtualization setup across distros

set -euo pipefail

# ============================================================================
# Universal Package Management Functions
# ============================================================================

# Detect package manager
detect_package_manager() {
    if command -v apt >/dev/null 2>&1; then
        echo "apt"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

# Universal package installer
install_package() {
    local packages=("$@")
    local pm=$(detect_package_manager)

    case $pm in
        apt)
            sudo apt update
            sudo apt install -y "${packages[@]}"
            ;;
        yum)
            sudo yum install -y "${packages[@]}"
            ;;
        dnf)
            sudo dnf install -y "${packages[@]}"
            ;;
        pacman)
            sudo pacman -Syu --noconfirm "${packages[@]}"
            ;;
        *)
            echo "Unsupported package manager: $pm"
            return 1
            ;;
    esac
}

# ============================================================================
# Service Management Functions
# ============================================================================

# Enable and start service
enable_service() {
    local service=$1
    sudo systemctl enable "$service"
    sudo systemctl start "$service"
}

# Check if service is running
is_service_running() {
    local service=$1
    systemctl is-active --quiet "$service"
}

# ============================================================================
# Virtualization Support Functions
# ============================================================================

# Check if virtualization is supported
check_virtualization_support() {
    if grep -q -E '(vmx|svm)' /proc/cpuinfo; then
        echo "Hardware virtualization supported"
        return 0
    else
        echo "Hardware virtualization not supported"
        return 1
    fi
}

# Check if KVM is available
check_kvm_available() {
    if [ -c /dev/kvm ]; then
        echo "KVM device available"
        return 0
    else
        echo "KVM device not available"
        return 1
    fi
}

# Add user to libvirt group
add_user_to_libvirt() {
    local user=${1:-$(whoami)}
    sudo usermod -a -G libvirt "$user"
    echo "Added $user to libvirt group. Please log out and back in for changes to take effect."
}

# ============================================================================
# Common Virtualization Packages
# ============================================================================

# Get distro-specific packages
get_virt_packages() {
    local pm=$(detect_package_manager)
    local packages=()

    case $pm in
        apt)
            packages=(
                qemu-kvm
                libvirt-daemon-system
                libvirt-clients
                virt-manager
                bridge-utils
                virtinst
                libguestfs-tools
            )
            ;;
        yum|dnf)
            packages=(
                qemu-kvm
                libvirt
                libvirt-daemon-kvm
                virt-manager
                virt-install
                libguestfs-tools
            )
            ;;
        pacman)
            packages=(
                qemu
                libvirt
                virt-manager
                bridge-utils
                virt-install
                libguestfs
            )
            ;;
        *)
            echo "Unknown package manager"
            return 1
            ;;
    esac

    echo "${packages[@]}"
}

# Install virtualization packages
install_virt_packages() {
    local packages
    packages=$(get_virt_packages)
    install_package $packages
}

# ============================================================================
# Network Setup Functions
# ============================================================================

# Create default network bridge
create_default_network() {
    local net_xml="${MAIN_LIB_DIR}/../installer/templates/network_default.xml"
    if [ -f "$net_xml" ]; then
        sudo virsh net-define "$net_xml"
        sudo virsh net-start default
        sudo virsh net-autostart default
    else
        echo "Network template not found: $net_xml"
    fi
}

# ============================================================================
# VM Creation Functions
# ============================================================================

# Create VM from template
create_vm_from_template() {
    local vm_name=$1
    local template_xml="${MAIN_LIB_DIR}/../installer/templates/vm_template.xml"
    local vm_xml="/tmp/${vm_name}.xml"

    if [ ! -f "$template_xml" ]; then
        echo "VM template not found: $template_xml"
        return 1
    fi

    # Copy and customize template
    cp "$template_xml" "$vm_xml"
    sed -i "s/vm-name/$vm_name/g" "$vm_xml"

    # Define VM
    sudo virsh define "$vm_xml"
    rm "$vm_xml"

    echo "VM $vm_name created successfully"
}

# List running VMs
list_running_vms() {
    sudo virsh list --all
}

# ============================================================================
# Utility Functions
# ============================================================================

# Log virtualization operations
log_virt_operation() {
    local message=$1
    local log_file="${LOG_DIR}/vm_operations.log"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$log_file"
}

# Validate VM name
validate_vm_name() {
    local name=$1
    if [[ $name =~ ^[a-zA-Z0-9_-]+$ ]]; then
        return 0
    else
        echo "Invalid VM name. Use only letters, numbers, hyphens, and underscores."
        return 1
    fi
}
