#!/usr/bin/env python3
"""
Shared pytest fixtures for E2E tests
Task 2.5.4 - Green Phase

Provides:
- claude_workspace: Fully isolated test workspace with automatic script setup
- Automatic cleanup after tests
- Environment variable management
"""

import os
import shutil
from pathlib import Path

import pytest


@pytest.fixture(scope="function")
def claude_workspace(tmp_path):
    """
    Fully isolated Claude workspace with all scripts pre-installed

    Creates complete .claude/ directory structure with:
    - All Python scripts from .claude/scripts/ automatically copied
    - All Bash scripts copied and made executable
    - Initial agent notes files
    - Environment variables configured
    - Automatic cleanup after test

    Args:
        tmp_path: pytest tmp_path fixture (temporary directory)

    Returns:
        Path: Workspace root directory

    Example:
        def test_my_feature(claude_workspace):
            script = claude_workspace / ".claude" / "scripts" / "agent-switch.sh"
            assert script.exists()
    """
    # Create workspace root
    workspace = tmp_path / "test_workspace"
    workspace.mkdir()

    # Create .claude directory structure
    claude_dir = workspace / ".claude"
    claude_dir.mkdir()

    # Create subdirectories
    (claude_dir / "agents" / "planner").mkdir(parents=True)
    (claude_dir / "agents" / "builder").mkdir(parents=True)
    (claude_dir / "scripts").mkdir()
    (claude_dir / "logs").mkdir()
    (claude_dir / "states").mkdir()
    (claude_dir / "shared").mkdir()  # For shared files like phase-todo.md

    # Create initial agent notes
    planner_notes = claude_dir / "agents" / "planner" / "notes.md"
    planner_notes.write_text("# Planner Notes\n\n## Current Task: Test\n")

    builder_notes = claude_dir / "agents" / "builder" / "notes.md"
    builder_notes.write_text("# Builder Notes\n\n## Current Task: Test\n")

    # Automatic script copying from .claude/scripts/
    # This eliminates manual shutil.copy() in every test
    scripts_src = Path(__file__).parent.parent.parent / "scripts"

    if scripts_src.exists():
        # Copy Python scripts
        for script_file in scripts_src.glob("*.py"):
            dest = claude_dir / "scripts" / script_file.name
            shutil.copy(script_file, dest)

        # Copy Bash scripts and make executable
        for script_file in scripts_src.glob("*.sh"):
            dest = claude_dir / "scripts" / script_file.name
            shutil.copy(script_file, dest)
            dest.chmod(0o755)  # Make executable

    # Set environment variables for test isolation
    os.environ["CLAUDE_PROJECT_DIR"] = str(workspace)
    os.environ["CLAUDE_AGENT"] = "planner"

    # Yield workspace to test
    yield workspace

    # Automatic cleanup
    if "CLAUDE_PROJECT_DIR" in os.environ:
        del os.environ["CLAUDE_PROJECT_DIR"]
    if "CLAUDE_AGENT" in os.environ:
        del os.environ["CLAUDE_AGENT"]
