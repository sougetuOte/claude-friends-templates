#!/usr/bin/env python3
"""
Test for GitHub Actions CI/CD configuration.
Following t-wada style TDD: Red Phase - Writing failing test first
"""

import os
import yaml
from pathlib import Path
import pytest


class TestGitHubActionsConfig:
    """Test suite for GitHub Actions CI/CD configuration."""

    def setup_method(self):
        """Set up test environment."""
        self.project_root = Path(__file__).parent.parent.parent.parent
        self.workflows_dir = self.project_root / ".github" / "workflows"
        self.ci_config_path = self.workflows_dir / "ci.yml"
        self.test_config_path = self.workflows_dir / "tests.yml"

    def test_github_workflows_directory_exists(self):
        """Test that .github/workflows directory exists."""
        assert self.workflows_dir.exists(), f"Directory {self.workflows_dir} should exist"
        assert self.workflows_dir.is_dir(), f"{self.workflows_dir} should be a directory"

    def test_ci_workflow_file_exists(self):
        """Test that CI workflow file exists."""
        assert self.ci_config_path.exists(), f"CI config {self.ci_config_path} should exist"
        assert self.ci_config_path.is_file(), f"{self.ci_config_path} should be a file"

    def test_ci_workflow_has_valid_yaml(self):
        """Test that CI workflow has valid YAML syntax."""
        with open(self.ci_config_path, 'r') as f:
            config = yaml.safe_load(f)

        assert config is not None, "CI config should contain valid YAML"
        assert 'name' in config, "CI config should have a name"
        # 'on' might be parsed as True or as string 'on'
        assert 'on' in config or True in config, "CI config should have triggers"
        assert 'jobs' in config, "CI config should have jobs defined"

    def test_ci_triggers_on_push_and_pr(self):
        """Test that CI triggers on push and pull requests."""
        with open(self.ci_config_path, 'r') as f:
            config = yaml.safe_load(f)

        # 'on' key might be parsed as True or as string 'on'
        triggers = config.get('on', config.get(True, {}))
        assert 'push' in triggers, "CI should trigger on push"
        assert 'pull_request' in triggers, "CI should trigger on pull requests"

        # Check branch configuration
        push_config = triggers.get('push', {})
        assert 'branches' in push_config, "Push trigger should specify branches"
        assert 'main' in push_config['branches'], "Should trigger on main branch"

    def test_ci_has_test_job(self):
        """Test that CI has a test job configured."""
        with open(self.ci_config_path, 'r') as f:
            config = yaml.safe_load(f)

        jobs = config.get('jobs', {})
        assert 'test' in jobs, "CI should have a test job"

        test_job = jobs['test']
        assert 'runs-on' in test_job, "Test job should specify OS"

        # Check for matrix or direct OS specification
        runs_on = str(test_job['runs-on'])
        assert 'ubuntu-latest' in runs_on or 'matrix.os' in runs_on, "Should run on Ubuntu or use matrix"
        assert 'steps' in test_job, "Test job should have steps"

    def test_ci_uses_python_312(self):
        """Test that CI uses Python 3.12."""
        with open(self.ci_config_path, 'r') as f:
            config = yaml.safe_load(f)

        test_job = config['jobs']['test']

        # Check matrix strategy for Python version
        if 'strategy' in test_job and 'matrix' in test_job['strategy']:
            matrix = test_job['strategy']['matrix']
            if 'python-version' in matrix:
                versions = matrix['python-version']
                assert '3.12' in versions, "Should include Python 3.12 in test matrix"
                return

        # Otherwise check steps for Python setup
        steps = test_job.get('steps', [])
        python_setup = None
        for step in steps:
            if step.get('uses', '').startswith('actions/setup-python'):
                python_setup = step
                break

        assert python_setup is not None, "Should have Python setup step"
        assert 'with' in python_setup, "Python setup should have configuration"

        python_version = str(python_setup['with'].get('python-version', ''))
        # Check if it's a matrix reference or direct version
        assert '3.12' in python_version or 'matrix.python-version' in python_version, "Should use Python 3.12"

    def test_ci_installs_dependencies(self):
        """Test that CI installs project dependencies."""
        with open(self.ci_config_path, 'r') as f:
            config = yaml.safe_load(f)

        test_job = config['jobs']['test']
        steps = test_job.get('steps', [])

        # Check for dependency installation
        install_found = False
        for step in steps:
            if 'run' in step:
                if 'pip install' in step['run'] or 'requirements' in step['run']:
                    install_found = True
                    break

        assert install_found, "CI should install dependencies"

    def test_ci_runs_tests_with_coverage(self):
        """Test that CI runs tests with coverage reporting."""
        with open(self.ci_config_path, 'r') as f:
            config = yaml.safe_load(f)

        test_job = config['jobs']['test']
        steps = test_job.get('steps', [])

        # Check for test execution with coverage
        test_found = False
        coverage_found = False
        for step in steps:
            if 'run' in step:
                if 'pytest' in step['run']:
                    test_found = True
                if '--cov' in step['run'] or 'coverage' in step['run']:
                    coverage_found = True

        assert test_found, "CI should run pytest"
        assert coverage_found, "CI should generate coverage reports"

    def test_ci_has_linting_job(self):
        """Test that CI has code quality checks."""
        with open(self.ci_config_path, 'r') as f:
            config = yaml.safe_load(f)

        jobs = config.get('jobs', {})

        # Either separate lint job or linting in test job
        has_lint_job = 'lint' in jobs or 'quality' in jobs

        if not has_lint_job:
            # Check if linting is part of test job
            test_job = jobs.get('test', {})
            steps = test_job.get('steps', [])

            for step in steps:
                if 'run' in step:
                    if 'ruff' in step['run'] or 'black' in step['run'] or 'mypy' in step['run']:
                        has_lint_job = True
                        break

        assert has_lint_job, "CI should have linting/quality checks"

    def test_ci_uses_caching(self):
        """Test that CI uses dependency caching for efficiency."""
        with open(self.ci_config_path, 'r') as f:
            config = yaml.safe_load(f)

        test_job = config['jobs']['test']
        steps = test_job.get('steps', [])

        # Check for cache action or pip cache
        cache_found = False
        for step in steps:
            uses = step.get('uses', '')
            if 'cache' in uses.lower():
                cache_found = True
                break
            # Check Python setup with cache
            if uses.startswith('actions/setup-python'):
                if step.get('with', {}).get('cache') == 'pip':
                    cache_found = True
                    break

        assert cache_found, "CI should use caching for better performance"