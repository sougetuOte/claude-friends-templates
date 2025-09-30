#!/usr/bin/env python3
"""
Test for Error Pattern Learning System
Following t-wada style TDD: Red Phase - Writing failing tests first

Test Coverage:
- Log file loading and JSONL parsing
- Error pattern detection and classification
- Frequency analysis for repeated patterns
- Insight generation (high error rates, repeated patterns, agent balance)
- Time-based pattern analysis
- Edge cases (empty logs, corrupted entries, missing files)
"""

import sys
import json
import tempfile
from pathlib import Path
import pytest

# Add .claude directory to Python path
claude_dir = Path(__file__).parent.parent.parent
sys.path.insert(0, str(claude_dir))


class TestErrorPatternLearning:
    """Test suite for error pattern learning system."""

    def test_log_analyzer_initialization(self):
        """Test that LogAnalyzer can be initialized."""
        from scripts.error_pattern_learning import LogAnalyzer

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "test.jsonl"
            log_path.touch()

            analyzer = LogAnalyzer(log_path)

            assert analyzer is not None
            assert analyzer.log_file == log_path
            assert isinstance(analyzer.entries, list)

    def test_log_analyzer_loads_jsonl_entries(self):
        """Test that LogAnalyzer loads JSONL log entries."""
        from scripts.error_pattern_learning import LogAnalyzer

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "test.jsonl"

            # Create sample log entries
            entries = [
                {
                    "timestamp": "2025-09-30T10:00:00+00:00",
                    "level": "INFO",
                    "message": "Test message 1",
                    "logger": "test",
                    "context": {},
                    "metadata": {},
                },
                {
                    "timestamp": "2025-09-30T10:01:00+00:00",
                    "level": "ERROR",
                    "message": "Test error",
                    "logger": "test",
                    "context": {},
                    "metadata": {},
                },
            ]

            with log_path.open("w") as f:
                for entry in entries:
                    f.write(json.dumps(entry) + "\n")

            analyzer = LogAnalyzer(log_path)

            assert len(analyzer.entries) == 2
            assert analyzer.entries[0]["level"] == "INFO"
            assert analyzer.entries[1]["level"] == "ERROR"

    def test_log_analyzer_handles_missing_file(self):
        """Test that LogAnalyzer handles missing log file gracefully."""
        from scripts.error_pattern_learning import LogAnalyzer

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "nonexistent.jsonl"

            analyzer = LogAnalyzer(log_path)

            assert len(analyzer.entries) == 0

    def test_log_analyzer_skips_corrupted_entries(self):
        """Test that LogAnalyzer skips corrupted JSONL entries."""
        from scripts.error_pattern_learning import LogAnalyzer

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "test.jsonl"

            with log_path.open("w") as f:
                f.write('{"level": "INFO", "message": "Valid entry"}\n')
                f.write("CORRUPTED LINE\n")
                f.write('{"level": "ERROR", "message": "Another valid entry"}\n')

            analyzer = LogAnalyzer(log_path)

            # Should load only valid entries
            assert len(analyzer.entries) == 2
            assert analyzer.entries[0]["message"] == "Valid entry"
            assert analyzer.entries[1]["message"] == "Another valid entry"

    def test_analyze_patterns_detects_errors(self):
        """Test that analyze_patterns() detects error patterns."""
        from scripts.error_pattern_learning import LogAnalyzer

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "test.jsonl"

            entries = [
                {
                    "level": "INFO",
                    "message": "Normal operation",
                    "context": {},
                    "metadata": {},
                },
                {
                    "level": "ERROR",
                    "message": "Connection failed",
                    "context": {},
                    "metadata": {},
                },
                {
                    "level": "ERROR",
                    "message": "Connection failed",
                    "context": {},
                    "metadata": {},
                },
                {
                    "level": "CRITICAL",
                    "message": "System crash",
                    "context": {},
                    "metadata": {},
                },
            ]

            with log_path.open("w") as f:
                for entry in entries:
                    f.write(json.dumps(entry) + "\n")

            analyzer = LogAnalyzer(log_path)
            patterns = analyzer.analyze_patterns()

            assert "error_patterns" in patterns
            assert "Connection failed" in patterns["error_patterns"]
            assert len(patterns["error_patterns"]["Connection failed"]) == 2
            assert "System crash" in patterns["error_patterns"]

    def test_analyze_patterns_counts_operations(self):
        """Test that analyze_patterns() counts operation types."""
        from scripts.error_pattern_learning import LogAnalyzer

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "test.jsonl"

            entries = [
                {
                    "level": "INFO",
                    "message": "Msg1",
                    "context": {},
                    "metadata": {"operation": "read"},
                },
                {
                    "level": "INFO",
                    "message": "Msg2",
                    "context": {},
                    "metadata": {"operation": "write"},
                },
                {
                    "level": "INFO",
                    "message": "Msg3",
                    "context": {},
                    "metadata": {"operation": "read"},
                },
            ]

            with log_path.open("w") as f:
                for entry in entries:
                    f.write(json.dumps(entry) + "\n")

            analyzer = LogAnalyzer(log_path)
            patterns = analyzer.analyze_patterns()

            assert "operation_counts" in patterns
            assert patterns["operation_counts"]["read"] == 2
            assert patterns["operation_counts"]["write"] == 1

    def test_analyze_patterns_tracks_agent_activities(self):
        """Test that analyze_patterns() tracks agent activities."""
        from scripts.error_pattern_learning import LogAnalyzer

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "test.jsonl"

            entries = [
                {
                    "level": "INFO",
                    "message": "Msg1",
                    "context": {"agent": "planner"},
                    "metadata": {},
                },
                {
                    "level": "INFO",
                    "message": "Msg2",
                    "context": {"agent": "builder"},
                    "metadata": {},
                },
                {
                    "level": "INFO",
                    "message": "Msg3",
                    "context": {"agent": "planner"},
                    "metadata": {},
                },
            ]

            with log_path.open("w") as f:
                for entry in entries:
                    f.write(json.dumps(entry) + "\n")

            analyzer = LogAnalyzer(log_path)
            patterns = analyzer.analyze_patterns()

            assert "agent_activities" in patterns
            assert patterns["agent_activities"]["planner"] == 2
            assert patterns["agent_activities"]["builder"] == 1

    def test_generate_insights_detects_high_error_rate(self):
        """Test that generate_insights() detects high error rates (>10%)."""
        from scripts.error_pattern_learning import LogAnalyzer

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "test.jsonl"

            # Create 10 entries: 2 errors = 20% error rate (> 10%)
            entries = []
            for i in range(8):
                entries.append(
                    {
                        "level": "INFO",
                        "message": f"Info {i}",
                        "context": {},
                        "metadata": {},
                    }
                )
            for i in range(2):
                entries.append(
                    {
                        "level": "ERROR",
                        "message": f"Error {i}",
                        "context": {},
                        "metadata": {},
                    }
                )

            with log_path.open("w") as f:
                for entry in entries:
                    f.write(json.dumps(entry) + "\n")

            analyzer = LogAnalyzer(log_path)
            insights = analyzer.generate_insights()

            # Should detect high error rate
            assert any("High error rate" in insight for insight in insights)

    def test_generate_insights_detects_repeated_patterns(self):
        """Test that generate_insights() detects repeated error patterns (≥3 times)."""
        from scripts.error_pattern_learning import LogAnalyzer

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "test.jsonl"

            # Create same error 3 times
            entries = [
                {
                    "level": "ERROR",
                    "message": "Timeout error",
                    "context": {},
                    "metadata": {},
                },
                {
                    "level": "ERROR",
                    "message": "Timeout error",
                    "context": {},
                    "metadata": {},
                },
                {
                    "level": "ERROR",
                    "message": "Timeout error",
                    "context": {},
                    "metadata": {},
                },
            ]

            with log_path.open("w") as f:
                for entry in entries:
                    f.write(json.dumps(entry) + "\n")

            analyzer = LogAnalyzer(log_path)
            insights = analyzer.generate_insights()

            # Should detect repeated pattern
            assert any(
                "Repeated error pattern" in insight and "Timeout error" in insight
                for insight in insights
            )

    def test_generate_insights_detects_agent_imbalance(self):
        """Test that generate_insights() detects agent work imbalance."""
        from scripts.error_pattern_learning import LogAnalyzer

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "test.jsonl"

            # Create 10 planner entries, 2 builder entries (5:1 ratio > 2:1 threshold)
            entries = []
            for i in range(10):
                entries.append(
                    {
                        "level": "INFO",
                        "message": f"Plan {i}",
                        "context": {"agent": "planner"},
                        "metadata": {},
                    }
                )
            for i in range(2):
                entries.append(
                    {
                        "level": "INFO",
                        "message": f"Build {i}",
                        "context": {"agent": "builder"},
                        "metadata": {},
                    }
                )

            with log_path.open("w") as f:
                for entry in entries:
                    f.write(json.dumps(entry) + "\n")

            analyzer = LogAnalyzer(log_path)
            insights = analyzer.generate_insights()

            # Should detect planner/builder imbalance
            assert any(
                "Planner is significantly more active" in insight
                for insight in insights
            )

    def test_error_pattern_classifier_initialization(self):
        """Test that ErrorPatternClassifier can be initialized."""
        from scripts.error_pattern_learning import ErrorPatternClassifier

        classifier = ErrorPatternClassifier()

        assert classifier is not None
        assert hasattr(classifier, "classify")

    def test_error_pattern_classifier_categorizes_errors(self):
        """Test that ErrorPatternClassifier categorizes error types."""
        from scripts.error_pattern_learning import ErrorPatternClassifier

        classifier = ErrorPatternClassifier()

        # Test different error types
        assert classifier.classify("Connection timeout") == "network"
        assert classifier.classify("File not found") == "filesystem"
        assert classifier.classify("Permission denied") == "permission"
        assert classifier.classify("Invalid JSON format") == "data_format"
        assert classifier.classify("Unknown error type") == "unknown"

    def test_error_pattern_classifier_handles_case_insensitive(self):
        """Test that ErrorPatternClassifier is case-insensitive."""
        from scripts.error_pattern_learning import ErrorPatternClassifier

        classifier = ErrorPatternClassifier()

        assert classifier.classify("CONNECTION TIMEOUT") == "network"
        assert classifier.classify("file Not Found") == "filesystem"

    def test_pattern_frequency_analyzer_initialization(self):
        """Test that PatternFrequencyAnalyzer can be initialized."""
        from scripts.error_pattern_learning import PatternFrequencyAnalyzer

        analyzer = PatternFrequencyAnalyzer()

        assert analyzer is not None
        assert hasattr(analyzer, "add_pattern")
        assert hasattr(analyzer, "get_frequent_patterns")

    def test_pattern_frequency_analyzer_tracks_frequencies(self):
        """Test that PatternFrequencyAnalyzer tracks pattern frequencies."""
        from scripts.error_pattern_learning import PatternFrequencyAnalyzer

        analyzer = PatternFrequencyAnalyzer()

        # Add same pattern multiple times
        analyzer.add_pattern("Connection failed")
        analyzer.add_pattern("Connection failed")
        analyzer.add_pattern("Timeout")

        frequencies = analyzer.get_frequent_patterns(min_count=2)

        assert "Connection failed" in frequencies
        assert frequencies["Connection failed"] == 2
        assert "Timeout" not in frequencies  # Below threshold

    def test_pattern_frequency_analyzer_filters_by_threshold(self):
        """Test that PatternFrequencyAnalyzer filters by minimum count."""
        from scripts.error_pattern_learning import PatternFrequencyAnalyzer

        analyzer = PatternFrequencyAnalyzer()

        for i in range(5):
            analyzer.add_pattern("Frequent error")
        for i in range(2):
            analyzer.add_pattern("Rare error")

        # Get patterns with min_count=3
        frequencies = analyzer.get_frequent_patterns(min_count=3)

        assert len(frequencies) == 1
        assert "Frequent error" in frequencies
        assert "Rare error" not in frequencies

    def test_log_analyzer_returns_total_entry_count(self):
        """Test that analyze_patterns() returns total entry count."""
        from scripts.error_pattern_learning import LogAnalyzer

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "test.jsonl"

            entries = [
                {
                    "level": "INFO",
                    "message": f"Message {i}",
                    "context": {},
                    "metadata": {},
                }
                for i in range(10)
            ]

            with log_path.open("w") as f:
                for entry in entries:
                    f.write(json.dumps(entry) + "\n")

            analyzer = LogAnalyzer(log_path)
            patterns = analyzer.analyze_patterns()

            assert patterns["total_entries"] == 10

    def test_log_analyzer_handles_empty_context_and_metadata(self):
        """Test that LogAnalyzer handles entries with missing context/metadata."""
        from scripts.error_pattern_learning import LogAnalyzer

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "test.jsonl"

            # Entry without context or metadata keys
            entries = [{"level": "ERROR", "message": "Error without context"}]

            with log_path.open("w") as f:
                for entry in entries:
                    f.write(json.dumps(entry) + "\n")

            analyzer = LogAnalyzer(log_path)
            patterns = analyzer.analyze_patterns()

            # Should not crash, should handle gracefully
            assert patterns["total_entries"] == 1
            assert "Error without context" in patterns["error_patterns"]


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
