#!/usr/bin/env bash
# ============================================================================
# main.sh - Main Script for KVM/QEMU Setup
# ============================================================================
set -euo pipefail   


# Source main library
source "$(dirname "${BASH_SOURCE[0]}")/lib/main_lib.sh" 
# Source utility scripts
source "$(dirname "${BASH_SOURCE[0]}")/utils/network_setup.sh"
source "$(dirname "${BASH_SOURCE[0]}")/utils/storage_setup.sh"

check_if_application_is_installed() {


}
install_application() {

}

start_application() {

}

start_cli() {

}

start_gui(){
    
}