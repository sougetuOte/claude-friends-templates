#!/bin/bash

# =============================================================================
# Stage Guard - 開発段階チェック & 品質ゲートシステム
# Agent-First システムの核心コンポーネント
# =============================================================================

set -euo pipefail

# Configuration
DEBUG_MODE=${STAGE_GUARD_DEBUG:-false}
BYPASS_MODE=${STAGE_GUARD_BYPASS:-false}
LOG_FILE=".claude/logs/stage-guard.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    local msg="[INFO] $(date '+%Y-%m-%d %H:%M:%S') $*"
    echo -e "$msg" >&2
    [[ "$DEBUG_MODE" == "true" ]] && echo "$msg" >> "$LOG_FILE"
}

log_warn() {
    local msg="[WARN] $(date '+%Y-%m-%d %H:%M:%S') $*"
    echo -e "${YELLOW}$msg${NC}" >&2
    echo "$msg" >> "$LOG_FILE"
}

log_error() {
    local msg="[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $*"
    echo -e "${RED}$msg${NC}" >&2
    echo "$msg" >> "$LOG_FILE"
}

log_success() {
    local msg="[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') $*"
    echo -e "${GREEN}$msg${NC}" >&2
    [[ "$DEBUG_MODE" == "true" ]] && echo "$msg" >> "$LOG_FILE"
}

# Initialize logging
init_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    if [[ ! -f "$LOG_FILE" ]]; then
        touch "$LOG_FILE"
    fi
}

# Check requirements stage
check_requirements_stage() {
    log_info "Checking requirements stage..."
    
    local score=0
    local max_score=5
    local issues=()
    
    # Check 1: Requirements file exists
    if [[ -f "docs/requirements/index.md" ]]; then
        score=$((score + 1))
        log_success "✓ Requirements file exists"
    else
        issues+=("Requirements file missing: docs/requirements/index.md")
    fi
    
    # Check 2: Requirements file has sufficient content
    if [[ -f "docs/requirements/index.md" ]]; then
        local word_count=$(wc -w < "docs/requirements/index.md")
        if [[ $word_count -gt 200 ]]; then
            score=$((score + 1))
            log_success "✓ Requirements has sufficient content ($word_count words)"
        else
            issues+=("Requirements file too short: $word_count words (minimum: 200)")
        fi
    fi
    
    # Check 3: Functional requirements section
    if [[ -f "docs/requirements/index.md" ]] && grep -q "Functional Requirements\|機能要件" "docs/requirements/index.md"; then
        score=$((score + 1))
        log_success "✓ Functional requirements section found"
    else
        issues+=("Missing functional requirements section")
    fi
    
    # Check 4: Non-functional requirements section
    if [[ -f "docs/requirements/index.md" ]] && grep -q "Non-Functional Requirements\|非機能要件" "docs/requirements/index.md"; then
        score=$((score + 1))
        log_success "✓ Non-functional requirements section found"
    else
        issues+=("Missing non-functional requirements section")
    fi
    
    # Check 5: Technology stack specified
    if [[ -f "docs/requirements/index.md" ]] && grep -q "Technology Stack\|技術スタック" "docs/requirements/index.md"; then
        score=$((score + 1))
        log_success "✓ Technology stack section found"
    else
        issues+=("Missing technology stack specification")
    fi
    
    # Calculate percentage
    local percentage=$(( score * 100 / max_score ))
    
    echo "REQUIREMENTS_SCORE=$score" 
    echo "REQUIREMENTS_MAX=$max_score"
    echo "REQUIREMENTS_PERCENTAGE=$percentage"
    
    if [[ ${#issues[@]} -gt 0 ]]; then
        echo "REQUIREMENTS_ISSUES=("
        for issue in "${issues[@]}"; do
            echo "  \"$issue\""
        done
        echo ")"
    fi
    
    return $((max_score - score))
}

# Check design stage
check_design_stage() {
    log_info "Checking design stage..."
    
    local score=0
    local max_score=5
    local issues=()
    
    # Check 1: Design directory exists
    if [[ -d "docs/design/" ]]; then
        score=$((score + 1))
        log_success "✓ Design directory exists"
    else
        issues+=("Design directory missing: docs/design/")
    fi
    
    # Check 2: Architecture design
    if [[ -f "docs/design/architecture.md" ]]; then
        score=$((score + 1))
        log_success "✓ Architecture design exists"
    else
        issues+=("Architecture design missing: docs/design/architecture.md")
    fi
    
    # Check 3: API design
    if [[ -f "docs/design/api.md" ]]; then
        score=$((score + 1))
        log_success "✓ API design exists"
    else
        issues+=("API design missing: docs/design/api.md")
    fi
    
    # Check 4: Database design
    if [[ -f "docs/design/database.md" ]]; then
        score=$((score + 1))
        log_success "✓ Database design exists"
    else
        issues+=("Database design missing: docs/design/database.md")
    fi
    
    # Check 5: At least one design document has content
    local has_content=false
    for file in "docs/design/architecture.md" "docs/design/api.md" "docs/design/database.md"; do
        if [[ -f "$file" ]] && [[ $(wc -w < "$file") -gt 50 ]]; then
            has_content=true
            break
        fi
    done
    
    if [[ "$has_content" == "true" ]]; then
        score=$((score + 1))
        log_success "✓ Design documents have sufficient content"
    else
        issues+=("Design documents lack sufficient content (minimum: 50 words each)")
    fi
    
    local percentage=$(( score * 100 / max_score ))
    
    echo "DESIGN_SCORE=$score"
    echo "DESIGN_MAX=$max_score" 
    echo "DESIGN_PERCENTAGE=$percentage"
    
    if [[ ${#issues[@]} -gt 0 ]]; then
        echo "DESIGN_ISSUES=("
        for issue in "${issues[@]}"; do
            echo "  \"$issue\""
        done
        echo ")"
    fi
    
    return $((max_score - score))
}

# Check tasks stage  
check_tasks_stage() {
    log_info "Checking tasks stage..."
    
    local score=0
    local max_score=4
    local issues=()
    
    # Check 1: Phase-todo file exists
    if [[ -f "memo/phase-todo.md" ]] || [[ -f ".claude/shared/phase-todo.md" ]]; then
        score=$((score + 1))
        log_success "✓ Phase-todo file exists"
    else
        issues+=("Phase-todo file missing: memo/phase-todo.md or .claude/shared/phase-todo.md")
    fi
    
    # Check 2: Has multiple phases
    local todo_file=""
    [[ -f "memo/phase-todo.md" ]] && todo_file="memo/phase-todo.md"
    [[ -f ".claude/shared/phase-todo.md" ]] && todo_file=".claude/shared/phase-todo.md"
    
    if [[ -n "$todo_file" ]] && [[ $(grep -c "Phase\|フェーズ" "$todo_file") -ge 3 ]]; then
        score=$((score + 1))
        log_success "✓ Multiple phases defined"
    else
        issues+=("Insufficient phase definition (minimum: 3 phases)")
    fi
    
    # Check 3: Has detailed tasks
    if [[ -n "$todo_file" ]] && [[ $(grep -c "\- \[" "$todo_file") -ge 5 ]]; then
        score=$((score + 1))
        log_success "✓ Detailed tasks defined"
    else
        issues+=("Insufficient task details (minimum: 5 tasks)")
    fi
    
    # Check 4: Has task priorities or status
    if [[ -n "$todo_file" ]] && (grep -q "Priority\|優先度\|Status\|状態" "$todo_file" || grep -q "🔴\|🟡\|🟢\|✅" "$todo_file"); then
        score=$((score + 1))
        log_success "✓ Task priorities or status defined"
    else
        issues+=("Missing task priorities or status indicators")
    fi
    
    local percentage=$(( score * 100 / max_score ))
    
    echo "TASKS_SCORE=$score"
    echo "TASKS_MAX=$max_score"
    echo "TASKS_PERCENTAGE=$percentage"
    
    if [[ ${#issues[@]} -gt 0 ]]; then
        echo "TASKS_ISSUES=("
        for issue in "${issues[@]}"; do
            echo "  \"$issue\""
        done
        echo ")"
    fi
    
    return $((max_score - score))
}

# Generate stage report
generate_stage_report() {
    log_info "Generating comprehensive stage report..."
    
    # Get current working directory for context
    local project_root=$(pwd)
    local project_name=$(basename "$project_root")
    
    echo "# 🎯 Project Stage Analysis Report"
    echo ""
    echo "**Project**: $project_name"
    echo "**Timestamp**: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "**Location**: $project_root"
    echo ""
    
    # Requirements analysis
    echo "## 📋 Requirements Stage"
    local req_result
    req_result=$(check_requirements_stage 2>/dev/null)
    eval "$req_result"
    
    echo "- **Score**: $REQUIREMENTS_SCORE/$REQUIREMENTS_MAX ($REQUIREMENTS_PERCENTAGE%)"
    
    if [[ $REQUIREMENTS_PERCENTAGE -ge 80 ]]; then
        echo "- **Status**: ✅ **READY**"
    elif [[ $REQUIREMENTS_PERCENTAGE -ge 60 ]]; then
        echo "- **Status**: ⚠️ **NEEDS IMPROVEMENT**"
    else
        echo "- **Status**: ❌ **INCOMPLETE**"
    fi
    
    if [[ -n "${REQUIREMENTS_ISSUES:-}" ]]; then
        echo "- **Issues**:"
        eval "$REQUIREMENTS_ISSUES"
        for issue in "${REQUIREMENTS_ISSUES[@]:-}"; do
            echo "  - $issue"
        done
    fi
    echo ""
    
    # Design analysis  
    echo "## 🎨 Design Stage"
    local design_result
    design_result=$(check_design_stage 2>/dev/null)
    eval "$design_result"
    
    echo "- **Score**: $DESIGN_SCORE/$DESIGN_MAX ($DESIGN_PERCENTAGE%)"
    
    if [[ $DESIGN_PERCENTAGE -ge 80 ]]; then
        echo "- **Status**: ✅ **READY**"
    elif [[ $DESIGN_PERCENTAGE -ge 60 ]]; then
        echo "- **Status**: ⚠️ **NEEDS IMPROVEMENT**"  
    else
        echo "- **Status**: ❌ **INCOMPLETE**"
    fi
    
    if [[ -n "${DESIGN_ISSUES:-}" ]]; then
        echo "- **Issues**:"
        eval "$DESIGN_ISSUES"
        for issue in "${DESIGN_ISSUES[@]:-}"; do
            echo "  - $issue"
        done
    fi
    echo ""
    
    # Tasks analysis
    echo "## 📝 Tasks Stage"
    local tasks_result
    tasks_result=$(check_tasks_stage 2>/dev/null)
    eval "$tasks_result"
    
    echo "- **Score**: $TASKS_SCORE/$TASKS_MAX ($TASKS_PERCENTAGE%)"
    
    if [[ $TASKS_PERCENTAGE -ge 75 ]]; then
        echo "- **Status**: ✅ **READY**"
    elif [[ $TASKS_PERCENTAGE -ge 50 ]]; then
        echo "- **Status**: ⚠️ **NEEDS IMPROVEMENT**"
    else
        echo "- **Status**: ❌ **INCOMPLETE**"
    fi
    
    if [[ -n "${TASKS_ISSUES:-}" ]]; then
        echo "- **Issues**:"
        eval "$TASKS_ISSUES"
        for issue in "${TASKS_ISSUES[@]:-}"; do
            echo "  - $issue"
        done
    fi
    echo ""
    
    # Overall assessment
    local overall_ready=true
    [[ $REQUIREMENTS_PERCENTAGE -lt 80 ]] && overall_ready=false
    [[ $DESIGN_PERCENTAGE -lt 80 ]] && overall_ready=false  
    [[ $TASKS_PERCENTAGE -lt 75 ]] && overall_ready=false
    
    echo "## 🎯 Overall Assessment"
    if [[ "$overall_ready" == "true" ]]; then
        echo "- **Status**: 🟢 **READY FOR IMPLEMENTATION**"
        echo "- **Recommendation**: You can safely proceed with `/agent:builder`"
        echo ""
        echo "🚀 **Next Steps**:"
        echo "1. Review the analysis above"
        echo "2. Start implementation with \`/agent:builder\`" 
        echo "3. Follow TDD practices during development"
    else
        echo "- **Status**: 🔴 **NOT READY FOR IMPLEMENTATION**"
        echo "- **Recommendation**: Complete missing stages before implementation"
        echo ""
        echo "⚠️ **Required Actions**:"
        
        if [[ $REQUIREMENTS_PERCENTAGE -lt 80 ]]; then
            echo "1. 📋 Complete requirements analysis with \`/agent:requirements\` or \`/agent:planner\`"
        fi
        
        if [[ $DESIGN_PERCENTAGE -lt 80 ]]; then
            echo "2. 🎨 Complete design phase with \`/agent:planner\`"
        fi
        
        if [[ $TASKS_PERCENTAGE -lt 75 ]]; then
            echo "3. 📝 Complete task planning with \`/agent:planner\`"
        fi
    fi
    
    echo ""
    echo "---"
    echo "*Generated by Agent-First Stage Guard System*"
}

# Main guard function
main_guard() {
    local requested_agent="${1:-unknown}"
    local bypass_reason="${2:-}"
    
    init_logging
    log_info "Stage Guard activated for agent: $requested_agent"
    
    # Check bypass mode
    if [[ "$BYPASS_MODE" == "true" ]]; then
        log_warn "BYPASS MODE: Stage Guard checks disabled"
        if [[ -n "$bypass_reason" ]]; then
            log_info "Bypass reason: $bypass_reason"
        fi
        return 0
    fi
    
    # Allow agent:first always
    if [[ "$requested_agent" == "first" ]]; then
        log_info "Agent First access: ALLOWED"
        return 0
    fi
    
    # For planner and builder, check readiness
    case "$requested_agent" in
        "planner")
            log_info "Planner access requested - checking requirements readiness"
            check_requirements_stage >/dev/null
            local req_result=$?
            
            if [[ $req_result -gt 3 ]]; then  # Less than 40% complete
                log_error "❌ PLANNER ACCESS DENIED"
                echo ""
                echo -e "${RED}⚠️ STAGE GUARD: Planner Access Denied${NC}"
                echo ""
                echo "Requirements stage is incomplete. Please run:"
                echo -e "${BLUE}/agent:first${NC} - to get guidance on completing requirements"
                echo ""
                return 1
            else
                log_success "✅ Planner access: APPROVED"
                return 0
            fi
            ;;
            
        "builder")
            log_info "Builder access requested - checking full readiness"
            
            # Check all stages
            check_requirements_stage >/dev/null
            local req_result=$?
            check_design_stage >/dev/null  
            local design_result=$?
            check_tasks_stage >/dev/null
            local tasks_result=$?
            
            local total_issues=$((req_result + design_result + tasks_result))
            
            if [[ $total_issues -gt 2 ]]; then  # More than 2 issues total
                log_error "❌ BUILDER ACCESS DENIED"
                echo ""
                echo -e "${RED}⚠️ STAGE GUARD: Builder Access Denied${NC}"
                echo ""
                echo "Project stages are incomplete. Please run:"
                echo -e "${BLUE}/agent:first${NC} - to get a detailed analysis and guidance"
                echo ""
                return 1
            else
                log_success "✅ Builder access: APPROVED"
                return 0
            fi
            ;;
            
        *)
            log_info "Unknown agent access: $requested_agent - allowing"
            return 0
            ;;
    esac
}

# Help function
show_help() {
    cat << 'EOF'
Stage Guard - 開発段階チェック & 品質ゲートシステム

Usage: stage-guard.sh [command] [args...]

Commands:
  guard <agent>           Run stage guard check for specified agent
  check-requirements      Check requirements stage only
  check-design           Check design stage only  
  check-tasks            Check tasks stage only
  report                 Generate comprehensive stage report
  help                   Show this help message

Environment Variables:
  STAGE_GUARD_DEBUG      Enable debug logging (default: false)
  STAGE_GUARD_BYPASS     Bypass all checks (default: false)

Examples:
  ./stage-guard.sh guard planner
  ./stage-guard.sh report > stage-analysis.md
  STAGE_GUARD_DEBUG=true ./stage-guard.sh check-requirements

EOF
}

# Main execution
main() {
    local command="${1:-help}"
    
    case "$command" in
        "guard")
            main_guard "${2:-unknown}" "${3:-}"
            ;;
        "check-requirements")
            check_requirements_stage
            ;;
        "check-design") 
            check_design_stage
            ;;
        "check-tasks")
            check_tasks_stage
            ;;
        "report")
            generate_stage_report
            ;;
        *)
            show_help
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi