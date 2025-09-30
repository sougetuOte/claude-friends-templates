#!/usr/bin/env python3

"""
Agent Handover Generator - OPTIMIZED VERSION
Performance improvements: 367ms → target <100ms (3.67x speedup)

Optimizations applied:
1. orjson for JSON parsing/serialization (2-10x faster)
2. Simplified test status check (avoid expensive pytest --collect-only)
3. Concurrent Git/test status gathering
4. Function caching for repeated operations
5. Reduced subprocess overhead

Benchmark: Target <100ms (from 367ms baseline)
"""

import argparse
import os
import re
import subprocess
import sys
import uuid
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from functools import cache
from pathlib import Path
from typing import Dict, Any, List, Optional
from dataclasses import dataclass, asdict

# Use orjson for faster JSON operations (2-10x speedup)
try:
    import orjson

    def json_dumps(obj, indent=False):
        """orjson wrapper"""
        option = orjson.OPT_INDENT_2 if indent else 0
        return orjson.dumps(obj, option=option).decode("utf-8")

    def json_loads(data):
        """orjson wrapper"""
        if isinstance(data, str):
            data = data.encode("utf-8")
        return orjson.loads(data)
except ImportError:
    # Fallback to standard json
    import json

    json_dumps = lambda obj, indent=False: json.dumps(obj, indent=2 if indent else None)
    json_loads = json.loads

# Constants
HANDOVER_SCHEMA_VERSION = "2.0.0"
SUPPORTED_AGENTS = ["planner", "builder", "reviewer", "architect", "coordinator"]
DEFAULT_COMPRESSION_RATIO = 0.3


@dataclass
class HandoverMetadata:
    """Handover metadata"""

    id: str
    schema_version: str
    created_at: str
    from_agent: str
    to_agent: str
    agent_session_id: str
    handover_type: str = "standard"


@dataclass
class TraceInfo:
    """Trace information"""

    trace_id: str
    correlation_id: str
    parent_span_id: Optional[str] = None
    session_id: Optional[str] = None


@dataclass
class ProvenanceInfo:
    """Provenance tracking"""

    created_by: str
    creation_timestamp: str
    source_files_modified: List[str]
    tools_used: List[str]
    session_state: Dict[str, Any]
    environment_snapshot: Dict[str, str]


class HandoverGeneratorOptimized:
    """Optimized agent handover generator"""

    def __init__(self):
        self.schema_version = HANDOVER_SCHEMA_VERSION
        self.project_root = Path(os.environ.get("CLAUDE_PROJECT_DIR", Path.cwd()))

    def detect_agent_switch(self, prompt_file: str) -> Dict[str, Any]:
        """Detect agent switch from prompt file"""
        prompt_path = Path(prompt_file)
        if not prompt_path.exists():
            return {"error": "Prompt file not found"}

        content = prompt_path.read_text()

        # Detect agent switch pattern
        agent_pattern = r"/agent:(planner|builder|reviewer|architect|first)"
        match = re.search(agent_pattern, content)

        if match:
            target_agent = match.group(1)
            if target_agent == "first":
                target_agent = "planner"

            return {
                "switch_detected": True,
                "target_agent": target_agent,
                "pattern_matched": match.group(0),
            }

        return {"switch_detected": False}

    def get_git_status(self) -> str:
        """Get git status (optimized with timeout)"""
        try:
            result = subprocess.run(
                ["git", "status", "--short"],
                capture_output=True,
                text=True,
                cwd=self.project_root,
                timeout=2,  # 2 second timeout
            )
            return result.stdout if result.returncode == 0 else "Not a git repository"
        except (subprocess.TimeoutExpired, Exception):
            return "git_unavailable"

    def get_test_status_fast(self) -> str:
        """
        Fast test status check - optimized version

        Instead of running pytest --collect-only (expensive),
        just check if test files exist
        """
        test_dirs = [
            self.project_root / ".claude" / "tests",
            self.project_root / "tests",
            self.project_root / "test",
        ]

        for test_dir in test_dirs:
            if test_dir.exists():
                # Check for any test files
                test_files = list(test_dir.glob("**/test_*.py")) + list(
                    test_dir.glob("**/*_test.py")
                )
                if test_files:
                    return f"tests_available ({len(test_files)} files)"

        return "no_tests"

    def gather_context_concurrent(self) -> Dict[str, Any]:
        """
        Gather Git status and test status concurrently

        Optimization: Run both operations in parallel using ThreadPoolExecutor
        Expected speedup: 1.5-2x (from ~0.237s to ~0.12-0.15s)
        """
        context = {}

        with ThreadPoolExecutor(max_workers=2) as executor:
            # Submit both tasks concurrently
            future_git = executor.submit(self.get_git_status)
            future_tests = executor.submit(self.get_test_status_fast)

            # Gather results
            context["git_status"] = future_git.result()
            context["test_status"] = future_tests.result()

        return context

    @cache
    def get_modified_files(self) -> List[str]:
        """Get modified files (cached for repeated calls)"""
        try:
            result = subprocess.run(
                ["git", "diff", "--name-only", "HEAD"],
                capture_output=True,
                text=True,
                cwd=self.project_root,
                timeout=2,
            )
            if result.returncode == 0:
                return [f.strip() for f in result.stdout.split("\n") if f.strip()]
            return []
        except Exception:
            return []

    def extract_recent_activities(self, agent: str) -> List[str]:
        """Extract recent activities from agent notes (optimized file reading)"""
        # Try new structure first
        notes_file = self.project_root / ".claude" / "agents" / agent / "notes.md"

        # Fallback to old structure
        if not notes_file.exists():
            notes_file = self.project_root / ".claude" / agent / "notes.md"

        if not notes_file.exists():
            return ["No recent activities found"]

        try:
            content = notes_file.read_text()

            # Extract recent activities section
            lines = content.split("\n")
            in_activities = False
            activities = []

            for line in lines:
                if "最近の活動" in line or "Recent Activities" in line:
                    in_activities = True
                    continue
                elif line.startswith("## ") and in_activities:
                    break
                elif in_activities and line.strip():
                    activities.append(line.strip())

            return activities[:10] if activities else ["No recent activities found"]
        except Exception:
            return ["Error reading activities"]

    def create_handover_document(
        self,
        from_agent: str,
        to_agent: str,
        session_id: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Create handover document (optimized version)"""

        # Generate IDs
        handover_id = str(uuid.uuid4())
        trace_id = str(uuid.uuid4())
        correlation_id = str(uuid.uuid4())
        session_id = session_id or str(uuid.uuid4())

        # Metadata
        metadata = HandoverMetadata(
            id=handover_id,
            schema_version=self.schema_version,
            created_at=datetime.now(timezone.utc).isoformat(),
            from_agent=from_agent,
            to_agent=to_agent,
            agent_session_id=session_id,
            handover_type="standard",
        )

        # Trace info
        trace_info = TraceInfo(
            trace_id=trace_id,
            correlation_id=correlation_id,
            parent_span_id=None,
            session_id=session_id,
        )

        # Gather context concurrently (OPTIMIZATION: parallel execution)
        context_data = self.gather_context_concurrent()

        # Get modified files (cached)
        modified_files = self.get_modified_files()

        # Extract activities
        from_agent_activities = self.extract_recent_activities(from_agent)

        # Summary
        summary = {
            "completedTasks": from_agent_activities[:5],
            "currentTask": f"Handover from {from_agent} to {to_agent}",
            "blockers": [],
            "nextSteps": [
                f"{to_agent.capitalize()} agent to continue work",
                "Review recent activities",
                "Check modified files",
            ],
        }

        # Context
        context = {
            "gitStatus": context_data.get("git_status", "unknown"),
            "modifiedFiles": modified_files,
            "testStatus": context_data.get("test_status", "unknown"),
            "recentActivities": from_agent_activities,
        }

        # Provenance
        provenance = ProvenanceInfo(
            created_by=from_agent,
            creation_timestamp=datetime.now(timezone.utc).isoformat(),
            source_files_modified=modified_files,
            tools_used=["handover-generator-optimized"],
            session_state={"agent": from_agent, "session_id": session_id},
            environment_snapshot={
                "pwd": str(self.project_root),
                "python_version": f"{sys.version_info.major}.{sys.version_info.minor}",
            },
        )

        # Build handover document
        handover_doc = {
            "metadata": asdict(metadata),
            "trace": asdict(trace_info),
            "summary": summary,
            "context": context,
            "provenance": asdict(provenance),
        }

        return handover_doc

    def save_handover(self, handover_doc: Dict[str, Any]) -> Path:
        """Save handover document (using orjson for speed)"""
        claude_dir = self.project_root / ".claude"
        claude_dir.mkdir(parents=True, exist_ok=True)

        # Generate filename with timestamp
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        counter = os.getpid() % 100  # Use process ID for uniqueness
        filename = f"handover-{timestamp}-{counter:02d}.json"
        handover_path = claude_dir / filename

        # Write with orjson (faster serialization)
        handover_json = json_dumps(handover_doc, indent=True)
        handover_path.write_text(handover_json)

        return handover_path


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="Optimized Agent Handover Generator")
    parser.add_argument(
        "--from-agent",
        required=True,
        choices=SUPPORTED_AGENTS + ["first"],
        help="Source agent name",
    )
    parser.add_argument(
        "--to-agent",
        required=True,
        choices=SUPPORTED_AGENTS,
        help="Target agent name",
    )
    parser.add_argument(
        "--session-id",
        help="Session ID for tracking",
    )

    args = parser.parse_args()

    # Create generator
    generator = HandoverGeneratorOptimized()

    # Handle 'first' agent
    from_agent = "planner" if args.from_agent == "first" else args.from_agent

    # Create handover
    handover_doc = generator.create_handover_document(
        from_agent=from_agent,
        to_agent=args.to_agent,
        session_id=args.session_id,
    )

    # Save handover
    handover_path = generator.save_handover(handover_doc)

    print(f"Handover file created: {handover_path}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
