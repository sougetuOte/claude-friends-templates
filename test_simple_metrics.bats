#!/usr/bin/env bats

@test "simple test to check if metrics collector can be sourced" {
    if [[ -f ".claude/hooks/monitoring/metrics-collector.sh" ]]; then
        source ".claude/hooks/monitoring/metrics-collector.sh"
        echo "Script found and sourced"
    else
        echo "Script not found at .claude/hooks/monitoring/metrics-collector.sh"
        exit 1
    fi
}

@test "test collect_metrics function exists" {
    source ".claude/hooks/monitoring/metrics-collector.sh"
    type collect_metrics
}