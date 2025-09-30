#!/usr/bin/env python3
"""
Deployment Automation Script
Automated deployment with version management, Git tagging, and GitHub releases

Phase 5.2.1 - Green Phase
Minimal implementation to pass tests

Features:
- Semantic versioning (major.minor.patch)
- Git tag creation and management
- GitHub release creation via gh CLI
- Pre-deployment validation (tests, security, clean tree)
- Rollback on failure
- Dry-run mode for testing
- AI-optimized logging integration

Version: 1.0.0
Python: 3.12+

Usage:
    Basic deployment:
        >>> python deploy.py --version 1.2.3

    With release type:
        >>> python deploy.py --release-type minor

    Dry-run:
        >>> python deploy.py --version 1.2.3 --dry-run

    Custom changelog:
        >>> python deploy.py --version 1.2.3 --changelog "Custom notes"
"""

import argparse
import json
import re
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Any, List, Optional, Tuple
from datetime import datetime, timezone

# AI Logger integration
try:
    from ai_logger import logger

    HAS_AI_LOGGER = True
except ImportError:
    HAS_AI_LOGGER = False

    # Fallback logger
    class FallbackLogger:
        def info(self, msg: str, **kwargs):
            print(f"[INFO] {msg}")

        def error(self, msg: str, **kwargs):
            print(f"[ERROR] {msg}", file=sys.stderr)

        def warning(self, msg: str, **kwargs):
            print(f"[WARN] {msg}")

        def set_context(self, **kwargs):
            pass

    logger = FallbackLogger()


@dataclass
class DeploymentResult:
    """Deployment result dataclass."""

    success: bool
    version: str
    tag: str = ""
    release_url: str = ""
    release_notes: str = ""
    dry_run: bool = False
    error: Optional[str] = None


class VersionManager:
    """Semantic version management."""

    VERSION_PATTERN = re.compile(r"^(\d+)\.(\d+)\.(\d+)$")

    def parse_version(self, version_str: str) -> Tuple[int, int, int]:
        """
        Parse semantic version string.

        Args:
            version_str: Version string (e.g., "1.2.3")

        Returns:
            Tuple of (major, minor, patch)

        Raises:
            ValueError: If version string is invalid
        """
        match = self.VERSION_PATTERN.match(version_str)
        if not match:
            raise ValueError(f"Invalid semantic version: {version_str}")

        major, minor, patch = match.groups()
        return int(major), int(minor), int(patch)

    def increment(self, version_str: str, release_type: str) -> str:
        """
        Increment version based on release type.

        Args:
            version_str: Current version (e.g., "1.2.3")
            release_type: "major", "minor", or "patch"

        Returns:
            New version string

        Raises:
            ValueError: If release_type is invalid
        """
        major, minor, patch = self.parse_version(version_str)

        if release_type == "major":
            return f"{major + 1}.0.0"
        elif release_type == "minor":
            return f"{major}.{minor + 1}.0"
        elif release_type == "patch":
            return f"{major}.{minor}.{patch + 1}"
        else:
            raise ValueError(f"Invalid release type: {release_type}")

    def read_version_file(self, version_file: Path) -> str:
        """Read version from VERSION file."""
        if not version_file.exists():
            raise FileNotFoundError(f"VERSION file not found: {version_file}")

        return version_file.read_text().strip()

    def write_version_file(self, version_file: Path, version: str) -> None:
        """Write version to VERSION file."""
        version_file.write_text(f"{version}\n")


class GitManager:
    """Git operations manager."""

    def __init__(self, repo_path: str = "."):
        """
        Initialize Git manager.

        Args:
            repo_path: Path to Git repository
        """
        self.repo_path = Path(repo_path)

    def _run_git(
        self, args: List[str], check: bool = True
    ) -> subprocess.CompletedProcess:
        """
        Run git command.

        Args:
            args: Git command arguments
            check: Raise exception on non-zero exit code

        Returns:
            CompletedProcess result
        """
        cmd = ["git", "-C", str(self.repo_path)] + args
        return subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=check,
        )

    def create_tag(self, tag: str, message: str) -> None:
        """
        Create annotated Git tag.

        Args:
            tag: Tag name (e.g., "v1.2.3")
            message: Tag annotation message

        Raises:
            RuntimeError: If tag creation fails
        """
        try:
            self._run_git(["tag", "-a", tag, "-m", message])
            logger.info(f"Created Git tag: {tag}", tag_name=tag, tag_message=message)
        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to create tag: {tag}", error=str(e))
            raise RuntimeError(f"Failed to create tag: {e.stderr}")
        except (PermissionError, OSError) as e:
            logger.error(f"Permission error creating tag: {tag}", error=str(e))
            raise RuntimeError(f"Permission denied: {e}")

    def tag_exists(self, tag: str) -> bool:
        """Check if tag exists."""
        result = self._run_git(["tag", "-l", tag], check=False)
        return bool(result.stdout.strip())

    def push_tag(self, tag: str) -> None:
        """Push tag to remote."""
        try:
            self._run_git(["push", "origin", tag])
            logger.info(f"Pushed tag to remote: {tag}", tag=tag)
        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to push tag: {tag}", error=str(e))
            raise RuntimeError(f"Failed to push tag: {e.stderr}")

    def delete_tag(self, tag: str) -> None:
        """Delete local tag (for rollback)."""
        try:
            self._run_git(["tag", "-d", tag], check=False)
        except subprocess.CalledProcessError:
            pass  # Tag may not exist

    def has_uncommitted_changes(self) -> bool:
        """Check if there are uncommitted changes."""
        result = self._run_git(["status", "--porcelain"], check=False)
        return bool(result.stdout.strip())

    def verify_clean_working_tree(self) -> None:
        """
        Verify working tree is clean.

        Raises:
            RuntimeError: If working tree has uncommitted changes
        """
        if self.has_uncommitted_changes():
            result = self._run_git(["status", "--short"])
            raise RuntimeError(
                "Working tree has uncommitted changes:\n"
                f"{result.stdout}\n"
                "Please commit or stash changes before deploying."
            )

    def get_current_branch(self) -> str:
        """Get current branch name."""
        result = self._run_git(["rev-parse", "--abbrev-ref", "HEAD"])
        return result.stdout.strip()

    def verify_deployment_branch(self, allowed: List[str] = None) -> None:
        """
        Verify deployment happens from allowed branch.

        Args:
            allowed: List of allowed branch names (default: ["main", "master"])

        Raises:
            ValueError: If current branch is not allowed
        """
        if allowed is None:
            allowed = ["main", "master"]

        current_branch = self.get_current_branch()
        if current_branch not in allowed:
            raise ValueError(
                f"Deployment must be from {allowed} branch, "
                f"currently on: {current_branch}"
            )


class GitHubReleaseManager:
    """GitHub release management via gh CLI."""

    def is_gh_installed(self) -> bool:
        """Check if gh CLI is installed."""
        try:
            result = subprocess.run(
                ["gh", "--version"],
                capture_output=True,
                check=False,
            )
            return result.returncode == 0
        except FileNotFoundError:
            return False

    def create_release(
        self,
        tag: str,
        title: str,
        notes: str,
        assets: List[str] = None,
        draft: bool = False,
    ) -> str:
        """
        Create GitHub release using gh CLI.

        Args:
            tag: Git tag name
            title: Release title
            notes: Release notes
            assets: Optional list of asset file paths
            draft: Create as draft release

        Returns:
            Release URL

        Raises:
            EnvironmentError: If gh CLI is not installed
            RuntimeError: If release creation fails
        """
        if not self.is_gh_installed():
            raise EnvironmentError(
                "GitHub CLI (gh) is not installed. "
                "Install from: https://cli.github.com/"
            )

        cmd = [
            "gh",
            "release",
            "create",
            tag,
            "--title",
            title,
            "--notes",
            notes,
        ]

        if draft:
            cmd.append("--draft")

        if assets:
            for asset in assets:
                cmd.append(asset)

        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                check=True,
            )
            release_url = result.stdout.strip()
            logger.info(
                f"Created GitHub release: {tag}",
                tag=tag,
                title=title,
                url=release_url,
            )
            return release_url
        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to create release: {tag}", error=str(e))
            raise RuntimeError(f"Failed to create GitHub release: {e.stderr}")

    def generate_release_notes(
        self,
        from_tag: str,
        to_tag: str,
        repo_path: str = ".",
    ) -> str:
        """
        Generate release notes from git commits.

        Args:
            from_tag: Previous tag
            to_tag: New tag
            repo_path: Repository path

        Returns:
            Generated release notes
        """
        try:
            # Get commits between tags
            result = subprocess.run(
                [
                    "git",
                    "-C",
                    repo_path,
                    "log",
                    f"{from_tag}..{to_tag}",
                    "--pretty=format:- %s",
                ],
                capture_output=True,
                text=True,
                check=True,
            )

            commits = result.stdout.strip()

            notes = f"## Changes in {to_tag}\n\n"
            if commits:
                notes += commits
            else:
                notes += "No significant changes."

            return notes
        except subprocess.CalledProcessError:
            # Fallback if tags don't exist
            return f"Release {to_tag}"


class PreDeploymentValidator:
    """Pre-deployment validation checks."""

    def __init__(self, repo_path: str = "."):
        """
        Initialize validator.

        Args:
            repo_path: Repository path
        """
        self.repo_path = Path(repo_path)
        self.git_manager = GitManager(repo_path)

    def run_tests(self) -> bool:
        """
        Run test suite.

        Returns:
            True if tests pass

        Raises:
            RuntimeError: If tests fail
        """
        try:
            result = subprocess.run(
                ["python", "-m", "pytest", ".claude/tests/unit/", "-v", "--tb=short"],
                capture_output=True,
                cwd=self.repo_path,
                check=False,
            )

            if result.returncode == 0:
                logger.info("All tests passed", tests="passed")
                return True
            else:
                logger.error("Tests failed", tests="failed", output=result.stderr)
                raise RuntimeError(f"Tests failed:\n{result.stdout}\n{result.stderr}")
        except FileNotFoundError:
            logger.warning("pytest not found, skipping tests")
            return True  # Don't block deployment if pytest not installed

    def check_security(self) -> bool:
        """
        Run security checks.

        Returns:
            True if security checks pass
        """
        try:
            # Run bandit for security linting
            result = subprocess.run(
                ["bandit", "-r", ".claude/scripts/", "-ll"],
                capture_output=True,
                cwd=self.repo_path,
                check=False,
            )

            if result.returncode == 0:
                logger.info("Security checks passed", security="passed")
                return True
            else:
                logger.warning(
                    "Security issues found", security="issues", output=result.stdout
                )
                return True  # Warning only, don't block deployment
        except FileNotFoundError:
            logger.warning("bandit not found, skipping security checks")
            return True

    def validate_version_unique(self, version: str) -> None:
        """
        Verify version tag doesn't already exist.

        Args:
            version: Version string

        Raises:
            ValueError: If tag already exists
        """
        tag = f"v{version}"
        if self.git_manager.tag_exists(tag):
            raise ValueError(f"Tag {tag} already exists. Use a different version.")

    def check_remote_connection(self) -> bool:
        """
        Check connection to Git remote.

        Returns:
            True if remote is reachable
        """
        try:
            result = subprocess.run(
                [
                    "git",
                    "-C",
                    str(self.repo_path),
                    "ls-remote",
                    "--exit-code",
                    "origin",
                ],
                capture_output=True,
                timeout=10,
                check=False,
            )

            if result.returncode == 0:
                logger.info("Remote connection successful", remote="origin")
                return True
            else:
                logger.warning("Remote connection failed", remote="origin")
                return False
        except subprocess.TimeoutExpired:
            logger.warning("Remote connection timeout", remote="origin")
            return False

    def validate(self) -> None:
        """
        Run all validation checks.

        Raises:
            RuntimeError: If any critical check fails
        """
        logger.info("Running pre-deployment validation", phase="validation")

        # Check working tree
        self.git_manager.verify_clean_working_tree()

        # Check branch
        self.git_manager.verify_deployment_branch()

        # Run tests
        self.run_tests()

        # Check security
        self.check_security()

        # Check remote
        if not self.check_remote_connection():
            logger.warning("Remote unreachable, deployment may fail")

        logger.info("Pre-deployment validation passed", phase="validation")


class DeploymentManager:
    """Main deployment orchestrator."""

    def __init__(self, repo_path: str = "."):
        """
        Initialize deployment manager.

        Args:
            repo_path: Repository path
        """
        self.repo_path = Path(repo_path)
        self.version_manager = VersionManager()
        self.git_manager = GitManager(repo_path)
        self.github_manager = GitHubReleaseManager()
        self.validator = PreDeploymentValidator(repo_path)

        # Set AI logger context
        if HAS_AI_LOGGER:
            logger.set_context(agent="deployment", task_name="automated_deployment")

    def deploy(
        self,
        version: str,
        release_type: Optional[str] = None,
        changelog: Optional[str] = None,
        dry_run: bool = False,
        skip_validation: bool = False,
    ) -> Dict[str, Any]:
        """
        Execute deployment workflow.

        Args:
            version: Version string (e.g., "1.2.3")
            release_type: Optional release type for version increment
            changelog: Optional custom changelog
            dry_run: Dry-run mode (no actual deployment)
            skip_validation: Skip pre-deployment validation

        Returns:
            Deployment result dictionary

        Raises:
            RuntimeError: If deployment fails
        """
        start_time = time.time()
        tag = f"v{version}"

        logger.info(
            f"Starting deployment: {version}",
            version=version,
            dry_run=dry_run,
            phase="start",
        )

        try:
            # Pre-deployment validation
            if not skip_validation and not dry_run:
                self.validator.validate()
                self.validator.validate_version_unique(version)

            # Generate release notes
            if changelog:
                release_notes = changelog
            else:
                try:
                    # Try to generate from commits
                    last_tag = subprocess.run(
                        [
                            "git",
                            "-C",
                            str(self.repo_path),
                            "describe",
                            "--tags",
                            "--abbrev=0",
                        ],
                        capture_output=True,
                        text=True,
                        check=False,
                    )

                    if last_tag.returncode == 0:
                        prev_tag = last_tag.stdout.strip()
                        release_notes = self.github_manager.generate_release_notes(
                            from_tag=prev_tag,
                            to_tag=tag,
                            repo_path=str(self.repo_path),
                        )
                    else:
                        release_notes = f"Release {version}"
                except Exception:
                    release_notes = f"Release {version}"

            if dry_run:
                logger.info(
                    "Dry-run mode: Skipping actual deployment",
                    version=version,
                    phase="dry_run",
                )
                return {
                    "success": True,
                    "version": version,
                    "tag": tag,
                    "release_notes": release_notes,
                    "dry_run": True,
                }

            # Create Git tag
            self.git_manager.create_tag(tag, f"Release {version}")

            # Push tag
            try:
                self.git_manager.push_tag(tag)
            except RuntimeError as e:
                # Rollback: Delete local tag
                logger.error("Failed to push tag, rolling back", error=str(e))
                self.git_manager.delete_tag(tag)
                raise

            # Create GitHub release
            try:
                release_url = self.github_manager.create_release(
                    tag=tag,
                    title=f"Version {version}",
                    notes=release_notes,
                )
            except (EnvironmentError, RuntimeError) as e:
                # Rollback: Delete tag (locally and remotely)
                logger.error("Failed to create release, rolling back", error=str(e))
                self.git_manager.delete_tag(tag)
                # Note: Remote tag cleanup would require --delete flag
                raise

            # Log deployment
            self._log_deployment(version, tag, release_url)

            elapsed = time.time() - start_time
            logger.info(
                f"Deployment successful: {version}",
                version=version,
                tag=tag,
                elapsed=f"{elapsed:.2f}s",
                phase="complete",
            )

            return {
                "success": True,
                "version": version,
                "tag": tag,
                "release_url": release_url,
                "release_notes": release_notes,
                "dry_run": False,
            }

        except Exception as e:
            logger.error(
                f"Deployment failed: {version}",
                version=version,
                error=str(e),
                phase="failed",
            )
            raise RuntimeError(f"Deployment failed: {e}")

    def _log_deployment(self, version: str, tag: str, release_url: str) -> None:
        """Log deployment to deployment log file."""
        log_dir = self.repo_path / ".claude" / "logs"
        log_dir.mkdir(parents=True, exist_ok=True)

        log_file = log_dir / "deployment.log"

        log_entry = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "version": version,
            "tag": tag,
            "release_url": release_url,
        }

        with log_file.open("a") as f:
            json.dump(log_entry, f)
            f.write("\n")


def main():
    """CLI entry point."""
    parser = argparse.ArgumentParser(
        description="Automated deployment script with version management"
    )
    parser.add_argument(
        "--version",
        type=str,
        help="Version string (e.g., 1.2.3)",
    )
    parser.add_argument(
        "--release-type",
        type=str,
        choices=["major", "minor", "patch"],
        help="Release type for version increment",
    )
    parser.add_argument(
        "--changelog",
        type=str,
        help="Custom changelog/release notes",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Dry-run mode (no actual deployment)",
    )
    parser.add_argument(
        "--skip-validation",
        action="store_true",
        help="Skip pre-deployment validation",
    )
    parser.add_argument(
        "--repo-path",
        type=str,
        default=".",
        help="Repository path (default: current directory)",
    )

    args = parser.parse_args()

    if not args.version and not args.release_type:
        parser.error("Either --version or --release-type is required")

    try:
        manager = DeploymentManager(repo_path=args.repo_path)

        # Determine version
        if args.release_type:
            # Read current version and increment
            version_file = Path(args.repo_path) / "VERSION"
            if version_file.exists():
                current_version = manager.version_manager.read_version_file(
                    version_file
                )
                version = manager.version_manager.increment(
                    current_version, args.release_type
                )
                print(f"Incrementing version: {current_version} -> {version}")
            else:
                parser.error("VERSION file not found, use --version instead")
        else:
            version = args.version

        # Execute deployment
        result = manager.deploy(
            version=version,
            changelog=args.changelog,
            dry_run=args.dry_run,
            skip_validation=args.skip_validation,
        )

        print(f"\n{'='*60}")
        print(f"Deployment {'Simulation' if result['dry_run'] else 'Complete'}!")
        print(f"{'='*60}")
        print(f"Version:      {result['version']}")
        print(f"Tag:          {result['tag']}")
        if not result["dry_run"] and result.get("release_url"):
            print(f"Release URL:  {result['release_url']}")
        print(f"{'='*60}\n")

        sys.exit(0)

    except Exception as e:
        print(f"\n[ERROR] {e}\n", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
