#!/usr/bin/env python3

"""
Agent Handover Generator
2025 Best Practices Implementation with Versioned Schemas and Provenance Tracking

Following 2025 multi-agent coordination best practices:
- API-oriented handoffs with strict validation
- Provenance and tool state preservation
- Context preservation with trace IDs
- Event-driven coordination
- Full observability and monitoring
"""

import argparse
import json
import os
import sys
import uuid
import hashlib
import gzip
import tempfile
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Any, List, Optional, Union
from dataclasses import dataclass, asdict
import re

# Python 3.12 features
from typing import override

# Constants for 2025 handover system
HANDOVER_SCHEMA_VERSION = "2.0.0"
SUPPORTED_AGENTS = ["planner", "builder", "reviewer", "architect", "coordinator"]
DEFAULT_COMPRESSION_RATIO = 0.3


@dataclass
class HandoverMetadata:
    """Handover metadata following 2025 best practices"""
    id: str
    schema_version: str
    created_at: str
    from_agent: str
    to_agent: str
    agent_session_id: str
    handover_type: str = "standard"


@dataclass
class TraceInfo:
    """Trace information for 2025 observability"""
    trace_id: str
    correlation_id: str
    parent_span_id: Optional[str] = None
    session_id: Optional[str] = None


@dataclass
class ProvenanceInfo:
    """Provenance tracking for audit and replay"""
    created_by: str
    creation_timestamp: str
    source_files_modified: List[str]
    tools_used: List[str]
    session_state: Dict[str, Any]
    environment_snapshot: Dict[str, str]


class HandoverGenerator:
    """Agent handover generator following 2025 best practices"""

    def __init__(self):
        self.schema_version = HANDOVER_SCHEMA_VERSION
        self.project_root = Path.cwd()

    def detect_agent_switch(self, prompt_file: str) -> Dict[str, Any]:
        """Detect agent switch from prompt file"""
        if not Path(prompt_file).exists():
            return {"error": "Prompt file not found"}

        with open(prompt_file, 'r') as f:
            content = f.read()

        # Detect agent switch pattern
        agent_pattern = r'/agent:(planner|builder|reviewer|architect|first)'
        match = re.search(agent_pattern, content)

        if match:
            target_agent = match.group(1)
            if target_agent == "first":
                target_agent = "planner"  # Default first agent

            return {
                "switch_detected": True,
                "target_agent": target_agent,
                "pattern_matched": match.group(0)
            }

        return {"switch_detected": False}

    def get_git_status(self) -> Dict[str, Any]:
        """Get current Git status"""
        try:
            # Git status
            status_result = subprocess.run(
                ["git", "status", "--short"],
                capture_output=True, text=True, cwd=self.project_root
            )

            # Current branch
            branch_result = subprocess.run(
                ["git", "branch", "--show-current"],
                capture_output=True, text=True, cwd=self.project_root
            )

            # Modified files
            diff_result = subprocess.run(
                ["git", "diff", "--name-only"],
                capture_output=True, text=True, cwd=self.project_root
            )

            return {
                "status": status_result.stdout.strip(),
                "current_branch": branch_result.stdout.strip(),
                "modified_files": diff_result.stdout.strip().split('\n') if diff_result.stdout.strip() else []
            }
        except Exception as e:
            return {
                "status": "N/A",
                "current_branch": "N/A",
                "modified_files": [],
                "error": str(e)
            }

    def get_test_status(self) -> str:
        """Get current test status"""
        try:
            result = subprocess.run(
                ["python", "-m", "pytest", "--collect-only", "-q"],
                capture_output=True, text=True, cwd=self.project_root
            )
            if result.returncode == 0:
                return "tests_available"
            else:
                return "no_tests"
        except:
            return "unknown"

    def extract_recent_activities(self, agent: str) -> List[str]:
        """Extract recent activities from agent notes"""
        notes_file = self.project_root / ".claude" / agent / "notes.md"

        if not notes_file.exists():
            return ["No recent activities found"]

        try:
            with open(notes_file, 'r') as f:
                content = f.read()

            # Extract recent activities section
            lines = content.split('\n')
            in_activities = False
            activities = []

            for line in lines:
                if "最近の活動" in line or "Recent Activities" in line:
                    in_activities = True
                    continue
                elif line.startswith('## ') and in_activities:
                    break
                elif in_activities and line.strip():
                    activities.append(line.strip())

            return activities[:10] if activities else ["No recent activities found"]
        except:
            return ["Error reading activities"]

    def get_current_task(self, agent: str) -> str:
        """Get current task from agent notes"""
        notes_file = self.project_root / ".claude" / agent / "notes.md"

        if not notes_file.exists():
            return "No current task"

        try:
            with open(notes_file, 'r') as f:
                content = f.read()

            # Look for current task pattern
            task_pattern = r'現在のタスク[:：]\s*(.+)'
            match = re.search(task_pattern, content)
            if match:
                return match.group(1).strip()

            # Alternative pattern
            task_pattern2 = r'Current Task[:：]\s*(.+)'
            match2 = re.search(task_pattern2, content)
            if match2:
                return match2.group(1).strip()

            return "No current task specified"
        except:
            return "Error reading current task"

    def calculate_priority(self, blockers: List[str], complexity: str = "normal") -> str:
        """Calculate handover priority"""
        if len(blockers) > 0:
            return "high"
        elif complexity == "high":
            return "high"
        else:
            return "normal"

    def generate_ai_hints(self, from_agent: str, to_agent: str, complexity: str = "normal") -> Dict[str, Any]:
        """Generate AI hints for receiving agent"""
        hints = {
            "priority": self.calculate_priority([], complexity),
            "complexity_level": complexity,
            "suggested_approach": f"Continue work from {from_agent} perspective",
            "potential_blockers": [],
            "debugging_hints": [
                "Check recent test results",
                "Verify Git status before proceeding"
            ],
            "performance_considerations": [
                "Monitor resource usage",
                "Consider parallel execution where possible"
            ],
            "security_notes": [
                "Validate all inputs",
                "Check for sensitive data in handover"
            ]
        }

        # Agent-specific hints
        if to_agent == "builder":
            hints["suggested_approach"] = "Focus on implementation and testing"
            hints["debugging_hints"].append("Run TDD cycle if implementing new features")
        elif to_agent == "planner":
            hints["suggested_approach"] = "Focus on strategy and planning"
            hints["debugging_hints"].append("Review project requirements and constraints")

        return hints

    def compress_context(self, context_data: Dict[str, Any], compression_ratio: float = 0.3) -> Dict[str, Any]:
        """Compress large context data"""
        # Convert to JSON string
        json_str = json.dumps(context_data, indent=2)
        original_size = len(json_str.encode('utf-8'))

        # Compress with gzip
        compressed_data = gzip.compress(json_str.encode('utf-8'))
        compressed_size = len(compressed_data)

        # Calculate actual compression ratio
        actual_ratio = compressed_size / original_size if original_size > 0 else 1.0

        return {
            "compressed": True,
            "compression_info": {
                "original_size": original_size,
                "compressed_size": compressed_size,
                "compression_ratio": actual_ratio,
                "algorithm": "gzip"
            },
            "data": compressed_data.hex()  # Store as hex string
        }

    def create_handover_document(
        self,
        from_agent: str,
        to_agent: str,
        trace_id: Optional[str] = None,
        correlation_id: Optional[str] = None,
        context: Optional[str] = None,
        include_provenance: bool = True,
        capture_state: bool = True,
        generate_ai_hints: bool = True,
        task_complexity: str = "normal",
        compress_context_data: Optional[str] = None,
        compression_ratio: float = 0.3,
        use_template: Optional[str] = None
    ) -> Dict[str, Any]:
        """Create handover document following 2025 best practices"""

        # Generate IDs
        handover_id = str(uuid.uuid4())
        if not trace_id:
            trace_id = str(uuid.uuid4())
        if not correlation_id:
            correlation_id = str(uuid.uuid4())

        # Metadata
        metadata = HandoverMetadata(
            id=handover_id,
            schema_version=self.schema_version,
            created_at=datetime.now(timezone.utc).isoformat(),
            from_agent=from_agent,
            to_agent=to_agent,
            agent_session_id=str(uuid.uuid4()),
            handover_type="template" if use_template else "standard"
        )

        # Trace information
        trace_info = TraceInfo(
            trace_id=trace_id,
            correlation_id=correlation_id,
            session_id=str(uuid.uuid4())
        )

        # Base handover structure
        handover = {
            "schema_version": self.schema_version,
            "metadata": asdict(metadata),
            "trace_info": asdict(trace_info),
            "summary": {
                "completed_tasks": self.extract_recent_activities(from_agent),
                "current_task": context or self.get_current_task(from_agent),
                "blockers": [],
                "next_steps": [f"Continue work as {to_agent}"]
            },
            "context": {
                "task_description": context or "Agent handover",
                "agent_specific_context": {} if use_template else {"note": "Standard handover"}
            }
        }

        # Add template-specific fields
        if use_template:
            handover["metadata"]["source_agent_type"] = use_template
            handover["context"]["agent_specific_context"] = {
                "template_used": use_template,
                "specialized_fields": f"Fields specific to {use_template} agent"
            }

        # Provenance tracking
        if include_provenance:
            git_status = self.get_git_status()
            provenance = ProvenanceInfo(
                created_by=f"{from_agent}_agent",
                creation_timestamp=datetime.now(timezone.utc).isoformat(),
                source_files_modified=git_status.get("modified_files", []),
                tools_used=["handover-generator", "git"],
                session_state={"active": True},
                environment_snapshot=dict(os.environ)
            )
            handover["provenance"] = asdict(provenance)

        # State snapshot
        if capture_state:
            git_status = self.get_git_status()
            handover["state_snapshot"] = {
                "git_status": git_status.get("status", "N/A"),
                "current_branch": git_status.get("current_branch", "N/A"),
                "modified_files": git_status.get("modified_files", []),
                "test_status": self.get_test_status(),
                "task_progress": "in_progress",
                "environment_vars": {k: v for k, v in os.environ.items() if not k.startswith("CLAUDE_")},
                "active_tools": ["git", "pytest", "python"]
            }

        # AI hints
        if generate_ai_hints:
            handover["ai_hints"] = self.generate_ai_hints(from_agent, to_agent, task_complexity)

        # Context compression
        if compress_context_data:
            try:
                with open(compress_context_data, 'r') as f:
                    large_context = json.load(f)
                compressed_result = self.compress_context(large_context, compression_ratio)
                handover["context"]["compressed_data"] = compressed_result
                # Extract compression_info to top level of context for easier access
                handover["context"]["compression_info"] = compressed_result["compression_info"]
            except:
                handover["context"]["compression_error"] = "Failed to load context file"

        return handover

    def validate_handover(self, handover_file: str) -> Dict[str, Any]:
        """Validate handover document"""
        try:
            with open(handover_file, 'r') as f:
                handover = json.load(f)

            # Check schema version
            if handover.get("schema_version") != HANDOVER_SCHEMA_VERSION:
                return {
                    "is_valid": False,
                    "error": f"Invalid schema version. Expected {HANDOVER_SCHEMA_VERSION}"
                }

            # Check required fields
            required_fields = ["metadata", "trace_info", "summary", "context"]
            missing_fields = [field for field in required_fields if field not in handover]

            if missing_fields:
                return {
                    "is_valid": False,
                    "error": f"Missing required fields: {missing_fields}"
                }

            return {"is_valid": True}
        except Exception as e:
            return {"is_valid": False, "error": str(e)}

    def verify_integrity(self, handover_file: str) -> Dict[str, Any]:
        """Verify handover integrity with checksum"""
        try:
            with open(handover_file, 'rb') as f:
                content = f.read()

            checksum = hashlib.sha256(content).hexdigest()

            # Basic validation
            validation_result = self.validate_handover(handover_file)

            return {
                "is_valid": validation_result["is_valid"],
                "checksum": checksum,
                "file_size": len(content),
                "validation_details": validation_result
            }
        except Exception as e:
            return {"is_valid": False, "error": str(e)}

    def batch_generate(self, agents: List[str], output_dir: str) -> Dict[str, Any]:
        """Generate handovers for multiple agents"""
        results = {}

        for agent in agents:
            try:
                handover = self.create_handover_document(
                    from_agent=agent,
                    to_agent="coordinator",
                    capture_state=True
                )

                output_file = Path(output_dir) / f"handover_{agent}.json"
                with open(output_file, 'w') as f:
                    json.dump(handover, f, indent=2)

                results[agent] = {"status": "success", "file": str(output_file)}
            except Exception as e:
                results[agent] = {"status": "error", "error": str(e)}

        return results


def main():
    """Main CLI interface"""
    parser = argparse.ArgumentParser(description="Agent Handover Generator - 2025 Best Practices")

    # Detection mode
    parser.add_argument("--detect-switch", help="Detect agent switch from prompt file")

    # Generation parameters
    parser.add_argument("--from-agent", help="Source agent")
    parser.add_argument("--to-agent", help="Target agent")
    parser.add_argument("--output", help="Output file path")

    # 2025 best practice features
    parser.add_argument("--trace-id", help="Trace ID for observability")
    parser.add_argument("--correlation-id", help="Correlation ID for tracking")
    parser.add_argument("--context", help="Context description")
    parser.add_argument("--include-provenance", action="store_true", default=True, help="Include provenance tracking (default: enabled)")
    parser.add_argument("--capture-state", action="store_true", default=True, help="Capture state snapshot (default: enabled)")
    parser.add_argument("--generate-ai-hints", action="store_true", default=True, help="Generate AI hints (default: enabled)")
    parser.add_argument("--task-complexity", choices=["low", "normal", "high"], default="normal")

    # Compression
    parser.add_argument("--compress-context", help="Compress large context file")
    parser.add_argument("--compression-ratio", type=float, default=0.3)

    # Validation
    parser.add_argument("--validate", help="Validate handover file")
    parser.add_argument("--verify-integrity", help="Verify handover integrity")

    # Batch operations
    parser.add_argument("--batch-generate", action="store_true", help="Batch generate handovers")
    parser.add_argument("--agents", help="Comma-separated list of agents")
    parser.add_argument("--output-dir", help="Output directory for batch operations")

    # Templates
    parser.add_argument("--use-template", help="Use agent-specific template")

    args = parser.parse_args()

    generator = HandoverGenerator()

    try:
        # Agent switch detection
        if args.detect_switch:
            result = generator.detect_agent_switch(args.detect_switch)
            print(json.dumps(result))
            return 0

        # Validation
        if args.validate:
            result = generator.validate_handover(args.validate)
            print(json.dumps(result))
            return 0 if result["is_valid"] else 1

        # Integrity verification
        if args.verify_integrity:
            result = generator.verify_integrity(args.verify_integrity)
            print(json.dumps(result))
            return 0 if result["is_valid"] else 1

        # Batch generation
        if args.batch_generate and args.agents and args.output_dir:
            agents = [agent.strip() for agent in args.agents.split(",")]
            Path(args.output_dir).mkdir(parents=True, exist_ok=True)
            result = generator.batch_generate(agents, args.output_dir)
            print(json.dumps(result))
            return 0

        # Standard handover generation
        if args.from_agent and args.to_agent and args.output:
            handover = generator.create_handover_document(
                from_agent=args.from_agent,
                to_agent=args.to_agent,
                trace_id=args.trace_id,
                correlation_id=args.correlation_id,
                context=args.context,
                include_provenance=args.include_provenance,
                capture_state=args.capture_state,
                generate_ai_hints=args.generate_ai_hints,
                task_complexity=args.task_complexity,
                compress_context_data=args.compress_context,
                compression_ratio=args.compression_ratio,
                use_template=args.use_template
            )

            # Ensure output directory exists
            Path(args.output).parent.mkdir(parents=True, exist_ok=True)

            with open(args.output, 'w') as f:
                json.dump(handover, f, indent=2)

            return 0

        # No valid operation specified
        parser.print_help()
        return 1

    except Exception as e:
        print(json.dumps({"error": str(e)}), file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())