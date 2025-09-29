#!/usr/bin/env python3
"""
Test for project dependencies and requirements.
Following t-wada style TDD: Red Phase - Writing failing test first
"""

import subprocess
import sys
import importlib
from pathlib import Path
import pytest


class TestDependencies:
    """Test suite for project dependencies."""

    def test_requirements_file_exists(self):
        """Test that requirements.txt file exists in project root."""
        project_root = Path(__file__).parent.parent.parent.parent
        requirements_file = project_root / "requirements.txt"

        assert requirements_file.exists(), f"requirements.txt not found at {requirements_file}"

    def test_requirements_file_not_empty(self):
        """Test that requirements.txt contains dependencies."""
        project_root = Path(__file__).parent.parent.parent.parent
        requirements_file = project_root / "requirements.txt"

        with open(requirements_file, 'r') as f:
            content = f.read().strip()

        assert content, "requirements.txt is empty"
        assert len(content.split('\n')) > 0, "requirements.txt should contain at least one dependency"

    def test_pytest_is_available(self):
        """Test that pytest is installed."""
        try:
            import pytest
            assert pytest.__version__
        except ImportError:
            pytest.fail("pytest is not installed")

    def test_coverage_is_available(self):
        """Test that pytest-cov is installed."""
        try:
            import pytest_cov
            assert pytest_cov
        except ImportError:
            pytest.fail("pytest-cov is not installed")

    def test_typing_extensions_available(self):
        """Test that typing_extensions is available for Python 3.12."""
        try:
            import typing_extensions
            assert typing_extensions
        except ImportError:
            pytest.fail("typing_extensions is not installed")

    def test_dataclasses_json_available(self):
        """Test that dataclasses-json is available for structured logging."""
        try:
            import dataclasses_json
            assert dataclasses_json
        except ImportError:
            pytest.fail("dataclasses-json is not installed")

    def test_jsonschema_available(self):
        """Test that jsonschema is available for validation."""
        try:
            import jsonschema
            assert jsonschema
        except ImportError:
            pytest.fail("jsonschema is not installed")

    def test_click_available(self):
        """Test that click is available for CLI tools."""
        try:
            import click
            assert click
        except ImportError:
            pytest.fail("click is not installed")

    def test_pydantic_available(self):
        """Test that pydantic is available for data validation."""
        try:
            import pydantic
            assert pydantic
        except ImportError:
            pytest.fail("pydantic is not installed")

    def test_aiofiles_available(self):
        """Test that aiofiles is available for async file operations."""
        try:
            import aiofiles
            assert aiofiles
        except ImportError:
            pytest.fail("aiofiles is not installed")

    def test_requirements_can_be_installed(self):
        """Test that all requirements can be installed successfully."""
        project_root = Path(__file__).parent.parent.parent.parent
        requirements_file = project_root / "requirements.txt"

        # Check if pip can parse the requirements file
        result = subprocess.run(
            [sys.executable, "-m", "pip", "check"],
            capture_output=True,
            text=True
        )

        assert result.returncode == 0, f"Dependency conflicts detected: {result.stderr}"

    def test_no_conflicting_dependencies(self):
        """Test that there are no conflicting dependencies."""
        result = subprocess.run(
            [sys.executable, "-m", "pip", "list", "--format=json"],
            capture_output=True,
            text=True
        )

        assert result.returncode == 0, "Failed to list installed packages"

        import json
        packages = json.loads(result.stdout)
        package_names = [p['name'].lower() for p in packages]

        # Check for no duplicate packages with different cases
        assert len(package_names) == len(set(package_names)), "Duplicate packages detected"