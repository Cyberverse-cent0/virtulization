#!/usr/bin/bash
# ============================================================================
# network_manager.sh - Network Management Module
# Description: Manages network configurations for VMs
# ============================================================================

# Source main library if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")"
if [ -f "${LIB_DIR}/main_lib.sh" ]; then
    source "${LIB_DIR}/main_lib.sh"
fi

# ============================================================================
# NETWORK MANAGER FUNCTIONS
# ============================================================================

# Setup NAT network
network_setup_nat() {
    local network_name="${1:-default}"
    local subnet="${2:-192.168.122.0/24}"

    print_info "Setting up NAT network: $network_name"

    # Check if network already exists
    if virsh net-info "$network_name" >/dev/null 2>&1; then
        print_info "Network already exists: $network_name"
        return 0
    fi

    # Create network XML
    cat > "/tmp/${network_name}_net.xml" << EOF
<network>
  <name>$network_name</name>
  <bridge name='virbr0'/>
  <forward mode='nat'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
EOF

    # Define and start network
    if virsh net-define "/tmp/${network_name}_net.xml" && \
       virsh net-autostart "$network_name" && \
       virsh net-start "$network_name"; then

        print_success "NAT network created: $network_name"
        rm -f "/tmp/${network_name}_net.xml"
        return 0
    else
        print_error "Failed to create NAT network"
        rm -f "/tmp/${network_name}_net.xml"
        return 1
    fi
}

# Setup bridge network
network_setup_bridge() {
    local bridge_name="${1:-br0}"
    local interface="${2:-eth0}"

    print_info "Setting up bridge network: $bridge_name on $interface"

    # Check if bridge exists
    if brctl show | grep -q "$bridge_name"; then
        print_info "Bridge already exists: $bridge_name"
        return 0
    fi

    # Create bridge
    sudo brctl addbr "$bridge_name"
    sudo brctl addif "$bridge_name" "$interface"
    sudo ip link set "$bridge_name" up
    sudo ip link set "$interface" up

    if [ $? -eq 0 ]; then
        print_success "Bridge network created: $bridge_name"

        # Create libvirt network for the bridge
        cat > "/tmp/${bridge_name}_net.xml" << EOF
<network>
  <name>$bridge_name</name>
  <forward mode='bridge'/>
  <bridge name='$bridge_name'/>
</network>
EOF

        if virsh net-define "/tmp/${bridge_name}_net.xml" && \
           virsh net-autostart "$bridge_name"; then
            print_success "Libvirt network created for bridge: $bridge_name"
        else
            print_warning "Failed to create libvirt network for bridge"
        fi

        rm -f "/tmp/${bridge_name}_net.xml"
        return 0
    else
        print_error "Failed to create bridge network"
        return 1
    fi
}

# List networks
network_list() {
    print_header "Libvirt Networks"

    virsh net-list --all
}

# Create network
network_create() {
    local network_name="$1"
    local network_xml="$2"

    print_info "Creating network: $network_name"

    if [ -f "$network_xml" ]; then
        if virsh net-define "$network_xml" && \
           virsh net-autostart "$network_name" && \
           virsh net-start "$network_name"; then
            print_success "Network created: $network_name"
            return 0
        else
            print_error "Failed to create network: $network_name"
            return 1
        fi
    else
        print_error "Network XML file not found: $network_xml"
        return 1
    fi
}

# Delete network
network_delete() {
    local network_name="$1"

    print_info "Deleting network: $network_name"

    # Stop and undefine network
    if virsh net-destroy "$network_name" 2>/dev/null && \
       virsh net-undefine "$network_name"; then
        print_success "Network deleted: $network_name"
        return 0
    else
        print_error "Failed to delete network: $network_name"
        return 1
    fi
}

# Attach VM to network
network_attach() {
    local vm_name="$1"
    local network_name="$2"

    print_info "Attaching VM $vm_name to network $network_name"

    if virsh attach-interface "$vm_name" network "$network_name" --model virtio; then
        print_success "VM attached to network: $network_name"
        return 0
    else
        print_error "Failed to attach VM to network"
        return 1
    fi
}

# Detach VM from network
network_detach() {
    local vm_name="$1"
    local mac_address="$2"

    print_info "Detaching VM $vm_name from network"

    if [ -z "$mac_address" ]; then
        # Get MAC address of first interface
        mac_address=$(virsh domiflist "$vm_name" | grep -v "MAC address" | head -1 | awk '{print $5}')
    fi

    if [ -n "$mac_address" ]; then
        if virsh detach-interface "$vm_name" bridge --mac "$mac_address"; then
            print_success "VM detached from network"
            return 0
        else
            print_error "Failed to detach VM from network"
            return 1
        fi
    else
        print_error "Could not determine MAC address for VM: $vm_name"
        return 1
    fi
}

# Setup port forwarding
network_port_forward() {
    local host_port="$1"
    local guest_ip="$2"
    local guest_port="$3"
    local protocol="${4:-tcp}"

    print_info "Setting up port forwarding: $host_port -> $guest_ip:$guest_port ($protocol)"

    # Add iptables rule
    sudo iptables -t nat -A PREROUTING -p "$protocol" --dport "$host_port" -j DNAT --to-destination "$guest_ip:$guest_port"

    if [ $? -eq 0 ]; then
        print_success "Port forwarding configured"
        print_info "Rule added to iptables NAT table"
        return 0
    else
        print_error "Failed to configure port forwarding"
        return 1
    fi
}

# Monitor network traffic
network_monitor() {
    local interface="${1:-virbr0}"
    local duration="${2:-10}"

    print_header "Network Traffic Monitor ($interface)"

    print_info "Monitoring for $duration seconds..."

    sudo timeout "$duration" tcpdump -i "$interface" -n -q 2>/dev/null || \
    echo "tcpdump not available or insufficient permissions"

    print_info "Monitoring completed"
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Get network information
network_info() {
    local network_name="$1"

    print_header "Network Information: $network_name"

    virsh net-info "$network_name"
    echo
    virsh net-dumpxml "$network_name"
}

# List network DHCP leases
network_leases() {
    local network_name="$1"

    print_header "DHCP Leases for Network: $network_name"

    virsh net-dhcp-leases "$network_name"
}

# Restart network
network_restart() {
    local network_name="$1"

    print_info "Restarting network: $network_name"

    if virsh net-destroy "$network_name" && virsh net-start "$network_name"; then
        print_success "Network restarted: $network_name"
        return 0
    else
        print_error "Failed to restart network: $network_name"
        return 1
    fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

# Export functions if sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    export -f network_setup_nat
    export -f network_setup_bridge
    export -f network_list
    export -f network_create
    export -f network_delete
    export -f network_attach
    export -f network_detach
    export -f network_port_forward
    export -f network_monitor
    export -f network_info
    export -f network_leases
    export -f network_restart
fi