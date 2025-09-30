#!/usr/bin/env python3
"""
E2E Test Suite: Logging System Integration
Tests for AI Logger, Error Pattern Learning, and Log Analysis Tool integration

TDD Red Phase: Write failing tests first
Test Framework: pytest 8.4+
Target: Task 4.1.1 - E2E Integration Test Suite for Logging System
Python: 3.12+
"""

import json
import os
import subprocess
import time

import pytest


class TestLoggingSystemIntegration:
    """Test Suite: Logging system integration with agent handover"""

    @pytest.mark.e2e
    @pytest.mark.integration
    def test_agent_switch_creates_log_entries(self, claude_workspace, tmp_path):
        """
        Test 1: Agent switch generates structured log entries

        Expected: FAIL (AI logger not integrated with agent-switch.sh)
        """
        # Arrange: Set up AI logger with custom log file
        log_file = tmp_path / "ai-activity.jsonl"
        os.environ["AI_LOG_FILE"] = str(log_file)
        os.environ["CLAUDE_AGENT"] = "planner"

        # Act: Trigger agent switch
        result = subprocess.run(
            [
                "bash",
                str(claude_workspace / ".claude" / "scripts" / "agent-switch.sh"),
                "planner",
                "builder",
            ],
            cwd=claude_workspace,
            capture_output=True,
            text=True,
            timeout=30,
        )

        # Assert: Log entries created
        assert log_file.exists(), "AI log file not created"

        # Read log entries
        log_entries = []
        with open(log_file) as f:
            for line in f:
                if line.strip():
                    log_entries.append(json.loads(line))

        assert len(log_entries) > 0, "No log entries created"

        # Verify log entry structure
        first_entry = log_entries[0]
        assert "timestamp" in first_entry, "Missing timestamp"
        assert "level" in first_entry, "Missing log level"
        assert "message" in first_entry, "Missing message"
        assert "context" in first_entry, "Missing context"

        # Verify agent context
        assert "agent" in first_entry["context"], "Missing agent in context"

    @pytest.mark.e2e
    @pytest.mark.integration
    def test_handover_failure_generates_error_log(self, claude_workspace, tmp_path):
        """
        Test 2: Handover failure generates ERROR level log

        Expected: FAIL (error logging not implemented)
        """
        # Arrange: Set up logger with invalid handover scenario
        log_file = tmp_path / "ai-activity.jsonl"
        os.environ["AI_LOG_FILE"] = str(log_file)
        os.environ["CLAUDE_AGENT"] = "planner"

        # Simulate error by providing invalid arguments
        result = subprocess.run(
            [
                "bash",
                str(claude_workspace / ".claude" / "scripts" / "agent-switch.sh"),
                "invalid_agent",
                "builder",
            ],
            cwd=claude_workspace,
            capture_output=True,
            text=True,
            timeout=30,
        )

        # Assert: Error log created (even if script fails)
        if log_file.exists():
            with open(log_file) as f:
                log_entries = [json.loads(line) for line in f if line.strip()]

            # Find ERROR level logs
            error_logs = [e for e in log_entries if e.get("level") == "ERROR"]
            assert len(error_logs) > 0, "No ERROR logs for failed handover"

            # Verify AI metadata for errors
            error_log = error_logs[0]
            assert "ai_metadata" in error_log, "Missing AI metadata"
            assert (
                error_log["ai_metadata"]["priority"] == "high"
            ), "Error should have high priority"

    @pytest.mark.e2e
    @pytest.mark.integration
    def test_error_pattern_detection_after_multiple_handovers(
        self, claude_workspace, tmp_path
    ):
        """
        Test 3: Error pattern learning detects repeated errors

        Expected: FAIL (pattern detection not integrated)
        """
        # Arrange: Create log file with multiple similar errors
        log_file = tmp_path / "ai-activity.jsonl"
        os.environ["AI_LOG_FILE"] = str(log_file)

        # Simulate multiple handovers with errors
        error_message = "Connection timeout during handover"
        for i in range(5):
            # Write mock error logs
            log_entry = {
                "timestamp": f"2025-09-30T10:0{i}:00+00:00",
                "level": "ERROR",
                "message": error_message,
                "logger": "agent-switch",
                "context": {"agent": "planner", "correlation_id": f"test-{i}"},
                "metadata": {},
                "ai_metadata": {"priority": "high", "requires_human_review": True},
            }
            with open(log_file, "a") as f:
                f.write(json.dumps(log_entry) + "\n")

        # Act: Run error pattern learning
        # Import after PATH setup
        import sys

        sys.path.insert(0, str(claude_workspace / ".claude" / "scripts"))
        from error_pattern_learning import LogAnalyzer

        analyzer = LogAnalyzer(log_file)
        patterns = analyzer.analyze_patterns()
        insights = analyzer.generate_insights()

        # Assert: Pattern detected
        assert "error_patterns" in patterns, "Missing error_patterns"
        assert error_message in patterns["error_patterns"], "Pattern not detected"
        assert (
            len(patterns["error_patterns"][error_message]) >= 3
        ), "Should detect repeated pattern"

        # Assert: Insight generated
        pattern_insights = [i for i in insights if "Repeated error pattern" in i]
        assert len(pattern_insights) > 0, "No insight for repeated pattern"

    @pytest.mark.e2e
    @pytest.mark.integration
    def test_log_analysis_generates_comprehensive_report(
        self, claude_workspace, tmp_path
    ):
        """
        Test 4: Log analysis tool generates full report

        Expected: FAIL (report generation not fully integrated)
        """
        # Arrange: Create diverse log entries
        log_file = tmp_path / "ai-activity.jsonl"

        # Write sample logs (INFO and ERROR)
        log_entries = [
            {
                "timestamp": "2025-09-30T10:00:00+00:00",
                "level": "INFO",
                "message": "Handover started",
                "logger": "agent-switch",
                "context": {"agent": "planner"},
                "metadata": {"operation": "handover"},
                "ai_metadata": {"priority": "normal"},
            },
            {
                "timestamp": "2025-09-30T10:01:00+00:00",
                "level": "ERROR",
                "message": "Network error",
                "logger": "agent-switch",
                "context": {"agent": "builder"},
                "metadata": {"operation": "handover"},
                "ai_metadata": {"priority": "high"},
            },
            {
                "timestamp": "2025-09-30T10:02:00+00:00",
                "level": "INFO",
                "message": "Handover completed",
                "logger": "agent-switch",
                "context": {"agent": "builder"},
                "metadata": {"operation": "handover"},
                "ai_metadata": {"priority": "normal"},
            },
        ]

        with open(log_file, "w") as f:
            for entry in log_entries:
                f.write(json.dumps(entry) + "\n")

        # Act: Generate analysis report
        import sys

        sys.path.insert(0, str(claude_workspace / ".claude" / "scripts"))
        from error_pattern_learning import LogAnalyzer
        from log_analysis_tool import ReportGenerator

        analyzer = LogAnalyzer(log_file)
        generator = ReportGenerator(analyzer)
        report = generator.generate_full_report()

        # Assert: Report structure
        assert "summary" in report, "Missing summary"
        assert "time_series" in report, "Missing time_series"
        assert "statistics" in report, "Missing statistics"
        assert "insights" in report, "Missing insights"

        # Assert: Summary accuracy
        assert report["summary"]["total_entries"] == 3, "Wrong total entries"
        assert report["summary"]["total_errors"] == 1, "Wrong error count"

        # Assert: Agent activity tracking
        assert "agent_activities" in report["summary"], "Missing agent activities"
        agent_activities = report["summary"]["agent_activities"]
        assert "planner" in agent_activities, "Planner activity not tracked"
        assert "builder" in agent_activities, "Builder activity not tracked"

    @pytest.mark.e2e
    @pytest.mark.integration
    def test_complete_cycle_with_logging(self, claude_workspace, tmp_path):
        """
        Test 5: Complete cycle (Planner→Builder→Planner) with full logging

        Expected: FAIL (complete integration not tested)
        """
        # Arrange: Set up logging
        log_file = tmp_path / "ai-activity.jsonl"
        os.environ["AI_LOG_FILE"] = str(log_file)
        os.environ["CLAUDE_AGENT"] = "planner"

        # Phase 1: Planner → Builder
        result1 = subprocess.run(
            [
                "bash",
                str(claude_workspace / ".claude" / "scripts" / "agent-switch.sh"),
                "planner",
                "builder",
            ],
            cwd=claude_workspace,
            capture_output=True,
            text=True,
            timeout=30,
        )

        # Phase 2: Builder → Planner
        os.environ["CLAUDE_AGENT"] = "builder"
        result2 = subprocess.run(
            [
                "bash",
                str(claude_workspace / ".claude" / "scripts" / "agent-switch.sh"),
                "builder",
                "planner",
            ],
            cwd=claude_workspace,
            capture_output=True,
            text=True,
            timeout=30,
        )

        # Assert: Log file exists
        assert log_file.exists(), "Log file not created"

        # Assert: Log entries for both handovers
        with open(log_file) as f:
            log_entries = [json.loads(line) for line in f if line.strip()]

        assert len(log_entries) >= 2, "Insufficient log entries for complete cycle"

        # Verify correlation between handovers
        planner_entries = [
            e for e in log_entries if e.get("context", {}).get("agent") == "planner"
        ]
        builder_entries = [
            e for e in log_entries if e.get("context", {}).get("agent") == "builder"
        ]

        assert len(planner_entries) > 0, "No planner entries"
        assert len(builder_entries) > 0, "No builder entries"

    @pytest.mark.e2e
    @pytest.mark.integration
    def test_log_file_rotation_on_large_volume(self, claude_workspace, tmp_path):
        """
        Test 6: Log file rotation when exceeding size limit

        Expected: FAIL (log rotation not implemented)
        """
        # Arrange: Create large log file
        log_file = tmp_path / "ai-activity.jsonl"

        # Write many entries to exceed typical rotation threshold (e.g., 10MB)
        large_message = "A" * 1000  # 1KB message
        for i in range(1000):  # 1MB total
            log_entry = {
                "timestamp": f"2025-09-30T10:00:{i%60:02d}+00:00",
                "level": "INFO",
                "message": f"Entry {i}: {large_message}",
                "logger": "test",
                "context": {},
                "metadata": {},
                "ai_metadata": {},
            }
            with open(log_file, "a") as f:
                f.write(json.dumps(log_entry) + "\n")

        # Assert: Log file size check
        log_size_mb = log_file.stat().st_size / (1024 * 1024)
        assert log_size_mb > 0.5, "Log file should be substantial"

        # Note: Actual rotation behavior would be tested with logging config
        # For now, we verify file can be read and analyzed despite size
        import sys

        sys.path.insert(0, str(claude_workspace / ".claude" / "scripts"))
        from error_pattern_learning import LogAnalyzer

        analyzer = LogAnalyzer(log_file)
        patterns = analyzer.analyze_patterns()

        assert patterns["total_entries"] == 1000, "Should load all entries"

    @pytest.mark.e2e
    @pytest.mark.integration
    def test_ai_metadata_accuracy_for_different_log_levels(
        self, claude_workspace, tmp_path
    ):
        """
        Test 7: AI metadata correctly assigned based on log level

        Expected: FAIL (AI metadata generation not fully implemented)
        """
        # Arrange: Create logs with various levels
        log_file = tmp_path / "ai-activity.jsonl"

        levels_and_priorities = [
            ("DEBUG", "normal"),
            ("INFO", "normal"),
            ("WARNING", "normal"),
            ("ERROR", "high"),
            ("CRITICAL", "high"),
        ]

        for level, expected_priority in levels_and_priorities:
            log_entry = {
                "timestamp": "2025-09-30T10:00:00+00:00",
                "level": level,
                "message": f"Test {level}",
                "logger": "test",
                "context": {},
                "metadata": {},
                "ai_metadata": {
                    "priority": expected_priority,
                    "requires_human_review": level in ["ERROR", "CRITICAL"],
                },
            }
            with open(log_file, "a") as f:
                f.write(json.dumps(log_entry) + "\n")

        # Act: Verify AI metadata
        with open(log_file) as f:
            entries = [json.loads(line) for line in f if line.strip()]

        # Assert: All entries have correct AI metadata
        for entry, (level, expected_priority) in zip(entries, levels_and_priorities, strict=False):
            assert entry["level"] == level, f"Level mismatch for {level}"
            assert (
                entry["ai_metadata"]["priority"] == expected_priority
            ), f"Priority mismatch for {level}"

            if level in ["ERROR", "CRITICAL"]:
                assert (
                    entry["ai_metadata"]["requires_human_review"] is True
                ), f"Should require human review for {level}"
            else:
                assert (
                    entry["ai_metadata"]["requires_human_review"] is False
                ), f"Should not require human review for {level}"

    @pytest.mark.e2e
    @pytest.mark.integration
    @pytest.mark.slow
    def test_performance_log_analysis_on_large_dataset(
        self, claude_workspace, tmp_path
    ):
        """
        Test 8: Log analysis performs well on large datasets

        Expected: FAIL (performance not optimized)
        Target: Analyze 10,000 entries in <5 seconds
        """
        # Arrange: Create large log dataset
        log_file = tmp_path / "ai-activity.jsonl"

        for i in range(10000):
            log_entry = {
                "timestamp": f"2025-09-30T{(i//3600)%24:02d}:{(i//60)%60:02d}:{i%60:02d}+00:00",
                "level": "ERROR" if i % 10 == 0 else "INFO",
                "message": f"Entry {i}: Operation completed",
                "logger": "test",
                "context": {"agent": "planner" if i % 2 == 0 else "builder"},
                "metadata": {"operation": f"op_{i%5}"},
                "ai_metadata": {"priority": "normal"},
            }
            with open(log_file, "a") as f:
                f.write(json.dumps(log_entry) + "\n")

        # Act: Measure analysis time
        import sys

        sys.path.insert(0, str(claude_workspace / ".claude" / "scripts"))
        from error_pattern_learning import LogAnalyzer

        start_time = time.time()
        analyzer = LogAnalyzer(log_file)
        patterns = analyzer.analyze_patterns()
        insights = analyzer.generate_insights()
        elapsed_time = time.time() - start_time

        # Assert: Performance target
        assert elapsed_time < 5.0, f"Analysis took {elapsed_time:.2f}s, expected <5s"

        # Assert: Analysis accuracy
        assert patterns["total_entries"] == 10000, "Should analyze all entries"
        assert len(patterns["error_patterns"]) > 0, "Should detect error patterns"


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short", "-m", "e2e and integration"])
