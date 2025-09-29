#!/usr/bin/env python3

"""
Handover Generator Tests
Following t-wada TDD methodology - Red Phase
Tests for agent handover system following 2025 best practices

Based on 2025 best practices:
- API-oriented handoffs with versioned schemas
- Provenance and state preservation
- Context preservation with trace IDs
- Event-driven multi-agent coordination
- Full observability and monitoring
"""

import unittest
import json
import tempfile
import shutil
from pathlib import Path
import uuid
from datetime import datetime, timezone
import subprocess
import os

# Add project root to path for imports
import sys
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))


class TestHandoverGenerator(unittest.TestCase):
    """Test suite for agent handover generation system"""

    def setUp(self):
        """Set up test environment"""
        self.project_root = Path(__file__).parent.parent.parent.parent
        self.test_dir = tempfile.mkdtemp()
        self.handover_script = self.project_root / ".claude" / "scripts" / "handover-generator.py"
        self.agent_switch_script = self.project_root / ".claude" / "hooks" / "agent-switch.sh"
        self.handover_dir = Path(self.test_dir) / ".claude" / "handover"
        self.handover_dir.mkdir(parents=True, exist_ok=True)

    def tearDown(self):
        """Clean up test environment"""
        if os.path.exists(self.test_dir):
            shutil.rmtree(self.test_dir)

    def test_handover_generator_script_exists(self):
        """Test 1: Handover generator script exists"""
        self.assertTrue(
            self.handover_script.exists(),
            f"Handover generator script should exist at {self.handover_script}"
        )

    def test_handover_generator_script_is_executable(self):
        """Test 2: Handover generator script is executable"""
        self.assertTrue(
            os.access(self.handover_script, os.X_OK),
            "Handover generator script should be executable"
        )

    def test_agent_switch_hook_exists(self):
        """Test 3: Agent switch hook exists"""
        self.assertTrue(
            self.agent_switch_script.exists(),
            f"Agent switch hook should exist at {self.agent_switch_script}"
        )

    def test_agent_switch_detection(self):
        """Test 4: Agent switch detection from command"""
        # Create sample prompt file with agent switch command
        prompt_content = """
        Please continue with the implementation.
        /agent:builder
        """
        prompt_file = Path(self.test_dir) / "prompt.txt"
        with open(prompt_file, 'w') as f:
            f.write(prompt_content)

        # Test agent switch detection
        result = subprocess.run([
            "python", str(self.handover_script),
            "--detect-switch", str(prompt_file)
        ], capture_output=True, text=True)

        self.assertEqual(result.returncode, 0,
                        f"Agent switch detection should succeed. stderr: {result.stderr}")

        output = json.loads(result.stdout)
        self.assertEqual(output["target_agent"], "builder")

    def test_handover_document_generation_versioned_schema(self):
        """Test 5: Handover document generation with versioned schema (2025 best practice)"""
        # Generate handover from builder to planner
        result = subprocess.run([
            "python", str(self.handover_script),
            "--from-agent", "builder",
            "--to-agent", "planner",
            "--output", str(self.handover_dir / "test_handover.json")
        ], capture_output=True, text=True)

        self.assertEqual(result.returncode, 0,
                        f"Handover generation should succeed. stderr: {result.stderr}")

        # Validate generated handover document
        handover_file = self.handover_dir / "test_handover.json"
        self.assertTrue(handover_file.exists(), "Handover file should be generated")

        with open(handover_file, 'r') as f:
            handover = json.load(f)

        # Validate versioned schema structure (2025 best practice)
        required_sections = [
            "schema_version",
            "metadata",
            "provenance",
            "context",
            "state_snapshot",
            "trace_info",
            "summary",
            "ai_hints"
        ]

        for section in required_sections:
            self.assertIn(section, handover,
                         f"Handover should contain '{section}' section")

        # Validate schema version
        self.assertEqual(handover["schema_version"], "2.0.0",
                        "Should use 2025 handover schema version")

    def test_context_preservation_with_trace_ids(self):
        """Test 6: Context preservation with trace IDs (2025 best practice)"""
        trace_id = str(uuid.uuid4())
        correlation_id = str(uuid.uuid4())

        result = subprocess.run([
            "python", str(self.handover_script),
            "--from-agent", "planner",
            "--to-agent", "builder",
            "--trace-id", trace_id,
            "--correlation-id", correlation_id,
            "--context", "implement_authentication_system",
            "--output", str(self.handover_dir / "context_test.json")
        ], capture_output=True, text=True)

        self.assertEqual(result.returncode, 0,
                        f"Context preservation should succeed. stderr: {result.stderr}")

        with open(self.handover_dir / "context_test.json", 'r') as f:
            handover = json.load(f)

        # Validate trace information preservation
        self.assertEqual(handover["trace_info"]["trace_id"], trace_id)
        self.assertEqual(handover["trace_info"]["correlation_id"], correlation_id)
        self.assertIn("implement_authentication_system", handover["context"]["task_description"])

    def test_provenance_tracking(self):
        """Test 7: Provenance tracking (2025 best practice)"""
        result = subprocess.run([
            "python", str(self.handover_script),
            "--from-agent", "builder",
            "--to-agent", "planner",
            "--include-provenance",
            "--output", str(self.handover_dir / "provenance_test.json")
        ], capture_output=True, text=True)

        self.assertEqual(result.returncode, 0,
                        f"Provenance tracking should succeed. stderr: {result.stderr}")

        with open(self.handover_dir / "provenance_test.json", 'r') as f:
            handover = json.load(f)

        # Validate provenance information
        provenance = handover["provenance"]
        required_provenance_fields = [
            "created_by",
            "creation_timestamp",
            "source_files_modified",
            "tools_used",
            "session_state",
            "environment_snapshot"
        ]

        for field in required_provenance_fields:
            self.assertIn(field, provenance,
                         f"Provenance should contain '{field}' field")

    def test_state_snapshot_capture(self):
        """Test 8: State snapshot capture"""
        result = subprocess.run([
            "python", str(self.handover_script),
            "--from-agent", "builder",
            "--to-agent", "planner",
            "--capture-state",
            "--output", str(self.handover_dir / "state_test.json")
        ], capture_output=True, text=True)

        self.assertEqual(result.returncode, 0,
                        f"State capture should succeed. stderr: {result.stderr}")

        with open(self.handover_dir / "state_test.json", 'r') as f:
            handover = json.load(f)

        # Validate state snapshot
        state = handover["state_snapshot"]
        required_state_fields = [
            "git_status",
            "current_branch",
            "modified_files",
            "test_status",
            "task_progress",
            "environment_vars",
            "active_tools"
        ]

        for field in required_state_fields:
            self.assertIn(field, state,
                         f"State snapshot should contain '{field}' field")

    def test_ai_hints_generation(self):
        """Test 9: AI hints generation for receiving agent"""
        result = subprocess.run([
            "python", str(self.handover_script),
            "--from-agent", "planner",
            "--to-agent", "builder",
            "--generate-ai-hints",
            "--task-complexity", "high",
            "--output", str(self.handover_dir / "ai_hints_test.json")
        ], capture_output=True, text=True)

        self.assertEqual(result.returncode, 0,
                        f"AI hints generation should succeed. stderr: {result.stderr}")

        with open(self.handover_dir / "ai_hints_test.json", 'r') as f:
            handover = json.load(f)

        # Validate AI hints
        ai_hints = handover["ai_hints"]
        required_hint_fields = [
            "priority",
            "complexity_level",
            "suggested_approach",
            "potential_blockers",
            "debugging_hints",
            "performance_considerations",
            "security_notes"
        ]

        for field in required_hint_fields:
            self.assertIn(field, ai_hints,
                         f"AI hints should contain '{field}' field")

        self.assertEqual(ai_hints["complexity_level"], "high")

    def test_handover_validation(self):
        """Test 10: Handover document validation"""
        # Create invalid handover
        invalid_handover = {
            "schema_version": "1.0.0",  # Old version
            "metadata": {},
            # Missing required fields
        }

        invalid_file = self.handover_dir / "invalid.json"
        with open(invalid_file, 'w') as f:
            json.dump(invalid_handover, f)

        result = subprocess.run([
            "python", str(self.handover_script),
            "--validate", str(invalid_file)
        ], capture_output=True, text=True)

        self.assertNotEqual(result.returncode, 0,
                           "Invalid handover should fail validation")

    def test_handover_compression(self):
        """Test 11: Handover context compression for large contexts"""
        # Create large context
        large_context = {
            "large_data": ["item" + str(i) for i in range(1000)],
            "verbose_logs": "DEBUG: " * 500 + "Large log content"
        }

        large_context_file = self.handover_dir / "large_context.json"
        with open(large_context_file, 'w') as f:
            json.dump(large_context, f)

        result = subprocess.run([
            "python", str(self.handover_script),
            "--from-agent", "builder",
            "--to-agent", "planner",
            "--compress-context", str(large_context_file),
            "--compression-ratio", "0.3",
            "--output", str(self.handover_dir / "compressed_test.json")
        ], capture_output=True, text=True)

        self.assertEqual(result.returncode, 0,
                        f"Context compression should succeed. stderr: {result.stderr}")

        # Validate compression
        with open(self.handover_dir / "compressed_test.json", 'r') as f:
            handover = json.load(f)

        self.assertIn("compression_info", handover["context"])
        self.assertGreater(handover["context"]["compression_info"]["original_size"], 0)
        self.assertGreater(handover["context"]["compression_info"]["compressed_size"], 0)

    def test_batch_handover_generation(self):
        """Test 12: Batch handover generation for multiple agents"""
        agents = ["planner", "builder", "reviewer"]

        result = subprocess.run([
            "python", str(self.handover_script),
            "--batch-generate",
            "--agents", ",".join(agents),
            "--output-dir", str(self.handover_dir)
        ], capture_output=True, text=True)

        self.assertEqual(result.returncode, 0,
                        f"Batch handover generation should succeed. stderr: {result.stderr}")

        # Validate batch generation
        for agent in agents:
            handover_file = self.handover_dir / f"handover_{agent}.json"
            self.assertTrue(handover_file.exists(),
                           f"Handover file for {agent} should be generated")

    def test_handover_integrity_check(self):
        """Test 13: Handover integrity verification"""
        # Generate valid handover
        result = subprocess.run([
            "python", str(self.handover_script),
            "--from-agent", "builder",
            "--to-agent", "planner",
            "--output", str(self.handover_dir / "integrity_test.json")
        ], capture_output=True, text=True)

        self.assertEqual(result.returncode, 0)

        # Verify integrity
        result = subprocess.run([
            "python", str(self.handover_script),
            "--verify-integrity", str(self.handover_dir / "integrity_test.json")
        ], capture_output=True, text=True)

        self.assertEqual(result.returncode, 0,
                        f"Integrity verification should succeed. stderr: {result.stderr}")

        output = json.loads(result.stdout)
        self.assertTrue(output["is_valid"])
        self.assertIn("checksum", output)

    def test_agent_switch_hook_integration(self):
        """Test 14: Integration with agent switch hook"""
        # Create test prompt with agent switch
        prompt_content = "Continue with implementation\n/agent:planner"
        prompt_file = Path(self.test_dir) / "test_prompt.txt"
        with open(prompt_file, 'w') as f:
            f.write(prompt_content)

        # Set environment variables for hook
        env = os.environ.copy()
        env['CLAUDE_HANDOVER_DIR'] = str(self.handover_dir)
        env['CLAUDE_CURRENT_AGENT'] = 'builder'

        result = subprocess.run([
            "bash", str(self.agent_switch_script),
            str(prompt_file)
        ], capture_output=True, text=True, env=env)

        self.assertEqual(result.returncode, 0,
                        f"Agent switch hook should succeed. stderr: {result.stderr}")

        # Verify handover was generated
        latest_handover = self.handover_dir / "latest.json"
        self.assertTrue(latest_handover.exists(),
                       "Latest handover symlink should be created")

    def test_handover_template_system(self):
        """Test 15: Handover template system for different agent types"""
        agent_types = ["planner", "builder", "reviewer", "architect"]

        for agent_type in agent_types:
            result = subprocess.run([
                "python", str(self.handover_script),
                "--from-agent", agent_type,
                "--to-agent", "coordinator",
                "--use-template", agent_type,
                "--output", str(self.handover_dir / f"template_{agent_type}.json")
            ], capture_output=True, text=True)

            self.assertEqual(result.returncode, 0,
                            f"Template generation for {agent_type} should succeed. stderr: {result.stderr}")

            with open(self.handover_dir / f"template_{agent_type}.json", 'r') as f:
                handover = json.load(f)

            # Validate agent-specific template fields
            self.assertEqual(handover["metadata"]["source_agent_type"], agent_type)
            self.assertIn("agent_specific_context", handover["context"])

    def test_handover_dependencies_in_requirements(self):
        """Test 16: Handover system dependencies are in requirements.txt"""
        requirements_file = self.project_root / "requirements.txt"
        self.assertTrue(requirements_file.exists(), "requirements.txt should exist")

        with open(requirements_file, 'r') as f:
            requirements = f.read()

        # Check for required handover system packages
        required_packages = [
            "pydantic",  # For data validation
            "dataclasses-json",  # For JSON serialization
            "python-dotenv",  # Environment variable management
            "structlog",  # Structured logging
            "jsonschema"  # JSON schema validation
        ]

        for package in required_packages:
            self.assertIn(package, requirements.lower(),
                         f"requirements.txt should contain {package} for handover system")


if __name__ == '__main__':
    unittest.main()