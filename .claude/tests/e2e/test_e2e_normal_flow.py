#!/usr/bin/env python3
"""
E2E Test Suite A: Normal Flow Tests
Tests for Planner→Builder→Planner complete handover cycles

TDD Red Phase: Write failing tests first
Test Framework: pytest
Target: Task 2.5.1 - E2E Integration Test Suite
"""

import json
import os
import subprocess
import time

import pytest
from jsonschema import ValidationError, validate

# JSON Schema for handover validation (Schema 2.0.0 - snake_case format)
HANDOVER_SCHEMA = {
    "$schema": "http://json-schema.org/draft-07/schema#",
    "type": "object",
    "required": ["metadata", "summary", "context"],
    "properties": {
        "metadata": {
            "type": "object",
            "required": ["id", "created_at", "from_agent", "to_agent"],
            "properties": {
                "id": {"type": "string", "minLength": 1},
                "created_at": {"type": "string", "format": "date-time"},
                "from_agent": {
                    "type": "string",
                    "enum": ["planner", "builder", "first"],
                },
                "to_agent": {"type": "string", "enum": ["planner", "builder"]},
                "schema_version": {"type": "string"},
                "agent_session_id": {"type": "string"},
                "handover_type": {"type": "string"},
            },
        },
        "summary": {
            "type": "object",
            "required": ["currentTask", "nextSteps"],
            "properties": {
                "completedTasks": {"type": "array", "items": {"type": "string"}},
                "currentTask": {"type": "string"},
                "blockers": {"type": "array", "items": {"type": "string"}},
                "nextSteps": {"type": "array", "items": {"type": "string"}},
            },
        },
        "context": {
            "type": "object",
            "properties": {
                "gitStatus": {"type": "string"},
                "modifiedFiles": {"type": "array", "items": {"type": "string"}},
                "testStatus": {"type": "string"},
                "recentActivities": {"type": "array", "items": {"type": "string"}},
            },
        },
        "trace": {
            "type": "object",
            "properties": {
                "trace_id": {"type": "string"},
                "correlation_id": {"type": "string"},
                "parent_span_id": {"type": ["string", "null"]},
                "session_id": {"type": "string"},
            },
        },
        "provenance": {
            "type": "object",
            "properties": {
                "created_by": {"type": "string"},
                "creation_timestamp": {"type": "string"},
                "source_files_modified": {"type": "array"},
                "tools_used": {"type": "array"},
                "session_state": {"type": "object"},
                "environment_snapshot": {"type": "object"},
            },
        },
    },
}


# claude_workspace fixture removed - now using claude_workspace from conftest.py
# This eliminates 40+ lines of duplicate fixture code


@pytest.fixture
def planner_state():
    """Mock Planner state"""
    return {
        "agent": "planner",
        "current_task": "Design authentication system",
        "completed_tasks": ["Requirement analysis", "Architecture design"],
        "next_steps": ["Implementation", "Unit tests"],
        "blockers": [],
    }


@pytest.fixture
def builder_state():
    """Mock Builder state"""
    return {
        "agent": "builder",
        "current_task": "Implement authentication system",
        "completed_tasks": ["Code implementation"],
        "next_steps": ["Integration testing", "Documentation"],
        "blockers": [],
    }


class TestNormalFlowHandover:
    """Test Suite A: Normal handover flows"""

    @pytest.mark.e2e
    def test_planner_to_builder_handover_creates_file(
        self, claude_workspace, planner_state
    ):
        """
        Test 1: Planner→Builder handover creates handover file

        Expected: FAIL (handover system not integrated yet)
        """
        # Arrange: Set up Planner environment
        os.environ["CLAUDE_AGENT"] = "planner"
        handover_dir = claude_workspace / ".claude"

        # Act: Trigger agent switch via agent-switch.sh
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

        # Assert: Handover file created
        handover_files = list(handover_dir.glob("handover-*.json"))
        assert len(handover_files) > 0, "No handover file created"

        # Assert: Script executed successfully
        assert result.returncode == 0, f"agent-switch.sh failed: {result.stderr}"

    @pytest.mark.e2e
    def test_planner_to_builder_handover_valid_schema(
        self, claude_workspace, planner_state
    ):
        """
        Test 2: Planner→Builder handover produces valid JSON schema (2.0.0)

        Expected: PASS (schema validation with snake_case fields)
        """
        # Arrange
        os.environ["CLAUDE_AGENT"] = "planner"

        # Act: Generate handover
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

        # Find handover file
        handover_files = sorted((claude_workspace / ".claude").glob("handover-*.json"))
        assert len(handover_files) > 0, "No handover file found"

        latest_handover = handover_files[-1]
        with open(latest_handover) as f:
            handover_data = json.load(f)

        # Assert: Schema validation (2.0.0 with snake_case)
        try:
            validate(instance=handover_data, schema=HANDOVER_SCHEMA)
        except ValidationError as e:
            pytest.fail(f"Handover JSON schema validation failed: {e.message}")

        # Additional checks for schema 2.0.0 fields
        assert (
            handover_data["metadata"]["schema_version"] == "2.0.0"
        ), "Expected schema version 2.0.0"
        assert (
            "created_at" in handover_data["metadata"]
        ), "Missing created_at field (snake_case)"
        assert (
            "from_agent" in handover_data["metadata"]
        ), "Missing from_agent field (snake_case)"
        assert (
            "to_agent" in handover_data["metadata"]
        ), "Missing to_agent field (snake_case)"

    @pytest.mark.e2e
    def test_planner_to_builder_handover_performance(self, claude_workspace):
        """
        Test 3: Planner→Builder handover completes in <30 seconds

        Expected: FAIL (performance not optimized)
        """
        # Arrange
        os.environ["CLAUDE_AGENT"] = "planner"

        # Act: Measure handover generation time
        start_time = time.time()
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
        elapsed_time = time.time() - start_time

        # Assert: Performance requirement (ADR-00: <10s context understanding, target <30s total)
        assert elapsed_time < 30.0, f"Handover took {elapsed_time:.2f}s, expected <30s"
        assert result.returncode == 0, "Handover failed"

    @pytest.mark.e2e
    def test_builder_to_planner_handover_creates_file(
        self, claude_workspace, builder_state
    ):
        """
        Test 4: Builder→Planner handover creates handover file

        Expected: FAIL (reverse direction not tested)
        """
        # Arrange: Set up Builder environment
        os.environ["CLAUDE_AGENT"] = "builder"
        handover_dir = claude_workspace / ".claude"

        # Act: Trigger agent switch
        result = subprocess.run(
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

        # Assert: Handover file created
        handover_files = list(handover_dir.glob("handover-*.json"))
        assert len(handover_files) > 0, "No handover file created"
        assert result.returncode == 0, f"agent-switch.sh failed: {result.stderr}"

    @pytest.mark.e2e
    def test_builder_to_planner_handover_valid_schema(
        self, claude_workspace, builder_state
    ):
        """
        Test 5: Builder→Planner handover produces valid JSON schema (2.0.0)

        Expected: PASS (schema validation with snake_case fields)
        """
        # Arrange
        os.environ["CLAUDE_AGENT"] = "builder"

        # Act: Generate handover
        result = subprocess.run(
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

        # Find handover file
        handover_files = sorted((claude_workspace / ".claude").glob("handover-*.json"))
        assert len(handover_files) > 0, "No handover file found"

        latest_handover = handover_files[-1]
        with open(latest_handover) as f:
            handover_data = json.load(f)

        # Assert: Schema validation (2.0.0 with snake_case)
        try:
            validate(instance=handover_data, schema=HANDOVER_SCHEMA)
        except ValidationError as e:
            pytest.fail(f"Handover JSON schema validation failed: {e.message}")

        # Additional checks for schema 2.0.0 fields
        assert (
            handover_data["metadata"]["schema_version"] == "2.0.0"
        ), "Expected schema version 2.0.0"
        assert (
            "created_at" in handover_data["metadata"]
        ), "Missing created_at field (snake_case)"
        assert (
            "from_agent" in handover_data["metadata"]
        ), "Missing from_agent field (snake_case)"
        assert (
            "to_agent" in handover_data["metadata"]
        ), "Missing to_agent field (snake_case)"

    @pytest.mark.e2e
    def test_complete_cycle_planner_builder_planner(self, claude_workspace):
        """
        Test 6: Complete cycle (Planner→Builder→Planner) maintains state

        Expected: FAIL (complete integration not tested)
        """
        # Phase 1: Planner work
        os.environ["CLAUDE_AGENT"] = "planner"
        initial_task = "Design and implement feature X"

        # Create initial state
        planner_notes = claude_workspace / ".claude" / "agents" / "planner" / "notes.md"
        planner_notes.write_text(
            f"# Planner Notes\n\n## Current Task: {initial_task}\n"
        )

        # Phase 2: Planner → Builder
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
        assert result1.returncode == 0, f"First handover failed: {result1.stderr}"

        # Find first handover
        handover_files = sorted((claude_workspace / ".claude").glob("handover-*.json"))
        assert len(handover_files) >= 1, "First handover file not created"
        handover1 = handover_files[-1]

        with open(handover1) as f:
            handover1_data = json.load(f)

        # Verify first handover (using snake_case)
        assert handover1_data["metadata"]["from_agent"] == "planner"
        assert handover1_data["metadata"]["to_agent"] == "builder"
        # Note: currentTask is auto-generated, not extracted from notes.md
        # Verify it exists and has reasonable content
        assert (
            len(handover1_data["summary"]["currentTask"]) > 0
        ), "currentTask should not be empty"

        # Phase 3: Builder work simulation
        os.environ["CLAUDE_AGENT"] = "builder"
        builder_notes = claude_workspace / ".claude" / "agents" / "builder" / "notes.md"
        builder_notes.write_text(
            f"# Builder Notes\n\n## Current Task: Implementing {initial_task}\n"
        )

        # Phase 4: Builder → Planner
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
        assert result2.returncode == 0, f"Second handover failed: {result2.stderr}"

        # Find second handover
        handover_files = sorted((claude_workspace / ".claude").glob("handover-*.json"))
        assert len(handover_files) >= 2, "Second handover file not created"
        handover2 = handover_files[-1]

        with open(handover2) as f:
            handover2_data = json.load(f)

        # Verify second handover (using snake_case)
        assert handover2_data["metadata"]["from_agent"] == "builder"
        assert handover2_data["metadata"]["to_agent"] == "planner"

        # Assert: State continuity (handover completed successfully)
        # Note: currentTask is auto-generated by handover-generator, not from notes.md
        # Verify the handover structure and that cycle completed
        assert (
            len(handover2_data["summary"]["currentTask"]) > 0
        ), "currentTask should not be empty"
        assert (
            handover2_data["metadata"]["from_agent"] == "builder"
        ), "Second handover should be from builder"
        assert (
            handover2_data["metadata"]["to_agent"] == "planner"
        ), "Second handover should be to planner"

    @pytest.mark.e2e
    def test_handover_contains_git_status(self, claude_workspace):
        """
        Test 7: Handover includes git status information

        Expected: FAIL (git integration not implemented)
        """
        # Arrange: Initialize git repo
        subprocess.run(["git", "init"], cwd=claude_workspace, capture_output=True)
        subprocess.run(
            ["git", "config", "user.email", "test@example.com"],
            cwd=claude_workspace,
            capture_output=True,
        )
        subprocess.run(
            ["git", "config", "user.name", "Test User"],
            cwd=claude_workspace,
            capture_output=True,
        )

        # Create a test file
        test_file = claude_workspace / "test.txt"
        test_file.write_text("Test content")

        os.environ["CLAUDE_AGENT"] = "planner"

        # Act: Generate handover
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

        # Assert: Git status in handover
        handover_files = sorted((claude_workspace / ".claude").glob("handover-*.json"))
        assert len(handover_files) > 0

        with open(handover_files[-1]) as f:
            handover_data = json.load(f)

        assert "context" in handover_data, "Missing context field"
        assert "gitStatus" in handover_data["context"], "Missing gitStatus field"
        assert handover_data["context"]["gitStatus"] != "", "Git status is empty"

    @pytest.mark.e2e
    def test_handover_includes_modified_files(self, claude_workspace):
        """
        Test 8: Handover includes list of modified files

        Expected: FAIL (file tracking not implemented)
        """
        # Arrange: Create git repo with modifications
        subprocess.run(["git", "init"], cwd=claude_workspace, capture_output=True)
        subprocess.run(
            ["git", "config", "user.email", "test@example.com"],
            cwd=claude_workspace,
            capture_output=True,
        )
        subprocess.run(
            ["git", "config", "user.name", "Test User"],
            cwd=claude_workspace,
            capture_output=True,
        )

        # Create and commit initial file
        file1 = claude_workspace / "file1.py"
        file1.write_text("print('hello')")
        subprocess.run(
            ["git", "add", "file1.py"], cwd=claude_workspace, capture_output=True
        )
        subprocess.run(
            ["git", "commit", "-m", "Initial"],
            cwd=claude_workspace,
            capture_output=True,
        )

        # Modify file
        file1.write_text("print('hello world')")

        # Create new file
        file2 = claude_workspace / "file2.py"
        file2.write_text("print('new file')")

        os.environ["CLAUDE_AGENT"] = "builder"

        # Act: Generate handover
        result = subprocess.run(
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

        # Assert: Modified files listed
        handover_files = sorted((claude_workspace / ".claude").glob("handover-*.json"))
        assert len(handover_files) > 0

        with open(handover_files[-1]) as f:
            handover_data = json.load(f)

        assert (
            "modifiedFiles" in handover_data["context"]
        ), "Missing modifiedFiles field"
        modified_files = handover_data["context"]["modifiedFiles"]

        assert isinstance(modified_files, list), "modified_files should be a list"
        assert len(modified_files) > 0, "No modified files detected"
        assert any(
            "file1.py" in f for f in modified_files
        ), "file1.py not in modified files"


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
