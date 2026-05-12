#!/usr/bin/bash
# ============================================================================
# text_utils.sh - Text Processing Utilities
# Dependencies: print_info.sh
# ============================================================================

# Source print_info
SCRIPT_DIR_TEXT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR_TEXT="$(dirname "$SCRIPT_DIR_TEXT")"
CORE_DIR_TEXT="${LIB_DIR_TEXT}/core"
source "${CORE_DIR_TEXT}/print_info.sh"

# Convert to uppercase
to_uppercase() {
    local text="$1"
    echo "$text" | tr '[:lower:]' '[:upper:]'
}

# Convert to lowercase
to_lowercase() {
    local text="$1"
    echo "$text" | tr '[:upper:]' '[:lower:]'
}

# Capitalize first letter
capitalize() {
    local text="$1"
    echo "${text^}"
}

# Trim whitespace
trim() {
    local text="$1"
    echo "$text" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

# Check if string contains substring
string_contains() {
    local string="$1"
    local substring="$2"
    
    if [[ "$string" == *"$substring"* ]]; then
        print_success "String contains '$substring'"
        return 0
    else
        print_error "String does not contain '$substring'"
        return 1
    fi
}

# Count word occurrences
count_word() {
    local text="$1"
    local word="$2"
    
    local count=$(echo "$text" | grep -o "$word" | wc -l)
    echo "$count"
}

# Extract emails from text
extract_emails() {
    local text="$1"
    local email_regex="[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"
    
    echo "$text" | grep -oE "$email_regex" | sort -u
}

# Print centered text
print_centered() {
    local text="$1"
    local width="${2:-80}"
    local padding=$(( (width - ${#text}) / 2 ))
    
    printf "%${padding}s%s\n" "" "$text"
}

# Print separator line
print_separator() {
    local char="${1:-=}"
    local width="${2:-80}"
    
    printf '%*s\n' "$width" '' | tr ' ' "$char"
}

# Print header
print_header() {
    local title="$1"
    echo
    print_separator "="
    print_centered "$title"
    print_separator "="
    echo
}

# Create JSON string
to_json() {
    local key="$1"
    local value="$2"
    
    echo "{\"$key\": \"$value\"}"
}

# Base64 encode
base64_encode() {
    local text="$1"
    echo -n "$text" | base64
}

# Base64 decode
base64_decode() {
    local encoded="$1"
    echo "$encoded" | base64 -d
}