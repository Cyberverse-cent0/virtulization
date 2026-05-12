#!/usr/bin/bash
# ============================================================================
# vm_manager.sh - VM Management Module
# Description: Manages VM lifecycle operations
# ============================================================================

# Source main library if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")"
if [ -f "${LIB_DIR}/main_lib.sh" ]; then
    source "${LIB_DIR}/main_lib.sh"
fi

# ============================================================================
# VM MANAGER FUNCTIONS
# ============================================================================

# Create new VM
vm_create() {
    local vm_name="$1"
    local memory_mb="${2:-2048}"
    local vcpus="${3:-2}"
    local disk_size_gb="${4:-20}"
    local iso_path="${5:-}"

    print_info "Creating VM: $vm_name"

    # Validate inputs
    if ! validate_not_empty "$vm_name" "VM name"; then return 1; fi
    if ! validate_number "$memory_mb" "Memory (MB)"; then return 1; fi
    if ! validate_number "$vcpus" "VCPUs"; then return 1; fi
    if ! validate_number "$disk_size_gb" "Disk size (GB)"; then return 1; fi

    # Check if VM already exists
    if virsh dominfo "$vm_name" >/dev/null 2>&1; then
        print_error "VM already exists: $vm_name"
        return 1
    fi

    # Create disk image
    local disk_path="${VM_STORAGE_LOCATION}/images/${vm_name}.qcow2"
    print_info "Creating disk image: $disk_path"

    qemu-img create -f qcow2 "$disk_path" "${disk_size_gb}G"
    if [ $? -ne 0 ]; then
        print_error "Failed to create disk image"
        return 1
    fi

    # Create VM using virt-install
    print_info "Installing VM with virt-install"

    local install_cmd="virt-install --name $vm_name --memory $memory_mb --vcpus $vcpus --disk $disk_path --network network=default"

    if [[ "$iso_path" ]]; then
        if [ -f "$iso_path" ]; then
            install_cmd="$install_cmd --cdrom $iso_path"
        else
            print_warning "ISO not found, creating VM without installation media"
        fi
    fi

    install_cmd="$install_cmd --os-variant generic --graphics vnc --noautoconsole"

    print_debug "Running: $install_cmd"

    if eval "$install_cmd"; then
        print_success "VM created successfully: $vm_name"
        return 0
    else
        print_error "Failed to create VM: $vm_name"
        # Clean up disk image
        rm -f "$disk_path"
        return 1
    fi
}

# Delete VM
vm_delete() {
    local vm_name="$1"

    print_info "Deleting VM: $vm_name"

    # Check if VM exists
    if ! virsh dominfo "$vm_name" >/dev/null 2>&1; then
        print_error "VM does not exist: $vm_name"
        return 1
    fi

    # Stop VM if running
    if virsh domstate "$vm_name" | grep -q "running"; then
        print_info "Stopping VM before deletion"
        vm_stop "$vm_name"
    fi

    # Undefine VM
    if virsh undefine "$vm_name" --remove-all-storage; then
        print_success "VM deleted: $vm_name"
        return 0
    else
        print_error "Failed to delete VM: $vm_name"
        return 1
    fi
}

# Start VM
vm_start() {
    local vm_name="$1"

    print_info "Starting VM: $vm_name"

    if virsh start "$vm_name"; then
        print_success "VM started: $vm_name"
        return 0
    else
        print_error "Failed to start VM: $vm_name"
        return 1
    fi
}

# Stop VM
vm_stop() {
    local vm_name="$1"

    print_info "Stopping VM: $vm_name"

    if virsh shutdown "$vm_name"; then
        print_success "VM shutdown initiated: $vm_name"
        return 0
    else
        print_error "Failed to shutdown VM: $vm_name"
        return 1
    fi
}

# Restart VM
vm_restart() {
    local vm_name="$1"

    print_info "Restarting VM: $vm_name"

    if virsh reboot "$vm_name"; then
        print_success "VM restarted: $vm_name"
        return 0
    else
        print_error "Failed to restart VM: $vm_name"
        return 1
    fi
}

# List all VMs
vm_list() {
    print_header "Virtual Machines"

    virsh list --all
}

# Get VM information
vm_info() {
    local vm_name="$1"

    print_header "VM Information: $vm_name"

    if virsh dominfo "$vm_name" 2>/dev/null; then
        echo
        echo "Network interfaces:"
        virsh domiflist "$vm_name" 2>/dev/null || echo "No network interfaces found"

        echo
        echo "Disk devices:"
        virsh domblklist "$vm_name" 2>/dev/null || echo "No disk devices found"
    else
        print_error "VM not found: $vm_name"
        return 1
    fi
}

# Clone VM
vm_clone() {
    local source_vm="$1"
    local new_vm="$2"

    print_info "Cloning VM $source_vm to $new_vm"

    if ! virsh dominfo "$source_vm" >/dev/null 2>&1; then
        print_error "Source VM does not exist: $source_vm"
        return 1
    fi

    if virsh dominfo "$new_vm" >/dev/null 2>&1; then
        print_error "Target VM already exists: $new_vm"
        return 1
    fi

    # Stop source VM if running
    local was_running=false
    if virsh domstate "$source_vm" | grep -q "running"; then
        print_info "Stopping source VM for cloning"
        vm_stop "$source_vm"
        was_running=true
    fi

    # Clone using virt-clone
    if virt-clone --original "$source_vm" --name "$new_vm" --auto-clone; then
        print_success "VM cloned successfully: $new_vm"

        # Restart source VM if it was running
        if [ "$was_running" = true ]; then
            vm_start "$source_vm"
        fi

        return 0
    else
        print_error "Failed to clone VM"
        # Restart source VM if it was running
        if [ "$was_running" = true ]; then
            vm_start "$source_vm"
        fi
        return 1
    fi
}

# Create snapshot
vm_snapshot_create() {
    local vm_name="$1"
    local snapshot_name="$2"

    print_info "Creating snapshot for VM $vm_name: $snapshot_name"

    if virsh snapshot-create-as "$vm_name" "$snapshot_name"; then
        print_success "Snapshot created: $snapshot_name"
        return 0
    else
        print_error "Failed to create snapshot"
        return 1
    fi
}

# Restore snapshot
vm_snapshot_restore() {
    local vm_name="$1"
    local snapshot_name="$2"

    print_info "Restoring snapshot for VM $vm_name: $snapshot_name"

    if virsh snapshot-revert "$vm_name" "$snapshot_name"; then
        print_success "Snapshot restored: $snapshot_name"
        return 0
    else
        print_error "Failed to restore snapshot"
        return 1
    fi
}

# Delete snapshot
vm_snapshot_delete() {
    local vm_name="$1"
    local snapshot_name="$2"

    print_info "Deleting snapshot for VM $vm_name: $snapshot_name"

    if virsh snapshot-delete "$vm_name" "$snapshot_name"; then
        print_success "Snapshot deleted: $snapshot_name"
        return 0
    else
        print_error "Failed to delete snapshot"
        return 1
    fi
}

# Resize VM disk
vm_resize_disk() {
    local vm_name="$1"
    local new_size_gb="$2"

    print_info "Resizing disk for VM $vm_name to ${new_size_gb}G"

    # Get disk path
    local disk_path=$(virsh domblklist "$vm_name" | grep vda | awk '{print $2}')

    if [ -z "$disk_path" ]; then
        print_error "Could not find disk path for VM: $vm_name"
        return 1
    fi

    # Resize disk image
    if qemu-img resize "$disk_path" "${new_size_gb}G"; then
        print_success "Disk resized to ${new_size_gb}G"
        print_info "Note: VM may need to be restarted and filesystem resized inside guest"
        return 0
    else
        print_error "Failed to resize disk"
        return 1
    fi
}

# Add new disk
vm_add_disk() {
    local vm_name="$1"
    local disk_size_gb="$2"
    local disk_name="${3:-${vm_name}_data}"

    print_info "Adding disk to VM $vm_name: ${disk_name} (${disk_size_gb}G)"

    local disk_path="${VM_STORAGE_LOCATION}/disks/${disk_name}.qcow2"

    # Create disk image
    qemu-img create -f qcow2 "$disk_path" "${disk_size_gb}G"

    # Attach to VM
    if virsh attach-disk "$vm_name" "$disk_path" vdb --driver qemu --subdriver qcow2 --cache none; then
        print_success "Disk added successfully"
        return 0
    else
        print_error "Failed to add disk"
        rm -f "$disk_path"
        return 1
    fi
}

# Remove disk
vm_remove_disk() {
    local vm_name="$1"
    local target="${2:-vdb}"

    print_info "Removing disk from VM $vm_name: $target"

    if virsh detach-disk "$vm_name" "$target"; then
        print_success "Disk removed successfully"
        return 0
    else
        print_error "Failed to remove disk"
        return 1
    fi
}

# Add network interface
vm_add_network() {
    local vm_name="$1"
    local network="${2:-default}"

    print_info "Adding network interface to VM $vm_name: $network"

    if virsh attach-interface "$vm_name" network "$network" --model virtio; then
        print_success "Network interface added"
        return 0
    else
        print_error "Failed to add network interface"
        return 1
    fi
}

# Open VM console
vm_console() {
    local vm_name="$1"

    print_info "Opening console for VM: $vm_name"

    virsh console "$vm_name"
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Get VM state
vm_state() {
    local vm_name="$1"

    virsh domstate "$vm_name" 2>/dev/null || echo "VM not found: $vm_name"
}

# List VM snapshots
vm_snapshots() {
    local vm_name="$1"

    print_header "Snapshots for VM: $vm_name"

    virsh snapshot-list "$vm_name"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

# Export functions if sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    export -f vm_create
    export -f vm_delete
    export -f vm_start
    export -f vm_stop
    export -f vm_restart
    export -f vm_list
    export -f vm_info
    export -f vm_clone
    export -f vm_snapshot_create
    export -f vm_snapshot_restore
    export -f vm_snapshot_delete
    export -f vm_resize_disk
    export -f vm_add_disk
    export -f vm_remove_disk
    export -f vm_add_network
    export -f vm_console
    export -f vm_state
    export -f vm_snapshots
fi