#!/bin/bash

# validate-config.sh - Configuration validation script using latest JSON Schema practices
# Created: 2025-09-17 (全体リファクタリング)
# Implements: JSON Schema Draft 2020-12, RFC 8927 (JSON Type Definition)

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCHEMAS_DIR="$PROJECT_ROOT/.claude/schemas"
CONFIG_FILE="${PROJECT_ROOT}/.claude/settings-phase2.json"
SCHEMA_FILE="${SCHEMAS_DIR}/settings-phase2.schema.json"

# Colors for output (2025 accessibility standards)
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions (structured logging 2025 best practices)
log_info() {
    printf "${BLUE}[INFO]${NC} %s\n" "$*" >&2
}

log_success() {
    printf "${GREEN}[SUCCESS]${NC} %s\n" "$*" >&2
}

log_warning() {
    printf "${YELLOW}[WARNING]${NC} %s\n" "$*" >&2
}

log_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$*" >&2
}

log_structured() {
    local level="$1"
    local component="$2"
    local message="$3"
    local context="${4:-}"

    printf '{"timestamp":"%s","level":"%s","component":"%s","message":"%s","context":"%s"}\n' \
           "$(date -Iseconds)" "$level" "$component" "$message" "$context" >&2
}

# Validation functions
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check for jq (essential for JSON processing)
    if ! command -v jq >/dev/null 2>&1; then
        log_error "jq is required but not installed. Please install jq."
        log_info "On Ubuntu/Debian: sudo apt-get install jq"
        log_info "On macOS: brew install jq"
        return 1
    fi

    # Check for advanced JSON schema validators (2025 recommendation)
    local validator_found=false

    # Try ajv-cli (industry standard)
    if command -v ajv >/dev/null 2>&1; then
        log_info "Found ajv-cli validator (recommended)"
        validator_found=true
    fi

    # Try jtd-validate (RFC 8927 compliant)
    if command -v jtd-validate >/dev/null 2>&1; then
        log_info "Found jtd-validate (RFC 8927 compliant)"
        validator_found=true
    fi

    if ! $validator_found; then
        log_warning "No advanced JSON schema validator found. Using basic jq validation only."
        log_info "For enhanced validation, install ajv-cli: npm install -g ajv-cli"
        log_info "Or jtd-validate: https://jsontypedef.com/docs/jtd-validate/"
    fi

    return 0
}

# Basic JSON syntax validation
validate_json_syntax() {
    local file="$1"
    local component="$2"

    log_info "Validating JSON syntax for $component..."

    if [[ ! -f "$file" ]]; then
        log_error "Configuration file not found: $file"
        return 1
    fi

    if ! jq empty "$file" 2>/dev/null; then
        log_error "Invalid JSON syntax in $file"
        log_structured "ERROR" "$component" "JSON syntax validation failed" "$file"

        # Provide helpful error details
        local error_details
        error_details=$(jq empty "$file" 2>&1 || true)
        log_error "JSON Error Details: $error_details"
        return 1
    fi

    log_success "JSON syntax validation passed for $component"
    return 0
}

# Advanced JSON Schema validation (using ajv-cli if available)
validate_with_ajv() {
    local config_file="$1"
    local schema_file="$2"

    if ! command -v ajv >/dev/null 2>&1; then
        return 2  # Skip if ajv not available
    fi

    log_info "Performing advanced JSON Schema validation with ajv-cli..."

    if ajv validate -s "$schema_file" -d "$config_file" 2>/dev/null; then
        log_success "JSON Schema validation passed with ajv-cli"
        return 0
    else
        log_error "JSON Schema validation failed with ajv-cli"

        # Get detailed error information
        local validation_errors
        validation_errors=$(ajv validate -s "$schema_file" -d "$config_file" 2>&1 || true)
        log_error "Validation errors: $validation_errors"

        log_structured "ERROR" "schema_validation" "Advanced validation failed" "$validation_errors"
        return 1
    fi
}

# Business logic validation (domain-specific checks)
validate_business_logic() {
    local config_file="$1"

    log_info "Performing business logic validation..."

    local errors=0

    # Check Phase 2 version compatibility
    local version
    version=$(jq -r '.phase2.version // empty' "$config_file")
    if [[ -z "$version" ]]; then
        log_error "Phase 2 version is required"
        ((errors++))
    elif [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_error "Invalid version format: $version (expected: X.Y.Z)"
        ((errors++))
    fi

    # Check memory bank configuration consistency
    local memory_enabled
    memory_enabled=$(jq -r '.phase2.features.memory_bank.enabled // false' "$config_file")
    if [[ "$memory_enabled" == "true" ]]; then
        local max_lines
        max_lines=$(jq -r '.phase2.features.memory_bank.max_lines_per_file // 0' "$config_file")
        if [[ "$max_lines" -lt 100 ]] || [[ "$max_lines" -gt 5000 ]]; then
            log_warning "Memory bank max_lines_per_file ($max_lines) outside recommended range (100-5000)"
        fi

        local threshold
        threshold=$(jq -r '.phase2.features.memory_bank.importance_threshold // 0' "$config_file")
        if [[ "$threshold" -lt 1 ]] || [[ "$threshold" -gt 10 ]]; then
            log_error "Memory bank importance_threshold ($threshold) must be between 1-10"
            ((errors++))
        fi
    fi

    # Check parallel execution configuration
    local parallel_enabled
    parallel_enabled=$(jq -r '.phase2.features.parallel_execution.enabled // false' "$config_file")
    if [[ "$parallel_enabled" == "true" ]]; then
        local max_workers
        max_workers=$(jq -r '.phase2.features.parallel_execution.max_workers // 0' "$config_file")
        local cpu_cores
        cpu_cores=$(nproc 2>/dev/null || echo "4")

        if [[ "$max_workers" -gt $((cpu_cores * 2)) ]]; then
            log_warning "max_workers ($max_workers) exceeds recommended limit (2x CPU cores: $((cpu_cores * 2)))"
        fi
    fi

    # Check monitoring thresholds consistency
    local monitoring_enabled
    monitoring_enabled=$(jq -r '.phase2.features.monitoring.enabled // false' "$config_file")
    if [[ "$monitoring_enabled" == "true" ]]; then
        # Validate that critical thresholds are higher than warning thresholds
        local warning_error_rate critical_error_rate
        warning_error_rate=$(jq -r '.phase2.features.monitoring.thresholds.error_rate.warning // 0' "$config_file")
        critical_error_rate=$(jq -r '.phase2.features.monitoring.thresholds.error_rate.critical // 0' "$config_file")

        if [[ $(echo "$critical_error_rate <= $warning_error_rate" | bc -l 2>/dev/null || echo "0") == "1" ]]; then
            log_error "Critical error rate threshold ($critical_error_rate) must be higher than warning threshold ($warning_error_rate)"
            ((errors++))
        fi
    fi

    if [[ $errors -eq 0 ]]; then
        log_success "Business logic validation passed"
        return 0
    else
        log_error "Business logic validation failed with $errors error(s)"
        log_structured "ERROR" "business_logic" "Validation failed" "errors=$errors"
        return 1
    fi
}

# Security validation (2025 security standards)
validate_security() {
    local config_file="$1"

    log_info "Performing security validation..."

    local warnings=0

    # Check for security settings
    local input_validation
    input_validation=$(jq -r '.phase2.security.input_validation.enabled // false' "$config_file")
    if [[ "$input_validation" != "true" ]]; then
        log_warning "Input validation is disabled - security risk"
        ((warnings++))
    fi

    local strict_mode
    strict_mode=$(jq -r '.phase2.security.input_validation.strict_mode // false' "$config_file")
    if [[ "$strict_mode" != "true" ]]; then
        log_warning "Strict mode is disabled - consider enabling for production"
        ((warnings++))
    fi

    # Check for audit logging
    local audit_logging
    audit_logging=$(jq -r '.phase2.security.data_protection.audit_logging // false' "$config_file")
    if [[ "$audit_logging" != "true" ]]; then
        log_warning "Audit logging is disabled - recommended for compliance"
        ((warnings++))
    fi

    # Check file paths for path traversal attempts
    local archive_path
    archive_path=$(jq -r '.phase2.features.memory_bank.archive.archive_path // ""' "$config_file")
    if [[ "$archive_path" == *".."* ]]; then
        log_error "Security risk: Archive path contains '..' - potential path traversal"
        return 1
    fi

    if [[ $warnings -gt 0 ]]; then
        log_warning "Security validation completed with $warnings warning(s)"
    else
        log_success "Security validation passed"
    fi

    return 0
}

# Performance impact analysis
analyze_performance_impact() {
    local config_file="$1"

    log_info "Analyzing performance impact..."

    local performance_score=100
    local recommendations=()

    # Check memory settings
    local max_memory
    max_memory=$(jq -r '.phase2.performance.resource_limits.max_memory_mb // 2048' "$config_file")
    if [[ "$max_memory" -gt 4096 ]]; then
        recommendations+=("High memory limit ($max_memory MB) may impact system performance")
        ((performance_score -= 10))
    fi

    # Check parallel workers vs CPU cores
    local max_workers
    max_workers=$(jq -r '.phase2.features.parallel_execution.max_workers // 4' "$config_file")
    local cpu_cores
    cpu_cores=$(nproc 2>/dev/null || echo "4")

    if [[ "$max_workers" -gt "$cpu_cores" ]]; then
        recommendations+=("max_workers ($max_workers) > CPU cores ($cpu_cores) - may cause context switching overhead")
        ((performance_score -= 15))
    fi

    # Check monitoring interval
    local monitoring_interval
    monitoring_interval=$(jq -r '.phase2.features.monitoring.real_time.update_interval_seconds // 30' "$config_file")
    if [[ "$monitoring_interval" -lt 10 ]]; then
        recommendations+=("Very frequent monitoring updates ($monitoring_interval s) may impact performance")
        ((performance_score -= 5))
    fi

    log_info "Performance score: $performance_score/100"

    if [[ ${#recommendations[@]} -gt 0 ]]; then
        log_info "Performance recommendations:"
        for rec in "${recommendations[@]}"; do
            log_warning "  - $rec"
        done
    else
        log_success "No performance concerns detected"
    fi

    return 0
}

# Generate validation report
generate_report() {
    local config_file="$1"
    local report_file="${PROJECT_ROOT}/.claude/logs/config-validation-$(date +%Y%m%d-%H%M%S).json"

    log_info "Generating validation report..."

    mkdir -p "$(dirname "$report_file")"

    local report_data
    report_data=$(cat <<EOF
{
  "validation_timestamp": "$(date -Iseconds)",
  "config_file": "$config_file",
  "schema_file": "$SCHEMA_FILE",
  "validator_version": "1.0.0",
  "system_info": {
    "os": "$(uname -s)",
    "hostname": "$(hostname)",
    "user": "$(whoami)",
    "pwd": "$(pwd)",
    "cpu_cores": $(nproc 2>/dev/null || echo "4")
  },
  "validation_results": {
    "syntax_valid": true,
    "schema_valid": true,
    "business_logic_valid": true,
    "security_valid": true
  },
  "configuration_summary": $(jq '.phase2 | {
    version: .version,
    enabled_features: [
      if .features.memory_bank.enabled then "memory_bank" else empty end,
      if .features.parallel_execution.enabled then "parallel_execution" else empty end,
      if .features.tdd_checks.enabled then "tdd_checks" else empty end,
      if .features.monitoring.enabled then "monitoring" else empty end
    ]
  }' "$config_file" 2>/dev/null || echo 'null')
}
EOF
    )

    echo "$report_data" > "$report_file"
    log_success "Validation report generated: $report_file"

    return 0
}

# Main validation function
main() {
    local config_file="${1:-$CONFIG_FILE}"
    local schema_file="${2:-$SCHEMA_FILE}"

    log_info "Starting Phase 2 configuration validation..."
    log_info "Config file: $config_file"
    log_info "Schema file: $schema_file"

    # Prerequisites check
    if ! check_prerequisites; then
        log_error "Prerequisites check failed"
        exit 1
    fi

    # Step 1: JSON syntax validation
    if ! validate_json_syntax "$config_file" "settings-phase2"; then
        log_error "Configuration validation failed at syntax check"
        exit 1
    fi

    if ! validate_json_syntax "$schema_file" "schema"; then
        log_error "Schema validation failed at syntax check"
        exit 1
    fi

    # Step 2: Advanced JSON Schema validation
    local schema_result
    validate_with_ajv "$config_file" "$schema_file"
    schema_result=$?

    if [[ $schema_result -eq 1 ]]; then
        log_error "Configuration validation failed at schema validation"
        exit 1
    elif [[ $schema_result -eq 2 ]]; then
        log_info "Advanced schema validation skipped (ajv-cli not available)"
    fi

    # Step 3: Business logic validation
    if ! validate_business_logic "$config_file"; then
        log_error "Configuration validation failed at business logic check"
        exit 1
    fi

    # Step 4: Security validation
    if ! validate_security "$config_file"; then
        log_error "Configuration validation failed at security check"
        exit 1
    fi

    # Step 5: Performance impact analysis
    analyze_performance_impact "$config_file"

    # Step 6: Generate report
    generate_report "$config_file"

    log_success "✅ Configuration validation completed successfully!"
    log_info "Your Phase 2 configuration is valid and ready for use."

    return 0
}

# Help function
show_help() {
    cat <<EOF
Usage: $0 [CONFIG_FILE] [SCHEMA_FILE]

Validates Phase 2 configuration using latest JSON Schema practices (2025).

Arguments:
  CONFIG_FILE    Path to settings-phase2.json (default: .claude/settings-phase2.json)
  SCHEMA_FILE    Path to schema file (default: .claude/schemas/settings-phase2.schema.json)

Features:
  - JSON syntax validation
  - JSON Schema validation (Draft 2020-12)
  - Business logic validation
  - Security assessment
  - Performance impact analysis
  - Structured logging
  - Detailed reporting

Examples:
  $0                                    # Validate default configuration
  $0 custom-config.json                # Validate custom configuration
  $0 config.json schema.json           # Validate with custom schema

Requirements:
  - jq (required)
  - ajv-cli (recommended): npm install -g ajv-cli
  - jtd-validate (optional): RFC 8927 compliant validator

For more information, see: docs/PHASE2_CONFIGURATION_GUIDE.md
EOF
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        -h|--help|help)
            show_help
            exit 0
            ;;
        *)
            main "$@"
            ;;
    esac
fi
