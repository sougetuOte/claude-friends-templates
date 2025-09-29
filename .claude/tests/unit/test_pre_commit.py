#!/usr/bin/env python3
"""
Test for pre-commit hook configuration.
Following t-wada style TDD: Red Phase - Writing failing test first
"""

import os
import yaml
import subprocess
from pathlib import Path
import pytest


class TestPreCommitConfig:
    """Test suite for pre-commit hook configuration."""

    def setup_method(self):
        """Set up test environment."""
        self.project_root = Path(__file__).parent.parent.parent.parent
        self.pre_commit_config_path = self.project_root / ".pre-commit-config.yaml"
        self.git_hooks_dir = self.project_root / ".git" / "hooks"

    def test_pre_commit_config_file_exists(self):
        """Test that .pre-commit-config.yaml exists."""
        assert self.pre_commit_config_path.exists(), f"Pre-commit config {self.pre_commit_config_path} should exist"
        assert self.pre_commit_config_path.is_file(), f"{self.pre_commit_config_path} should be a file"

    def test_pre_commit_config_has_valid_yaml(self):
        """Test that pre-commit config has valid YAML syntax."""
        with open(self.pre_commit_config_path, 'r') as f:
            config = yaml.safe_load(f)

        assert config is not None, "Pre-commit config should contain valid YAML"
        assert 'repos' in config, "Pre-commit config should have repos section"
        assert isinstance(config['repos'], list), "Repos should be a list"

    def test_pre_commit_has_python_linting_hooks(self):
        """Test that Python linting hooks are configured."""
        with open(self.pre_commit_config_path, 'r') as f:
            config = yaml.safe_load(f)

        repos = config.get('repos', [])

        # Check for ruff or black/flake8
        has_python_linting = False
        for repo in repos:
            repo_url = repo.get('repo', '')
            if 'ruff' in repo_url or 'black' in repo_url or 'flake8' in repo_url:
                has_python_linting = True
                break

        assert has_python_linting, "Should have Python linting hooks (ruff, black, or flake8)"

    def test_pre_commit_has_formatting_hooks(self):
        """Test that formatting hooks are configured."""
        with open(self.pre_commit_config_path, 'r') as f:
            config = yaml.safe_load(f)

        repos = config.get('repos', [])

        # Check for formatting tools
        has_formatting = False
        for repo in repos:
            repo_url = repo.get('repo', '')
            hooks = repo.get('hooks', [])
            for hook in hooks:
                hook_id = hook.get('id', '')
                if hook_id in ['black', 'ruff-format', 'prettier', 'trailing-whitespace', 'end-of-file-fixer']:
                    has_formatting = True
                    break

        assert has_formatting, "Should have formatting hooks"

    def test_pre_commit_has_security_checks(self):
        """Test that security check hooks are configured."""
        with open(self.pre_commit_config_path, 'r') as f:
            config = yaml.safe_load(f)

        repos = config.get('repos', [])

        # Check for security tools
        has_security = False
        for repo in repos:
            repo_url = repo.get('repo', '')
            hooks = repo.get('hooks', [])
            for hook in hooks:
                hook_id = hook.get('id', '')
                if 'bandit' in hook_id or 'detect-secrets' in hook_id or 'check-added-large-files' in hook_id:
                    has_security = True
                    break

        assert has_security, "Should have security check hooks"

    def test_pre_commit_has_test_runner_hook(self):
        """Test that test runner hook is configured."""
        with open(self.pre_commit_config_path, 'r') as f:
            config = yaml.safe_load(f)

        repos = config.get('repos', [])

        # Check for test runner
        has_test_runner = False
        for repo in repos:
            hooks = repo.get('hooks', [])
            for hook in hooks:
                hook_id = hook.get('id', '')
                hook_name = hook.get('name', '')
                if 'test' in hook_id.lower() or 'pytest' in hook_id or 'test' in hook_name.lower():
                    has_test_runner = True
                    break

        assert has_test_runner, "Should have test runner hook"

    def test_pre_commit_has_yaml_checker(self):
        """Test that YAML validation hook is configured."""
        with open(self.pre_commit_config_path, 'r') as f:
            config = yaml.safe_load(f)

        repos = config.get('repos', [])

        # Check for YAML validator
        has_yaml_check = False
        for repo in repos:
            hooks = repo.get('hooks', [])
            for hook in hooks:
                hook_id = hook.get('id', '')
                if 'check-yaml' in hook_id or 'yaml' in hook_id:
                    has_yaml_check = True
                    break

        assert has_yaml_check, "Should have YAML validation hook"

    def test_pre_commit_has_json_checker(self):
        """Test that JSON validation hook is configured."""
        with open(self.pre_commit_config_path, 'r') as f:
            config = yaml.safe_load(f)

        repos = config.get('repos', [])

        # Check for JSON validator
        has_json_check = False
        for repo in repos:
            hooks = repo.get('hooks', [])
            for hook in hooks:
                hook_id = hook.get('id', '')
                if 'check-json' in hook_id or 'json' in hook_id:
                    has_json_check = True
                    break

        assert has_json_check, "Should have JSON validation hook"

    def test_pre_commit_has_merge_conflict_checker(self):
        """Test that merge conflict checker is configured."""
        with open(self.pre_commit_config_path, 'r') as f:
            config = yaml.safe_load(f)

        repos = config.get('repos', [])

        # Check for merge conflict checker
        has_conflict_check = False
        for repo in repos:
            hooks = repo.get('hooks', [])
            for hook in hooks:
                hook_id = hook.get('id', '')
                if 'check-merge-conflict' in hook_id:
                    has_conflict_check = True
                    break

        assert has_conflict_check, "Should have merge conflict checker"

    def test_pre_commit_is_installable(self):
        """Test that pre-commit hooks can be installed."""
        # This test checks if pre-commit command exists and config is valid
        try:
            # Check if pre-commit is installed
            result = subprocess.run(
                ['python', '-m', 'pre_commit', '--version'],
                capture_output=True,
                text=True,
                timeout=5
            )
            pre_commit_installed = result.returncode == 0
        except (subprocess.SubprocessError, FileNotFoundError):
            pre_commit_installed = False

        if pre_commit_installed:
            # Validate config
            result = subprocess.run(
                ['python', '-m', 'pre_commit', 'validate-config', str(self.pre_commit_config_path)],
                capture_output=True,
                text=True,
                timeout=10
            )
            assert result.returncode == 0, f"Pre-commit config validation failed: {result.stderr}"
        else:
            # Skip if pre-commit is not installed
            pytest.skip("pre-commit not installed")