#!/usr/bin/bash
# ============================================================================
# iso_manager.sh - ISO Management Module
# Description: Manages ISO downloads, verification, and cataloging
# ============================================================================

# Source main library if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")"
if [ -f "${LIB_DIR}/main_lib.sh" ]; then
    source "${LIB_DIR}/main_lib.sh"
fi

# ============================================================================
# ISO MANAGER FUNCTIONS
# ============================================================================

# Add new ISO source
iso_add_source() {
    local distro="$1"
    local source_file="$2"

    print_info "Adding ISO source for $distro"

    if [ -f "$source_file" ]; then
        print_success "Source file exists: $source_file"
    else
        print_error "Source file not found: $source_file"
        return 1
    fi
}

# Remove ISO source
iso_remove_source() {
    local distro="$1"

    print_info "Removing ISO source for $distro"
    # Implementation would go here
    print_warning "ISO source removal not yet implemented"
}

# List all ISO sources
iso_list_sources() {
    print_header "Available ISO Sources"

    declare -A sources=(
        ["Ubuntu"]="$DOWNLOADER_DIR/ubuntu_source_iso.txt"
        ["Debian"]="$DOWNLOADER_DIR/debina_source_iso.txt"
        ["Fedora"]="$DOWNLOADER_DIR/fedora_source_iso.txt"
        ["Arch Linux"]="$DOWNLOADER_DIR/arch_linux_source_iso.txt"
        ["Others"]="$DOWNLOADER_DIR/others_distro_source_list.txt"
    )

    for distro in "${!sources[@]}"; do
        local source_file="${sources[$distro]}"
        if [ -f "$source_file" ]; then
            print_info "$distro sources available"
        else
            print_warning "$distro source file not found: $source_file"
        fi
    done
}

# Download ISO file
iso_download() {
    local url="$1"
    local filename="$2"
    local checksum="${3:-}"

    print_info "Downloading ISO: $filename"

    local download_path="${ISO_DOWNLOAD_LOCATION}/${filename}"

    # Check if already exists
    if [ -f "$download_path" ]; then
        print_info "ISO already exists: $download_path"
        if [[ "$checksum" ]]; then
            iso_verify "$download_path" "$checksum"
        fi
        return 0
    fi

    # Download with wget
    if wget --show-progress -O "$download_path" "$url"; then
        print_success "Downloaded: $filename"

        # Verify checksum if provided
        if [[ "$checksum" ]]; then
            iso_verify "$download_path" "$checksum"
        fi

        return 0
    else
        print_error "Failed to download: $url"
        return 1
    fi
}

# Verify ISO checksum
iso_verify() {
    local iso_path="$1"
    local expected_checksum="$2"

    print_info "Verifying ISO checksum: $(basename "$iso_path")"

    if [[ ! "$expected_checksum" ]]; then
        print_warning "No checksum provided for verification"
        return 0
    fi

    # Calculate actual checksum (assuming SHA256)
    local actual_checksum
    if command -v sha256sum >/dev/null 2>&1; then
        actual_checksum=$(sha256sum "$iso_path" | cut -d' ' -f1)
    else
        print_warning "sha256sum not available, skipping verification"
        return 0
    fi

    if [ "$actual_checksum" = "$expected_checksum" ]; then
        print_success "Checksum verification passed"
        return 0
    else
        print_error "Checksum verification failed"
        print_error "Expected: $expected_checksum"
        print_error "Actual: $actual_checksum"
        return 1
    fi
}

# List local ISOs
iso_list_local() {
    print_header "Local ISO Files"

    if [ -d "$ISO_DOWNLOAD_LOCATION" ]; then
        local count=$(find "$ISO_DOWNLOAD_LOCATION" -name "*.iso" | wc -l)
        print_info "Found $count ISO files:"

        find "$ISO_DOWNLOAD_LOCATION" -name "*.iso" -exec ls -lh {} \; | \
        while read -r line; do
            echo "  $line"
        done
    else
        print_warning "ISO directory not accessible: $ISO_DOWNLOAD_LOCATION"
    fi
}

# Remove ISO file
iso_remove() {
    local filename="$1"

    local iso_path="${ISO_DOWNLOAD_LOCATION}/${filename}"

    if [ -f "$iso_path" ]; then
        print_info "Removing ISO: $filename"
        rm -f "$iso_path"
        print_success "ISO removed: $filename"
    else
        print_error "ISO not found: $filename"
        return 1
    fi
}

# Search for ISO
iso_search() {
    local pattern="$1"

    print_info "Searching for ISOs matching: $pattern"

    if [ -d "$ISO_DOWNLOAD_LOCATION" ]; then
        find "$ISO_DOWNLOAD_LOCATION" -name "*${pattern}*.iso" -exec ls -lh {} \;
    else
        print_warning "ISO directory not accessible"
    fi
}

# Update source list
iso_update_sources() {
    print_info "Updating ISO source lists"
    # Implementation would fetch latest sources
    print_warning "Source update not yet implemented"
}

# Import existing ISO
iso_import() {
    local source_path="$1"
    local filename="${2:-$(basename "$source_path")}"

    print_info "Importing ISO: $source_path"

    if [ ! -f "$source_path" ]; then
        print_error "Source file not found: $source_path"
        return 1
    fi

    local dest_path="${ISO_DOWNLOAD_LOCATION}/${filename}"

    cp "$source_path" "$dest_path"

    if [ $? -eq 0 ]; then
        print_success "ISO imported: $filename"
        return 0
    else
        print_error "Failed to import ISO"
        return 1
    fi
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Get ISO information
iso_info() {
    local filename="$1"

    local iso_path="${ISO_DOWNLOAD_LOCATION}/${filename}"

    if [ -f "$iso_path" ]; then
        print_info "ISO Information: $filename"
        ls -lh "$iso_path"
        file "$iso_path" 2>/dev/null || echo "File type detection not available"
    else
        print_error "ISO not found: $filename"
    fi
}

# Clean up old ISOs
iso_cleanup() {
    local days="${1:-90}"

    print_info "Cleaning up ISOs older than $days days"

    if [ -d "$ISO_DOWNLOAD_LOCATION" ]; then
        find "$ISO_DOWNLOAD_LOCATION" -name "*.iso" -mtime +$days -delete 2>/dev/null
        print_success "Cleanup completed"
    else
        print_warning "ISO directory not accessible"
    fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

# Export functions if sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    export -f iso_add_source
    export -f iso_remove_source
    export -f iso_list_sources
    export -f iso_download
    export -f iso_verify
    export -f iso_list_local
    export -f iso_remove
    export -f iso_search
    export -f iso_update_sources
    export -f iso_import
    export -f iso_info
    export -f iso_cleanup
fi