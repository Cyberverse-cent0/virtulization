#!/usr/bin/bash
# ============================================================================
# storage_manager.sh - Storage Management Module
# Description: Manages storage pools, symlinks, and storage operations
# ============================================================================

# Source main library if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")"
if [ -f "${LIB_DIR}/main_lib.sh" ]; then
    source "${LIB_DIR}/main_lib.sh"
fi

# ============================================================================
# STORAGE MANAGER FUNCTIONS
# ============================================================================

# Initialize storage system
storage_init() {
    print_info "Initializing storage management system..."

    # Create storage directory structure
    storage_create_directory "$STORAGE_BASE_DIR"
    storage_create_directory "$ISO_STORAGE_DIR"
    storage_create_directory "$VM_STORAGE_DIR"
    storage_create_directory "$TEMPLATE_STORAGE_DIR"
    storage_create_directory "$BACKUP_STORAGE_DIR"

    # Set up symlinks
    storage_set_symlink "$ISO_STORAGE_DIR" "$ISO_LINK_DIR"
    storage_set_symlink "$VM_STORAGE_DIR" "$VM_LINK_DIR"
    storage_set_symlink "$TEMPLATE_STORAGE_DIR" "$TEMPLATE_LINK_DIR"
    storage_set_symlink "$BACKUP_STORAGE_DIR" "$BACKUP_LINK_DIR"

    print_success "Storage system initialized"
}

# Add new storage pool
storage_add_pool() {
    local pool_name="$1"
    local pool_path="$2"
    local pool_type="${3:-dir}"  # dir, nfs, lvm, etc.

    print_info "Adding storage pool: $pool_name ($pool_type)"

    case $pool_type in
        dir)
            storage_create_directory "$pool_path"
            ;;
        nfs)
            # NFS mount logic would go here
            print_warning "NFS pool support not yet implemented"
            return 1
            ;;
        lvm)
            # LVM logic would go here
            print_warning "LVM pool support not yet implemented"
            return 1
            ;;
        *)
            print_error "Unsupported pool type: $pool_type"
            return 1
            ;;
    esac

    print_success "Storage pool added: $pool_name"
}

# Remove storage pool
storage_remove_pool() {
    local pool_name="$1"

    print_info "Removing storage pool: $pool_name"
    # Implementation would go here
    print_warning "Storage pool removal not yet implemented"
}

# List all storage pools
storage_list_pools() {
    print_header "Storage Pools"

    echo "Local Storage Pools:"
    echo "  ISO Pool: $ISO_STORAGE_DIR ($(du -sh "$ISO_STORAGE_DIR" 2>/dev/null | cut -f1))"
    echo "  VM Pool: $VM_STORAGE_DIR ($(du -sh "$VM_STORAGE_DIR" 2>/dev/null | cut -f1))"
    echo "  Template Pool: $TEMPLATE_STORAGE_DIR ($(du -sh "$TEMPLATE_STORAGE_DIR" 2>/dev/null | cut -f1))"
    echo "  Backup Pool: $BACKUP_STORAGE_DIR ($(du -sh "$BACKUP_STORAGE_DIR" 2>/dev/null | cut -f1))"
}

# Get storage information
storage_get_info() {
    local path="$1"

    if [ -d "$path" ]; then
        local size=$(du -sh "$path" 2>/dev/null | cut -f1)
        local files=$(find "$path" -type f | wc -l)
        echo "Path: $path"
        echo "Size: $size"
        echo "Files: $files"
    else
        echo "Path not accessible: $path"
    fi
}

# Check available space
storage_check_space() {
    local path="$1"
    local min_space="${2:-1G}"

    print_debug "Checking space for: $path (min: $min_space)"

    local available=$(df -BG "$path" 2>/dev/null | tail -1 | awk '{print $4}' | sed 's/G//')
    local min_gb=$(echo "$min_space" | sed 's/G//')

    if [ "$available" -lt "$min_gb" ]; then
        print_warning "Low disk space: ${available}G available, ${min_gb}G required"
        return 1
    else
        print_success "Sufficient disk space: ${available}G available"
        return 0
    fi
}

# Create storage directories
storage_create_directory() {
    local dir_path="$1"

    if [ ! -d "$dir_path" ]; then
        print_info "Creating directory: $dir_path"
        mkdir -p "$dir_path"
        if [ $? -eq 0 ]; then
            print_success "Directory created: $dir_path"
        else
            print_error "Failed to create directory: $dir_path"
            return 1
        fi
    else
        print_debug "Directory already exists: $dir_path"
    fi
}

# Set up storage symlinks
storage_set_symlink() {
    local target="$1"
    local link_name="$2"

    print_debug "Setting up symlink: $link_name -> $target"

    # Remove existing symlink or file
    if [ -L "$link_name" ]; then
        rm -f "$link_name"
    elif [ -e "$link_name" ]; then
        print_warning "Backing up existing file: $link_name"
        mv "$link_name" "${link_name}.backup.$(date +%Y%m%d_%H%M%S)"
    fi

    # Create target directory if it doesn't exist
    storage_create_directory "$target"

    # Create symlink
    ln -sf "$target" "$link_name"

    if [ $? -eq 0 ]; then
        print_success "Symlink created: $link_name -> $target"
    else
        print_error "Failed to create symlink: $link_name"
        return 1
    fi
}

# Migrate storage to new location
storage_migrate() {
    local old_path="$1"
    local new_path="$2"

    print_info "Migrating storage from $old_path to $new_path"

    if [ ! -d "$old_path" ]; then
        print_error "Source path does not exist: $old_path"
        return 1
    fi

    # Create new directory
    storage_create_directory "$new_path"

    # Copy files
    print_info "Copying files..."
    cp -r "$old_path"/* "$new_path"/ 2>/dev/null

    if [ $? -eq 0 ]; then
        print_success "Migration completed"
        print_info "Old path: $old_path (can be removed manually)"
        print_info "New path: $new_path"
    else
        print_error "Migration failed"
        return 1
    fi
}

# Backup storage configuration
storage_backup() {
    local backup_file="${1:-storage_backup_$(date +%Y%m%d_%H%M%S).tar.gz}"

    print_info "Creating storage configuration backup: $backup_file"

    # Create backup of configuration and symlinks
    tar -czf "$backup_file" \
        -C "$LIB_DIR" config/ \
        -C "$PROJECT_ROOT" \
        iso vms templates backups \
        2>/dev/null

    if [ $? -eq 0 ]; then
        print_success "Backup created: $backup_file"
    else
        print_error "Backup failed"
        return 1
    fi
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Get storage statistics
storage_stats() {
    print_header "Storage Statistics"

    echo "ISO Storage:"
    storage_get_info "$ISO_STORAGE_DIR"
    echo

    echo "VM Storage:"
    storage_get_info "$VM_STORAGE_DIR"
    echo

    echo "Template Storage:"
    storage_get_info "$TEMPLATE_STORAGE_DIR"
    echo

    echo "Backup Storage:"
    storage_get_info "$BACKUP_STORAGE_DIR"
}

# Clean up old backups
storage_cleanup() {
    local days="${1:-30}"

    print_info "Cleaning up backups older than $days days"

    find "$BACKUP_STORAGE_DIR" -name "*.backup.*" -mtime +$days -delete 2>/dev/null

    print_success "Cleanup completed"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

# Export functions if sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    export -f storage_init
    export -f storage_add_pool
    export -f storage_remove_pool
    export -f storage_list_pools
    export -f storage_get_info
    export -f storage_check_space
    export -f storage_create_directory
    export -f storage_set_symlink
    export -f storage_migrate
    export -f storage_backup
    export -f storage_stats
    export -f storage_cleanup
fi