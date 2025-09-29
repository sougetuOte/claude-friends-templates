#!/usr/bin/env python3
"""
AI Log Analyzer V2 - Vibe Logger準拠版
Analyzes AI-friendly activity logs and provides insights for debugging
"""

import json
import sys
from collections import defaultdict, Counter
from pathlib import Path
import argparse


class AILogAnalyzer:
    def __init__(self, log_file):
        self.log_file = Path(log_file)
        self.logs = []
        self.errors = []

    def load_logs(self):
        """Load logs from JSONL file with robust error handling"""
        if not self.log_file.exists():
            print(f"Error: Log file not found: {self.log_file}")
            return False

        with open(self.log_file, "r", encoding="utf-8") as f:
            for line_num, line in enumerate(f, 1):
                line = line.strip()
                if not line:
                    continue

                try:
                    log_entry = json.loads(line)
                    self.logs.append(log_entry)
                except json.JSONDecodeError as e:
                    self.errors.append(f"Line {line_num}: {e}")

        return True

    def analyze(self):
        """Perform comprehensive analysis of logs"""
        if not self.logs:
            return None

        analysis = {
            "summary": self._get_summary(),
            "errors": self._analyze_errors(),
            "patterns": self._find_patterns(),
            "ai_insights": self._generate_ai_insights(),
            "debug_hints": self._collect_debug_hints(),
        }

        return analysis

    def _get_summary(self):
        """Generate summary statistics"""
        total_logs = len(self.logs)

        # Count by level
        level_counts = Counter(log.get("level", "UNKNOWN") for log in self.logs)

        # Count by operation
        operation_counts = Counter(log.get("operation", "unknown") for log in self.logs)

        # Time range
        timestamps = [
            log.get("timestamp", "") for log in self.logs if log.get("timestamp")
        ]
        if timestamps:
            start_time = min(timestamps)
            end_time = max(timestamps)
        else:
            start_time = end_time = "N/A"

        return {
            "total_operations": total_logs,
            "parse_errors": len(self.errors),
            "level_breakdown": dict(level_counts),
            "operation_breakdown": dict(operation_counts),
            "time_range": {"start": start_time, "end": end_time},
        }

    def _analyze_errors(self):
        """Analyze error patterns"""
        error_logs = [log for log in self.logs if log.get("level") == "ERROR"]

        if not error_logs:
            return {"count": 0, "patterns": []}

        # Group errors by operation
        errors_by_operation = defaultdict(list)
        for log in error_logs:
            operation = log.get("operation", "unknown")
            errors_by_operation[operation].append(log)

        # Extract patterns
        patterns = []
        for operation, logs in errors_by_operation.items():
            pattern = {
                "operation": operation,
                "count": len(logs),
                "messages": [
                    log.get("message", "") for log in logs[:3]
                ],  # First 3 examples
                "ai_todos": [
                    log.get("ai_todo", "") for log in logs if log.get("ai_todo")
                ],
            }
            patterns.append(pattern)

        return {
            "count": len(error_logs),
            "patterns": sorted(patterns, key=lambda x: x["count"], reverse=True),
        }

    def _find_patterns(self):
        """Find activity patterns"""
        # Most frequent operations
        operations = [log.get("operation", "unknown") for log in self.logs]
        operation_freq = Counter(operations).most_common(5)

        # File activity
        file_activity = defaultdict(int)
        for log in self.logs:
            context = log.get("context", {})
            if isinstance(context, dict):
                files = context.get("files", {})
                if isinstance(files, dict) and "primary_file" in files:
                    file_activity[files["primary_file"]] += 1

        # Command patterns (for executeCommand operations)
        commands = []
        for log in self.logs:
            if log.get("operation") == "executeCommand":
                context = log.get("context", {})
                if isinstance(context, dict) and "command" in context:
                    commands.append(context["command"])

        command_freq = Counter(commands).most_common(5)

        return {
            "frequent_operations": operation_freq,
            "file_activity": dict(
                sorted(file_activity.items(), key=lambda x: x[1], reverse=True)[:10]
            ),
            "common_commands": command_freq,
        }

    def _generate_ai_insights(self):
        """Generate AI-friendly insights"""
        insights = []

        # High error rate operations
        operation_errors = defaultdict(lambda: {"total": 0, "errors": 0})
        for log in self.logs:
            operation = log.get("operation", "unknown")
            operation_errors[operation]["total"] += 1
            if log.get("level") == "ERROR":
                operation_errors[operation]["errors"] += 1

        for operation, stats in operation_errors.items():
            if stats["total"] > 5 and stats["errors"] / stats["total"] > 0.3:
                error_rate = (stats["errors"] / stats["total"]) * 100
                insights.append(
                    {
                        "type": "high_error_rate",
                        "operation": operation,
                        "message": f"Operation '{operation}' has {error_rate:.1f}% error rate",
                        "recommendation": "Investigate common failure patterns and add error handling",
                    }
                )

        # Repeated operations
        operation_sequences = []
        for i in range(len(self.logs) - 1):
            if self.logs[i].get("operation") == self.logs[i + 1].get("operation"):
                operation_sequences.append(self.logs[i].get("operation"))

        repeated_ops = Counter(operation_sequences)
        for op, count in repeated_ops.most_common(3):
            if count > 5:
                insights.append(
                    {
                        "type": "repeated_operation",
                        "operation": op,
                        "message": f"Operation '{op}' is frequently repeated ({count} times)",
                        "recommendation": "Consider batching or optimizing repeated operations",
                    }
                )

        return insights

    def _collect_debug_hints(self):
        """Collect human notes and AI todos for debugging"""
        debug_hints = {"human_notes": [], "ai_todos": [], "error_contexts": []}

        for log in self.logs:
            if log.get("human_note"):
                debug_hints["human_notes"].append(
                    {
                        "timestamp": log.get("timestamp"),
                        "operation": log.get("operation"),
                        "note": log.get("human_note"),
                    }
                )

            if log.get("ai_todo"):
                debug_hints["ai_todos"].append(
                    {
                        "timestamp": log.get("timestamp"),
                        "operation": log.get("operation"),
                        "todo": log.get("ai_todo"),
                    }
                )

            if log.get("level") == "ERROR":
                context = log.get("context", {})
                if isinstance(context, dict) and "error_output" in context:
                    debug_hints["error_contexts"].append(
                        {
                            "timestamp": log.get("timestamp"),
                            "operation": log.get("operation"),
                            "error": context.get("error_output", "")[
                                :200
                            ],  # First 200 chars
                        }
                    )

        return debug_hints

    def format_report(self, analysis, format_type="summary"):
        """Format analysis report for output"""
        if format_type == "json":
            return json.dumps(analysis, indent=2, ensure_ascii=False)

        elif format_type == "summary":
            lines = ["=== AI Log Analysis Report (V2) ===\n"]

            # Summary section
            summary = analysis["summary"]
            lines.append("📊 Summary:")
            lines.append(f"  Total operations: {summary['total_operations']}")
            lines.append(f"  Parse errors: {summary['parse_errors']}")
            lines.append(
                f"  Time range: {summary['time_range']['start']} to {summary['time_range']['end']}"
            )
            lines.append("\n  Level breakdown:")
            for level, count in summary["level_breakdown"].items():
                lines.append(f"    {level}: {count}")

            # Error analysis
            errors = analysis["errors"]
            lines.append("\n❌ Error Analysis:")
            lines.append(f"  Total errors: {errors['count']}")
            if errors["patterns"]:
                lines.append("  Error patterns:")
                for pattern in errors["patterns"][:3]:
                    lines.append(
                        f"    - {pattern['operation']}: {pattern['count']} errors"
                    )

            # Patterns
            patterns = analysis["patterns"]
            lines.append("\n🔍 Activity Patterns:")
            lines.append("  Most frequent operations:")
            for op, count in patterns["frequent_operations"]:
                lines.append(f"    - {op}: {count} times")

            # AI Insights
            insights = analysis["ai_insights"]
            if insights:
                lines.append("\n💡 AI Insights:")
                for insight in insights:
                    lines.append(f"  - {insight['message']}")
                    lines.append(f"    → {insight['recommendation']}")

            # Debug hints
            debug = analysis["debug_hints"]
            if debug["ai_todos"]:
                lines.append("\n🔧 AI TODOs:")
                for todo in debug["ai_todos"][:5]:
                    lines.append(f"  - [{todo['operation']}] {todo['todo']}")

            return "\n".join(lines)

        elif format_type == "errors-only":
            lines = ["=== Error Report ===\n"]

            errors = analysis["errors"]
            lines.append(f"Total errors: {errors['count']}\n")

            for pattern in errors["patterns"]:
                lines.append(f"\n{pattern['operation']} ({pattern['count']} errors):")
                for msg in pattern["messages"]:
                    lines.append(f"  - {msg}")

            debug = analysis["debug_hints"]
            if debug["error_contexts"]:
                lines.append("\n\nError Details:")
                for ctx in debug["error_contexts"][:10]:
                    lines.append(f"\n[{ctx['timestamp']}] {ctx['operation']}:")
                    lines.append(f"  {ctx['error']}")

            return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Analyze AI-friendly activity logs")
    parser.add_argument(
        "--log-file",
        default=Path.home() / ".claude" / "ai-activity.jsonl",
        help="Path to log file (default: ~/.claude/ai-activity.jsonl)",
    )
    parser.add_argument(
        "--format",
        choices=["summary", "json", "errors-only"],
        default="summary",
        help="Output format (default: summary)",
    )
    parser.add_argument(
        "--errors-only", action="store_true", help="Show only error analysis"
    )

    args = parser.parse_args()

    if args.errors_only:
        args.format = "errors-only"

    # Create analyzer
    analyzer = AILogAnalyzer(args.log_file)

    # Load logs
    if not analyzer.load_logs():
        sys.exit(1)

    if analyzer.errors:
        print(f"Warning: {len(analyzer.errors)} parse errors encountered")
        for error in analyzer.errors[:5]:
            print(f"  {error}")
        print()

    # Analyze
    analysis = analyzer.analyze()
    if not analysis:
        print("No logs to analyze")
        sys.exit(0)

    # Format and output
    report = analyzer.format_report(analysis, args.format)
    print(report)


if __name__ == "__main__":
    main()
