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
        self.api_docs_script = self.project_root / ".claude" / "scripts" / "api-docs-generator.py"
        self.config_file = self.project_root / ".claude" / "api-docs-config.json"

    def tearDown(self):
        """Clean up test environment"""
        if os.path.exists(self.test_dir):
            shutil.rmtree(self.test_dir)

    def test_api_docs_generator_script_exists(self):
        """Test 1: API documentation generator script exists"""
        self.assertTrue(
            self.api_docs_script.exists(),
            f"API docs generator script should exist at {self.api_docs_script}"
        )

    def test_api_docs_generator_script_is_executable(self):
        """Test 2: API documentation generator script is executable"""
        self.assertTrue(
            os.access(self.api_docs_script, os.X_OK),
            "API docs generator script should be executable"
        )

    def test_api_docs_config_file_exists(self):
        """Test 3: API documentation configuration file exists"""
        self.assertTrue(
            self.config_file.exists(),
            f"API docs config file should exist at {self.config_file}"
        )

    def test_api_docs_config_has_required_settings(self):
        """Test 4: API documentation config has required settings"""
        self.assertTrue(self.config_file.exists(), "Config file must exist")

        with open(self.config_file, 'r') as f:
            config = json.load(f)

        # Required configuration sections
        required_sections = [
            "openapi",
            "swagger_ui",
            "redoc",
            "scalar",
            "validation",
            "ci_integration",
            "output"
        ]

        for section in required_sections:
            self.assertIn(
                section, config,
                f"Config should contain '{section}' section"
            )

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
        with open(sample_file, 'w') as f:
            f.write(sample_api)

        # Test schema generation
        result = subprocess.run([
            "python", str(self.api_docs_script),
            "--input", str(sample_file),
            "--output", str(Path(self.test_dir) / "schema.json"),
            "--format", "json"
        ], capture_output=True, text=True)

        self.assertEqual(result.returncode, 0,
                        f"Schema generation should succeed. stderr: {result.stderr}")

        # Check generated schema
        schema_file = Path(self.test_dir) / "schema.json"
        self.assertTrue(schema_file.exists(), "Schema file should be generated")

        with open(schema_file, 'r') as f:
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
                        "responses": {"200": {"description": "Success"}}
                    }
                }
            }
        }

        schema_file = Path(self.test_dir) / "schema.json"
        with open(schema_file, 'w') as f:
            json.dump(sample_schema, f)

        # Test Swagger UI generation
        result = subprocess.run([
            "python", str(self.api_docs_script),
            "--schema", str(schema_file),
            "--generate", "swagger-ui",
            "--output", str(Path(self.test_dir) / "swagger-ui")
        ], capture_output=True, text=True)

        self.assertEqual(result.returncode, 0,
                        f"Swagger UI generation should succeed. stderr: {result.stderr}")

        # Check generated files
        swagger_dir = Path(self.test_dir) / "swagger-ui"
        self.assertTrue(swagger_dir.exists(), "Swagger UI directory should be created")

        required_files = ["index.html", "swagger-ui-bundle.js", "swagger-ui-standalone-preset.js"]
        for file_name in required_files:
            file_path = swagger_dir / file_name
            self.assertTrue(file_path.exists(), f"Swagger UI should contain {file_name}")

    def test_redoc_generation(self):
        """Test 7: ReDoc documentation generation"""
        sample_schema = {
            "openapi": "3.0.0",
            "info": {"title": "Test API", "version": "1.0.0"},
            "paths": {"/health": {"get": {"responses": {"200": {"description": "OK"}}}}}
        }

        schema_file = Path(self.test_dir) / "schema.json"
        with open(schema_file, 'w') as f:
            json.dump(sample_schema, f)

        result = subprocess.run([
            "python", str(self.api_docs_script),
            "--schema", str(schema_file),
            "--generate", "redoc",
            "--output", str(Path(self.test_dir) / "redoc")
        ], capture_output=True, text=True)

        self.assertEqual(result.returncode, 0,
                        f"ReDoc generation should succeed. stderr: {result.stderr}")

        redoc_dir = Path(self.test_dir) / "redoc"
        self.assertTrue(redoc_dir.exists(), "ReDoc directory should be created")
        self.assertTrue((redoc_dir / "index.html").exists(), "ReDoc should have index.html")

    def test_openapi_schema_validation(self):
        """Test 8: OpenAPI schema validation"""
        # Test valid schema
        valid_schema = {
            "openapi": "3.0.0",
            "info": {"title": "Valid API", "version": "1.0.0"},
            "paths": {}
        }

        valid_file = Path(self.test_dir) / "valid_schema.json"
        with open(valid_file, 'w') as f:
            json.dump(valid_schema, f)

        result = subprocess.run([
            "python", str(self.api_docs_script),
            "--validate", str(valid_file)
        ], capture_output=True, text=True)

        self.assertEqual(result.returncode, 0,
                        f"Valid schema should pass validation. stderr: {result.stderr}")

        # Test invalid schema
        invalid_schema = {
            "openapi": "3.0.0",
            # Missing required 'info' field
            "paths": {}
        }

        invalid_file = Path(self.test_dir) / "invalid_schema.json"
        with open(invalid_file, 'w') as f:
            json.dump(invalid_schema, f)

        result = subprocess.run([
            "python", str(self.api_docs_script),
            "--validate", str(invalid_file)
        ], capture_output=True, text=True)

        self.assertNotEqual(result.returncode, 0,
                           "Invalid schema should fail validation")

    def test_multiple_format_support(self):
        """Test 9: Support for multiple output formats (JSON, YAML)"""
        sample_schema = {
            "openapi": "3.0.0",
            "info": {"title": "Test API", "version": "1.0.0"},
            "paths": {}
        }

        # Test JSON output
        json_file = Path(self.test_dir) / "schema.json"
        result = subprocess.run([
            "python", str(self.api_docs_script),
            "--generate-schema",
            "--output", str(json_file),
            "--format", "json"
        ], capture_output=True, text=True)

        self.assertEqual(result.returncode, 0, "JSON format generation should succeed")
        self.assertTrue(json_file.exists(), "JSON schema file should be created")

        # Test YAML output
        yaml_file = Path(self.test_dir) / "schema.yaml"
        result = subprocess.run([
            "python", str(self.api_docs_script),
            "--generate-schema",
            "--output", str(yaml_file),
            "--format", "yaml"
        ], capture_output=True, text=True)

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
                                            "email": {"type": "string"}
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        schema_file = Path(self.test_dir) / "schema.json"
        with open(schema_file, 'w') as f:
            json.dump(sample_schema, f)

        result = subprocess.run([
            "python", str(self.api_docs_script),
            "--schema", str(schema_file),
            "--generate-samples",
            "--languages", "python,javascript,curl",
            "--output", str(Path(self.test_dir) / "samples")
        ], capture_output=True, text=True)

        self.assertEqual(result.returncode, 0,
                        f"Code sample generation should succeed. stderr: {result.stderr}")

        samples_dir = Path(self.test_dir) / "samples"
        self.assertTrue(samples_dir.exists(), "Samples directory should be created")

        expected_files = ["python.py", "javascript.js", "curl.sh"]
        for file_name in expected_files:
            self.assertTrue((samples_dir / file_name).exists(),
                          f"Sample file {file_name} should be generated")

    def test_ci_integration_configuration(self):
        """Test 11: CI/CD integration configuration"""
        result = subprocess.run([
            "python", str(self.api_docs_script),
            "--setup-ci",
            "--ci-type", "github-actions",
            "--output", str(Path(self.test_dir) / ".github")
        ], capture_output=True, text=True)

        self.assertEqual(result.returncode, 0,
                        f"CI setup should succeed. stderr: {result.stderr}")

        ci_file = Path(self.test_dir) / ".github" / "workflows" / "api-docs.yml"
        self.assertTrue(ci_file.exists(), "GitHub Actions workflow should be created")

        # Check workflow content
        with open(ci_file, 'r') as f:
            workflow = f.read()

        required_steps = [
            "checkout",
            "generate-docs",
            "validate-schema",
            "deploy-docs"
        ]

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
            }
        }

        schema_file = Path(self.test_dir) / "incomplete.json"
        with open(schema_file, 'w') as f:
            json.dump(incomplete_schema, f)

        result = subprocess.run([
            "python", str(self.api_docs_script),
            "--check-completeness", str(schema_file),
            "--min-coverage", "80"
        ], capture_output=True, text=True)

        # Should fail due to incomplete documentation
        self.assertNotEqual(result.returncode, 0,
                           "Incomplete documentation should fail completeness check")

        # Check that it reports specific issues
        self.assertIn("missing", result.stdout.lower() or result.stderr.lower(),
                     "Should report missing documentation elements")

    def test_interactive_documentation_server(self):
        """Test 13: Interactive documentation server"""
        sample_schema = {
            "openapi": "3.0.0",
            "info": {"title": "Test API", "version": "1.0.0"},
            "paths": {}
        }

        schema_file = Path(self.test_dir) / "schema.json"
        with open(schema_file, 'w') as f:
            json.dump(sample_schema, f)

        # Test server start (should return quickly for testing)
        result = subprocess.run([
            "python", str(self.api_docs_script),
            "--serve",
            "--schema", str(schema_file),
            "--port", "8080",
            "--test-mode"  # Special flag for testing
        ], capture_output=True, text=True, timeout=10)

        self.assertEqual(result.returncode, 0,
                        f"Documentation server should start successfully. stderr: {result.stderr}")

        # Check that server indicates successful startup
        self.assertIn("server", result.stdout.lower() or result.stderr.lower(),
                     "Should indicate server startup")

    def test_theme_and_customization_support(self):
        """Test 14: Documentation theme and customization"""
        result = subprocess.run([
            "python", str(self.api_docs_script),
            "--customize",
            "--theme", "dark",
            "--logo", str(Path(self.test_dir) / "logo.png"),
            "--custom-css", str(Path(self.test_dir) / "custom.css"),
            "--output", str(Path(self.test_dir) / "customized")
        ], capture_output=True, text=True)

        self.assertEqual(result.returncode, 0,
                        f"Documentation customization should succeed. stderr: {result.stderr}")

        customized_dir = Path(self.test_dir) / "customized"
        self.assertTrue(customized_dir.exists(), "Customized documentation should be created")

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
                        "bearerFormat": "JWT"
                    }
                }
            },
            "security": [{"bearerAuth": []}],
            "paths": {
                "/protected": {
                    "get": {
                        "security": [{"bearerAuth": []}],
                        "responses": {"200": {"description": "Success"}}
                    }
                }
            }
        }

        schema_file = Path(self.test_dir) / "secure_schema.json"
        with open(schema_file, 'w') as f:
            json.dump(schema_with_security, f)

        result = subprocess.run([
            "python", str(self.api_docs_script),
            "--schema", str(schema_file),
            "--generate", "swagger-ui",
            "--output", str(Path(self.test_dir) / "secure-docs")
        ], capture_output=True, text=True)

        self.assertEqual(result.returncode, 0,
                        f"Secure API documentation should be generated. stderr: {result.stderr}")

        # Check that security information is preserved
        docs_dir = Path(self.test_dir) / "secure-docs"
        self.assertTrue(docs_dir.exists(), "Secure docs directory should be created")

    def test_api_docs_dependencies_in_requirements(self):
        """Test 16: API documentation dependencies are in requirements.txt"""
        requirements_file = self.project_root / "requirements.txt"
        self.assertTrue(requirements_file.exists(), "requirements.txt should exist")

        with open(requirements_file, 'r') as f:
            requirements = f.read()

        # Check for required API documentation packages
        required_packages = [
            "fastapi",
            "pydantic",
            "uvicorn",
            "openapi-spec-validator",
            "pyyaml"
        ]

        for package in required_packages:
            self.assertIn(package, requirements.lower(),
                         f"requirements.txt should contain {package} for API documentation")


if __name__ == '__main__':
    unittest.main()