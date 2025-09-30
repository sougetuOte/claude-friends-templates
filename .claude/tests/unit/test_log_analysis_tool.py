#!/usr/bin/env python3
"""
Test for Log Analysis Tool (Automated Analysis Script)
Following t-wada style TDD: Red Phase - Writing failing tests first

Test Coverage:
- AnalysisReport generation (JSON, HTML, text formats)
- Time-series analysis (hourly, daily trends)
- Statistical summaries (mean, median, percentiles)
- Report file generation and validation
- Multiple output formats
- Trend detection algorithms
- Command-line interface
"""

import sys
import json
import tempfile
from pathlib import Path
import pytest

# Add .claude directory to Python path
claude_dir = Path(__file__).parent.parent.parent
sys.path.insert(0, str(claude_dir))


class TestLogAnalysisTool:
    """Test suite for automated log analysis tool."""

    def test_analysis_report_initialization(self):
        """Test that AnalysisReport can be initialized."""
        from scripts.log_analysis_tool import AnalysisReport
        from scripts.error_pattern_learning import LogAnalyzer

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "test.jsonl"
            log_path.touch()

            analyzer = LogAnalyzer(log_path)
            report = AnalysisReport(analyzer)

            assert report is not None
            assert report.analyzer == analyzer

    def test_analysis_report_generates_summary(self):
        """Test that AnalysisReport generates a summary dict."""
        from scripts.log_analysis_tool import AnalysisReport
        from scripts.error_pattern_learning import LogAnalyzer

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "test.jsonl"

            # Create sample log entries
            entries = [
                {
                    "timestamp": "2025-09-30T10:00:00+00:00",
                    "level": "INFO",
                    "message": "Test message",
                    "context": {"agent": "builder"},
                    "metadata": {},
                },
                {
                    "timestamp": "2025-09-30T11:00:00+00:00",
                    "level": "ERROR",
                    "message": "Test error",
                    "context": {"agent": "planner"},
                    "metadata": {},
                },
            ]

            with log_path.open("w") as f:
                for entry in entries:
                    f.write(json.dumps(entry) + "\n")

            analyzer = LogAnalyzer(log_path)
            report = AnalysisReport(analyzer)
            summary = report.generate_summary()

            assert "total_entries" in summary
            assert "total_errors" in summary
            assert "error_rate" in summary
            assert summary["total_entries"] == 2
            assert summary["total_errors"] == 1

    def test_analysis_report_exports_to_json(self):
        """Test that AnalysisReport can export to JSON file."""
        from scripts.log_analysis_tool import AnalysisReport
        from scripts.error_pattern_learning import LogAnalyzer

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "test.jsonl"
            log_path.touch()

            analyzer = LogAnalyzer(log_path)
            report = AnalysisReport(analyzer)

            output_path = Path(tmpdir) / "report.json"
            report.export_json(output_path)

            assert output_path.exists()

            # Verify valid JSON
            with output_path.open("r") as f:
                data = json.load(f)
                assert "summary" in data
                assert "patterns" in data
                assert "insights" in data

    def test_analysis_report_exports_to_html(self):
        """Test that AnalysisReport can export to HTML file."""
        from scripts.log_analysis_tool import AnalysisReport
        from scripts.error_pattern_learning import LogAnalyzer

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "test.jsonl"
            log_path.touch()

            analyzer = LogAnalyzer(log_path)
            report = AnalysisReport(analyzer)

            output_path = Path(tmpdir) / "report.html"
            report.export_html(output_path)

            assert output_path.exists()

            # Verify HTML structure
            with output_path.open("r") as f:
                html = f.read()
                assert "<html>" in html
                assert "<head>" in html
                assert "<body>" in html
                assert "Log Analysis Report" in html

    def test_analysis_report_exports_to_text(self):
        """Test that AnalysisReport can export to plain text file."""
        from scripts.log_analysis_tool import AnalysisReport
        from scripts.error_pattern_learning import LogAnalyzer

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "test.jsonl"
            log_path.touch()

            analyzer = LogAnalyzer(log_path)
            report = AnalysisReport(analyzer)

            output_path = Path(tmpdir) / "report.txt"
            report.export_text(output_path)

            assert output_path.exists()

            # Verify text content
            with output_path.open("r") as f:
                text = f.read()
                assert "Log Analysis Report" in text
                assert "Total Entries:" in text

    def test_time_series_analyzer_initialization(self):
        """Test that TimeSeriesAnalyzer can be initialized."""
        from scripts.log_analysis_tool import TimeSeriesAnalyzer
        from scripts.error_pattern_learning import LogAnalyzer

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "test.jsonl"
            log_path.touch()

            analyzer = LogAnalyzer(log_path)
            ts_analyzer = TimeSeriesAnalyzer(analyzer)

            assert ts_analyzer is not None
            assert ts_analyzer.analyzer == analyzer

    def test_time_series_analyzer_groups_by_hour(self):
        """Test that TimeSeriesAnalyzer groups entries by hour."""
        from scripts.log_analysis_tool import TimeSeriesAnalyzer
        from scripts.error_pattern_learning import LogAnalyzer

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "test.jsonl"

            # Create entries across different hours
            entries = [
                {
                    "timestamp": "2025-09-30T10:00:00+00:00",
                    "level": "INFO",
                    "message": "Msg1",
                    "context": {},
                    "metadata": {},
                },
                {
                    "timestamp": "2025-09-30T10:30:00+00:00",
                    "level": "ERROR",
                    "message": "Err1",
                    "context": {},
                    "metadata": {},
                },
                {
                    "timestamp": "2025-09-30T11:00:00+00:00",
                    "level": "INFO",
                    "message": "Msg2",
                    "context": {},
                    "metadata": {},
                },
            ]

            with log_path.open("w") as f:
                for entry in entries:
                    f.write(json.dumps(entry) + "\n")

            analyzer = LogAnalyzer(log_path)
            ts_analyzer = TimeSeriesAnalyzer(analyzer)
            hourly = ts_analyzer.group_by_hour()

            # Should have 2 hours: 10:00 and 11:00
            assert len(hourly) == 2
            assert "2025-09-30 10:00" in hourly
            assert "2025-09-30 11:00" in hourly
            assert len(hourly["2025-09-30 10:00"]) == 2
            assert len(hourly["2025-09-30 11:00"]) == 1

    def test_time_series_analyzer_groups_by_day(self):
        """Test that TimeSeriesAnalyzer groups entries by day."""
        from scripts.log_analysis_tool import TimeSeriesAnalyzer
        from scripts.error_pattern_learning import LogAnalyzer

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "test.jsonl"

            # Create entries across different days
            entries = [
                {
                    "timestamp": "2025-09-30T10:00:00+00:00",
                    "level": "INFO",
                    "message": "Msg1",
                    "context": {},
                    "metadata": {},
                },
                {
                    "timestamp": "2025-10-01T10:00:00+00:00",
                    "level": "INFO",
                    "message": "Msg2",
                    "context": {},
                    "metadata": {},
                },
            ]

            with log_path.open("w") as f:
                for entry in entries:
                    f.write(json.dumps(entry) + "\n")

            analyzer = LogAnalyzer(log_path)
            ts_analyzer = TimeSeriesAnalyzer(analyzer)
            daily = ts_analyzer.group_by_day()

            # Should have 2 days
            assert len(daily) == 2
            assert "2025-09-30" in daily
            assert "2025-10-01" in daily

    def test_time_series_analyzer_detects_error_spike(self):
        """Test that TimeSeriesAnalyzer detects error spikes."""
        from scripts.log_analysis_tool import TimeSeriesAnalyzer
        from scripts.error_pattern_learning import LogAnalyzer

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "test.jsonl"

            # Create normal traffic with one spike hour
            entries = []

            # Hour 1: 1 error (normal)
            entries.append(
                {
                    "timestamp": "2025-09-30T10:00:00+00:00",
                    "level": "ERROR",
                    "message": "Err",
                    "context": {},
                    "metadata": {},
                }
            )

            # Hour 2: 10 errors (spike)
            for i in range(10):
                entries.append(
                    {
                        "timestamp": f"2025-09-30T11:{i:02d}:00+00:00",
                        "level": "ERROR",
                        "message": f"Err{i}",
                        "context": {},
                        "metadata": {},
                    }
                )

            with log_path.open("w") as f:
                for entry in entries:
                    f.write(json.dumps(entry) + "\n")

            analyzer = LogAnalyzer(log_path)
            ts_analyzer = TimeSeriesAnalyzer(analyzer)
            spikes = ts_analyzer.detect_error_spikes(threshold=5)

            # Should detect hour 11 as spike
            assert len(spikes) > 0
            assert any("11:00" in spike for spike in spikes)

    def test_statistics_calculator_initialization(self):
        """Test that StatisticsCalculator can be initialized."""
        from scripts.log_analysis_tool import StatisticsCalculator

        calc = StatisticsCalculator()

        assert calc is not None

    def test_statistics_calculator_computes_mean(self):
        """Test that StatisticsCalculator computes mean."""
        from scripts.log_analysis_tool import StatisticsCalculator

        calc = StatisticsCalculator()
        values = [1, 2, 3, 4, 5]
        mean = calc.mean(values)

        assert mean == 3.0

    def test_statistics_calculator_computes_median(self):
        """Test that StatisticsCalculator computes median."""
        from scripts.log_analysis_tool import StatisticsCalculator

        calc = StatisticsCalculator()

        # Odd number of values
        values_odd = [1, 2, 3, 4, 5]
        median_odd = calc.median(values_odd)
        assert median_odd == 3.0

        # Even number of values
        values_even = [1, 2, 3, 4]
        median_even = calc.median(values_even)
        assert median_even == 2.5

    def test_statistics_calculator_computes_percentile(self):
        """Test that StatisticsCalculator computes percentiles."""
        from scripts.log_analysis_tool import StatisticsCalculator

        calc = StatisticsCalculator()
        values = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

        p50 = calc.percentile(values, 50)
        p95 = calc.percentile(values, 95)
        p99 = calc.percentile(values, 99)

        assert p50 == 5.5  # Median
        assert p95 >= 9.0  # Near max
        assert p99 >= 9.5  # Near max

    def test_statistics_calculator_handles_empty_list(self):
        """Test that StatisticsCalculator handles empty lists gracefully."""
        from scripts.log_analysis_tool import StatisticsCalculator

        calc = StatisticsCalculator()

        assert calc.mean([]) == 0.0
        assert calc.median([]) == 0.0
        assert calc.percentile([], 50) == 0.0

    def test_report_generator_creates_full_report(self):
        """Test that ReportGenerator creates a comprehensive report."""
        from scripts.log_analysis_tool import ReportGenerator
        from scripts.error_pattern_learning import LogAnalyzer

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "test.jsonl"

            # Create sample entries
            entries = [
                {
                    "timestamp": "2025-09-30T10:00:00+00:00",
                    "level": "INFO",
                    "message": "Info msg",
                    "context": {"agent": "builder"},
                    "metadata": {"operation": "read"},
                },
                {
                    "timestamp": "2025-09-30T10:30:00+00:00",
                    "level": "ERROR",
                    "message": "Error msg",
                    "context": {"agent": "planner"},
                    "metadata": {"operation": "write"},
                },
            ]

            with log_path.open("w") as f:
                for entry in entries:
                    f.write(json.dumps(entry) + "\n")

            analyzer = LogAnalyzer(log_path)
            generator = ReportGenerator(analyzer)
            report = generator.generate_full_report()

            assert "summary" in report
            assert "time_series" in report
            assert "statistics" in report
            assert "insights" in report
            assert "error_categories" in report


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
