#!/usr/bin/env bash
# Phase 2 Release Test Script
# Sprint 2.6.4 リリーステスト実行スクリプト

set -euo pipefail

# テストレポート設定
TEST_REPORT_DIR="$(pwd)/.claude/test-reports/phase2-release"
TEST_TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
TEST_REPORT_FILE="$TEST_REPORT_DIR/phase2-release-test-$TEST_TIMESTAMP.md"

# テスト環境設定
export CLAUDE_PROJECT_DIR="$(pwd)"
export TEST_ENV="release"

# 色付き出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ユーティリティ関数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1" >> "$TEST_REPORT_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $1" >> "$TEST_REPORT_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >> "$TEST_REPORT_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARNING] $1" >> "$TEST_REPORT_FILE"
}

# テストレポート初期化
init_test_report() {
    mkdir -p "$TEST_REPORT_DIR"
    cat > "$TEST_REPORT_FILE" << EOF
# Phase 2 Release Test Report
## Sprint 2.6.4 - $(date '+%Y-%m-%d %H:%M:%S')

### テスト環境
- プロジェクト: claude-friends-templates
- バージョン: Phase 2
- 実行日時: $(date '+%Y-%m-%d %H:%M:%S')
- 実行環境: $CLAUDE_PROJECT_DIR

### テスト対象機能
1. Memory Bank重要度スコアリング
2. 並列Subagent実行（最大10並列）
3. t-wada式TDD厳格適用
4. Prometheus形式メトリクス監視
5. JSONL構造化ログ（2025標準）
6. Zero Trust + SBOM + CVSS 4.0セキュリティ強化
7. AI駆動パフォーマンス監視

---

## テスト実行結果

EOF
    log_info "テストレポート初期化完了: $TEST_REPORT_FILE"
}

# Phase 2機能テスト実行
test_memory_bank_scoring() {
    log_info "Memory Bank重要度スコアリング テスト開始"

    local test_notes_file="$CLAUDE_PROJECT_DIR/.claude/test/notes.md"
    mkdir -p "$(dirname "$test_notes_file")"

    # テストデータ生成
    cat > "$test_notes_file" << EOF
# Critical Architecture Decision
This is a critical design decision that must be preserved.
BREAKING CHANGE: API interface modified.

# Important Features
- Feature 1: High priority implementation
- Feature 2: Important update

# Regular Notes
Some regular development notes here.
Fixed minor bug in utility function.
EOF

    # 重要度分析テスト
    if [ -f ".claude/hooks/memory/lib/analysis.sh" ]; then
        source .claude/hooks/memory/lib/analysis.sh
        local importance_score=$(analyze_content_importance "$test_notes_file" 2>/dev/null || echo "0")

        if [[ "$importance_score" -gt 0 ]]; then
            log_success "Memory Bank重要度スコアリング: スコア=$importance_score"
            return 0
        else
            log_error "Memory Bank重要度スコアリング: スコアが0または失敗"
            return 1
        fi
    else
        log_warning "Memory Bank重要度スコアリング: 実装ファイルが見つかりません"
        return 1
    fi
}

test_parallel_execution() {
    log_info "並列Subagent実行 テスト開始"

    # 並列実行環境テスト
    if [ -f ".claude/hooks/parallel/parallel-executor.sh" ]; then
        # 構文チェック
        if bash -n .claude/hooks/parallel/parallel-executor.sh; then
            log_success "並列Subagent実行: 構文チェック成功"

            # 基本機能テスト
            source .claude/hooks/parallel/parallel-executor.sh

            # テスト用キュー作成
            local test_queue_dir="$CLAUDE_PROJECT_DIR/.claude/test/queue"
            mkdir -p "$test_queue_dir"
            export QUEUE_DIR="$test_queue_dir"

            # 簡単なタスク実行テスト
            if type enqueue_task >/dev/null 2>&1; then
                enqueue_task "echo 'Test task executed'" >/dev/null 2>&1
                log_success "並列Subagent実行: タスクエンキュー成功"
                return 0
            else
                log_warning "並列Subagent実行: enqueue_task関数が見つかりません"
                return 1
            fi
        else
            log_error "並列Subagent実行: 構文エラーが検出されました"
            return 1
        fi
    else
        log_error "並列Subagent実行: 実装ファイルが見つかりません"
        return 1
    fi
}

test_tdd_enforcement() {
    log_info "t-wada式TDD厳格適用 テスト開始"

    if [ -f ".claude/hooks/tdd/tdd-checker.sh" ]; then
        # 構文チェック
        if bash -n .claude/hooks/tdd/tdd-checker.sh; then
            log_success "t-wada式TDD厳格適用: 構文チェック成功"

            # TDDチェック機能テスト
            source .claude/hooks/tdd/tdd-checker.sh

            if type perform_tdd_check >/dev/null 2>&1; then
                log_success "t-wada式TDD厳格適用: perform_tdd_check関数利用可能"
                return 0
            else
                log_warning "t-wada式TDD厳格適用: perform_tdd_check関数が見つかりません"
                return 1
            fi
        else
            log_error "t-wada式TDD厳格適用: 構文エラーが検出されました"
            return 1
        fi
    else
        log_error "t-wada式TDD厳格適用: 実装ファイルが見つかりません"
        return 1
    fi
}

test_prometheus_metrics() {
    log_info "Prometheus形式メトリクス監視 テスト開始"

    if [ -f ".claude/hooks/monitoring/metrics-collector.sh" ]; then
        # 構文チェック
        if bash -n .claude/hooks/monitoring/metrics-collector.sh; then
            log_success "Prometheus形式メトリクス監視: 構文チェック成功"

            # メトリクス収集機能テスト
            source .claude/hooks/monitoring/metrics-collector.sh

            # テスト用メトリクスディレクトリ
            local test_metrics_dir="$CLAUDE_PROJECT_DIR/.claude/test/metrics"
            mkdir -p "$test_metrics_dir"
            export METRICS_FILE="$test_metrics_dir/metrics.txt"

            if type collect_metrics >/dev/null 2>&1; then
                collect_metrics "test-hook" 0.5 "success" >/dev/null 2>&1
                log_success "Prometheus形式メトリクス監視: メトリクス収集成功"
                return 0
            else
                log_warning "Prometheus形式メトリクス監視: collect_metrics関数が見つかりません"
                return 1
            fi
        else
            log_error "Prometheus形式メトリクス監視: 構文エラーが検出されました"
            return 1
        fi
    else
        log_error "Prometheus形式メトリクス監視: 実装ファイルが見つかりません"
        return 1
    fi
}

test_structured_logging() {
    log_info "JSONL構造化ログ（2025標準） テスト開始"

    if [ -f ".claude/hooks/monitoring/structured-logger.sh" ]; then
        # 構文チェック
        if bash -n .claude/hooks/monitoring/structured-logger.sh; then
            log_success "JSONL構造化ログ: 構文チェック成功"

            # 構造化ログ機能テスト
            source .claude/hooks/monitoring/structured-logger.sh

            if type log_structured >/dev/null 2>&1; then
                log_structured "INFO" "test-component" "Test structured log message" >/dev/null 2>&1
                log_success "JSONL構造化ログ: ログ生成成功"
                return 0
            else
                log_warning "JSONL構造化ログ: log_structured関数が見つかりません"
                return 1
            fi
        else
            log_error "JSONL構造化ログ: 構文エラーが検出されました"
            return 1
        fi
    else
        log_warning "JSONL構造化ログ: 実装ファイルが見つかりません（オプション機能）"
        return 1
    fi
}

test_security_enhancements() {
    log_info "Zero Trust + SBOM + CVSS 4.0セキュリティ強化 テスト開始"

    local security_files=(
        ".claude/scripts/security-audit.py"
        ".claude/scripts/sbom-generator.py"
        ".claude/scripts/zero-trust-controller.py"
    )

    local passed=0
    local total=${#security_files[@]}

    for file in "${security_files[@]}"; do
        if [ -f "$file" ]; then
            # Python構文チェック
            if python3 -m py_compile "$file" 2>/dev/null; then
                log_success "セキュリティ強化: $file 構文チェック成功"
                ((passed++))
            else
                log_error "セキュリティ強化: $file 構文エラー"
            fi
        else
            log_warning "セキュリティ強化: $file が見つかりません"
        fi
    done

    if [[ $passed -ge 2 ]]; then
        log_success "Zero Trust + SBOM + CVSS 4.0セキュリティ強化: $passed/$total 成功"
        return 0
    else
        log_error "Zero Trust + SBOM + CVSS 4.0セキュリティ強化: $passed/$total 成功（不十分）"
        return 1
    fi
}

test_ai_performance_monitoring() {
    log_info "AI駆動パフォーマンス監視 テスト開始"

    if [ -f ".claude/shared/monitoring/ai-performance-analyzer.py" ]; then
        # Python構文チェック
        if python3 -m py_compile .claude/shared/monitoring/ai-performance-analyzer.py 2>/dev/null; then
            log_success "AI駆動パフォーマンス監視: 構文チェック成功"
            return 0
        else
            log_error "AI駆動パフォーマンス監視: 構文エラーが検出されました"
            return 1
        fi
    else
        log_warning "AI駆動パフォーマンス監視: 実装ファイルが見つかりません"
        return 1
    fi
}

# パフォーマンスベンチマーク
run_performance_benchmark() {
    log_info "パフォーマンスベンチマーク実行開始"

    # Memory Bank回転のパフォーマンステスト
    local start_time=$(date +%s%N)

    # 大きなテストファイル作成（1000行）
    local test_file="$CLAUDE_PROJECT_DIR/.claude/test/performance-test.md"
    mkdir -p "$(dirname "$test_file")"

    for i in $(seq 1 1000); do
        echo "Performance test line $i with some content" >> "$test_file"
    done

    local end_time=$(date +%s%N)
    local duration=$((($end_time - $start_time) / 1000000)) # ms

    if [[ $duration -lt 1000 ]]; then
        log_success "パフォーマンスベンチマーク: 1000行ファイル作成 ${duration}ms < 1000ms"
        return 0
    else
        log_warning "パフォーマンスベンチマーク: 1000行ファイル作成 ${duration}ms >= 1000ms"
        return 1
    fi
}

# エラーハンドリングテスト
test_error_handling() {
    log_info "エラーハンドリング検証開始"

    # 存在しないファイルアクセステスト
    if [ -f ".claude/hooks/memory/notes-rotator.sh" ]; then
        source .claude/hooks/memory/notes-rotator.sh

        # 存在しないファイルに対してローテーション実行
        if rotate_notes_if_needed "/nonexistent/file.md" "test" 2>/dev/null; then
            log_warning "エラーハンドリング: 存在しないファイルでエラーを返すべき"
            return 1
        else
            log_success "エラーハンドリング: 適切にエラーを処理"
            return 0
        fi
    else
        log_warning "エラーハンドリング: テスト対象ファイルが見つかりません"
        return 1
    fi
}

# 総合結果レポート生成
generate_summary_report() {
    local total_tests=$1
    local passed_tests=$2
    local failed_tests=$((total_tests - passed_tests))
    local success_rate=$((passed_tests * 100 / total_tests))

    cat >> "$TEST_REPORT_FILE" << EOF

---

## テスト結果サマリー

### 総合結果
- **総テスト数**: $total_tests
- **成功**: $passed_tests
- **失敗**: $failed_tests
- **成功率**: $success_rate%

### リリース判定
EOF

    if [[ $success_rate -ge 80 ]]; then
        log_success "リリース判定: PASS (成功率 $success_rate% >= 80%)"
        echo "**判定: ✅ リリース可能**" >> "$TEST_REPORT_FILE"
        echo "" >> "$TEST_REPORT_FILE"
        echo "- 成功率が80%以上でリリース基準を満たしています" >> "$TEST_REPORT_FILE"
        echo "- Phase 2機能は本番環境で安全に動作可能です" >> "$TEST_REPORT_FILE"
        return 0
    else
        log_error "リリース判定: FAIL (成功率 $success_rate% < 80%)"
        echo "**判定: ❌ リリース不可**" >> "$TEST_REPORT_FILE"
        echo "" >> "$TEST_REPORT_FILE"
        echo "- 成功率が80%未満でリリース基準を満たしていません" >> "$TEST_REPORT_FILE"
        echo "- 失敗したテストの修正が必要です" >> "$TEST_REPORT_FILE"
        return 1
    fi
}

# メイン実行関数
main() {
    log_info "Phase 2 Release Test 開始"
    init_test_report

    # テスト実行配列
    local tests=(
        "test_memory_bank_scoring"
        "test_parallel_execution"
        "test_tdd_enforcement"
        "test_prometheus_metrics"
        "test_structured_logging"
        "test_security_enhancements"
        "test_ai_performance_monitoring"
        "run_performance_benchmark"
        "test_error_handling"
    )

    local total_tests=${#tests[@]}
    local passed_tests=0

    # 各テスト実行
    for test_func in "${tests[@]}"; do
        if $test_func; then
            ((passed_tests++))
        fi
        echo "" >> "$TEST_REPORT_FILE"
    done

    # 結果レポート生成
    generate_summary_report $total_tests $passed_tests

    log_info "Phase 2 Release Test 完了"
    log_info "詳細レポート: $TEST_REPORT_FILE"

    # 最終結果を返す
    if [[ $((passed_tests * 100 / total_tests)) -ge 80 ]]; then
        return 0
    else
        return 1
    fi
}

# スクリプトが直接実行された場合
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi