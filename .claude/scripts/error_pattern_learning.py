#!/usr/bin/env python3
"""
Error Pattern Learning System
AI-driven error pattern recognition and classification

Features:
- JSONL log file parsing
- Error pattern detection and classification
- Frequency analysis for repeated patterns
- Insight generation (error rates, agent balance)
- Pattern categorization (network, filesystem, permission, etc.)

Version: 1.0.0
Python: 3.12+

Usage Example:
    Basic log analysis:
        >>> from error_pattern_learning import LogAnalyzer
        >>> analyzer = LogAnalyzer(Path("~/.claude/ai-activity.jsonl"))
        >>> patterns = analyzer.analyze_patterns()
        >>> insights = analyzer.generate_insights()

    Error classification:
        >>> from error_pattern_learning import ErrorPatternClassifier
        >>> classifier = ErrorPatternClassifier()
        >>> error_type = classifier.classify("Connection timeout")
        >>> print(error_type)  # "network"

    Frequency analysis:
        >>> from error_pattern_learning import PatternFrequencyAnalyzer
        >>> analyzer = PatternFrequencyAnalyzer()
        >>> analyzer.add_pattern("File not found")
        >>> analyzer.add_pattern("File not found")
        >>> frequencies = analyzer.get_frequent_patterns(min_count=2)
        >>> print(frequencies)  # {"File not found": 2}

Output Format:
    analyze_patterns() returns:
    {
        "error_patterns": {
            "Connection failed": [entry1, entry2],
            "File not found": [entry3]
        },
        "operation_counts": {
            "read": 10,
            "write": 5
        },
        "agent_activities": {
            "planner": 15,
            "builder": 20
        },
        "total_entries": 35
    }

    generate_insights() returns:
    [
        "⚠️ High error rate detected: 15.0%",
        "🔁 Repeated error pattern: 'Timeout' (5 times)",
        "📊 Planner is significantly more active than Builder"
    ]
"""

import json
from pathlib import Path
from collections import Counter, defaultdict
from typing import List, Dict, Any


class LogAnalyzer:
    """
    Log analysis engine for AI-optimized JSONL logs.

    Analyzes log entries to detect patterns, classify errors,
    and generate actionable insights for debugging and improvement.

    Attributes:
        log_file: Path to JSONL log file
        entries: List of loaded log entries
        classifier: Error pattern classifier instance

    Example:
        >>> analyzer = LogAnalyzer(Path("~/.claude/ai-activity.jsonl"))
        >>> patterns = analyzer.analyze_patterns()
        >>> insights = analyzer.generate_insights()
        >>> error_categories = analyzer.categorize_errors()
    """

    def __init__(self, log_file: Path):
        """
        Initialize log analyzer.

        Args:
            log_file: Path to JSONL log file to analyze
        """
        self.log_file = log_file
        self.entries: List[Dict[str, Any]] = []
        self.classifier = ErrorPatternClassifier()
        self._load_logs()

    def _load_logs(self) -> None:
        """
        Load log entries from JSONL file.

        Skips corrupted entries and continues loading valid ones.
        Handles missing files gracefully by leaving entries empty.
        """
        if not self.log_file.exists():
            return

        with self.log_file.open("r", encoding="utf-8") as f:
            for line in f:
                try:
                    entry = json.loads(line)
                    self.entries.append(entry)
                except json.JSONDecodeError:
                    # Skip corrupted lines
                    continue

    def analyze_patterns(self) -> Dict[str, Any]:
        """
        Analyze log entries to detect patterns.

        Returns:
            Dictionary containing:
            - error_patterns: Dict of error messages to list of entries
            - operation_counts: Counter of operation types
            - agent_activities: Count of activities per agent
            - total_entries: Total number of log entries
        """
        error_patterns = defaultdict(list)
        operation_counts = Counter()
        agent_activities = defaultdict(list)

        for entry in self.entries:
            # Collect error patterns
            level = entry.get("level")
            if level in ["ERROR", "CRITICAL"]:
                message = entry.get("message", "Unknown")
                error_patterns[message].append(entry)

            # Count operations
            operation = entry.get("metadata", {}).get("operation", "unknown")
            operation_counts[operation] += 1

            # Track agent activities
            agent = entry.get("context", {}).get("agent", "unknown")
            agent_activities[agent].append(entry)

        return {
            "error_patterns": dict(error_patterns),
            "operation_counts": dict(operation_counts),
            "agent_activities": {k: len(v) for k, v in agent_activities.items()},
            "total_entries": len(self.entries),
        }

    def generate_insights(self) -> List[str]:
        """
        Generate AI-driven insights from log analysis.

        Detects:
        - High error rates (> 10%)
        - Repeated error patterns (≥ 3 occurrences)
        - Agent work imbalance (planner > builder * 2)

        Returns:
            List of insight strings with emoji indicators
        """
        insights = []
        patterns = self.analyze_patterns()

        # Error rate analysis
        error_count = sum(
            1 for e in self.entries if e.get("level") in ["ERROR", "CRITICAL"]
        )
        error_rate = (error_count / len(self.entries) * 100) if self.entries else 0

        if error_rate > 10:
            insights.append(f"⚠️ High error rate detected: {error_rate:.1f}%")

        # Frequent error patterns
        for pattern, occurrences in patterns["error_patterns"].items():
            if len(occurrences) >= 3:
                insights.append(
                    f"🔁 Repeated error pattern: '{pattern}' ({len(occurrences)} times)"
                )

        # Agent activity balance
        activities = patterns["agent_activities"]
        planner_count = activities.get("planner", 0)
        builder_count = activities.get("builder", 0)

        if builder_count > 0 and planner_count > builder_count * 2:
            insights.append("📊 Planner is significantly more active than Builder")

        return insights

    def categorize_errors(self) -> Dict[str, List[Dict[str, Any]]]:
        """
        Categorize errors by type using ErrorPatternClassifier.

        Returns:
            Dictionary mapping error categories to lists of error entries
        """
        categorized = defaultdict(list)

        for entry in self.entries:
            if entry.get("level") in ["ERROR", "CRITICAL"]:
                message = entry.get("message", "Unknown")
                category = self.classifier.classify(message)
                categorized[category].append(entry)

        return dict(categorized)

    def get_error_summary(self) -> Dict[str, Any]:
        """
        Get comprehensive error summary.

        Returns:
            Dictionary with error counts, categories, and top patterns
        """
        categorized = self.categorize_errors()
        patterns = self.analyze_patterns()

        # Get top 5 most frequent error patterns
        error_freq = {
            pattern: len(entries)
            for pattern, entries in patterns["error_patterns"].items()
        }
        top_patterns = sorted(error_freq.items(), key=lambda x: x[1], reverse=True)[:5]

        return {
            "total_errors": sum(len(v) for v in categorized.values()),
            "by_category": {k: len(v) for k, v in categorized.items()},
            "top_patterns": dict(top_patterns),
        }


class ErrorPatternClassifier:
    """
    Error pattern classifier for categorizing error types.

    Classifies errors into categories:
    - network: Connection, timeout, DNS issues
    - filesystem: File not found, permission denied
    - permission: Access denied, unauthorized
    - data_format: Invalid JSON, parse errors
    - resource: Memory, CPU, disk space issues
    - unknown: Uncategorized errors

    Example:
        >>> classifier = ErrorPatternClassifier()
        >>> classifier.classify("Connection timeout")  # Returns "network"
        >>> classifier.classify("Out of memory")  # Returns "resource"
    """

    def __init__(self):
        """Initialize error pattern classifier with enhanced categories."""
        # Define error categories with keywords
        self.categories = {
            "network": [
                "connection",
                "timeout",
                "dns",
                "socket",
                "network",
                "unreachable",
                "refused",
                "host",
                "ssl",
                "certificate",
            ],
            "filesystem": [
                "file not found",
                "no such file",
                "directory",
                "path",
                "disk",
                "read",
                "write",
                "io error",
            ],
            "permission": [
                "permission denied",
                "access denied",
                "unauthorized",
                "forbidden",
                "not allowed",
                "authentication",
            ],
            "data_format": [
                "invalid json",
                "parse error",
                "decode",
                "format",
                "syntax error",
                "malformed",
                "corrupt",
            ],
            "resource": [
                "memory",
                "cpu",
                "disk space",
                "out of",
                "limit exceeded",
                "quota",
                "capacity",
                "overflow",
            ],
        }

    def classify(self, message: str) -> str:
        """
        Classify error message into category.

        Uses keyword matching with priority order:
        1. network
        2. resource
        3. filesystem
        4. permission
        5. data_format
        6. unknown (fallback)

        Args:
            message: Error message to classify

        Returns:
            Category name: "network", "filesystem", "permission",
            "data_format", "resource", or "unknown"
        """
        message_lower = message.lower()

        for category, keywords in self.categories.items():
            for keyword in keywords:
                if keyword in message_lower:
                    return category

        return "unknown"

    def get_all_categories(self) -> List[str]:
        """
        Get list of all available error categories.

        Returns:
            List of category names
        """
        return list(self.categories.keys()) + ["unknown"]


class PatternFrequencyAnalyzer:
    """
    Pattern frequency analyzer for tracking recurring patterns.

    Tracks frequency of patterns and identifies those
    meeting minimum occurrence thresholds.

    Example:
        >>> analyzer = PatternFrequencyAnalyzer()
        >>> analyzer.add_pattern("Timeout error")
        >>> analyzer.add_pattern("Timeout error")
        >>> analyzer.add_pattern("Timeout error")
        >>> frequent = analyzer.get_frequent_patterns(min_count=2)
        >>> print(frequent)  # {"Timeout error": 3}
        >>> top_patterns = analyzer.get_top_patterns(n=5)
    """

    def __init__(self):
        """Initialize pattern frequency analyzer."""
        self.pattern_counts: Counter = Counter()

    def add_pattern(self, pattern: str) -> None:
        """
        Add pattern occurrence.

        Args:
            pattern: Pattern string to track
        """
        self.pattern_counts[pattern] += 1

    def add_patterns(self, patterns: List[str]) -> None:
        """
        Add multiple pattern occurrences at once.

        Args:
            patterns: List of pattern strings to track
        """
        for pattern in patterns:
            self.add_pattern(pattern)

    def get_frequent_patterns(self, min_count: int = 1) -> Dict[str, int]:
        """
        Get patterns meeting minimum occurrence threshold.

        Args:
            min_count: Minimum number of occurrences

        Returns:
            Dictionary of pattern to count for patterns >= min_count
        """
        return {
            pattern: count
            for pattern, count in self.pattern_counts.items()
            if count >= min_count
        }

    def get_top_patterns(self, n: int = 10) -> List[tuple]:
        """
        Get top N most frequent patterns.

        Args:
            n: Number of top patterns to return

        Returns:
            List of (pattern, count) tuples sorted by frequency
        """
        return self.pattern_counts.most_common(n)

    def get_pattern_count(self, pattern: str) -> int:
        """
        Get count for specific pattern.

        Args:
            pattern: Pattern to query

        Returns:
            Number of occurrences of the pattern
        """
        return self.pattern_counts.get(pattern, 0)

    def reset(self) -> None:
        """Reset all pattern counts."""
        self.pattern_counts.clear()


def main():
    """Main entry point for command-line usage."""
    import sys

    log_file = Path.home() / ".claude" / "ai-activity.jsonl"

    if not log_file.exists():
        print(f"Log file not found: {log_file}")
        sys.exit(1)

    analyzer = LogAnalyzer(log_file)
    patterns = analyzer.analyze_patterns()
    insights = analyzer.generate_insights()

    # Print analysis report
    print("\n=== Log Analysis Report ===")
    print(f"Total entries: {patterns['total_entries']}")

    print("\nOperation breakdown:")
    for op, count in patterns["operation_counts"].items():
        print(f"  {op}: {count}")

    print("\nAgent activities:")
    for agent, count in patterns["agent_activities"].items():
        print(f"  {agent}: {count}")

    if insights:
        print("\n=== AI Insights ===")
        for insight in insights:
            print(f"  {insight}")

    # JSON output option
    if "--json" in sys.argv:
        print("\n=== JSON Output ===")
        print(
            json.dumps(
                {
                    "patterns": patterns,
                    "insights": insights,
                },
                indent=2,
                ensure_ascii=False,
            )
        )


if __name__ == "__main__":
    main()
