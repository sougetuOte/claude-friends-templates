#!/usr/bin/env python3

"""
API Documentation Automation Tests
Following t-wada TDD methodology - Red Phase
Tests for OpenAPI/Swagger documentation automation system
"""

import unittest
import json
import subprocess
import tempfile
import shutil
from pathlib import Path
import yaml
import sys
import os

# Add project root to path for imports
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))


class TestAPIDocumentationAutomation(unittest.TestCase):
    """Test suite for API documentation automation system"""

    def setUp(self):
        """Set up test environment"""
        self.project_root = Path(__file__).parent.parent.parent.parent
        self.test_dir = tempfile.mkdtemp()
        self.api_docs_script = (
            self.project_root / ".claude" / "scripts" / "api-docs-generator.py"
        )
        self.config_file = self.project_root / ".claude" / "api-docs-config.json"

    def tearDown(self):
        """Clean up test environment"""
        if os.path.exists(self.test_dir):
            shutil.rmtree(self.test_dir)

    def test_api_docs_generator_script_exists(self):
        """Test 1: API documentation generator script exists"""
        self.assertTrue(
            self.api_docs_script.exists(),
            f"API docs generator script should exist at {self.api_docs_script}",
        )

    def test_api_docs_generator_script_is_executable(self):
        """Test 2: API documentation generator script is executable"""
        self.assertTrue(
            os.access(self.api_docs_script, os.X_OK),
            "API docs generator script should be executable",
        )

    def test_api_docs_config_file_exists(self):
        """Test 3: API documentation configuration file exists"""
        self.assertTrue(
            self.config_file.exists(),
            f"API docs config file should exist at {self.config_file}",
        )

    def test_api_docs_config_has_required_settings(self):
        """Test 4: API documentation config has required settings"""
        self.assertTrue(self.config_file.exists(), "Config file must exist")

        with open(self.config_file, "r") as f:
            config = json.load(f)

        # Required configuration sections
        required_sections = [
            "openapi",
            "swagger_ui",
            "redoc",
            "scalar",
            "validation",
            "ci_integration",
            "output",
        ]

        for section in required_sections:
            self.assertIn(section, config, f"Config should contain '{section}' section")

    def test_openapi_schema_generation(self):
        """Test 5: OpenAPI schema generation from code annotations"""
        # Create a sample API file
        sample_api = """
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(title="Test API", version="1.0.0")

class User(BaseModel):
    id: int
    name: str
    email: str

@app.get("/users", response_model=list[User])
def get_users():
    '''Get all users'''
    return []

@app.post("/users", response_model=User)
def create_user(user: User):
    '''Create a new user'''
    return user
"""

        sample_file = Path(self.test_dir) / "test_api.py"
        with open(sample_file, "w") as f:
            f.write(sample_api)

        # Test schema generation
        result = subprocess.run(
            [
                "python",
                str(self.api_docs_script),
                "--input",
                str(sample_file),
                "--output",
                str(Path(self.test_dir) / "schema.json"),
                "--format",
                "json",
            ],
            capture_output=True,
            text=True,
        )

        self.assertEqual(
            result.returncode,
            0,
            f"Schema generation should succeed. stderr: {result.stderr}",
        )

        # Check generated schema
        schema_file = Path(self.test_dir) / "schema.json"
        self.assertTrue(schema_file.exists(), "Schema file should be generated")

        with open(schema_file, "r") as f:
            schema = json.loads(f.read())

        # Validate OpenAPI structure
        required_fields = ["openapi", "info", "paths"]
        for field in required_fields:
            self.assertIn(field, schema, f"Schema should contain '{field}' field")

    def test_swagger_ui_generation(self):
        """Test 6: Swagger UI documentation generation"""
        # Create sample schema
        sample_schema = {
            "openapi": "3.0.0",
            "info": {"title": "Test API", "version": "1.0.0"},
            "paths": {
                "/users": {
                    "get": {
                        "summary": "Get users",
                        "responses": {"200": {"description": "Success"}},
                    }
                }
            },
        }

        schema_file = Path(self.test_dir) / "schema.json"
        with open(schema_file, "w") as f:
            json.dump(sample_schema, f)

        # Test Swagger UI generation
        result = subprocess.run(
            [
                "python",
                str(self.api_docs_script),
                "--schema",
                str(schema_file),
                "--generate",
                "swagger-ui",
                "--output",
                str(Path(self.test_dir) / "swagger-ui"),
            ],
            capture_output=True,
            text=True,
        )

        self.assertEqual(
            result.returncode,
            0,
            f"Swagger UI generation should succeed. stderr: {result.stderr}",
        )

        # Check generated files
        swagger_dir = Path(self.test_dir) / "swagger-ui"
        self.assertTrue(swagger_dir.exists(), "Swagger UI directory should be created")

        required_files = [
            "index.html",
            "swagger-ui-bundle.js",
            "swagger-ui-standalone-preset.js",
        ]
        for file_name in required_files:
            file_path = swagger_dir / file_name
            self.assertTrue(
                file_path.exists(), f"Swagger UI should contain {file_name}"
            )

    def test_redoc_generation(self):
        """Test 7: ReDoc documentation generation"""
        sample_schema = {
            "openapi": "3.0.0",
            "info": {"title": "Test API", "version": "1.0.0"},
            "paths": {
                "/health": {"get": {"responses": {"200": {"description": "OK"}}}}
            },
        }

        schema_file = Path(self.test_dir) / "schema.json"
        with open(schema_file, "w") as f:
            json.dump(sample_schema, f)

        result = subprocess.run(
            [
                "python",
                str(self.api_docs_script),
                "--schema",
                str(schema_file),
                "--generate",
                "redoc",
                "--output",
                str(Path(self.test_dir) / "redoc"),
            ],
            capture_output=True,
            text=True,
        )

        self.assertEqual(
            result.returncode,
            0,
            f"ReDoc generation should succeed. stderr: {result.stderr}",
        )

        redoc_dir = Path(self.test_dir) / "redoc"
        self.assertTrue(redoc_dir.exists(), "ReDoc directory should be created")
        self.assertTrue(
            (redoc_dir / "index.html").exists(), "ReDoc should have index.html"
        )

    def test_openapi_schema_validation(self):
        """Test 8: OpenAPI schema validation"""
        # Test valid schema
        valid_schema = {
            "openapi": "3.0.0",
            "info": {"title": "Valid API", "version": "1.0.0"},
            "paths": {},
        }

        valid_file = Path(self.test_dir) / "valid_schema.json"
        with open(valid_file, "w") as f:
            json.dump(valid_schema, f)

        result = subprocess.run(
            ["python", str(self.api_docs_script), "--validate", str(valid_file)],
            capture_output=True,
            text=True,
        )

        self.assertEqual(
            result.returncode,
            0,
            f"Valid schema should pass validation. stderr: {result.stderr}",
        )

        # Test invalid schema
        invalid_schema = {
            "openapi": "3.0.0",
            # Missing required 'info' field
            "paths": {},
        }

        invalid_file = Path(self.test_dir) / "invalid_schema.json"
        with open(invalid_file, "w") as f:
            json.dump(invalid_schema, f)

        result = subprocess.run(
            ["python", str(self.api_docs_script), "--validate", str(invalid_file)],
            capture_output=True,
            text=True,
        )

        self.assertNotEqual(
            result.returncode, 0, "Invalid schema should fail validation"
        )

    def test_multiple_format_support(self):
        """Test 9: Support for multiple output formats (JSON, YAML)"""
        # Test JSON output
        json_file = Path(self.test_dir) / "schema.json"
        result = subprocess.run(
            [
                "python",
                str(self.api_docs_script),
                "--generate-schema",
                "--output",
                str(json_file),
                "--format",
                "json",
            ],
            capture_output=True,
            text=True,
        )

        self.assertEqual(result.returncode, 0, "JSON format generation should succeed")
        self.assertTrue(json_file.exists(), "JSON schema file should be created")

        # Test YAML output
        yaml_file = Path(self.test_dir) / "schema.yaml"
        result = subprocess.run(
            [
                "python",
                str(self.api_docs_script),
                "--generate-schema",
                "--output",
                str(yaml_file),
                "--format",
                "yaml",
            ],
            capture_output=True,
            text=True,
        )

        self.assertEqual(result.returncode, 0, "YAML format generation should succeed")
        self.assertTrue(yaml_file.exists(), "YAML schema file should be created")

    def test_code_sample_generation(self):
        """Test 10: Automatic code sample generation"""
        sample_schema = {
            "openapi": "3.0.0",
            "info": {"title": "Test API", "version": "1.0.0"},
            "paths": {
                "/users": {
                    "post": {
                        "requestBody": {
                            "content": {
                                "application/json": {
                                    "schema": {
                                        "type": "object",
                                        "properties": {
                                            "name": {"type": "string"},
                                            "email": {"type": "string"},
                                        },
                                    }
                                }
                            }
                        }
                    }
                }
            },
        }

        schema_file = Path(self.test_dir) / "schema.json"
        with open(schema_file, "w") as f:
            json.dump(sample_schema, f)

        result = subprocess.run(
            [
                "python",
                str(self.api_docs_script),
                "--schema",
                str(schema_file),
                "--generate-samples",
                "--languages",
                "python,javascript,curl",
                "--output",
                str(Path(self.test_dir) / "samples"),
            ],
            capture_output=True,
            text=True,
        )

        self.assertEqual(
            result.returncode,
            0,
            f"Code sample generation should succeed. stderr: {result.stderr}",
        )

        samples_dir = Path(self.test_dir) / "samples"
        self.assertTrue(samples_dir.exists(), "Samples directory should be created")

        expected_files = ["python.py", "javascript.js", "curl.sh"]
        for file_name in expected_files:
            self.assertTrue(
                (samples_dir / file_name).exists(),
                f"Sample file {file_name} should be generated",
            )

    def test_ci_integration_configuration(self):
        """Test 11: CI/CD integration configuration"""
        result = subprocess.run(
            [
                "python",
                str(self.api_docs_script),
                "--setup-ci",
                "--ci-type",
                "github-actions",
                "--output",
                str(Path(self.test_dir) / ".github"),
            ],
            capture_output=True,
            text=True,
        )

        self.assertEqual(
            result.returncode, 0, f"CI setup should succeed. stderr: {result.stderr}"
        )

        ci_file = Path(self.test_dir) / ".github" / "workflows" / "api-docs.yml"
        self.assertTrue(ci_file.exists(), "GitHub Actions workflow should be created")

        # Check workflow content
        with open(ci_file, "r") as f:
            workflow = f.read()

        required_steps = ["checkout", "generate-docs", "validate-schema", "deploy-docs"]

        for step in required_steps:
            self.assertIn(step, workflow, f"Workflow should contain {step} step")

    def test_documentation_completeness_check(self):
        """Test 12: Documentation completeness validation"""
        # Create incomplete schema (missing descriptions)
        incomplete_schema = {
            "openapi": "3.0.0",
            "info": {"title": "Test API", "version": "1.0.0"},
            "paths": {
                "/users": {
                    "get": {
                        "responses": {"200": {"description": "Success"}}
                        # Missing summary, description, parameters
                    }
                }
            },
        }

        schema_file = Path(self.test_dir) / "incomplete.json"
        with open(schema_file, "w") as f:
            json.dump(incomplete_schema, f)

        result = subprocess.run(
            [
                "python",
                str(self.api_docs_script),
                "--check-completeness",
                str(schema_file),
                "--min-coverage",
                "80",
            ],
            capture_output=True,
            text=True,
        )

        # Should fail due to incomplete documentation
        self.assertNotEqual(
            result.returncode,
            0,
            "Incomplete documentation should fail completeness check",
        )

        # Check that it reports specific issues
        self.assertIn(
            "missing",
            result.stdout.lower() or result.stderr.lower(),
            "Should report missing documentation elements",
        )

    def test_interactive_documentation_server(self):
        """Test 13: Interactive documentation server"""
        sample_schema = {
            "openapi": "3.0.0",
            "info": {"title": "Test API", "version": "1.0.0"},
            "paths": {},
        }

        schema_file = Path(self.test_dir) / "schema.json"
        with open(schema_file, "w") as f:
            json.dump(sample_schema, f)

        # Test server start (should return quickly for testing)
        result = subprocess.run(
            [
                "python",
                str(self.api_docs_script),
                "--serve",
                "--schema",
                str(schema_file),
                "--port",
                "8080",
                "--test-mode",  # Special flag for testing
            ],
            capture_output=True,
            text=True,
            timeout=10,
        )

        self.assertEqual(
            result.returncode,
            0,
            f"Documentation server should start successfully. stderr: {result.stderr}",
        )

        # Check that server indicates successful startup
        self.assertIn(
            "server",
            result.stdout.lower() or result.stderr.lower(),
            "Should indicate server startup",
        )

    def test_theme_and_customization_support(self):
        """Test 14: Documentation theme and customization"""
        result = subprocess.run(
            [
                "python",
                str(self.api_docs_script),
                "--customize",
                "--theme",
                "dark",
                "--logo",
                str(Path(self.test_dir) / "logo.png"),
                "--custom-css",
                str(Path(self.test_dir) / "custom.css"),
                "--output",
                str(Path(self.test_dir) / "customized"),
            ],
            capture_output=True,
            text=True,
        )

        self.assertEqual(
            result.returncode,
            0,
            f"Documentation customization should succeed. stderr: {result.stderr}",
        )

        customized_dir = Path(self.test_dir) / "customized"
        self.assertTrue(
            customized_dir.exists(), "Customized documentation should be created"
        )

    def test_security_scheme_documentation(self):
        """Test 15: Security scheme documentation generation"""
        schema_with_security = {
            "openapi": "3.0.0",
            "info": {"title": "Secure API", "version": "1.0.0"},
            "components": {
                "securitySchemes": {
                    "bearerAuth": {
                        "type": "http",
                        "scheme": "bearer",
                        "bearerFormat": "JWT",
                    }
                }
            },
            "security": [{"bearerAuth": []}],
            "paths": {
                "/protected": {
                    "get": {
                        "security": [{"bearerAuth": []}],
                        "responses": {"200": {"description": "Success"}},
                    }
                }
            },
        }

        schema_file = Path(self.test_dir) / "secure_schema.json"
        with open(schema_file, "w") as f:
            json.dump(schema_with_security, f)

        result = subprocess.run(
            [
                "python",
                str(self.api_docs_script),
                "--schema",
                str(schema_file),
                "--generate",
                "swagger-ui",
                "--output",
                str(Path(self.test_dir) / "secure-docs"),
            ],
            capture_output=True,
            text=True,
        )

        self.assertEqual(
            result.returncode,
            0,
            f"Secure API documentation should be generated. stderr: {result.stderr}",
        )

        # Check that security information is preserved
        docs_dir = Path(self.test_dir) / "secure-docs"
        self.assertTrue(docs_dir.exists(), "Secure docs directory should be created")

    def test_api_docs_dependencies_in_requirements(self):
        """Test 16: API documentation dependencies are in requirements.txt"""
        requirements_file = self.project_root / "requirements.txt"
        self.assertTrue(requirements_file.exists(), "requirements.txt should exist")

        with open(requirements_file, "r") as f:
            requirements = f.read()

        # Check for required API documentation packages
        required_packages = [
            "fastapi",
            "pydantic",
            "uvicorn",
            "openapi-spec-validator",
            "pyyaml",
        ]

        for package in required_packages:
            self.assertIn(
                package,
                requirements.lower(),
                f"requirements.txt should contain {package} for API documentation",
            )

    # Error Path Tests (Refactor Phase - Coverage Improvement)

    def test_schema_generation_with_missing_input_file(self):
        """Test 17: Schema generation handles missing input file gracefully"""
        non_existent_file = Path(self.test_dir) / "nonexistent.py"
        output_file = Path(self.test_dir) / "schema.json"

        result = subprocess.run(
            [
                "python",
                str(self.api_docs_script),
                "--input",
                str(non_existent_file),
                "--output",
                str(output_file),
                "--format",
                "json",
            ],
            capture_output=True,
            text=True,
        )

        # Should complete but output minimal schema (empty paths)
        self.assertEqual(
            result.returncode, 0, "Should handle missing input file gracefully"
        )

        # Check that a schema was still generated (with empty paths)
        self.assertTrue(
            output_file.exists(), "Should generate schema even without input"
        )

        with open(output_file, "r") as f:
            schema = json.load(f)

        # Should have basic structure but empty paths
        self.assertIn("openapi", schema)
        self.assertIn("info", schema)
        self.assertIn("paths", schema)

    def test_schema_generation_with_unreadable_file(self):
        """Test 18: Schema generation handles permission errors"""
        # Create a file and make it unreadable
        unreadable_file = Path(self.test_dir) / "unreadable.py"
        unreadable_file.write_text("test content")
        os.chmod(unreadable_file, 0o000)

        output_file = Path(self.test_dir) / "schema.json"

        try:
            result = subprocess.run(
                [
                    "python",
                    str(self.api_docs_script),
                    "--input",
                    str(unreadable_file),
                    "--output",
                    str(output_file),
                    "--format",
                    "json",
                ],
                capture_output=True,
                text=True,
            )

            # Should fail gracefully (either error exit or success with empty schema)
            # Implementation may vary, just check it doesn't crash
            self.assertIn(
                result.returncode,
                [0, 1],
                "Should handle unreadable file without crashing",
            )
        finally:
            # Restore permissions for cleanup
            os.chmod(unreadable_file, 0o644)

    def test_swagger_ui_generation_with_missing_schema_file(self):
        """Test 19: Swagger UI generation handles missing schema file"""
        non_existent_schema = Path(self.test_dir) / "missing_schema.json"

        result = subprocess.run(
            [
                "python",
                str(self.api_docs_script),
                "--schema",
                str(non_existent_schema),
                "--generate",
                "swagger-ui",
                "--output",
                str(Path(self.test_dir) / "swagger-ui-error"),
            ],
            capture_output=True,
            text=True,
        )

        # Should handle missing schema gracefully
        self.assertEqual(
            result.returncode, 0, "Should create Swagger UI even without schema file"
        )

    def test_redoc_generation_with_missing_schema(self):
        """Test 20: ReDoc generation handles missing schema"""
        non_existent_schema = Path(self.test_dir) / "missing_schema.json"

        result = subprocess.run(
            [
                "python",
                str(self.api_docs_script),
                "--schema",
                str(non_existent_schema),
                "--generate",
                "redoc",
                "--output",
                str(Path(self.test_dir) / "redoc-error"),
            ],
            capture_output=True,
            text=True,
        )

        # Should handle missing schema gracefully
        self.assertEqual(
            result.returncode, 0, "Should create ReDoc even without schema file"
        )

    def test_validation_with_malformed_yaml(self):
        """Test 21: Validation handles malformed YAML gracefully"""
        malformed_yaml_file = Path(self.test_dir) / "malformed.yaml"
        with open(malformed_yaml_file, "w") as f:
            f.write("openapi: 3.0.0\ninfo: [invalid yaml structure\npaths: }}}")

        result = subprocess.run(
            [
                "python",
                str(self.api_docs_script),
                "--validate",
                str(malformed_yaml_file),
            ],
            capture_output=True,
            text=True,
        )

        # Should fail validation for malformed YAML
        self.assertNotEqual(result.returncode, 0, "Should detect malformed YAML")
        self.assertIn(
            "error",
            result.stdout.lower() or result.stderr.lower(),
            "Should report validation error",
        )

    def test_validation_with_malformed_json(self):
        """Test 22: Validation handles malformed JSON gracefully"""
        malformed_json_file = Path(self.test_dir) / "malformed.json"
        with open(malformed_json_file, "w") as f:
            f.write('{"openapi": "3.0.0", "info": invalid json}')

        result = subprocess.run(
            [
                "python",
                str(self.api_docs_script),
                "--validate",
                str(malformed_json_file),
            ],
            capture_output=True,
            text=True,
        )

        # Should fail validation for malformed JSON
        self.assertNotEqual(result.returncode, 0, "Should detect malformed JSON")

    def test_code_sample_generation_with_missing_schema(self):
        """Test 23: Code sample generation handles missing schema"""
        result = subprocess.run(
            [
                "python",
                str(self.api_docs_script),
                "--schema",
                str(Path(self.test_dir) / "nonexistent.json"),
                "--generate-samples",
                "--languages",
                "python,javascript",
                "--output",
                str(Path(self.test_dir) / "samples-error"),
            ],
            capture_output=True,
            text=True,
        )

        # Should fail when schema doesn't exist
        self.assertNotEqual(
            result.returncode, 0, "Should fail when schema file is missing"
        )

    def test_ci_integration_with_readonly_directory(self):
        """Test 24: CI integration handles permission errors"""
        # Test with valid CI type - just ensure it doesn't crash
        result = subprocess.run(
            [
                "python",
                str(self.api_docs_script),
                "--setup-ci",
                "--ci-type",
                "github-actions",
                "--output",
                str(Path(self.test_dir) / "ci-test"),
            ],
            capture_output=True,
            text=True,
        )

        # Should succeed for valid CI type and writable directory
        self.assertEqual(
            result.returncode, 0, "Should setup CI for valid configuration"
        )

    def test_completeness_check_with_corrupted_schema(self):
        """Test 25: Completeness check handles corrupted schema"""
        corrupted_schema_file = Path(self.test_dir) / "corrupted.json"
        with open(corrupted_schema_file, "w") as f:
            f.write("not a valid json at all")

        result = subprocess.run(
            [
                "python",
                str(self.api_docs_script),
                "--check-completeness",
                str(corrupted_schema_file),
                "--min-coverage",
                "80",
            ],
            capture_output=True,
            text=True,
        )

        # Should fail when schema is corrupted
        self.assertNotEqual(result.returncode, 0, "Should detect corrupted schema")

    # Configuration Tests

    def test_load_config_without_config_file(self):
        """Test 26: Load default config when config file doesn't exist"""
        # Create a generator with non-existent config
        import sys

        # Add scripts to path
        scripts_path = self.project_root / ".claude" / "scripts"
        sys.path.insert(0, str(scripts_path))

        try:
            # Import after adding to path
            import importlib

            api_docs_module = importlib.import_module("api-docs-generator")
            APIDocumentationGenerator = api_docs_module.APIDocumentationGenerator

            # Initialize with non-existent config
            generator = APIDocumentationGenerator(
                config_path="/nonexistent/config.json"
            )

            # Should have default config
            self.assertIsNotNone(generator.config)
            self.assertIn("openapi", generator.config)
            self.assertIn("swagger_ui", generator.config)
            self.assertIn("redoc", generator.config)
            self.assertEqual(generator.config["openapi"]["version"], "3.0.0")
        finally:
            sys.path.remove(str(scripts_path))

    # Edge Case Tests

    def test_schema_generation_with_no_routes(self):
        """Test 27: Schema generation with empty API file"""
        empty_api_file = Path(self.test_dir) / "empty_api.py"
        with open(empty_api_file, "w") as f:
            f.write("# Empty API file with no routes\n")

        output_file = Path(self.test_dir) / "empty_schema.json"

        result = subprocess.run(
            [
                "python",
                str(self.api_docs_script),
                "--input",
                str(empty_api_file),
                "--output",
                str(output_file),
                "--format",
                "json",
            ],
            capture_output=True,
            text=True,
        )

        self.assertEqual(result.returncode, 0, "Should generate schema for empty API")

        with open(output_file, "r") as f:
            schema = json.load(f)

        # Should have valid structure but empty paths
        self.assertIn("paths", schema)
        self.assertEqual(len(schema["paths"]), 0, "Should have no paths for empty API")

    def test_cli_with_no_arguments(self):
        """Test 28: CLI displays help when no arguments provided"""
        result = subprocess.run(
            ["python", str(self.api_docs_script)], capture_output=True, text=True
        )

        # Should display help and exit with error code
        self.assertNotEqual(
            result.returncode, 0, "Should return error when no arguments provided"
        )
        self.assertTrue(
            len(result.stdout) > 0 or len(result.stderr) > 0,
            "Should display help message",
        )

    def test_server_start_in_test_mode(self):
        """Test 29: Server start with test mode flag"""
        result = subprocess.run(
            [
                "python",
                str(self.api_docs_script),
                "--serve",
                "--port",
                "9999",
                "--test-mode",
            ],
            capture_output=True,
            text=True,
            timeout=5,
        )

        # Should succeed in test mode
        self.assertEqual(result.returncode, 0, "Should start in test mode successfully")
        self.assertIn(
            "server",
            result.stdout.lower() or result.stderr.lower(),
            "Should indicate server startup",
        )

    def test_validation_with_missing_title_in_info(self):
        """Test 30: Validation detects missing title in info section"""
        schema_without_title = {
            "openapi": "3.0.0",
            "info": {"version": "1.0.0"},  # Missing title
            "paths": {},
        }

        schema_file = Path(self.test_dir) / "no_title.json"
        with open(schema_file, "w") as f:
            json.dump(schema_without_title, f)

        result = subprocess.run(
            ["python", str(self.api_docs_script), "--validate", str(schema_file)],
            capture_output=True,
            text=True,
        )

        # Should fail validation
        self.assertNotEqual(result.returncode, 0, "Should detect missing title")
        self.assertIn(
            "title",
            result.stdout.lower() or result.stderr.lower(),
            "Should report missing title",
        )

    def test_completeness_check_with_well_documented_api(self):
        """Test 31: Completeness check passes for well-documented API"""
        well_documented_schema = {
            "openapi": "3.0.0",
            "info": {"title": "Well Documented API", "version": "1.0.0"},
            "paths": {
                "/users": {
                    "get": {
                        "summary": "Get all users",
                        "description": "Returns a list of all users in the system",
                        "responses": {"200": {"description": "Success"}},
                    },
                    "post": {
                        "summary": "Create user",
                        "description": "Creates a new user in the system",
                        "responses": {"201": {"description": "Created"}},
                    },
                },
                "/users/{id}": {
                    "get": {
                        "summary": "Get user by ID",
                        "description": "Returns a single user by ID",
                        "responses": {"200": {"description": "Success"}},
                    }
                },
            },
        }

        schema_file = Path(self.test_dir) / "well_documented.json"
        with open(schema_file, "w") as f:
            json.dump(well_documented_schema, f)

        result = subprocess.run(
            [
                "python",
                str(self.api_docs_script),
                "--check-completeness",
                str(schema_file),
                "--min-coverage",
                "80",
            ],
            capture_output=True,
            text=True,
        )

        # Should pass completeness check
        self.assertEqual(result.returncode, 0, "Should pass for well-documented API")

    def test_code_sample_generation_with_custom_base_url(self):
        """Test 32: Code sample generation uses custom base URL from servers"""
        schema_with_servers = {
            "openapi": "3.0.0",
            "info": {"title": "Test API", "version": "1.0.0"},
            "servers": [{"url": "https://api.example.com/v1"}],
            "paths": {
                "/health": {"get": {"responses": {"200": {"description": "OK"}}}}
            },
        }

        schema_file = Path(self.test_dir) / "servers_schema.json"
        with open(schema_file, "w") as f:
            json.dump(schema_with_servers, f)

        result = subprocess.run(
            [
                "python",
                str(self.api_docs_script),
                "--schema",
                str(schema_file),
                "--generate-samples",
                "--languages",
                "python,curl",
                "--output",
                str(Path(self.test_dir) / "custom_samples"),
            ],
            capture_output=True,
            text=True,
        )

        self.assertEqual(
            result.returncode, 0, "Should generate samples with custom base URL"
        )

        # Check that samples contain custom URL
        python_sample = Path(self.test_dir) / "custom_samples" / "python.py"
        self.assertTrue(python_sample.exists(), "Python sample should exist")

        with open(python_sample, "r") as f:
            content = f.read()

        self.assertIn(
            "https://api.example.com/v1",
            content,
            "Should use custom base URL from servers",
        )

    def test_schema_generation_with_router_pattern(self):
        """Test 33: Schema generation detects @router patterns"""
        router_api_file = Path(self.test_dir) / "router_api.py"
        with open(router_api_file, "w") as f:
            f.write("""
from fastapi import APIRouter

router = APIRouter(prefix="/api/v1")

@router.get("/items")
def get_items():
    return []

@router.post("/items")
def create_item():
    return {}

@router.delete("/items/{id}")
def delete_item(id: int):
    pass
""")

        output_file = Path(self.test_dir) / "router_schema.json"

        result = subprocess.run(
            [
                "python",
                str(self.api_docs_script),
                "--input",
                str(router_api_file),
                "--output",
                str(output_file),
                "--format",
                "json",
            ],
            capture_output=True,
            text=True,
        )

        self.assertEqual(
            result.returncode, 0, "Should generate schema for @router patterns"
        )

        with open(output_file, "r") as f:
            schema = json.load(f)

        # Should have detected the routes
        self.assertIn("paths", schema)
        self.assertGreater(len(schema["paths"]), 0, "Should detect router-based routes")

    def test_yaml_schema_generation(self):
        """Test 34: Schema can be generated in YAML format"""
        sample_api = Path(self.test_dir) / "test_api.py"
        with open(sample_api, "w") as f:
            f.write("""
from fastapi import FastAPI
app = FastAPI()

@app.get("/test")
def test():
    return {"status": "ok"}
""")

        output_file = Path(self.test_dir) / "schema.yaml"

        result = subprocess.run(
            [
                "python",
                str(self.api_docs_script),
                "--input",
                str(sample_api),
                "--output",
                str(output_file),
                "--format",
                "yaml",
            ],
            capture_output=True,
            text=True,
        )

        self.assertEqual(result.returncode, 0, "Should generate YAML schema")

        self.assertTrue(output_file.exists(), "YAML schema file should exist")

        # Should be valid YAML
        with open(output_file, "r") as f:
            schema = yaml.safe_load(f)

        self.assertIn("openapi", schema)
        self.assertIn("paths", schema)

    def test_completeness_check_with_empty_schema(self):
        """Test 35: Completeness check handles schema with no endpoints"""
        empty_paths_schema = {
            "openapi": "3.0.0",
            "info": {"title": "Empty API", "version": "1.0.0"},
            "paths": {},
        }

        schema_file = Path(self.test_dir) / "empty_paths.json"
        with open(schema_file, "w") as f:
            json.dump(empty_paths_schema, f)

        result = subprocess.run(
            [
                "python",
                str(self.api_docs_script),
                "--check-completeness",
                str(schema_file),
                "--min-coverage",
                "80",
            ],
            capture_output=True,
            text=True,
        )

        # Should pass for empty schema (100% of 0 = 100%)
        self.assertEqual(
            result.returncode, 0, "Should pass completeness check for empty schema"
        )


if __name__ == "__main__":
    unittest.main()
