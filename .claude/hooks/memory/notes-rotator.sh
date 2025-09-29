#!/bin/bash
# notes-rotator.sh - Memory Bank intelligent rotation system
# TDD implementation with enhanced archive management
# Created: 2025-09-16
# Version: 3.0.0 - Modular Architecture

# ==============================================================================
# Script Setup and Module Loading
# ==============================================================================

# Get script directory - handle both direct execution and sourcing from tests
if [[ -n "${BASH_SOURCE[0]}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

# Resolve the actual path (handle symlinks)
SCRIPT_DIR="$(cd "${SCRIPT_DIR}" && pwd -P)"
LIB_DIR="${SCRIPT_DIR}/lib"

# Check if lib directory exists, if not try alternate locations
if [[ ! -d "${LIB_DIR}" ]]; then
    # Try relative to the test location
    if [[ -d "${SCRIPT_DIR}/../../hooks/memory/lib" ]]; then
        LIB_DIR="${SCRIPT_DIR}/../../hooks/memory/lib"
    fi
fi

# Load all modules in order
if [[ ! -f "${LIB_DIR}/config.sh" ]]; then
    echo "ERROR: Cannot find config.sh at ${LIB_DIR}/config.sh" >&2
    echo "SCRIPT_DIR is: ${SCRIPT_DIR}" >&2
    echo "LIB_DIR is: ${LIB_DIR}" >&2
    exit 1
fi

source "${LIB_DIR}/config.sh" || {
    echo "ERROR: Failed to load config.sh module from ${LIB_DIR}" >&2
    exit 1
}

source "${LIB_DIR}/utils.sh" 2>/dev/null || {
    echo "ERROR: Failed to load utils.sh module" >&2
    exit 1
}

source "${LIB_DIR}/analysis.sh" 2>/dev/null || {
    echo "ERROR: Failed to load analysis.sh module" >&2
    exit 1
}

source "${LIB_DIR}/archive.sh" 2>/dev/null || {
    echo "ERROR: Failed to load archive.sh module" >&2
    exit 1
}

source "${LIB_DIR}/rotation.sh" 2>/dev/null || {
    echo "ERROR: Failed to load rotation.sh module" >&2
    exit 1
}

# Source legacy utilities for backward compatibility
source "${SCRIPT_DIR}/../common/hook-common.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/../common/json-utils.sh" 2>/dev/null || true

# Initialize configuration
init_config || {
    log_error "Failed to initialize configuration"
    exit 1
}

# Set up cleanup trap
setup_cleanup_trap

# ==============================================================================
# All functions are now provided by the loaded modules
# ==============================================================================
# The modular functions are already exported and available for use
# No wrapper functions needed as they would cause infinite recursion

# ==============================================================================
# Main Execution (for standalone testing)
# ==============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being executed directly (not sourced)
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <notes_file> [agent_name]"
        exit 1
    fi

    rotate_notes_if_needed "$1" "${2:-unknown}"
    exit $?
fi
