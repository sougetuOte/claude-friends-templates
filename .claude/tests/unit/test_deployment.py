#!/usr/bin/env python3
"""
Deployment Script Tests (TDD Green Phase)
Test suite for deployment automation script

Phase 5.2.1 - Green Phase
Implementation complete, tests enabled

Test Coverage Requirements:
- Version management (semantic versioning)
- Git tag creation and pushing
- GitHub release creation
- Pre-deployment validation
- Error handling and rollback

Version: 1.0.0
Python: 3.12+
"""

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock, patch

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent.parent / "scripts"))

from deploy import (
    DeploymentManager,
    VersionManager,
    GitManager,
    GitHubReleaseManager,
    PreDeploymentValidator,
)


class TestVersionManager(unittest.TestCase):
    """Test 1-5: Version management tests"""

    def setUp(self):
        """Set up test environment"""
        self.test_dir = tempfile.mkdtemp()
        self.version_file = Path(self.test_dir) / "VERSION"

    def test_parse_semantic_version_valid(self):
        """Test 1: Parse valid semantic version string"""
        manager = VersionManager()
        major, minor, patch = manager.parse_version("1.2.3")
        self.assertEqual((major, minor, patch), (1, 2, 3))

    def test_parse_semantic_version_invalid(self):
        """Test 2: Reject invalid version strings"""
        manager = VersionManager()
        with self.assertRaises(ValueError):
            manager.parse_version("invalid")

    def test_increment_patch_version(self):
        """Test 3: Increment patch version (1.2.3 -> 1.2.4)"""
        manager = VersionManager()
        new_version = manager.increment("1.2.3", "patch")
        self.assertEqual(new_version, "1.2.4")

    def test_increment_minor_version(self):
        """Test 4: Increment minor version (1.2.3 -> 1.3.0)"""
        manager = VersionManager()
        new_version = manager.increment("1.2.3", "minor")
        self.assertEqual(new_version, "1.3.0")

    def test_increment_major_version(self):
        """Test 5: Increment major version (1.2.3 -> 2.0.0)"""
        manager = VersionManager()
        new_version = manager.increment("1.2.3", "major")
        self.assertEqual(new_version, "2.0.0")


class TestGitManager(unittest.TestCase):
    """Test 6-10: Git operations tests"""

    def setUp(self):
        """Set up test environment"""
        self.test_dir = tempfile.mkdtemp()

    @patch("subprocess.run")
    def test_create_git_tag(self, mock_run):
        """Test 6: Create annotated Git tag"""
        mock_run.return_value = Mock(returncode=0, stdout="", stderr="")
        manager = GitManager(repo_path=self.test_dir)
        manager.create_tag("v1.2.3", "Release v1.2.3")
        mock_run.assert_called()

    @patch("subprocess.run")
    def test_check_uncommitted_changes(self, mock_run):
        """Test 7: Detect uncommitted changes"""
        mock_run.return_value = Mock(returncode=0, stdout="M file.py\n", stderr="")
        manager = GitManager(repo_path=self.test_dir)
        has_changes = manager.has_uncommitted_changes()
        self.assertTrue(has_changes)

    @patch("subprocess.run")
    def test_verify_clean_working_tree(self, mock_run):
        """Test 8: Verify clean working tree before deployment"""
        mock_run.return_value = Mock(returncode=0, stdout="", stderr="")
        manager = GitManager(repo_path=self.test_dir)
        # Should not raise if clean
        manager.verify_clean_working_tree()

    @patch("subprocess.run")
    def test_get_current_branch(self, mock_run):
        """Test 9: Get current Git branch name"""
        mock_run.return_value = Mock(returncode=0, stdout="main\n", stderr="")
        manager = GitManager(repo_path=self.test_dir)
        branch = manager.get_current_branch()
        self.assertEqual(branch, "main")

    @patch("subprocess.run")
    def test_verify_deployment_branch(self, mock_run):
        """Test 10: Verify deployment happens from main/master branch"""
        mock_run.return_value = Mock(returncode=0, stdout="feature-branch\n", stderr="")
        manager = GitManager(repo_path=self.test_dir)
        # Should raise if on feature branch
        with self.assertRaises(ValueError):
            manager.verify_deployment_branch(allowed=["main", "master"])


class TestGitHubReleaseManager(unittest.TestCase):
    """Test 11-15: GitHub release tests"""

    def setUp(self):
        """Set up test environment"""
        self.test_dir = tempfile.mkdtemp()

    @patch("subprocess.run")
    def test_create_github_release(self, mock_run):
        """Test 11: Create GitHub release using gh CLI"""
        mock_run.return_value = Mock(
            returncode=0, stdout="https://github.com/user/repo/releases/tag/v1.2.3"
        )
        manager = GitHubReleaseManager()
        url = manager.create_release(
            tag="v1.2.3",
            title="Version 1.2.3",
            notes="Release notes",
        )
        self.assertIn("github.com", url)

    @patch("subprocess.run")
    def test_generate_release_notes_from_commits(self, mock_run):
        """Test 12: Generate release notes from git commits"""
        mock_run.return_value = Mock(
            returncode=0, stdout="- feat: Add feature\n- fix: Fix bug"
        )
        manager = GitHubReleaseManager()
        notes = manager.generate_release_notes(
            from_tag="v1.2.2",
            to_tag="v1.2.3",
        )
        self.assertIsInstance(notes, str)
        self.assertIn("Changes", notes)

    @patch("subprocess.run")
    def test_check_gh_cli_installed(self, mock_run):
        """Test 13: Verify gh CLI is installed"""
        mock_run.return_value = Mock(returncode=0)
        manager = GitHubReleaseManager()
        is_installed = manager.is_gh_installed()
        self.assertTrue(is_installed)

    def test_release_creation_without_gh_cli(self):
        """Test 14: Handle missing gh CLI gracefully"""
        manager = GitHubReleaseManager()
        with patch.object(manager, "is_gh_installed", return_value=False):
            with self.assertRaises(EnvironmentError):
                manager.create_release("v1.2.3", "Title", "Notes")

    @patch("subprocess.run")
    def test_release_creation_with_assets(self, mock_run):
        """Test 15: Create release with asset files"""
        mock_run.return_value = Mock(
            returncode=0, stdout="https://github.com/user/repo/releases/tag/v1.2.3"
        )
        manager = GitHubReleaseManager()
        asset_file = Path(self.test_dir) / "package.zip"
        asset_file.touch()
        manager.create_release(
            tag="v1.2.3",
            title="Version 1.2.3",
            notes="Release notes",
            assets=[str(asset_file)],
        )


class TestPreDeploymentValidator(unittest.TestCase):
    """Test 16-20: Pre-deployment validation tests"""

    def setUp(self):
        """Set up test environment"""
        self.test_dir = tempfile.mkdtemp()

    @patch("subprocess.run")
    def test_run_tests_before_deployment(self, mock_run):
        """Test 16: Run test suite before deployment"""
        mock_run.return_value = Mock(returncode=0)
        validator = PreDeploymentValidator(repo_path=self.test_dir)
        result = validator.run_tests()
        self.assertTrue(result)

    @patch("subprocess.run")
    def test_fail_deployment_on_test_failure(self, mock_run):
        """Test 17: Prevent deployment if tests fail"""
        mock_run.side_effect = [
            Mock(returncode=0, stdout=""),  # status check
            Mock(returncode=0, stdout="main\n"),  # branch check
            Mock(returncode=1, stdout="FAILED", stderr="Test failed"),  # tests
        ]
        validator = PreDeploymentValidator(repo_path=self.test_dir)
        with self.assertRaises(RuntimeError):
            validator.validate()

    @patch("subprocess.run")
    def test_check_security_vulnerabilities(self, mock_run):
        """Test 18: Run security checks before deployment"""
        mock_run.return_value = Mock(returncode=0)
        validator = PreDeploymentValidator(repo_path=self.test_dir)
        result = validator.check_security()
        self.assertTrue(result)

    @patch.object(GitManager, "tag_exists")
    def test_validate_version_not_exists(self, mock_tag_exists):
        """Test 19: Verify version tag doesn't already exist"""
        mock_tag_exists.return_value = True
        validator = PreDeploymentValidator(repo_path=self.test_dir)
        with self.assertRaises(ValueError):
            validator.validate_version_unique("1.2.3")

    @patch("subprocess.run")
    def test_check_remote_connection(self, mock_run):
        """Test 20: Verify connection to GitHub remote"""
        mock_run.return_value = Mock(returncode=0)
        validator = PreDeploymentValidator(repo_path=self.test_dir)
        result = validator.check_remote_connection()
        self.assertTrue(result)


class TestDeploymentManager(unittest.TestCase):
    """Test 21-25: Main deployment workflow tests"""

    def setUp(self):
        """Set up test environment"""
        self.test_dir = tempfile.mkdtemp()

    @patch.object(GitHubReleaseManager, "create_release")
    @patch.object(GitManager, "push_tag")
    @patch.object(GitManager, "create_tag")
    @patch.object(PreDeploymentValidator, "validate")
    @patch.object(PreDeploymentValidator, "validate_version_unique")
    def test_full_deployment_workflow(
        self,
        mock_validate_version,
        mock_validate,
        mock_create_tag,
        mock_push_tag,
        mock_create_release,
    ):
        """Test 21: Complete deployment workflow"""
        mock_create_release.return_value = (
            "https://github.com/user/repo/releases/tag/v1.2.3"
        )
        manager = DeploymentManager(repo_path=self.test_dir)
        result = manager.deploy(version="1.2.3")
        self.assertTrue(result["success"])
        self.assertEqual(result["version"], "1.2.3")

    def test_deployment_with_dry_run(self):
        """Test 22: Dry-run mode without actual deployment"""
        manager = DeploymentManager(repo_path=self.test_dir)
        result = manager.deploy(version="1.2.3", dry_run=True)
        self.assertTrue(result["dry_run"])

    @patch.object(GitHubReleaseManager, "create_release")
    @patch.object(GitManager, "push_tag")
    @patch.object(GitManager, "create_tag")
    @patch.object(GitManager, "delete_tag")
    @patch.object(PreDeploymentValidator, "validate")
    @patch.object(PreDeploymentValidator, "validate_version_unique")
    def test_rollback_on_failure(
        self,
        mock_validate_version,
        mock_validate,
        mock_delete_tag,
        mock_create_tag,
        mock_push_tag,
        mock_create_release,
    ):
        """Test 23: Rollback deployment on failure"""
        mock_create_release.side_effect = RuntimeError("Release creation failed")
        manager = DeploymentManager(repo_path=self.test_dir)
        # Simulate failure during release creation
        with self.assertRaises(RuntimeError):
            manager.deploy(version="1.2.3")
        # Verify rollback happened (tag removed)
        mock_delete_tag.assert_called()

    @patch.object(GitHubReleaseManager, "create_release")
    @patch.object(GitManager, "push_tag")
    @patch.object(GitManager, "create_tag")
    @patch.object(PreDeploymentValidator, "validate")
    @patch.object(PreDeploymentValidator, "validate_version_unique")
    def test_deployment_logging(
        self,
        mock_validate_version,
        mock_validate,
        mock_create_tag,
        mock_push_tag,
        mock_create_release,
    ):
        """Test 24: Log deployment activities"""
        mock_create_release.return_value = (
            "https://github.com/user/repo/releases/tag/v1.2.3"
        )
        manager = DeploymentManager(repo_path=self.test_dir)
        manager.deploy(version="1.2.3")
        log_file = Path(self.test_dir) / ".claude" / "logs" / "deployment.log"
        self.assertTrue(log_file.exists())

    def test_deployment_with_custom_changelog(self):
        """Test 25: Deploy with custom CHANGELOG"""
        manager = DeploymentManager(repo_path=self.test_dir)
        custom_notes = "Custom release notes"
        result = manager.deploy(version="1.2.3", changelog=custom_notes, dry_run=True)
        self.assertEqual(result["release_notes"], custom_notes)


class TestErrorHandling(unittest.TestCase):
    """Test 26-30: Error handling tests"""

    @patch("subprocess.run")
    def test_handle_network_timeout(self, mock_run):
        """Test 26: Handle network timeout during GitHub API calls"""
        import subprocess

        mock_run.side_effect = subprocess.TimeoutExpired("git", 10)
        validator = PreDeploymentValidator()
        # Should handle timeout gracefully
        result = validator.check_remote_connection()
        self.assertFalse(result)

    @patch("subprocess.run")
    def test_handle_permission_denied(self, mock_run):
        """Test 27: Handle permission errors"""
        mock_run.side_effect = PermissionError("Permission denied")
        manager = GitManager()
        with self.assertRaises(RuntimeError):
            manager.create_tag("v1.2.3", "Release")

    @patch.object(GitManager, "tag_exists")
    def test_handle_duplicate_tag(self, mock_tag_exists):
        """Test 28: Handle duplicate tag error"""
        mock_tag_exists.return_value = True
        validator = PreDeploymentValidator()
        with self.assertRaises(ValueError) as ctx:
            validator.validate_version_unique("1.2.3")
        self.assertIn("already exists", str(ctx.exception))

    @patch.object(GitHubReleaseManager, "is_gh_installed")
    def test_handle_missing_credentials(self, mock_is_installed):
        """Test 29: Handle missing GitHub credentials"""
        mock_is_installed.return_value = False
        manager = GitHubReleaseManager()
        with self.assertRaises(EnvironmentError) as ctx:
            manager.create_release("v1.2.3", "Title", "Notes")
        self.assertIn("not installed", str(ctx.exception))

    @patch("subprocess.run")
    def test_handle_dirty_working_tree(self, mock_run):
        """Test 30: Prevent deployment with uncommitted changes"""
        mock_run.return_value = Mock(returncode=0, stdout="M file.py\n", stderr="")
        manager = GitManager()
        with self.assertRaises(RuntimeError) as ctx:
            manager.verify_clean_working_tree()
        self.assertIn("uncommitted changes", str(ctx.exception))


class TestVersionFileIO(unittest.TestCase):
    """Test 31-33: Version file I/O tests (Refactor Phase coverage improvement)"""

    def setUp(self):
        """Set up test environment"""
        self.test_dir = tempfile.mkdtemp()
        self.version_file = Path(self.test_dir) / "VERSION"

    def test_read_version_file(self):
        """Test 31: Read version from VERSION file"""
        self.version_file.write_text("1.2.3\n")
        manager = VersionManager()
        version = manager.read_version_file(self.version_file)
        self.assertEqual(version, "1.2.3")

    def test_read_missing_version_file(self):
        """Test 32: Handle missing VERSION file"""
        manager = VersionManager()
        with self.assertRaises(FileNotFoundError):
            manager.read_version_file(self.version_file)

    def test_write_version_file(self):
        """Test 33: Write version to VERSION file"""
        manager = VersionManager()
        manager.write_version_file(self.version_file, "2.0.0")
        content = self.version_file.read_text()
        self.assertEqual(content, "2.0.0\n")


class TestGitOperationsExtended(unittest.TestCase):
    """Test 34-37: Extended Git operations (Refactor Phase)"""

    def setUp(self):
        """Set up test environment"""
        self.test_dir = tempfile.mkdtemp()

    @patch("subprocess.run")
    def test_tag_exists_true(self, mock_run):
        """Test 34: Check if tag exists (positive case)"""
        mock_run.return_value = Mock(returncode=0, stdout="v1.2.3\n", stderr="")
        manager = GitManager(repo_path=self.test_dir)
        exists = manager.tag_exists("v1.2.3")
        self.assertTrue(exists)

    @patch("subprocess.run")
    def test_tag_exists_false(self, mock_run):
        """Test 35: Check if tag exists (negative case)"""
        mock_run.return_value = Mock(returncode=0, stdout="", stderr="")
        manager = GitManager(repo_path=self.test_dir)
        exists = manager.tag_exists("v9.9.9")
        self.assertFalse(exists)

    @patch("subprocess.run")
    def test_push_tag_success(self, mock_run):
        """Test 36: Push tag to remote successfully"""
        mock_run.return_value = Mock(returncode=0, stdout="", stderr="")
        manager = GitManager(repo_path=self.test_dir)
        manager.push_tag("v1.2.3")
        mock_run.assert_called()

    @patch("subprocess.run")
    def test_push_tag_failure(self, mock_run):
        """Test 37: Handle push tag failure"""
        mock_run.side_effect = subprocess.CalledProcessError(
            1, "git", stderr="Permission denied"
        )
        manager = GitManager(repo_path=self.test_dir)
        with self.assertRaises(RuntimeError):
            manager.push_tag("v1.2.3")


class TestReleaseNotesGeneration(unittest.TestCase):
    """Test 38-40: Release notes generation (Refactor Phase)"""

    @patch("subprocess.run")
    def test_generate_release_notes_with_commits(self, mock_run):
        """Test 38: Generate release notes from commit history"""
        mock_run.return_value = Mock(
            returncode=0, stdout="- feat: Add new feature\n- fix: Fix bug\n", stderr=""
        )
        manager = GitHubReleaseManager()
        notes = manager.generate_release_notes("v1.2.2", "v1.2.3")
        self.assertIn("Changes in v1.2.3", notes)
        self.assertIn("feat: Add new feature", notes)

    @patch("subprocess.run")
    def test_generate_release_notes_no_commits(self, mock_run):
        """Test 39: Generate release notes with no commits"""
        mock_run.return_value = Mock(returncode=0, stdout="", stderr="")
        manager = GitHubReleaseManager()
        notes = manager.generate_release_notes("v1.2.2", "v1.2.3")
        self.assertIn("No significant changes", notes)

    @patch("subprocess.run")
    def test_generate_release_notes_error_fallback(self, mock_run):
        """Test 40: Fallback when git log fails"""
        mock_run.side_effect = subprocess.CalledProcessError(1, "git")
        manager = GitHubReleaseManager()
        notes = manager.generate_release_notes("v1.2.2", "v1.2.3")
        self.assertEqual(notes, "Release v1.2.3")


class TestDeploymentLogging(unittest.TestCase):
    """Test 41-42: Deployment logging (Refactor Phase)"""

    def setUp(self):
        """Set up test environment"""
        self.test_dir = tempfile.mkdtemp()

    @patch.object(GitHubReleaseManager, "create_release")
    @patch.object(GitManager, "push_tag")
    @patch.object(GitManager, "create_tag")
    @patch.object(PreDeploymentValidator, "validate")
    @patch.object(PreDeploymentValidator, "validate_version_unique")
    def test_log_deployment_creates_log_file(
        self,
        mock_validate_version,
        mock_validate,
        mock_create_tag,
        mock_push_tag,
        mock_create_release,
    ):
        """Test 41: Deployment creates log file"""
        mock_create_release.return_value = (
            "https://github.com/user/repo/releases/tag/v1.2.3"
        )
        manager = DeploymentManager(repo_path=self.test_dir)
        manager.deploy(version="1.2.3")

        log_file = Path(self.test_dir) / ".claude" / "logs" / "deployment.log"
        self.assertTrue(log_file.exists())

        # Verify log content
        log_content = log_file.read_text()
        self.assertIn("1.2.3", log_content)
        self.assertIn("v1.2.3", log_content)

    @patch.object(GitHubReleaseManager, "create_release")
    @patch.object(GitManager, "push_tag")
    @patch.object(GitManager, "create_tag")
    @patch.object(PreDeploymentValidator, "validate")
    @patch.object(PreDeploymentValidator, "validate_version_unique")
    def test_multiple_deployments_append_to_log(
        self,
        mock_validate_version,
        mock_validate,
        mock_create_tag,
        mock_push_tag,
        mock_create_release,
    ):
        """Test 42: Multiple deployments append to log"""
        mock_create_release.return_value = (
            "https://github.com/user/repo/releases/tag/v1.2.3"
        )
        manager = DeploymentManager(repo_path=self.test_dir)

        # First deployment
        manager.deploy(version="1.2.3")
        # Second deployment
        mock_create_release.return_value = (
            "https://github.com/user/repo/releases/tag/v1.2.4"
        )
        manager.deploy(version="1.2.4")

        log_file = Path(self.test_dir) / ".claude" / "logs" / "deployment.log"
        log_lines = log_file.read_text().strip().split("\n")

        # Should have 2 log entries
        self.assertEqual(len(log_lines), 2)


if __name__ == "__main__":
    # Run all tests (Green + Refactor phases)
    unittest.main(verbosity=2)
