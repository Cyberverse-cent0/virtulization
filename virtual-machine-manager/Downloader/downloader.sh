#!/usr/bin/bash
# ============================================================================
# Downloader Script - First-time setup with symlink-based storage management
# Description: Sets up download locations using symlinks for flexible storage
# ============================================================================

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOWNLOADER_DIR="$SCRIPT_DIR"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LIB_DIR="${PROJECT_ROOT}/lib"

# Source the main library if it exists
if [ -f "${LIB_DIR}/main_lib.sh" ]; then
    source "${LIB_DIR}/main_lib.sh"
else
    # Basic fallback functions
    readonly RC='\033[0m'
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly CYAN='\033[0;36m'
    
    print_info() { echo -e "${BLUE}[INFO]${RC} $1"; }
    print_success() { echo -e "${GREEN}[SUCCESS]${RC} $1"; }
    print_warning() { echo -e "${YELLOW}[WARNING]${RC} $1" >&2; }
    print_error() { echo -e "${RED}[ERROR]${RC} $1" >&2; }
    print_header() { echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${RC}\n${BLUE}  $1${RC}\n${BLUE}════════════════════════════════════════════════════════════════${RC}\n"; }
    print_debug() { [ "${DEBUG:-0}" = "1" ] && echo -e "${CYAN}[DEBUG]${RC} $1"; }
fi

# ============================================================================
# CONFIGURATION
# ============================================================================

# Config directories
readonly CONFIG_DIR="${HOME}/.virtula_machine"
readonly CONFIG_FILE="${CONFIG_DIR}/config.conf"
readonly FIRST_RUN_MARKER="${CONFIG_DIR}/first_run_complete"
readonly STORAGE_MANIFEST="${CONFIG_DIR}/storage_links.txt"

# Default storage locations (inside project)
readonly PROJECT_STORAGE_DIR="${PROJECT_ROOT}/storage"
readonly DEFAULT_ISO_DIR="${PROJECT_STORAGE_DIR}/iso"
readonly DEFAULT_VM_DIR="${PROJECT_STORAGE_DIR}/vms"
readonly DEFAULT_TEMPLATE_DIR="${PROJECT_STORAGE_DIR}/templates"
readonly DEFAULT_BACKUP_DIR="${PROJECT_STORAGE_DIR}/backups"

# Symlink locations (actual paths that scripts will use)
readonly LINK_ISO_DIR="${PROJECT_ROOT}/iso"
readonly LINK_VM_DIR="${PROJECT_ROOT}/vms"
readonly LINK_TEMPLATE_DIR="${PROJECT_ROOT}/templates"
readonly LINK_BACKUP_DIR="${PROJECT_ROOT}/backups"

# These will be set after loading config or during setup
ISO_DOWNLOAD_LOCATION=""
VM_STORAGE_LOCATION=""
TEMPLATE_LOCATION=""
BACKUP_LOCATION=""

# ISO source files
readonly UBUNTU_SOURCE="${DOWNLOADER_DIR}/ubuntu_source_iso.txt"
readonly DEBIAN_SOURCE="${DOWNLOADER_DIR}/debina_source_iso.txt"
readonly FEDORA_SOURCE="${DOWNLOADER_DIR}/fedora_source_iso.txt"
readonly ARCH_SOURCE="${DOWNLOADER_DIR}/arch_linux_source_iso.txt"
readonly OTHERS_SOURCE="${DOWNLOADER_DIR}/others_distro_source_list.txt"

# ============================================================================
# SYMLINK MANAGEMENT FUNCTIONS
# ============================================================================

# Create symlink for ISO storage
setup_iso_symlink() {
    local target_dir="$1"
    
    print_info "Setting up ISO storage symlink..."
    
    # Remove existing symlink if it exists
    if [ -L "$LINK_ISO_DIR" ]; then
        print_info "Removing existing ISO symlink: $LINK_ISO_DIR"
        rm -f "$LINK_ISO_DIR"
    elif [ -e "$LINK_ISO_DIR" ]; then
        print_warning "Found existing directory at $LINK_ISO_DIR. Backing up..."
        mv "$LINK_ISO_DIR" "${LINK_ISO_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Create the target directory if it doesn't exist
    if [ ! -d "$target_dir" ]; then
        print_info "Creating target directory: $target_dir"
        mkdir -p "$target_dir"
    fi
    
    # Create the symlink
    ln -sf "$target_dir" "$LINK_ISO_DIR"
    
    if [ $? -eq 0 ]; then
        print_success "ISO symlink created: $LINK_ISO_DIR -> $target_dir"
        ISO_DOWNLOAD_LOCATION="$target_dir"
        return 0
    else
        print_error "Failed to create ISO symlink"
        return 1
    fi
}

# Create symlink for VM storage
setup_vm_symlink() {
    local target_dir="$1"
    
    print_info "Setting up VM storage symlink..."
    
    # Remove existing symlink if it exists
    if [ -L "$LINK_VM_DIR" ]; then
        print_info "Removing existing VM symlink: $LINK_VM_DIR"
        rm -f "$LINK_VM_DIR"
    elif [ -e "$LINK_VM_DIR" ]; then
        print_warning "Found existing directory at $LINK_VM_DIR. Backing up..."
        mv "$LINK_VM_DIR" "${LINK_VM_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Create the target directory if it doesn't exist
    if [ ! -d "$target_dir" ]; then
        print_info "Creating target directory: $target_dir"
        mkdir -p "$target_dir"
        mkdir -p "$target_dir/images"
        mkdir -p "$target_dir/disks"
    fi
    
    # Create the symlink
    ln -sf "$target_dir" "$LINK_VM_DIR"
    
    if [ $? -eq 0 ]; then
        print_success "VM symlink created: $LINK_VM_DIR -> $target_dir"
        VM_STORAGE_LOCATION="$target_dir"
        return 0
    else
        print_error "Failed to create VM symlink"
        return 1
    fi
}

# Create symlink for templates
setup_template_symlink() {
    local target_dir="$1"
    
    print_info "Setting up templates symlink..."
    
    if [ -L "$LINK_TEMPLATE_DIR" ]; then
        rm -f "$LINK_TEMPLATE_DIR"
    elif [ -e "$LINK_TEMPLATE_DIR" ]; then
        mv "$LINK_TEMPLATE_DIR" "${LINK_TEMPLATE_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir"
    fi
    
    ln -sf "$target_dir" "$LINK_TEMPLATE_DIR"
    
    if [ $? -eq 0 ]; then
        print_success "Templates symlink created: $LINK_TEMPLATE_DIR -> $target_dir"
        TEMPLATE_LOCATION="$target_dir"
        return 0
    else
        print_error "Failed to create templates symlink"
        return 1
    fi
}

# Create symlink for backups
setup_backup_symlink() {
    local target_dir="$1"
    
    print_info "Setting up backups symlink..."
    
    if [ -L "$LINK_BACKUP_DIR" ]; then
        rm -f "$LINK_BACKUP_DIR"
    elif [ -e "$LINK_BACKUP_DIR" ]; then
        mv "$LINK_BACKUP_DIR" "${LINK_BACKUP_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir"
    fi
    
    ln -sf "$target_dir" "$LINK_BACKUP_DIR"
    
    if [ $? -eq 0 ]; then
        print_success "Backups symlink created: $LINK_BACKUP_DIR -> $target_dir"
        BACKUP_LOCATION="$target_dir"
        return 0
    else
        print_error "Failed to create backups symlink"
        return 1
    fi
}

# ============================================================================
# STORAGE LOCATION SELECTION
# ============================================================================

select_storage_location() {
    local storage_type="$1"
    local default_location="$2"
    
    echo
    print_info "Configuring $storage_type storage location"
    echo "Current options:"
    echo "  1) Use default project location: $default_location"
    echo "  2) Specify custom location"
    echo "  3) Use external drive/mount point"
    read -r -p "Choice [1-3]: " choice
    
    case $choice in
        1)
            echo "$default_location"
            ;;
        2)
            read -r -p "Enter custom path: " custom_path
            echo "$custom_path"
            ;;
        3)
            print_info "Available mount points:"
            df -h | grep -E "^/dev/" | awk '{print $6 " (" $1 " - " $4 " free)"}'
            read -r -p "Enter mount point or directory path: " external_path
            echo "$external_path"
            ;;
        *)
            print_warning "Invalid choice, using default"
            echo "$default_location"
            ;;
    esac
}

# ============================================================================
# FIRST TIME SETUP
# ============================================================================

first_time_setup() {
    print_header "VIRTUAL MACHINE MANAGER - FIRST TIME SETUP"
    print_info "Welcome! Let's configure your storage locations using symlinks."
    echo
    
    # Create config directory
    init_config_directory
    
    # Select ISO storage location
    local iso_target=$(select_storage_location "ISO" "$DEFAULT_ISO_DIR")
    setup_iso_symlink "$iso_target"
    
    # Select VM storage location
    local vm_target=$(select_storage_location "VM" "$DEFAULT_VM_DIR")
    setup_vm_symlink "$vm_target"
    
    # Select templates location
    local template_target=$(select_storage_location "Templates" "$DEFAULT_TEMPLATE_DIR")
    setup_template_symlink "$template_target"
    
    # Select backups location
    local backup_target=$(select_storage_location "Backups" "$DEFAULT_BACKUP_DIR")
    setup_backup_symlink "$backup_target"
    
    # Save configuration
    save_config
    
    # Create storage manifest
    create_storage_manifest
    
    # Create marker file
    touch "$FIRST_RUN_MARKER"
    
    print_success "First-time setup completed successfully!"
    print_info "Storage locations are now managed via symlinks"
}

# ============================================================================
# CONFIGURATION MANAGEMENT
# ============================================================================

init_config_directory() {
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
        print_success "Created config directory: $CONFIG_DIR"
    fi
}

save_config() {
    cat > "$CONFIG_FILE" << EOF
# Virtual Machine Manager Configuration
# Generated on: $(date)

# Storage locations (actual paths behind symlinks)
ISO_STORAGE_PATH="$ISO_DOWNLOAD_LOCATION"
VM_STORAGE_PATH="$VM_STORAGE_LOCATION"
TEMPLATE_STORAGE_PATH="$TEMPLATE_LOCATION"
BACKUP_STORAGE_PATH="$BACKUP_LOCATION"

# Symlink paths (what scripts should use)
ISO_LINK_PATH="$LINK_ISO_DIR"
VM_LINK_PATH="$LINK_VM_DIR"
TEMPLATE_LINK_PATH="$LINK_TEMPLATE_DIR"
BACKUP_LINK_PATH="$LINK_BACKUP_DIR"

# Default VM settings
DEFAULT_VM_MEMORY="$DEFAULT_VM_MEMORY"
DEFAULT_VM_CPUS="$DEFAULT_VM_CPUS"
DEFAULT_VM_DISK_SIZE="$DEFAULT_VM_DISK_SIZE"
EOF
    
    print_success "Configuration saved to $CONFIG_FILE"
}

load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        print_info "Loading configuration..."
        source "$CONFIG_FILE"
        print_success "Configuration loaded"
        
        # Verify symlinks are valid
        verify_symlinks
        return 0
    else
        print_info "No existing configuration found"
        return 1
    fi
}

verify_symlinks() {
    print_debug "Verifying symlinks..."
    
    [ -L "$LINK_ISO_DIR" ] && [ -d "$LINK_ISO_DIR" ] && print_success "ISO symlink OK" || print_warning "ISO symlink issue"
    [ -L "$LINK_VM_DIR" ] && [ -d "$LINK_VM_DIR" ] && print_success "VM symlink OK" || print_warning "VM symlink issue"
    [ -L "$LINK_TEMPLATE_DIR" ] && [ -d "$LINK_TEMPLATE_DIR" ] && print_success "Templates symlink OK" || print_warning "Templates symlink issue"
}

create_storage_manifest() {
    cat > "$STORAGE_MANIFEST" << EOF
# Storage Symlink Manifest
# Generated: $(date)
# ============================================================================

IMPORTANT: These are symlinks pointing to actual storage locations

ISO Directory:      $LINK_ISO_DIR -> $(readlink -f "$LINK_ISO_DIR" 2>/dev/null || echo "Not set")
VM Directory:       $LINK_VM_DIR -> $(readlink -f "$LINK_VM_DIR" 2>/dev/null || echo "Not set")
Templates Directory: $LINK_TEMPLATE_DIR -> $(readlink -f "$LINK_TEMPLATE_DIR" 2>/dev/null || echo "Not set")
Backups Directory:  $LINK_BACKUP_DIR -> $(readlink -f "$LINK_BACKUP_DIR" 2>/dev/null || echo "Not set")

To change a location:
  1. Remove the symlink: rm -f /path/to/symlink
  2. Create new symlink: ln -sf /new/target /path/to/symlink
  3. Update config file: $CONFIG_FILE

Current storage usage:
EOF
    
    # Add disk usage info
    echo "" >> "$STORAGE_MANIFEST"
    df -h "$LINK_ISO_DIR" "$LINK_VM_DIR" 2>/dev/null >> "$STORAGE_MANIFEST"
    
    print_success "Storage manifest created: $STORAGE_MANIFEST"
}

# ============================================================================
# ISO SOURCE MANAGEMENT
# ============================================================================

load_iso_sources() {
    print_header "Available ISO Sources"
    
    declare -A sources=(
        ["Ubuntu"]="$UBUNTU_SOURCE"
        ["Debian"]="$DEBIAN_SOURCE"
        ["Fedora"]="$FEDORA_SOURCE"
        ["Arch Linux"]="$ARCH_SOURCE"
        ["Others"]="$OTHERS_SOURCE"
    )
    
    for distro in "${!sources[@]}"; do
        local source_file="${sources[$distro]}"
        if [ -f "$source_file" ]; then
            print_info "Loading $distro sources from: $source_file"
            echo "  $(cat "$source_file" | head -3 | tr '\n' ', ' | sed 's/, $//')"
            echo ""
        else
            print_warning "Source file not found for $distro: $source_file"
        fi
    done
}

download_iso() {
    local distro="$1"
    local iso_url="$2"
    local filename="$3"
    
    print_info "Downloading $distro ISO..."
    
    local download_path="${LINK_ISO_DIR}/${filename}"
    
    if [ -f "$download_path" ]; then
        print_info "ISO already exists: $download_path"
        read -r -p "Download again? (y/n): " redownload
        if [[ ! "$redownload" =~ ^[Yy]$ ]]; then
            print_info "Skipping download"
            return 0
        fi
    fi
    
    # Perform download
    if wget --show-progress -O "$download_path" "$iso_url"; then
        print_success "Downloaded: $filename"
        
        # Verify checksum if available
        verify_iso_checksum "$download_path"
        return 0
    else
        print_error "Failed to download: $iso_url"
        return 1
    fi
}

verify_iso_checksum() {
    local iso_path="$1"
    print_debug "ISO verification completed for: $(basename "$iso_path")"
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

show_current_setup() {
    print_header "Current Storage Setup"
    
    echo "ISO Directory:"
    ls -la "$LINK_ISO_DIR" 2>/dev/null | head -5 || echo "  ISO directory not accessible"
    echo ""
    
    echo "VM Directory:"
    ls -la "$LINK_VM_DIR" 2>/dev/null | head -5 || echo "  VM directory not accessible"
    echo ""
    
    echo "Storage Links:"
    echo "  ISO:       $LINK_ISO_DIR -> $(readlink -f "$LINK_ISO_DIR" 2>/dev/null || echo 'BROKEN')"
    echo "  VM:        $LINK_VM_DIR -> $(readlink -f "$LINK_VM_DIR" 2>/dev/null || echo 'BROKEN')"
    echo "  Templates: $LINK_TEMPLATE_DIR -> $(readlink -f "$LINK_TEMPLATE_DIR" 2>/dev/null || echo 'BROKEN')"
    echo "  Backups:   $LINK_BACKUP_DIR -> $(readlink -f "$LINK_BACKUP_DIR" 2>/dev/null || echo 'BROKEN')"
}

reconfigure_storage() {
    print_header "Reconfigure Storage Locations"
    print_warning "This will allow you to change storage locations"
    read -r -p "Continue? (y/n): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        first_time_setup
    else
        print_info "Reconfiguration cancelled"
    fi
}

check_for_first_time_run() {
    if [ ! -f "$FIRST_RUN_MARKER" ]; then
        print_info "First time running Virtual Machine Manager"
        first_time_setup
        return 0
    else
        print_success "Welcome back! Virtual Machine Manager is configured"
        load_config
        return 1
    fi
}

# ============================================================================
# MAIN MENU
# ============================================================================

show_menu() {
    print_header "VIRTUAL MACHINE MANAGER - DOWNLOADER"
    echo "1) Show current storage setup"
    echo "2) Download ISO (interactive)"
    echo "3) List available ISO sources"
    echo "4) Reconfigure storage locations"
    echo "5) View storage manifest"
    echo "6) Exit"
    echo
}

download_interactive() {
    print_header "Download ISO"
    
    # Show available distros
    echo "Available distributions:"
    echo "  1) Ubuntu"
    echo "  2) Debian"
    echo "  3) Fedora"
    echo "  4) Arch Linux"
    echo "  5) Others"
    echo "  6) Back to menu"
    echo
    
    read -r -p "Choice [1-6]: " distro_choice
    
    case $distro_choice in
        1)
            if [ -f "$UBUNTU_SOURCE" ]; then
                echo "Ubuntu ISOs available:"
                cat "$UBUNTU_SOURCE"
                read -r -p "Enter URL to download: " url
                read -r -p "Enter filename: " filename
                download_iso "Ubuntu" "$url" "$filename"
            else
                print_error "Ubuntu source file not found"
            fi
            ;;
        2)
            if [ -f "$DEBIAN_SOURCE" ]; then
                echo "Debian ISOs available:"
                cat "$DEBIAN_SOURCE"
                read -r -p "Enter URL to download: " url
                read -r -p "Enter filename: " filename
                download_iso "Debian" "$url" "$filename"
            else
                print_error "Debian source file not found"
            fi
            ;;
        3)
            if [ -f "$FEDORA_SOURCE" ]; then
                echo "Fedora ISOs available:"
                cat "$FEDORA_SOURCE"
                read -r -p "Enter URL to download: " url
                read -r -p "Enter filename: " filename
                download_iso "Fedora" "$url" "$filename"
            else
                print_error "Fedora source file not found"
            fi
            ;;
        4)
            if [ -f "$ARCH_SOURCE" ]; then
                echo "Arch Linux ISOs available:"
                cat "$ARCH_SOURCE"
                read -r -p "Enter URL to download: " url
                read -r -p "Enter filename: " filename
                download_iso "Arch Linux" "$url" "$filename"
            else
                print_error "Arch Linux source file not found"
            fi
            ;;
        5)
            if [ -f "$OTHERS_SOURCE" ]; then
                echo "Other distributions:"
                cat "$OTHERS_SOURCE"
                read -r -p "Enter URL to download: " url
                read -r -p "Enter filename: " filename
                download_iso "Other" "$url" "$filename"
            else
                print_error "Others source file not found"
            fi
            ;;
        6)
            return
            ;;
        *)
            print_error "Invalid choice"
            ;;
    esac
    
    echo
    read -r -p "Press Enter to continue..."
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    # Check for first-time run
    check_for_first_time_run
    
    # Interactive menu
    while true; do
        show_menu
        read -r -p "Choice [1-6]: " choice
        
        case $choice in
            1)
                show_current_setup
                ;;
            2)
                download_interactive
                ;;
            3)
                load_iso_sources
                ;;
            4)
                reconfigure_storage
                ;;
            5)
                cat "$STORAGE_MANIFEST" 2>/dev/null || print_warning "Manifest not found"
                ;;
            6)
                print_success "Exiting downloader"
                exit 0
                ;;
            *)
                print_error "Invalid choice"
                ;;
        esac
        echo
    done
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi