#!/usr/bin/bash
# ============================================================================
# file_ops.sh - File Operations Module
# Dependencies: print_info.sh, validator.sh
# ============================================================================

# Get directories
SCRIPT_DIR_FILEOPS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR_FILEOPS="$(dirname "$SCRIPT_DIR_FILEOPS")"
CORE_DIR_FILEOPS="${LIB_DIR_FILEOPS}/core"

# Source dependencies
source "${CORE_DIR_FILEOPS}/print_info.sh"
source "${CORE_DIR_FILEOPS}/validator.sh"

# Safe file copy with backup
safe_copy() {
    local source_file="$1"
    local dest_file="$2"
    
    # Validate source exists
    if ! validate_file_exists "$source_file"; then
        return 1
    fi
    
    # Create backup if destination exists
    if [ -f "$dest_file" ]; then
        local backup="${dest_file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$dest_file" "$backup"
        print_info "Backup created: $backup"
    fi
    
    # Copy file
    if cp "$source_file" "$dest_file"; then
        print_success "Copied $source_file to $dest_file"
        return 0
    else
        print_error "Failed to copy $source_file to $dest_file"
        return 1
    fi
}

# Safe file move
safe_move() {
    local source_file="$1"
    local dest_file="$2"
    
    if ! validate_file_exists "$source_file"; then
        return 1
    fi
    
    if mv "$source_file" "$dest_file"; then
        print_success "Moved $source_file to $dest_file"
        return 0
    else
        print_error "Failed to move $source_file to $dest_file"
        return 1
    fi
}

# Create directory with parents
create_directory() {
    local dir="$1"
    
    if [ -d "$dir" ]; then
        print_info "Directory already exists: $dir"
        return 0
    fi
    
    if mkdir -p "$dir"; then
        print_success "Created directory: $dir"
        return 0
    else
        print_error "Failed to create directory: $dir"
        return 1
    fi
}

# Remove file with confirmation
safe_remove() {
    local file="$1"
    local force="${2:-false}"
    
    if [ ! -f "$file" ]; then
        print_warning "File not found: $file"
        return 1
    fi
    
    if [ "$force" = "false" ]; then
        print_warning "About to delete: $file"
        read -r -p "Are you sure? [y/N]: " confirmation
        if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
            print_info "Deletion cancelled"
            return 1
        fi
    fi
    
    if rm "$file"; then
        print_success "Deleted: $file"
        return 0
    else
        print_error "Failed to delete: $file"
        return 1
    fi
}

# Get file size human readable
get_file_size() {
    local file="$1"
    
    if [ -f "$file" ]; then
        du -h "$file" | cut -f1
    else
        echo "N/A"
    fi
}

# Count lines in file
count_lines() {
    local file="$1"
    
    if [ -f "$file" ]; then
        local lines=$(wc -l < "$file")
        echo "$lines"
    else
        echo "0"
    fi
}

# Backup directory
backup_directory() {
    local source_dir="$1"
    local backup_dir="${2:-${source_dir}_backup_$(date +%Y%m%d)}"
    
    if [ ! -d "$source_dir" ]; then
        print_error "Source directory not found: $source_dir"
        return 1
    fi
    
    print_info "Backing up $source_dir to $backup_dir"
    
    if cp -r "$source_dir" "$backup_dir"; then
        print_success "Backup completed: $backup_dir"
        return 0
    else
        print_error "Backup failed"
        return 1
    fi
}