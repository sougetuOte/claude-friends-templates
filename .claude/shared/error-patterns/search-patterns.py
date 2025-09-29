#!/usr/bin/env python3
"""
Error Pattern Search Utility

This script helps search and retrieve error patterns from the library.
"""

import json
import sys
from pathlib import Path
from typing import List, Dict, Optional
import argparse


class ErrorPatternSearcher:
    def __init__(self, patterns_dir: str = None):
        if patterns_dir is None:
            # Default to the error-patterns directory
            self.patterns_dir = Path(__file__).parent
        else:
            self.patterns_dir = Path(patterns_dir)

        self.patterns = []
        self.load_patterns()

    def load_patterns(self):
        """Load all error patterns from the directory structure."""
        # Load from categories
        categories_dir = self.patterns_dir / "categories"
        if categories_dir.exists():
            for category_dir in categories_dir.iterdir():
                if category_dir.is_dir():
                    for pattern_file in category_dir.glob("*.json"):
                        self._load_pattern_file(pattern_file)

        # Load from languages
        languages_dir = self.patterns_dir / "languages"
        if languages_dir.exists():
            for lang_dir in languages_dir.iterdir():
                if lang_dir.is_dir():
                    for pattern_file in lang_dir.glob("*.json"):
                        self._load_pattern_file(pattern_file)

    def _load_pattern_file(self, filepath: Path):
        """Load a single pattern file."""
        try:
            with open(filepath, "r", encoding="utf-8") as f:
                pattern = json.load(f)
                pattern["_filepath"] = str(filepath)
                self.patterns.append(pattern)
        except Exception as e:
            print(f"Error loading {filepath}: {e}", file=sys.stderr)

    def search_by_keyword(self, keyword: str) -> List[Dict]:
        """Search patterns by keyword in symptoms, description, or name."""
        keyword_lower = keyword.lower()
        results = []

        for pattern in self.patterns:
            # Search in name and description
            if (
                keyword_lower in pattern.get("name", "").lower()
                or keyword_lower in pattern.get("description", "").lower()
            ):
                results.append(pattern)
                continue

            # Search in symptoms
            for symptom in pattern.get("symptoms", []):
                if keyword_lower in symptom.lower():
                    results.append(pattern)
                    break

            # Search in tags
            if keyword_lower in [tag.lower() for tag in pattern.get("tags", [])]:
                results.append(pattern)

        return self._deduplicate(results)

    def search_by_category(self, category: str) -> List[Dict]:
        """Search patterns by category."""
        return [
            p
            for p in self.patterns
            if p.get("category", "").lower() == category.lower()
        ]

    def search_by_language(self, language: str) -> List[Dict]:
        """Search patterns by language."""
        language_lower = language.lower()
        return [
            p
            for p in self.patterns
            if language_lower in [l.lower() for l in p.get("languages", [])]
        ]

    def search_by_severity(self, severity: str) -> List[Dict]:
        """Search patterns by severity level."""
        return [
            p
            for p in self.patterns
            if p.get("severity", "").lower() == severity.lower()
        ]

    def get_pattern_by_id(self, pattern_id: str) -> Optional[Dict]:
        """Get a specific pattern by its ID."""
        for pattern in self.patterns:
            if pattern.get("id") == pattern_id:
                return pattern
        return None

    def _deduplicate(self, patterns: List[Dict]) -> List[Dict]:
        """Remove duplicate patterns from results."""
        seen_ids = set()
        unique_patterns = []

        for pattern in patterns:
            if pattern.get("id") not in seen_ids:
                seen_ids.add(pattern.get("id"))
                unique_patterns.append(pattern)

        return unique_patterns

    def format_pattern(self, pattern: Dict, verbose: bool = False) -> str:
        """Format a pattern for display."""
        output = []
        output.append(f"\n{'='*60}")
        output.append(f"ID: {pattern.get('id', 'Unknown')}")
        output.append(f"Name: {pattern.get('name', 'Unknown')}")
        output.append(f"Category: {pattern.get('category', 'Unknown')}")
        output.append(f"Severity: {pattern.get('severity', 'Unknown')}")
        output.append(f"Languages: {', '.join(pattern.get('languages', []))}")
        output.append(f"\nDescription: {pattern.get('description', 'No description')}")

        if pattern.get("symptoms"):
            output.append("\nSymptoms:")
            for symptom in pattern["symptoms"]:
                output.append(f"  - {symptom}")

        if verbose:
            if pattern.get("causes"):
                output.append("\nCauses:")
                for cause in pattern["causes"]:
                    output.append(f"  - {cause}")

            if pattern.get("solutions"):
                output.append("\nSolutions:")
                for i, solution in enumerate(pattern["solutions"], 1):
                    output.append(
                        f"\n  Solution {i}: {solution.get('description', '')}"
                    )
                    if solution.get("code"):
                        output.append("  Code:")
                        for line in solution["code"].split("\n"):
                            output.append(f"    {line}")
                    if solution.get("preventive"):
                        output.append("  (Preventive measure)")

        if pattern.get("tags"):
            output.append(f"\nTags: {', '.join(pattern['tags'])}")

        return "\n".join(output)


def main():
    parser = argparse.ArgumentParser(description="Search error patterns library")
    parser.add_argument("search_term", nargs="?", help="Keyword to search for")
    parser.add_argument("-c", "--category", help="Filter by category")
    parser.add_argument("-l", "--language", help="Filter by language")
    parser.add_argument("-s", "--severity", help="Filter by severity")
    parser.add_argument("-i", "--id", help="Get specific pattern by ID")
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="Show detailed information"
    )
    parser.add_argument(
        "--list-categories", action="store_true", help="List all categories"
    )
    parser.add_argument(
        "--list-languages", action="store_true", help="List all languages"
    )
    parser.add_argument("--stats", action="store_true", help="Show statistics")

    args = parser.parse_args()

    searcher = ErrorPatternSearcher()

    if args.stats:
        print(f"Total patterns: {len(searcher.patterns)}")
        categories = {}
        languages = {}
        severities = {}

        for pattern in searcher.patterns:
            cat = pattern.get("category", "unknown")
            categories[cat] = categories.get(cat, 0) + 1

            sev = pattern.get("severity", "unknown")
            severities[sev] = severities.get(sev, 0) + 1

            for lang in pattern.get("languages", ["unknown"]):
                languages[lang] = languages.get(lang, 0) + 1

        print("\nCategories:")
        for cat, count in sorted(categories.items()):
            print(f"  {cat}: {count}")

        print("\nLanguages:")
        for lang, count in sorted(languages.items()):
            print(f"  {lang}: {count}")

        print("\nSeverities:")
        for sev, count in sorted(severities.items()):
            print(f"  {sev}: {count}")

        return

    if args.list_categories:
        categories = set(p.get("category", "") for p in searcher.patterns)
        print("Available categories:")
        for cat in sorted(categories):
            if cat:
                print(f"  - {cat}")
        return

    if args.list_languages:
        languages = set()
        for pattern in searcher.patterns:
            languages.update(pattern.get("languages", []))
        print("Available languages:")
        for lang in sorted(languages):
            print(f"  - {lang}")
        return

    # Perform search
    results = []

    if args.id:
        pattern = searcher.get_pattern_by_id(args.id)
        if pattern:
            results = [pattern]
    elif args.search_term:
        results = searcher.search_by_keyword(args.search_term)
    else:
        results = searcher.patterns

    # Apply filters
    if args.category:
        results = [
            p for p in results if p.get("category", "").lower() == args.category.lower()
        ]

    if args.language:
        results = [
            p
            for p in results
            if args.language.lower() in [l.lower() for l in p.get("languages", [])]
        ]

    if args.severity:
        results = [
            p for p in results if p.get("severity", "").lower() == args.severity.lower()
        ]

    # Display results
    if not results:
        print("No patterns found matching your criteria.")
    else:
        print(f"Found {len(results)} pattern(s):")
        for pattern in results:
            print(searcher.format_pattern(pattern, verbose=args.verbose))


if __name__ == "__main__":
    main()
