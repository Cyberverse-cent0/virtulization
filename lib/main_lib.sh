#!/usr/bin/bash
# ============================================================================
# main_lib.sh - Main Library File
# Description: Import all library modules with one source
# ============================================================================

# Get the directory of this script
get_main_lib_dir() {
    local source="${BASH_SOURCE[0]}"
    while [ -h "$source" ]; do
        local dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ $source != /* ]] && source="$dir/$source"
    done
    cd -P "$(dirname "$source")" && pwd
}

readonly MAIN_LIB_DIR="$(get_main_lib_dir)"
readonly CORE_DIR="${MAIN_LIB_DIR}/core"
readonly MODULES_DIR="${MAIN_LIB_DIR}/modules"
readonly CONFIG_DIR="${MAIN_LIB_DIR}/config"

# Colors for output (if not already defined)
if [ -z "${RC:-}" ]; then
    readonly RC='\033[0m'
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly CYAN='\033[0;36m'
fi

# Load configuration first
if [ -f "${CONFIG_DIR}/settings.conf" ]; then
    # Set PROJECT_ROOT for configuration
    export PROJECT_ROOT="$(cd "${MAIN_LIB_DIR}/.." && pwd)"
    source "${CONFIG_DIR}/settings.conf"
fi

# Load core modules
load_core_modules() {
    local core_files=(
        "print_info.sh"
        "logger.sh"
        "validator.sh"
        "system.sh"
    )
    
    for file in "${core_files[@]}"; do
        if [ -f "${CORE_DIR}/${file}" ]; then
            source "${CORE_DIR}/${file}"
        else
            echo "Warning: Core module not found: ${file}" >&2
        fi
    done
}

# Load modules
load_modules() {
    local module_files=(
        "file_ops.sh"
        "network.sh"
        "text_utils.sh"
        "virtualization.sh"
        "storage_manager.sh"
        "iso_manager.sh"
        "vm_manager.sh"
        "network_manager.sh"
    )
    
    for file in "${module_files[@]}"; do
        if [ -f "${MODULES_DIR}/${file}" ]; then
            source "${MODULES_DIR}/${file}"
        else
            echo "Warning: Module not found: ${file}" >&2
        fi
    done
}

# Initialize the library
init_library() {
    # Create log directory if it doesn't exist
    if [ ! -d "$LOG_DIR" ] && [ -n "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR" 2>/dev/null
    fi
    
    # Define storage directories
    readonly STORAGE_BASE_DIR="${PROJECT_ROOT}/storage"
    readonly ISO_STORAGE_DIR="${STORAGE_BASE_DIR}/iso"
    readonly VM_STORAGE_DIR="${STORAGE_BASE_DIR}/vms"
    readonly TEMPLATE_STORAGE_DIR="${STORAGE_BASE_DIR}/templates"
    readonly BACKUP_STORAGE_DIR="${STORAGE_BASE_DIR}/backups"
    
    # Define symlink paths
    readonly ISO_LINK_DIR="${PROJECT_ROOT}/iso"
    readonly VM_LINK_DIR="${PROJECT_ROOT}/vms"
    readonly TEMPLATE_LINK_DIR="${PROJECT_ROOT}/templates"
    readonly BACKUP_LINK_DIR="${PROJECT_ROOT}/backups"
    
    # Set default storage locations
    ISO_DOWNLOAD_LOCATION="${ISO_STORAGE_DIR}"
    VM_STORAGE_LOCATION="${VM_STORAGE_DIR}"
    TEMPLATE_LOCATION="${TEMPLATE_STORAGE_DIR}"
    BACKUP_LOCATION="${BACKUP_STORAGE_DIR}"
    
    # Set downloader directory
    DOWNLOADER_DIR="${PROJECT_ROOT}/Downloader"
    
    # Print initialization message
    if [ "${DEBUG_MODE}" = "1" ]; then
        echo "${CYAN}[LIBRARY]${RC} Initializing main library v${APP_VERSION}"
    fi
}

# Load everything
load_core_modules
load_modules
init_library

# Export library info
export LIBRARY_LOADED=true
export LIBRARY_VERSION="${APP_VERSION}"

# Display loaded modules (debug mode)
if [ "${DEBUG_MODE}" = "1" ]; then
    echo "${CYAN}[LIBRARY]${RC} All modules loaded successfully"
    echo "  - Core modules: 4"
    echo "  - Modules: 3"
    echo "  - Log directory: ${LOG_DIR}"
fi