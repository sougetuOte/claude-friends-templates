#!/usr/bin/env python3
"""
Test for pytest configuration file existence and validity.
Following t-wada style TDD: Red Phase - Writing failing test first
"""

import os
import configparser
from pathlib import Path
import pytest


class TestPytestConfiguration:
    """Test suite for pytest configuration."""

    def test_pytest_ini_exists(self):
        """Test that pytest.ini configuration file exists in project root."""
        project_root = Path(__file__).parent.parent.parent.parent
        pytest_ini_path = project_root / "pytest.ini"

        assert pytest_ini_path.exists(), f"pytest.ini not found at {pytest_ini_path}"

    def test_pytest_ini_has_required_sections(self):
        """Test that pytest.ini contains required configuration sections."""
        project_root = Path(__file__).parent.parent.parent.parent
        pytest_ini_path = project_root / "pytest.ini"

        # This test will fail initially (Red Phase)
        config = configparser.ConfigParser()
        config.read(pytest_ini_path)

        # Check for [pytest] section
        assert 'pytest' in config.sections(), "pytest.ini missing [pytest] section"

    def test_pytest_ini_has_testpaths_configured(self):
        """Test that pytest.ini has testpaths configured correctly."""
        project_root = Path(__file__).parent.parent.parent.parent
        pytest_ini_path = project_root / "pytest.ini"

        config = configparser.ConfigParser()
        config.read(pytest_ini_path)

        # Check for testpaths configuration
        assert config.has_option('pytest', 'testpaths'), \
            "pytest.ini missing 'testpaths' configuration"

        testpaths = config.get('pytest', 'testpaths')
        assert '.claude/tests' in testpaths, \
            ".claude/tests not found in testpaths configuration"

    def test_pytest_ini_has_python_files_pattern(self):
        """Test that pytest.ini has python_files pattern configured."""
        project_root = Path(__file__).parent.parent.parent.parent
        pytest_ini_path = project_root / "pytest.ini"

        config = configparser.ConfigParser()
        config.read(pytest_ini_path)

        # Check for python_files configuration
        assert config.has_option('pytest', 'python_files'), \
            "pytest.ini missing 'python_files' configuration"

        python_files = config.get('pytest', 'python_files')
        assert 'test_*.py' in python_files, \
            "test_*.py pattern not found in python_files configuration"

    def test_pytest_ini_has_coverage_settings(self):
        """Test that pytest.ini has coverage settings configured."""
        project_root = Path(__file__).parent.parent.parent.parent
        pytest_ini_path = project_root / "pytest.ini"

        config = configparser.ConfigParser()
        config.read(pytest_ini_path)

        # Check for coverage configuration
        assert config.has_option('pytest', 'addopts'), \
            "pytest.ini missing 'addopts' configuration"

        addopts = config.get('pytest', 'addopts')
        assert '--cov' in addopts, \
            "Coverage option --cov not found in addopts"
        assert '--cov-report=html' in addopts, \
            "HTML coverage report option not found in addopts"