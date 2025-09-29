#!/usr/bin/env python3
"""
Handover Document Optimizer

This script optimizes handover documents between agents by:
- Removing redundant information
- Compressing verbose content
- Structuring data for easy parsing
- Prioritizing critical information
"""

import argparse
import yaml
import re
from pathlib import Path
from typing import Dict, Any, Optional
from datetime import datetime


class HandoverOptimizer:
    """Optimizes handover documents for efficient agent communication."""

    def __init__(self, compression_level: str = "medium"):
        """
        Initialize optimizer with compression level.

        Args:
            compression_level: "low", "medium", or "high"
        """
        self.compression_level = compression_level
        self.compression_rules = self._get_compression_rules()
        self.stats = {
            "original_size": 0,
            "optimized_size": 0,
            "removed_items": [],
            "structured_items": [],
        }

    def optimize(self, content: str) -> str:
        """
        Optimize handover document content.

        Args:
            content: Raw handover document content

        Returns:
            Optimized content
        """
        self.stats["original_size"] = len(content)

        # Parse content structure
        sections = self._parse_sections(content)

        # Apply optimization strategies
        optimized_sections = {}
        for section_name, section_content in sections.items():
            optimized = self._optimize_section(section_name, section_content)
            if optimized:  # Only include non-empty sections
                optimized_sections[section_name] = optimized

        # Reconstruct document
        optimized_content = self._reconstruct_document(optimized_sections)
        self.stats["optimized_size"] = len(optimized_content)

        # Add metadata
        optimized_content = self._add_metadata(optimized_content)

        return optimized_content

    def _get_compression_rules(self) -> Dict[str, Dict[str, Any]]:
        """Get compression rules based on level."""
        base_rules = {
            "remove_patterns": [
                r"(?i)\b(basically|actually|just|simply|obviously)\b",
                r"\s+",  # Multiple spaces
                r"\n{3,}",  # Multiple newlines
            ],
            "section_priorities": {
                "objectives": "critical",
                "technical_context": "high",
                "implementation_plan": "critical",
                "success_criteria": "high",
                "background": "low",
                "nice_to_have": "low",
                "future_considerations": "low",
            },
            "max_bullet_points": 10,
            "max_description_length": 200,
        }

        if self.compression_level == "high":
            base_rules["max_bullet_points"] = 5
            base_rules["max_description_length"] = 100
            base_rules["remove_sections"] = [
                "background",
                "nice_to_have",
                "future_considerations",
            ]
        elif self.compression_level == "low":
            base_rules["max_bullet_points"] = 20
            base_rules["max_description_length"] = 500

        return base_rules

    def _parse_sections(self, content: str) -> Dict[str, str]:
        """Parse document into sections."""
        sections = {}
        current_section = "introduction"
        current_content = []

        lines = content.split("\n")
        for line in lines:
            # Detect section headers (## Header or ### Header)
            if re.match(r"^#{2,3}\s+(.+)", line):
                # Save previous section
                if current_content:
                    sections[current_section] = "\n".join(current_content)

                # Start new section
                current_section = re.sub(r"^#{2,3}\s+", "", line).lower()
                current_section = re.sub(r"[^a-z0-9_]", "_", current_section)
                current_content = []
            else:
                current_content.append(line)

        # Save last section
        if current_content:
            sections[current_section] = "\n".join(current_content)

        return sections

    def _optimize_section(self, section_name: str, content: str) -> Optional[str]:
        """Optimize a specific section."""
        priority = self.compression_rules["section_priorities"].get(
            section_name, "medium"
        )

        # Skip low priority sections in high compression
        if self.compression_level == "high" and priority == "low":
            self.stats["removed_items"].append(f"Section: {section_name}")
            return None

        # Apply text compression
        optimized = self._compress_text(content)

        # Convert to structured format if beneficial
        if self._should_structure(content):
            structured = self._structure_content(content)
            if structured:
                self.stats["structured_items"].append(section_name)
                return structured

        # Limit content length
        optimized = self._limit_content(optimized, section_name)

        return optimized

    def _compress_text(self, text: str) -> str:
        """Apply text compression rules."""
        compressed = text

        # Remove filler words and redundancies
        for pattern in self.compression_rules["remove_patterns"]:
            compressed = re.sub(pattern, " ", compressed)

        # Normalize whitespace
        compressed = " ".join(compressed.split())

        # Remove empty lines
        lines = [line.strip() for line in compressed.split("\n") if line.strip()]
        compressed = "\n".join(lines)

        return compressed

    def _should_structure(self, content: str) -> bool:
        """Determine if content should be converted to structured format."""
        # Check for patterns that indicate structurable content
        indicators = [
            r"^\s*[-*]\s+",  # Bullet points
            r"^\s*\d+\.\s+",  # Numbered lists
            r":\s*\n\s*[-*]",  # Key with list values
            r"^\s*\w+:\s*\w+",  # Key-value pairs
        ]

        lines = content.split("\n")
        structured_lines = sum(
            1 for line in lines for pattern in indicators if re.match(pattern, line)
        )

        return structured_lines > len(lines) * 0.3  # 30% threshold

    def _structure_content(self, content: str) -> Optional[str]:
        """Convert content to structured YAML format."""
        try:
            # Attempt to parse as key-value pairs or lists
            structured = self._parse_structured_content(content)
            if structured:
                return yaml.dump(structured, default_flow_style=False, sort_keys=False)
        except Exception:
            pass

        return None

    def _parse_structured_content(self, content: str) -> Optional[Dict[str, Any]]:
        """Parse content into structured format."""
        lines = content.strip().split("\n")
        result = {}
        current_key = None
        current_list = []

        for line in lines:
            line = line.strip()

            # Skip empty lines
            if not line:
                continue

            # Check for key-value pair
            kv_match = re.match(r"^(\w+):\s*(.*)$", line)
            if kv_match:
                # Save previous list if any
                if current_key and current_list:
                    result[current_key] = current_list
                    current_list = []

                key, value = kv_match.groups()
                current_key = key.lower()
                if value:
                    result[current_key] = value
                continue

            # Check for list item
            list_match = re.match(r"^[-*]\s+(.+)$", line)
            if list_match and current_key:
                current_list.append(list_match.group(1))
                continue

            # Otherwise, treat as continuation of previous value
            if current_key and current_key in result:
                if isinstance(result[current_key], str):
                    result[current_key] += f" {line}"

        # Save final list if any
        if current_key and current_list:
            result[current_key] = current_list

        return result if result else None

    def _limit_content(self, content: str, section_name: str) -> str:
        """Limit content length based on rules."""
        lines = content.split("\n")

        # Limit bullet points
        bullet_lines = []
        other_lines = []
        bullet_count = 0
        max_bullets = self.compression_rules["max_bullet_points"]

        for line in lines:
            if re.match(r"^\s*[-*]\s+", line) or re.match(r"^\s*\d+\.\s+", line):
                if bullet_count < max_bullets:
                    bullet_lines.append(line)
                    bullet_count += 1
                else:
                    self.stats["removed_items"].append(
                        f"Bullet point in {section_name}"
                    )
            else:
                other_lines.append(line)

        # Limit description length
        max_length = self.compression_rules["max_description_length"]
        limited_lines = []

        for line in other_lines:
            if len(line) > max_length:
                line = line[:max_length] + "..."
                self.stats["removed_items"].append(f"Truncated text in {section_name}")
            limited_lines.append(line)

        # Combine
        all_lines = limited_lines[:3]  # Keep first 3 description lines
        all_lines.extend(bullet_lines)
        all_lines.extend(limited_lines[3:7])  # Add a few more if space

        return "\n".join(all_lines)

    def _reconstruct_document(self, sections: Dict[str, str]) -> str:
        """Reconstruct optimized document from sections."""
        # Define section order
        section_order = [
            "task_summary",
            "objectives",
            "technical_context",
            "implementation_plan",
            "success_criteria",
            "critical_information",
            "resources",
            "next_steps",
        ]

        lines = ["# Optimized Handover Document\n"]

        # Add sections in order
        for section in section_order:
            if section in sections:
                # Format section header
                header = section.replace("_", " ").title()
                lines.append(f"\n## {header}\n")
                lines.append(sections[section])

        # Add remaining sections
        for section, content in sections.items():
            if section not in section_order:
                header = section.replace("_", " ").title()
                lines.append(f"\n## {header}\n")
                lines.append(content)

        return "\n".join(lines)

    def _add_metadata(self, content: str) -> str:
        """Add optimization metadata to document."""
        metadata = {
            "optimization": {
                "timestamp": datetime.now().isoformat(),
                "compression_level": self.compression_level,
                "original_size": self.stats["original_size"],
                "optimized_size": self.stats["optimized_size"],
                "compression_ratio": round(
                    self.stats["optimized_size"] / self.stats["original_size"], 2
                )
                if self.stats["original_size"] > 0
                else 1.0,
                "removed_items_count": len(self.stats["removed_items"]),
                "structured_sections": self.stats["structured_items"],
            }
        }

        metadata_yaml = yaml.dump(metadata, default_flow_style=False)

        return (
            content + f"\n\n---\n## Optimization Metadata\n```yaml\n{metadata_yaml}```"
        )

    def get_stats(self) -> Dict[str, Any]:
        """Get optimization statistics."""
        return self.stats


def main():
    parser = argparse.ArgumentParser(
        description="Optimize handover documents for agent communication"
    )
    parser.add_argument("input", help="Input handover document path")
    parser.add_argument(
        "-o", "--output", help="Output path (default: input_optimized.md)"
    )
    parser.add_argument(
        "-c",
        "--compression-level",
        choices=["low", "medium", "high"],
        default="medium",
        help="Compression level",
    )
    parser.add_argument(
        "--stats", action="store_true", help="Show optimization statistics"
    )

    args = parser.parse_args()

    # Read input file
    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Error: Input file {input_path} not found")
        return 1

    content = input_path.read_text(encoding="utf-8")

    # Optimize
    optimizer = HandoverOptimizer(compression_level=args.compression_level)
    optimized = optimizer.optimize(content)

    # Write output
    if args.output:
        output_path = Path(args.output)
    else:
        output_path = input_path.parent / f"{input_path.stem}_optimized.md"

    output_path.write_text(optimized, encoding="utf-8")
    print(f"Optimized document written to: {output_path}")

    # Show stats if requested
    if args.stats:
        stats = optimizer.get_stats()
        print("\nOptimization Statistics:")
        print(f"  Original size: {stats['original_size']} bytes")
        print(f"  Optimized size: {stats['optimized_size']} bytes")
        print(
            f"  Compression ratio: {stats['optimized_size']/stats['original_size']:.2%}"
        )
        print(f"  Items removed: {len(stats['removed_items'])}")
        print(f"  Sections structured: {len(stats['structured_items'])}")

    return 0


if __name__ == "__main__":
    exit(main())
