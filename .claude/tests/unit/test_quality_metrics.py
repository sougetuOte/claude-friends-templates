#!/usr/bin/env python3
"""
Test quality metrics measurement and monitoring system.
TDD Red Phase: These tests will fail until quality metrics system is implemented.
"""
import os
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch, MagicMock
import sys

class TestQualityMetrics(unittest.TestCase):
    """Test suite for code quality metrics measurement system."""

    def setUp(self):
        """Set up test environment before each test."""
        self.test_dir = Path(__file__).parent.parent.parent.parent
        self.quality_config_path = self.test_dir / ".claude" / "quality-config.json"
        self.metrics_script_path = self.test_dir / ".claude" / "scripts" / "quality-metrics.py"
        self.requirements_path = self.test_dir / "requirements.txt"

    def test_quality_metrics_dependencies_in_requirements(self):
        """Test that quality metrics dependencies are in requirements.txt."""
        if self.requirements_path.exists():
            with open(self.requirements_path, 'r') as f:
                content = f.read()

            # Check for quality metrics packages
            quality_packages = [
                "radon",  # Code complexity metrics
                "xenon",  # CI-friendly complexity checker
                "mccabe", # Cyclomatic complexity
                "flake8-complexity", # Flake8 complexity plugin
            ]

            has_quality_packages = any(pkg in content for pkg in quality_packages)
            self.assertTrue(
                has_quality_packages,
                f"requirements.txt should include quality metrics packages: {quality_packages}"
            )

    def test_quality_config_file_exists(self):
        """Test that quality metrics configuration file exists."""
        self.assertTrue(
            self.quality_config_path.exists(),
            f"Quality configuration file should exist at {self.quality_config_path}"
        )

    def test_quality_config_has_complexity_thresholds(self):
        """Test that quality config defines complexity thresholds."""
        if self.quality_config_path.exists():
            with open(self.quality_config_path, 'r') as f:
                config = json.load(f)

            # Check for complexity settings
            self.assertIn("complexity_thresholds", config,
                         "Config should have complexity_thresholds section")

            thresholds = config["complexity_thresholds"]

            # Verify threshold types
            expected_thresholds = {
                "cyclomatic_complexity": int,
                "cognitive_complexity": int,
                "max_lines_per_function": int,
                "max_parameters": int,
            }

            for threshold_name, expected_type in expected_thresholds.items():
                self.assertIn(threshold_name, thresholds,
                             f"Should have {threshold_name} threshold")
                self.assertIsInstance(thresholds[threshold_name], expected_type,
                                    f"{threshold_name} should be {expected_type.__name__}")

    def test_quality_config_has_duplication_settings(self):
        """Test that quality config includes duplication detection settings."""
        if self.quality_config_path.exists():
            with open(self.quality_config_path, 'r') as f:
                config = json.load(f)

            self.assertIn("duplication", config,
                         "Config should have duplication settings")

            duplication = config["duplication"]
            self.assertIn("min_lines", duplication,
                         "Should specify minimum lines for duplication detection")
            self.assertIn("threshold_percentage", duplication,
                         "Should specify duplication threshold percentage")

    def test_quality_metrics_script_exists(self):
        """Test that quality metrics measurement script exists."""
        self.assertTrue(
            self.metrics_script_path.exists(),
            f"Quality metrics script should exist at {self.metrics_script_path}"
        )

    def test_quality_metrics_script_is_executable(self):
        """Test that quality metrics script is executable."""
        if self.metrics_script_path.exists():
            # Check if script has executable permission
            self.assertTrue(
                os.access(self.metrics_script_path, os.X_OK),
                "Quality metrics script should be executable"
            )

    def test_radon_complexity_measurement(self):
        """Test that radon can measure code complexity."""
        # This test will fail until radon is installed and working
        try:
            import radon
            from radon.complexity import cc_visit
        except ImportError:
            self.fail("radon package should be available for complexity measurement")

        # Test with simple code sample
        test_code = """
def simple_function():
    return 42

def complex_function(x):
    if x > 0:
        if x > 10:
            return "high"
        else:
            return "medium"
    else:
        return "low"
"""

        try:
            results = cc_visit(test_code)
            self.assertIsInstance(results, list, "Should return list of complexity results")
            self.assertGreater(len(results), 0, "Should find at least one function")

            # Check complexity result structure
            for result in results:
                self.assertTrue(hasattr(result, 'complexity'), "Should have complexity attribute")
                self.assertTrue(hasattr(result, 'name'), "Should have name attribute")

        except Exception as e:
            self.fail(f"Radon complexity measurement should work: {e}")

    def test_xenon_threshold_checking(self):
        """Test that xenon can perform threshold-based complexity checking."""
        # Create temporary Python file with known complexity
        with tempfile.NamedTemporaryFile(mode='w', suffix='.py', delete=False) as f:
            f.write("""
def high_complexity_function(a, b, c, d, e):
    if a > 0:
        if b > 0:
            if c > 0:
                if d > 0:
                    if e > 0:
                        return a + b + c + d + e
                    else:
                        return a + b + c + d
                else:
                    return a + b + c
            else:
                return a + b
        else:
            return a
    else:
        return 0
""")
            temp_file = f.name

        try:
            # This will fail until xenon is installed
            result = subprocess.run(
                ["xenon", "--max-average", "A", temp_file],
                capture_output=True,
                text=True
            )

            # Xenon should exit with non-zero for high complexity
            self.assertNotEqual(result.returncode, 0,
                               "Xenon should fail for high complexity code")

        except FileNotFoundError:
            self.fail("xenon command should be available")
        finally:
            os.unlink(temp_file)

    def test_mccabe_integration(self):
        """Test that mccabe complexity checker works."""
        try:
            from mccabe import get_code_complexity
        except ImportError:
            self.fail("mccabe package should be available")

        # Test with complex code
        complex_code = """
def nested_conditions(x, y, z):
    if x:
        if y:
            if z:
                return 1
            else:
                return 2
        else:
            return 3
    elif y:
        return 4
    else:
        return 5
"""

        try:
            # mccabe.get_code_complexity returns int (0 = no violations, >0 = violations found)
            complexity = get_code_complexity(complex_code, threshold=7, filename="test")
            self.assertIsInstance(complexity, int, "Should return integer complexity count")

            # For complex code with low threshold, should find violations
            violations = get_code_complexity(complex_code, threshold=1, filename="test")
            self.assertGreater(violations, 0, "Should detect complexity violations with low threshold")

        except Exception as e:
            self.fail(f"McCabe complexity checking should work: {e}")

    def test_quality_report_generation(self):
        """Test that quality metrics can generate comprehensive reports."""
        # This will fail until report generation is implemented
        if self.metrics_script_path.exists():
            try:
                result = subprocess.run(
                    ["python", str(self.metrics_script_path), "--report", "--json"],
                    cwd=str(self.test_dir),
                    capture_output=True,
                    text=True
                )

                self.assertEqual(result.returncode, 0,
                               f"Quality metrics script should run successfully. "
                               f"stdout: '{result.stdout}', stderr: '{result.stderr}'")

                # Check JSON output format
                if not result.stdout.strip():
                    self.fail(f"No output from script. stderr: {result.stderr}")

                try:
                    report = json.loads(result.stdout)

                    # Required report sections
                    expected_sections = [
                        "complexity_metrics",
                        "duplication_metrics",
                        "maintainability_index",
                        "summary",
                        "recommendations"
                    ]

                    for section in expected_sections:
                        self.assertIn(section, report,
                                    f"Report should include {section} section")

                except json.JSONDecodeError:
                    self.fail("Quality report should produce valid JSON output")

            except Exception as e:
                self.fail(f"Quality metrics script execution should work: {e}")

    def test_ci_integration_config(self):
        """Test that quality metrics are configured for CI integration."""
        # Check GitHub Actions workflow includes quality checks
        github_workflow_path = self.test_dir / ".github" / "workflows" / "ci.yml"

        if github_workflow_path.exists():
            with open(github_workflow_path, 'r') as f:
                workflow_content = f.read()

            # Should include quality metric steps
            quality_indicators = [
                "radon",
                "xenon",
                "quality",
                "complexity"
            ]

            has_quality_steps = any(indicator in workflow_content.lower()
                                  for indicator in quality_indicators)

            self.assertTrue(has_quality_steps,
                           "CI workflow should include quality metric checks")

if __name__ == '__main__':
    # Set up proper test environment
    sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent))
    unittest.main()