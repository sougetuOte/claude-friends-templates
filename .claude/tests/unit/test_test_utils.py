#!/usr/bin/env python3
"""
Test for test utility functions.
Following t-wada style TDD: Red Phase - Writing failing test first
"""

import os
import json
import tempfile
from pathlib import Path
import pytest
from unittest.mock import Mock, patch, MagicMock


class TestTestUtils:
    """Test suite for test utility functions."""

    def test_create_temp_file_creates_file_with_content(self):
        """Test that create_temp_file creates a temporary file with specified content."""
        import sys
        sys.path.insert(0, '.claude/tests')
        from utils.test_utils import create_temp_file

        content = "test content"
        temp_file = create_temp_file(content)

        assert os.path.exists(temp_file)
        with open(temp_file, 'r') as f:
            assert f.read() == content

        # Cleanup
        os.unlink(temp_file)

    def test_create_temp_dir_creates_directory_structure(self):
        """Test that create_temp_dir creates a temporary directory with specified structure."""
        import sys
        sys.path.insert(0, '.claude/tests')
        from utils.test_utils import create_temp_dir

        structure = {
            'src': {
                'main.py': 'print("Hello")',
                'utils': {
                    'helper.py': 'def help(): pass'
                }
            },
            'tests': {
                'test_main.py': 'def test(): pass'
            }
        }

        temp_dir = create_temp_dir(structure)

        assert os.path.exists(temp_dir)
        assert os.path.exists(os.path.join(temp_dir, 'src', 'main.py'))
        assert os.path.exists(os.path.join(temp_dir, 'src', 'utils', 'helper.py'))
        assert os.path.exists(os.path.join(temp_dir, 'tests', 'test_main.py'))

        # Cleanup
        import shutil
        shutil.rmtree(temp_dir)

    def test_mock_subprocess_run_simulates_command_execution(self):
        """Test that mock_subprocess_run simulates subprocess.run behavior."""
        import sys
        sys.path.insert(0, '.claude/tests')
        from utils.test_utils import mock_subprocess_run

        mock_result = mock_subprocess_run(
            returncode=0,
            stdout='Command output',
            stderr=''
        )

        assert mock_result.returncode == 0
        assert mock_result.stdout == 'Command output'
        assert mock_result.stderr == ''

    def test_capture_logs_captures_log_messages(self):
        """Test that capture_logs context manager captures log messages."""
        import sys
        sys.path.insert(0, '.claude/tests')
        from utils.test_utils import capture_logs
        import logging

        logger = logging.getLogger('test_logger')

        with capture_logs('test_logger') as captured:
            logger.info('Test info message')
            logger.error('Test error message')

        assert len(captured) == 2
        assert captured[0]['level'] == 'INFO'
        assert captured[0]['message'] == 'Test info message'
        assert captured[1]['level'] == 'ERROR'
        assert captured[1]['message'] == 'Test error message'

    def test_assert_json_equal_compares_json_objects(self):
        """Test that assert_json_equal correctly compares JSON objects."""
        import sys
        sys.path.insert(0, '.claude/tests')
        from utils.test_utils import assert_json_equal

        obj1 = {'name': 'test', 'value': 42, 'items': [1, 2, 3]}
        obj2 = {'name': 'test', 'value': 42, 'items': [1, 2, 3]}

        # Should not raise an exception
        assert_json_equal(obj1, obj2)

        obj3 = {'name': 'test', 'value': 43, 'items': [1, 2, 3]}
        with pytest.raises(AssertionError):
            assert_json_equal(obj1, obj3)

    def test_mock_file_operations_provides_file_mocking(self):
        """Test that mock_file_operations provides proper file operation mocking."""
        import sys
        sys.path.insert(0, '.claude/tests')
        from utils.test_utils import mock_file_operations

        with mock_file_operations() as file_ops:
            # Write operation
            file_ops.write('/test/file.txt', 'test content')

            # Read operation
            content = file_ops.read('/test/file.txt')
            assert content == 'test content'

            # Check existence
            assert file_ops.exists('/test/file.txt')
            assert not file_ops.exists('/test/nonexistent.txt')

    def test_async_test_helper_handles_async_functions(self):
        """Test that async_test_helper properly handles async test functions."""
        import sys
        sys.path.insert(0, '.claude/tests')
        from utils.test_utils import async_test_helper

        @async_test_helper
        async def async_test_function():
            import asyncio
            await asyncio.sleep(0.01)
            return "async result"

        result = async_test_function()
        assert result == "async result"

    def test_benchmark_decorator_measures_execution_time(self):
        """Test that benchmark decorator measures function execution time."""
        import sys
        sys.path.insert(0, '.claude/tests')
        from utils.test_utils import benchmark
        import time

        @benchmark
        def slow_function():
            time.sleep(0.1)
            return "done"

        result, execution_time = slow_function()
        assert result == "done"
        assert execution_time >= 0.1
        assert execution_time < 0.2  # Should not take much longer than sleep time

    def test_parameterized_test_generates_multiple_test_cases(self):
        """Test that parameterized_test generates multiple test cases from parameters."""
        import sys
        sys.path.insert(0, '.claude/tests')
        from utils.test_utils import parameterized_test

        test_cases = [
            (2, 3, 5),
            (4, 6, 10),
            (-1, 1, 0),
        ]

        @parameterized_test(test_cases)
        def test_addition(a, b, expected):
            assert a + b == expected

        # The decorator should have created multiple test functions
        assert hasattr(test_addition, '_parameterized')
        assert len(test_addition._parameterized) == 3

    def test_environment_mock_temporarily_sets_environment_variables(self):
        """Test that environment_mock temporarily sets environment variables."""
        import sys
        sys.path.insert(0, '.claude/tests')
        from utils.test_utils import environment_mock

        original_value = os.environ.get('TEST_VAR')

        with environment_mock({'TEST_VAR': 'test_value', 'ANOTHER_VAR': '123'}):
            assert os.environ.get('TEST_VAR') == 'test_value'
            assert os.environ.get('ANOTHER_VAR') == '123'

        # Should restore original values
        assert os.environ.get('TEST_VAR') == original_value
        assert 'ANOTHER_VAR' not in os.environ or os.environ.get('ANOTHER_VAR') != '123'