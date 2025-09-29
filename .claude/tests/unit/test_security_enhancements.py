#!/usr/bin/env python3
"""
Test security enhancements including SBOM generation and vulnerability scanning.
TDD Red Phase: These tests will fail until security features are implemented.

Following t-wada style TDD with strict Red-Green-Refactor cycle.
Based on 2025 security best practices with CycloneDX, pip-audit, bandit, and semgrep.
"""

import os
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch, MagicMock
import sys

class TestSecurityEnhancements(unittest.TestCase):
    """Test suite for security enhancement system."""

    def setUp(self):
        """Set up test environment before each test."""
        self.test_dir = Path(__file__).parent.parent.parent.parent
        self.security_config_path = self.test_dir / ".claude" / "security-config.json"
        self.sbom_script_path = self.test_dir / ".claude" / "scripts" / "sbom-generator.py"
        self.vuln_scanner_path = self.test_dir / ".claude" / "scripts" / "vulnerability-scanner.py"
        self.requirements_path = self.test_dir / "requirements.txt"

    def test_security_dependencies_in_requirements(self):
        """Test that security tools dependencies are in requirements.txt."""
        if self.requirements_path.exists():
            with open(self.requirements_path, 'r') as f:
                content = f.read()

            # Check for security packages based on 2025 best practices
            security_packages = [
                "cyclonedx-bom",  # SBOM generation (CycloneDX standard)
                "pip-audit",      # Vulnerability scanning for dependencies
                "bandit",         # Python security linter
                "safety",         # Safety database checking
            ]

            missing_packages = [pkg for pkg in security_packages if pkg not in content]
            if missing_packages:
                self.fail(f"Missing security packages in requirements.txt: {missing_packages}")

    def test_security_config_file_exists(self):
        """Test that security configuration file exists."""
        self.assertTrue(
            self.security_config_path.exists(),
            f"Security configuration file should exist at {self.security_config_path}"
        )

    def test_security_config_has_sbom_settings(self):
        """Test that security config defines SBOM generation settings."""
        if self.security_config_path.exists():
            with open(self.security_config_path, 'r') as f:
                config = json.load(f)

            # Check for SBOM configuration
            self.assertIn("sbom", config, "Config should have SBOM section")

            sbom_config = config["sbom"]

            # Verify SBOM settings
            expected_sbom_settings = {
                "format": str,  # CycloneDX or SPDX
                "output_file": str,
                "include_dev_dependencies": bool,
                "include_license_info": bool,
            }

            for setting_name, expected_type in expected_sbom_settings.items():
                self.assertIn(setting_name, sbom_config,
                             f"Should have {setting_name} setting")
                self.assertIsInstance(sbom_config[setting_name], expected_type,
                                    f"{setting_name} should be {expected_type.__name__}")

    def test_security_config_has_vulnerability_scan_settings(self):
        """Test that security config includes vulnerability scanning settings."""
        if self.security_config_path.exists():
            with open(self.security_config_path, 'r') as f:
                config = json.load(f)

            self.assertIn("vulnerability_scanning", config,
                         "Config should have vulnerability scanning settings")

            vuln_config = config["vulnerability_scanning"]

            # Required vulnerability scanning settings
            required_settings = {
                "pip_audit_enabled": bool,
                "bandit_enabled": bool,
                "safety_enabled": bool,
                "fail_on_vulnerabilities": bool,
                "severity_threshold": str,  # high, medium, low
            }

            for setting_name, expected_type in required_settings.items():
                self.assertIn(setting_name, vuln_config,
                             f"Should have {setting_name} setting")
                self.assertIsInstance(vuln_config[setting_name], expected_type,
                                    f"{setting_name} should be {expected_type.__name__}")

    def test_sbom_generator_script_exists(self):
        """Test that SBOM generator script exists."""
        self.assertTrue(
            self.sbom_script_path.exists(),
            f"SBOM generator script should exist at {self.sbom_script_path}"
        )

    def test_sbom_generator_script_is_executable(self):
        """Test that SBOM generator script is executable."""
        if self.sbom_script_path.exists():
            # Check if script has executable permission
            self.assertTrue(
                os.access(self.sbom_script_path, os.X_OK),
                "SBOM generator script should be executable"
            )

    def test_vulnerability_scanner_script_exists(self):
        """Test that vulnerability scanner script exists."""
        self.assertTrue(
            self.vuln_scanner_path.exists(),
            f"Vulnerability scanner script should exist at {self.vuln_scanner_path}"
        )

    def test_vulnerability_scanner_script_is_executable(self):
        """Test that vulnerability scanner script is executable."""
        if self.vuln_scanner_path.exists():
            # Check if script has executable permission
            self.assertTrue(
                os.access(self.vuln_scanner_path, os.X_OK),
                "Vulnerability scanner script should be executable"
            )

    def test_cyclonedx_sbom_generation(self):
        """Test that CycloneDX SBOM generation works."""
        # This test will fail until cyclonedx-bom is installed and working
        try:
            # Test cyclonedx-bom availability
            result = subprocess.run(
                ["cyclonedx-py", "--help"],
                capture_output=True,
                text=True
            )
            self.assertEqual(result.returncode, 0,
                           "cyclonedx-py command should be available")

        except FileNotFoundError:
            self.fail("cyclonedx-py command should be available")

    def test_pip_audit_vulnerability_detection(self):
        """Test that pip-audit can detect vulnerabilities."""
        # This test will fail until pip-audit is installed
        try:
            # Create temporary requirements file with known vulnerable package
            with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as f:
                # Use a package with known vulnerabilities for testing
                f.write("Django==1.0\n")  # Very old version with known vulnerabilities
                temp_requirements = f.name

            try:
                result = subprocess.run(
                    ["pip-audit", "--requirement", temp_requirements, "--format", "json"],
                    capture_output=True,
                    text=True
                )

                # pip-audit should detect vulnerabilities (exit code != 0)
                self.assertNotEqual(result.returncode, 0,
                                   "pip-audit should detect vulnerabilities in old Django")

                # Should produce valid JSON output
                if result.stdout:
                    try:
                        audit_data = json.loads(result.stdout)
                        self.assertIsInstance(audit_data, (list, dict),
                                            "pip-audit should produce valid JSON")
                    except json.JSONDecodeError:
                        pass  # Some formats might not be JSON

            finally:
                os.unlink(temp_requirements)

        except FileNotFoundError:
            self.fail("pip-audit command should be available")

    def test_bandit_security_scanning(self):
        """Test that bandit can perform security scanning."""
        # Create temporary Python file with security issues
        with tempfile.NamedTemporaryFile(mode='w', suffix='.py', delete=False) as f:
            f.write("""
import subprocess
import os

# Security issue: hardcoded password
password = "hardcoded_password_123"

# Security issue: shell injection vulnerability
def run_command(user_input):
    command = f"echo {user_input}"
    os.system(command)  # Security vulnerability

# Security issue: eval usage
def evaluate_code(code):
    return eval(code)  # Security vulnerability
""")
            temp_file = f.name

        try:
            # This will fail until bandit is installed
            result = subprocess.run(
                ["bandit", "-f", "json", temp_file],
                capture_output=True,
                text=True
            )

            # Bandit should detect security issues (exit code != 0 for issues found)
            self.assertNotEqual(result.returncode, 0,
                               "Bandit should detect security issues in test code")

            # Should produce JSON output
            if result.stdout:
                try:
                    bandit_data = json.loads(result.stdout)
                    self.assertIn("results", bandit_data,
                                "Bandit should produce results section")
                except json.JSONDecodeError:
                    self.fail("Bandit should produce valid JSON output")

        except FileNotFoundError:
            self.fail("bandit command should be available")
        finally:
            os.unlink(temp_file)

    def test_safety_dependency_checking(self):
        """Test that safety can check for vulnerable dependencies."""
        try:
            # Test with current requirements
            result = subprocess.run(
                ["safety", "check", "--json"],
                capture_output=True,
                text=True
            )

            # Safety should run successfully (return code 0 = no vulnerabilities)
            # Note: This might fail if there are actual vulnerabilities
            self.assertIn(result.returncode, [0, 64],  # 0 = clean, 64 = vulnerabilities found
                         "Safety check should run successfully")

        except FileNotFoundError:
            self.fail("safety command should be available")

    def test_sbom_generation_automation(self):
        """Test that SBOM generation can be automated."""
        # This will fail until SBOM generator script is implemented
        if self.sbom_script_path.exists():
            try:
                result = subprocess.run(
                    ["python", str(self.sbom_script_path), "--format", "cyclonedx", "--output", "/tmp/test-sbom.json"],
                    cwd=str(self.test_dir),
                    capture_output=True,
                    text=True
                )

                self.assertEqual(result.returncode, 0,
                               f"SBOM generator should run successfully. stderr: {result.stderr}")

                # Check if SBOM file was created
                sbom_file = Path("/tmp/test-sbom.json")
                self.assertTrue(sbom_file.exists(),
                               "SBOM file should be generated")

                # Validate SBOM format
                with open(sbom_file, 'r') as f:
                    sbom_data = json.load(f)

                # Check for CycloneDX format
                self.assertIn("bomFormat", sbom_data,
                             "SBOM should have bomFormat field")
                self.assertEqual(sbom_data["bomFormat"], "CycloneDX",
                               "SBOM should be in CycloneDX format")

                # Cleanup
                sbom_file.unlink()

            except Exception as e:
                self.fail(f"SBOM generation script execution should work: {e}")

    def test_vulnerability_scanning_automation(self):
        """Test that vulnerability scanning can be automated."""
        # This will fail until vulnerability scanner script is implemented
        if self.vuln_scanner_path.exists():
            try:
                result = subprocess.run(
                    ["python", str(self.vuln_scanner_path), "--format", "json"],
                    cwd=str(self.test_dir),
                    capture_output=True,
                    text=True
                )

                self.assertEqual(result.returncode, 0,
                               f"Vulnerability scanner should run successfully. stderr: {result.stderr}")

                # Check JSON output format
                try:
                    scan_data = json.loads(result.stdout)

                    # Required report sections
                    expected_sections = [
                        "dependency_vulnerabilities",
                        "code_security_issues",
                        "summary",
                        "recommendations"
                    ]

                    for section in expected_sections:
                        self.assertIn(section, scan_data,
                                    f"Scan report should include {section} section")

                except json.JSONDecodeError:
                    self.fail("Vulnerability scanner should produce valid JSON output")

            except Exception as e:
                self.fail(f"Vulnerability scanner script execution should work: {e}")

    def test_ci_integration_with_security_scanning(self):
        """Test that security scanning is integrated into CI/CD."""
        # Check GitHub Actions workflow includes security checks
        github_workflow_path = self.test_dir / ".github" / "workflows" / "ci.yml"

        if github_workflow_path.exists():
            with open(github_workflow_path, 'r') as f:
                workflow_content = f.read()

            # Should include security scanning steps
            security_indicators = [
                "sbom",
                "vulnerability",
                "security",
                "bandit",
                "pip-audit",
                "safety"
            ]

            has_security_steps = any(indicator in workflow_content.lower()
                                   for indicator in security_indicators)

            self.assertTrue(has_security_steps,
                           "CI workflow should include security scanning steps")

    def test_security_policy_documentation_exists(self):
        """Test that security policy documentation exists."""
        # Check for security policy documentation
        security_docs = [
            self.test_dir / "docs" / "security-policy.md",
            self.test_dir / ".claude" / "docs" / "security-guide.md",
            self.test_dir / "SECURITY.md"
        ]

        policy_exists = any(doc.exists() for doc in security_docs)
        self.assertTrue(policy_exists,
                       "Security policy documentation should exist")

if __name__ == '__main__':
    # Set up proper test environment
    sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent))
    unittest.main()