#!/usr/bin/env python3
"""
Log Analysis Tool - Automated Analysis Script
Comprehensive log analysis with multiple output formats

Features:
- Multi-format report generation (JSON, HTML, Text)
- Time-series analysis (hourly, daily grouping)
- Statistical analysis (mean, median, percentiles)
- Error spike detection
- Comprehensive report generation

Version: 1.0.0
Python: 3.12+

Usage Example:
    Basic report generation:
        >>> from log_analysis_tool import ReportGenerator
        >>> from error_pattern_learning import LogAnalyzer
        >>> analyzer = LogAnalyzer(Path("~/.claude/ai-activity.jsonl"))
        >>> generator = ReportGenerator(analyzer)
        >>> report = generator.generate_full_report()

    Export to different formats:
        >>> from log_analysis_tool import AnalysisReport
        >>> report = AnalysisReport(analyzer)
        >>> report.export_json(Path("report.json"))
        >>> report.export_html(Path("report.html"))
        >>> report.export_text(Path("report.txt"))

    Time-series analysis:
        >>> from log_analysis_tool import TimeSeriesAnalyzer
        >>> ts_analyzer = TimeSeriesAnalyzer(analyzer)
        >>> hourly = ts_analyzer.group_by_hour()
        >>> daily = ts_analyzer.group_by_day()
        >>> spikes = ts_analyzer.detect_error_spikes(threshold=10)

    Statistical analysis:
        >>> from log_analysis_tool import StatisticsCalculator
        >>> calc = StatisticsCalculator()
        >>> mean = calc.mean([1, 2, 3, 4, 5])
        >>> median = calc.median([1, 2, 3, 4, 5])
        >>> p95 = calc.percentile([1, 2, 3, 4, 5], 95)
"""

import json
from pathlib import Path
from datetime import datetime
from collections import defaultdict
from typing import Dict, List, Any


class AnalysisReport:
    """
    Analysis report generator with multiple output formats.

    Generates comprehensive reports from log analysis results
    and exports them in JSON, HTML, or plain text formats.

    Features:
    - JSON export for programmatic consumption
    - HTML export with styled visualization
    - Plain text export for CLI viewing
    - Comprehensive summary statistics
    - AI-generated insights inclusion

    Example:
        >>> analyzer = LogAnalyzer(Path("logs.jsonl"))
        >>> report = AnalysisReport(analyzer)
        >>> report.export_json(Path("report.json"))
        >>> report.export_html(Path("report.html"))
        >>> summary = report.generate_summary()
    """

    def __init__(self, analyzer):
        """
        Initialize analysis report.

        Args:
            analyzer: LogAnalyzer instance with loaded log data
        """
        self.analyzer = analyzer
        self._cache = {}  # Cache for expensive computations

    def generate_summary(self) -> Dict[str, Any]:
        """
        Generate summary statistics with caching.

        Returns:
            Dictionary with total entries, errors, error rate, and agent info
        """
        # Check cache
        if "summary" in self._cache:
            return self._cache["summary"]

        patterns = self.analyzer.analyze_patterns()
        total_entries = patterns["total_entries"]

        # Count errors
        total_errors = sum(
            len(entries) for entries in patterns["error_patterns"].values()
        )

        error_rate = (total_errors / total_entries * 100) if total_entries > 0 else 0

        summary = {
            "total_entries": total_entries,
            "total_errors": total_errors,
            "error_rate": round(error_rate, 2),
            "agents": patterns["agent_activities"],
            "operations": patterns["operation_counts"],
        }

        # Cache result
        self._cache["summary"] = summary
        return summary

    def export_json(self, output_path: Path) -> None:
        """
        Export report to JSON file.

        Args:
            output_path: Path to output JSON file
        """
        patterns = self.analyzer.analyze_patterns()
        insights = self.analyzer.generate_insights()
        summary = self.generate_summary()

        report_data = {
            "summary": summary,
            "patterns": patterns,
            "insights": insights,
            "generated_at": datetime.now().isoformat(),
        }

        with output_path.open("w", encoding="utf-8") as f:
            json.dump(report_data, f, indent=2, ensure_ascii=False)

    def export_html(self, output_path: Path) -> None:
        """
        Export report to enhanced HTML file with styling.

        Args:
            output_path: Path to output HTML file
        """
        summary = self.generate_summary()
        insights = self.analyzer.generate_insights()
        error_categories = self.analyzer.categorize_errors()

        html = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Log Analysis Report</title>
    <style>
        body {{
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            background: #f5f5f5;
        }}
        .container {{ max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }}
        h1 {{ color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }}
        h2 {{ color: #34495e; margin-top: 30px; }}
        .summary {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }}
        .summary p {{ margin: 10px 0; }}
        .metric {{ display: inline-block; margin: 10px 20px 10px 0; }}
        .metric-value {{ font-size: 2em; font-weight: bold; }}
        .metric-label {{ font-size: 0.9em; opacity: 0.9; }}
        .insights {{ margin-top: 20px; }}
        .insight {{
            padding: 15px;
            margin: 10px 0;
            background: #fff3cd;
            border-left: 5px solid #ffc107;
            border-radius: 4px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }}
        .categories {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-top: 20px; }}
        .category {{ background: #ecf0f1; padding: 15px; border-radius: 8px; text-align: center; }}
        .category-count {{ font-size: 2em; font-weight: bold; color: #e74c3c; }}
        .category-name {{ font-size: 0.9em; color: #7f8c8d; margin-top: 5px; }}
        footer {{ margin-top: 40px; padding-top: 20px; border-top: 1px solid #ddd; color: #7f8c8d; font-size: 0.9em; text-align: center; }}
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 Log Analysis Report</h1>
        <div class="summary">
            <div class="metric">
                <div class="metric-value">{summary['total_entries']}</div>
                <div class="metric-label">Total Entries</div>
            </div>
            <div class="metric">
                <div class="metric-value">{summary['total_errors']}</div>
                <div class="metric-label">Total Errors</div>
            </div>
            <div class="metric">
                <div class="metric-value">{summary['error_rate']}%</div>
                <div class="metric-label">Error Rate</div>
            </div>
        </div>
"""

        # Error categories section
        if error_categories:
            html += (
                '        <h2>Error Categories</h2>\n        <div class="categories">\n'
            )
            for category, errors in error_categories.items():
                count = len(errors)
                html += f"""            <div class="category">
                <div class="category-count">{count}</div>
                <div class="category-name">{category.replace("_", " ").title()}</div>
            </div>\n"""
            html += "        </div>\n"

        # Insights section
        html += '        <h2>💡 Insights</h2>\n        <div class="insights">\n'
        if insights:
            for insight in insights:
                html += f'            <div class="insight">{insight}</div>\n'
        else:
            html += '            <div class="insight">✅ No critical issues detected</div>\n'

        html += f"""        </div>
        <footer>
            Generated by Log Analysis Tool • {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
        </footer>
    </div>
</body>
</html>"""

        with output_path.open("w", encoding="utf-8") as f:
            f.write(html)

    def export_text(self, output_path: Path) -> None:
        """
        Export report to plain text file.

        Args:
            output_path: Path to output text file
        """
        summary = self.generate_summary()
        insights = self.analyzer.generate_insights()

        lines = [
            "=" * 50,
            "Log Analysis Report",
            "=" * 50,
            "",
            "SUMMARY",
            "-" * 50,
            f"Total Entries: {summary['total_entries']}",
            f"Total Errors: {summary['total_errors']}",
            f"Error Rate: {summary['error_rate']}%",
            "",
            "INSIGHTS",
            "-" * 50,
        ]

        for insight in insights:
            lines.append(f"  • {insight}")

        lines.extend(
            [
                "",
                "=" * 50,
                f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            ]
        )

        with output_path.open("w", encoding="utf-8") as f:
            f.write("\n".join(lines))


class TimeSeriesAnalyzer:
    """
    Time-series analysis for log entries.

    Analyzes temporal patterns, groups entries by time periods,
    and detects anomalies like error spikes.

    Features:
    - Hourly grouping for fine-grained analysis
    - Daily grouping for trend analysis
    - Error spike detection with configurable threshold
    - Temporal pattern recognition

    Example:
        >>> ts_analyzer = TimeSeriesAnalyzer(analyzer)
        >>> hourly = ts_analyzer.group_by_hour()
        >>> spikes = ts_analyzer.detect_error_spikes(threshold=10)
        >>> for spike in spikes:
        ...     print(f"Alert: {spike}")
    """

    def __init__(self, analyzer):
        """
        Initialize time-series analyzer.

        Args:
            analyzer: LogAnalyzer instance with loaded log data
        """
        self.analyzer = analyzer
        self._hourly_cache = None
        self._daily_cache = None

    def group_by_hour(self) -> Dict[str, List[Dict[str, Any]]]:
        """
        Group log entries by hour with caching.

        Returns:
            Dictionary mapping hour strings to lists of entries
        """
        # Return cached result if available
        if self._hourly_cache is not None:
            return self._hourly_cache

        hourly = defaultdict(list)

        for entry in self.analyzer.entries:
            timestamp_str = entry.get("timestamp", "")
            if not timestamp_str:
                continue

            try:
                dt = datetime.fromisoformat(timestamp_str.replace("Z", "+00:00"))
                hour_key = dt.strftime("%Y-%m-%d %H:00")
                hourly[hour_key].append(entry)
            except (ValueError, AttributeError):
                continue

        self._hourly_cache = dict(hourly)
        return self._hourly_cache

    def group_by_day(self) -> Dict[str, List[Dict[str, Any]]]:
        """
        Group log entries by day with caching.

        Returns:
            Dictionary mapping date strings to lists of entries
        """
        # Return cached result if available
        if self._daily_cache is not None:
            return self._daily_cache

        daily = defaultdict(list)

        for entry in self.analyzer.entries:
            timestamp_str = entry.get("timestamp", "")
            if not timestamp_str:
                continue

            try:
                dt = datetime.fromisoformat(timestamp_str.replace("Z", "+00:00"))
                day_key = dt.strftime("%Y-%m-%d")
                daily[day_key].append(entry)
            except (ValueError, AttributeError):
                continue

        self._daily_cache = dict(daily)
        return self._daily_cache

    def detect_error_spikes(self, threshold: int = 5) -> List[str]:
        """
        Detect hours with error spikes.

        Args:
            threshold: Minimum error count to consider as spike

        Returns:
            List of hour strings with error spikes
        """
        hourly = self.group_by_hour()
        spikes = []

        for hour, entries in hourly.items():
            error_count = sum(
                1 for e in entries if e.get("level") in ["ERROR", "CRITICAL"]
            )

            if error_count >= threshold:
                spikes.append(f"{hour} ({error_count} errors)")

        return spikes


class StatisticsCalculator:
    """
    Statistical calculator for numerical analysis.

    Provides statistical functions for analyzing numerical
    data from logs (response times, counts, etc.).
    """

    def __init__(self):
        """Initialize statistics calculator."""
        pass

    def mean(self, values: List[float]) -> float:
        """
        Calculate arithmetic mean.

        Args:
            values: List of numerical values

        Returns:
            Mean value, or 0.0 if empty
        """
        if not values:
            return 0.0
        return sum(values) / len(values)

    def median(self, values: List[float]) -> float:
        """
        Calculate median.

        Args:
            values: List of numerical values

        Returns:
            Median value, or 0.0 if empty
        """
        if not values:
            return 0.0

        sorted_values = sorted(values)
        n = len(sorted_values)

        if n % 2 == 0:
            # Even number: average of two middle values
            return (sorted_values[n // 2 - 1] + sorted_values[n // 2]) / 2
        else:
            # Odd number: middle value
            return sorted_values[n // 2]

    def percentile(self, values: List[float], p: float) -> float:
        """
        Calculate percentile.

        Args:
            values: List of numerical values
            p: Percentile (0-100)

        Returns:
            Percentile value, or 0.0 if empty
        """
        if not values:
            return 0.0

        sorted_values = sorted(values)
        n = len(sorted_values)

        # Linear interpolation method
        k = (n - 1) * (p / 100)
        f = int(k)
        c = k - f

        if f + 1 < n:
            return sorted_values[f] + c * (sorted_values[f + 1] - sorted_values[f])
        else:
            return sorted_values[f]


class ReportGenerator:
    """
    Comprehensive report generator.

    Combines analysis from multiple sources to generate
    a complete, multi-faceted log analysis report.
    """

    def __init__(self, analyzer):
        """
        Initialize report generator.

        Args:
            analyzer: LogAnalyzer instance with loaded log data
        """
        self.analyzer = analyzer
        self.ts_analyzer = TimeSeriesAnalyzer(analyzer)
        self.stats_calc = StatisticsCalculator()

    def generate_full_report(self) -> Dict[str, Any]:
        """
        Generate comprehensive analysis report.

        Returns:
            Dictionary with summary, time-series, statistics, insights, and categorization
        """
        # Get basic analysis
        patterns = self.analyzer.analyze_patterns()
        insights = self.analyzer.generate_insights()
        error_categories = self.analyzer.categorize_errors()

        # Time-series analysis
        hourly = self.ts_analyzer.group_by_hour()
        daily = self.ts_analyzer.group_by_day()
        spikes = self.ts_analyzer.detect_error_spikes()

        # Calculate statistics
        hourly_counts = [len(entries) for entries in hourly.values()]
        stats = {}
        if hourly_counts:
            stats = {
                "hourly_mean": round(self.stats_calc.mean(hourly_counts), 2),
                "hourly_median": round(self.stats_calc.median(hourly_counts), 2),
                "hourly_p95": round(self.stats_calc.percentile(hourly_counts, 95), 2),
            }

        return {
            "summary": {
                "total_entries": patterns["total_entries"],
                "total_errors": sum(
                    len(v) for v in patterns["error_patterns"].values()
                ),
                "operation_counts": patterns["operation_counts"],
                "agent_activities": patterns["agent_activities"],
            },
            "time_series": {
                "hourly_count": len(hourly),
                "daily_count": len(daily),
                "error_spikes": spikes,
            },
            "statistics": stats,
            "insights": insights,
            "error_categories": {k: len(v) for k, v in error_categories.items()},
        }


def main():
    """Main entry point for command-line usage."""
    import sys
    from pathlib import Path
    from error_pattern_learning import LogAnalyzer

    log_file = Path.home() / ".claude" / "ai-activity.jsonl"

    if not log_file.exists():
        print(f"Log file not found: {log_file}")
        sys.exit(1)

    # Perform analysis
    analyzer = LogAnalyzer(log_file)
    generator = ReportGenerator(analyzer)
    report = generator.generate_full_report()

    # Print report
    print("\n" + "=" * 60)
    print("LOG ANALYSIS REPORT")
    print("=" * 60)

    print("\nSUMMARY:")
    print(f"  Total Entries: {report['summary']['total_entries']}")
    print(f"  Total Errors: {report['summary']['total_errors']}")

    print("\nTIME SERIES:")
    print(f"  Hours with activity: {report['time_series']['hourly_count']}")
    print(f"  Days with activity: {report['time_series']['daily_count']}")

    if report["time_series"]["error_spikes"]:
        print("\n  Error spikes detected:")
        for spike in report["time_series"]["error_spikes"]:
            print(f"    • {spike}")

    if report["statistics"]:
        print("\nSTATISTICS (entries per hour):")
        print(f"  Mean: {report['statistics']['hourly_mean']}")
        print(f"  Median: {report['statistics']['hourly_median']}")
        print(f"  P95: {report['statistics']['hourly_p95']}")

    if report["insights"]:
        print("\nINSIGHTS:")
        for insight in report["insights"]:
            print(f"  {insight}")

    # Export options
    if "--json" in sys.argv:
        output_path = Path("log-analysis-report.json")
        report_obj = AnalysisReport(analyzer)
        report_obj.export_json(output_path)
        print(f"\nJSON report exported to: {output_path}")

    if "--html" in sys.argv:
        output_path = Path("log-analysis-report.html")
        report_obj = AnalysisReport(analyzer)
        report_obj.export_html(output_path)
        print(f"\nHTML report exported to: {output_path}")

    if "--text" in sys.argv:
        output_path = Path("log-analysis-report.txt")
        report_obj = AnalysisReport(analyzer)
        report_obj.export_text(output_path)
        print(f"\nText report exported to: {output_path}")


if __name__ == "__main__":
    main()
