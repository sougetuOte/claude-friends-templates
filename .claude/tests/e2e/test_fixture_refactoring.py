#!/usr/bin/env python3
"""
E2E Test Suite: Fixture Refactoring Tests
Task 2.5.4 - Red Phase

Tests for shared fixture infrastructure refactoring
TDD Red Phase: Write failing tests first
"""

import ast
import os
import subprocess
from pathlib import Path

import pytest


class TestSharedFixture:
    """Test Suite for shared fixture functionality"""

    @pytest.mark.e2e
    def test_claude_workspace_has_all_scripts(self, claude_workspace):
        """
        Test 1: claude_workspace fixture includes all required scripts

        Expected: FAIL (conftest.py not created yet)
        """
        scripts_dir = claude_workspace / ".claude" / "scripts"

        required_scripts = [
            "agent-switch.sh",
            "handover-generator.py",
            "builder-startup.sh",
            "planner-startup.sh",
            "handover-lifecycle.sh",
            "state_synchronizer.py",
        ]

        for script in required_scripts:
            script_path = scripts_dir / script
            assert script_path.exists(), f"Missing script: {script}"

            # Bash scripts must be executable
            if script.endswith(".sh"):
                assert script_path.stat().st_mode & 0o111, f"{script} not executable"

    @pytest.mark.e2e
    def test_claude_workspace_has_directory_structure(self, claude_workspace):
        """
        Test 2: claude_workspace fixture creates complete directory structure

        Expected: FAIL (conftest.py not created yet)
        """
        required_dirs = [
            ".claude",
            ".claude/agents",
            ".claude/agents/planner",
            ".claude/agents/builder",
            ".claude/scripts",
            ".claude/logs",
            ".claude/states",
        ]

        for dir_path in required_dirs:
            full_path = claude_workspace / dir_path
            assert full_path.exists(), f"Missing directory: {dir_path}"
            assert full_path.is_dir(), f"{dir_path} is not a directory"

    @pytest.mark.e2e
    def test_claude_workspace_sets_environment(self, claude_workspace):
        """
        Test 3: claude_workspace fixture sets required environment variables

        Expected: FAIL (conftest.py not created yet)
        """
        assert "CLAUDE_PROJECT_DIR" in os.environ
        assert os.environ["CLAUDE_PROJECT_DIR"] == str(claude_workspace)
        assert "CLAUDE_AGENT" in os.environ
        assert os.environ["CLAUDE_AGENT"] in ["planner", "builder"]

    @pytest.mark.e2e
    def test_script_loader_imports_hyphenated_files(self, claude_workspace):
        """
        Test 4: script_loader can import hyphenated Python files

        Expected: FAIL (script_loader.py not created)
        """
        # Import script_loader from test directory
        import sys

        test_dir = Path(__file__).parent
        sys.path.insert(0, str(test_dir))

        try:
            from script_loader import load_script_module

            script_path = (
                claude_workspace / ".claude" / "scripts" / "handover-generator.py"
            )

            # Should not raise ImportError
            module = load_script_module(script_path, "handover_generator")

            # Verify module loaded
            assert hasattr(module, "HandoverGenerator")
        finally:
            sys.path.remove(str(test_dir))

    @pytest.mark.e2e
    def test_suite_b_uses_shared_fixture(self, claude_workspace):
        """
        Test 5: Suite B (State Sync) can use shared fixture

        Expected: FAIL initially, PASS after Green Phase
        """
        # Verify state_synchronizer.py available
        sync_script = claude_workspace / ".claude" / "scripts" / "state_synchronizer.py"
        assert sync_script.exists(), "state_synchronizer.py not copied"

        # Load module using script_loader
        import sys

        test_dir = Path(__file__).parent
        sys.path.insert(0, str(test_dir))

        try:
            from script_loader import load_script_module

            state_sync = load_script_module(sync_script, "state_synchronizer")

            # Create synchronizer
            sync = state_sync.StateSynchronizer(
                state_dir=str(claude_workspace / ".claude" / "states")
            )

            # Test basic operation
            result = sync.save_state("planner", {"test": "data"})
            assert result["success"] == True

            # Verify state file created
            state_file = (
                claude_workspace / ".claude" / "states" / "planner" / "current.json"
            )
            assert state_file.exists()
        finally:
            sys.path.remove(str(test_dir))


class TestFixtureCodeReduction:
    """Test that fixture code is properly centralized"""

    @pytest.mark.e2e
    def test_fixture_code_reduced_in_suite_files(self):
        """
        Test 6: Individual test suites no longer duplicate fixture code

        Expected: FAIL (suites not refactored yet)
        """
        suite_files = [
            Path(".claude/tests/e2e/test_e2e_normal_flow.py"),
            Path(".claude/tests/e2e/test_e2e_state_sync.py"),
            Path(".claude/tests/e2e/test_e2e_error_scenarios.py"),
        ]

        for suite_file in suite_files:
            if not suite_file.exists():
                pytest.skip(f"{suite_file.name} not found")

            with open(suite_file) as f:
                tree = ast.parse(f.read())

            # Count test_workspace fixture definitions
            fixture_count = 0
            for node in ast.walk(tree):
                if isinstance(node, ast.FunctionDef):
                    if node.name == "test_workspace":
                        # Check if it has @pytest.fixture decorator
                        for dec in node.decorator_list:
                            if isinstance(dec, ast.Call):
                                if (
                                    isinstance(dec.func, ast.Attribute)
                                    and dec.func.attr == "fixture"
                                ):
                                    fixture_count += 1
                            elif (
                                isinstance(dec, ast.Attribute) and dec.attr == "fixture"
                            ):
                                fixture_count += 1

            assert (
                fixture_count == 0
            ), f"{suite_file.name} still has {fixture_count} test_workspace fixtures (should use claude_workspace from conftest.py)"

    @pytest.mark.e2e
    def test_conftest_exists(self):
        """
        Test 7: conftest.py exists with shared fixtures

        Expected: FAIL (conftest.py not created)
        """
        conftest_path = Path(".claude/tests/e2e/conftest.py")
        assert conftest_path.exists(), "conftest.py not created"

        # Verify it defines claude_workspace fixture
        with open(conftest_path) as f:
            content = f.read()

        assert "def claude_workspace" in content, "claude_workspace fixture not defined"
        assert (
            "@pytest.fixture" in content
        ), "claude_workspace not decorated with @pytest.fixture"


class TestBashTestHelper:
    """Test Bash test helper functionality"""

    @pytest.mark.e2e
    def test_bash_helper_exists(self):
        """
        Test 8: test_helper.bash exists

        Expected: FAIL (test_helper.bash not created)
        """
        helper_path = Path(".claude/tests/e2e/test_helper.bash")
        assert helper_path.exists(), "test_helper.bash not created"

        # Verify it's executable
        assert helper_path.stat().st_mode & 0o111, "test_helper.bash not executable"

    @pytest.mark.e2e
    def test_bash_helper_has_required_functions(self):
        """
        Test 9: test_helper.bash defines required functions

        Expected: FAIL (test_helper.bash not created or incomplete)
        """
        helper_path = Path(".claude/tests/e2e/test_helper.bash")
        if not helper_path.exists():
            pytest.skip("test_helper.bash not created yet")

        with open(helper_path) as f:
            content = f.read()

        required_functions = [
            "setup_test_workspace",
            "cleanup_test_workspace",
            "count_handovers",
            "load_latest_handover",
            "validate_handover_json",
        ]

        for func in required_functions:
            assert (
                f"{func}()" in content or f"function {func}" in content
            ), f"Function {func} not defined in test_helper.bash"

    @pytest.mark.e2e
    def test_bash_helper_functions_work(self, tmp_path):
        """
        Test 10: test_helper.bash functions execute successfully

        Expected: FAIL (functions not implemented or buggy)
        """
        test_script = f"""
#!/usr/bin/env bash
# Mock BATS environment
export BATS_TEST_TMPDIR="{tmp_path}"

source "$(dirname "$0")/test_helper.bash"

# Test setup_test_workspace
setup_test_workspace
[ -d "$TEST_DIR/.claude/agents/planner" ] || exit 1
[ -d "$TEST_DIR/.claude/scripts" ] || exit 2

# Test count_handovers (should be 0 initially)
count=$(count_handovers)
[ "$count" -eq 0 ] || exit 3

# Test cleanup
cleanup_test_workspace
[ ! -d "$TEST_DIR" ] || exit 4

exit 0
"""

        # Write temporary test script
        test_dir = Path(".claude/tests/e2e")
        test_script_path = test_dir / "test_helper_validation.sh"
        test_script_path.write_text(test_script)
        test_script_path.chmod(0o755)

        try:
            # Execute test (use absolute path)
            result = subprocess.run(
                ["bash", str(test_script_path.absolute())],
                cwd=test_dir.absolute(),
                capture_output=True,
                text=True,
                timeout=10,
            )

            assert (
                result.returncode == 0
            ), f"test_helper.bash validation failed: stdout={result.stdout}, stderr={result.stderr}"
        finally:
            # Cleanup
            if test_script_path.exists():
                test_script_path.unlink()


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
