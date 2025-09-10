#!/bin/bash

# Claude Code Activity Logger Hook (Refactored Version)
# 開発活動の自動ログ記録 - 共有ユーティリティ使用版

# Load shared utilities
# shellcheck source=shared-utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/shared-utils.sh"

# Configuration
CLAUDE_LOG_FILE="${HOME}/.claude/activity.log"
METRICS_FILE="${HOME}/.claude/metrics.log"

# Initialize logging
init_logging "$CLAUDE_LOG_FILE"
init_logging "$METRICS_FILE"

# Get environment information
tool_name="${CLAUDE_TOOL_NAME:-unknown}"
file_paths="${CLAUDE_FILE_PATHS:-}"

# Log basic activity using shared utilities
log_info "Tool: $tool_name"

# Process file operations
if [[ -n "$file_paths" ]]; then
    IFS=',' read -ra FILES <<< "$file_paths"
    
    for file in "${FILES[@]}"; do
        if [[ -f "$file" ]]; then
            # Use shared utility to safely check file
            if check_file_readable "$file"; then
                file_size=$(stat -c%s "$file" 2>/dev/null || echo "0")
                file_ext="${file##*.}"
                
                log_info "File: $file (${file_size}B, .$file_ext)"
                
                # Categorize operation for metrics
                case "$tool_name" in
                    "Edit"|"Write"|"MultiEdit")
                        operation_type="CODE_EDIT"
                        ;;
                    "Read")
                        operation_type="FILE_READ"
                        ;;
                    "Bash")
                        operation_type="COMMAND_EXEC"
                        ;;
                    *)
                        operation_type="OTHER"
                        ;;
                esac
                
                # Log to metrics file with standardized format
                {
                    timestamp=$(get_timestamp)
                    echo "[$timestamp] $operation_type: $file_ext"
                } >> "$METRICS_FILE"
            else
                log_warn "Cannot read file: $file"
            fi
        else
            log_debug "File does not exist: $file"
        fi
    done
else
    log_debug "No file paths provided for tool: $tool_name"
fi

log_debug "Activity logging completed for tool: $tool_name"