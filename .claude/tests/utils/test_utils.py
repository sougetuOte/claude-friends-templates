#!/usr/bin/env python3
"""
Test utility functions for Claude Friends Templates.
Following t-wada style TDD: Refactor Phase - Improved implementation

This module provides utilities for testing including:
- Temporary file/directory creation
- Mock subprocess results
- Log capturing
- JSON comparison
- File operation mocking
- Async test helpers
- Benchmarking
- Parameterized tests
- Environment mocking
"""

import os
import tempfile
import json
import logging
import asyncio
import time
import functools
from contextlib import contextmanager
from typing import Dict, Any, List, Optional, Callable, Tuple, TypeVar
from pathlib import Path
from unittest.mock import MagicMock

# Type variables for better type hints
T = TypeVar('T')
AsyncFunc = TypeVar('AsyncFunc', bound=Callable)

# Export all utilities
__all__ = [
    'create_temp_file',
    'create_temp_dir',
    'mock_subprocess_run',
    'capture_logs',
    'assert_json_equal',
    'mock_file_operations',
    'MockFileOperations',
    'async_test_helper',
    'benchmark',
    'parameterized_test',
    'environment_mock',
]


def create_temp_file(content: str, suffix: Optional[str] = None) -> str:
    """Create a temporary file with specified content.

    Args:
        content: The content to write to the file
        suffix: Optional file suffix/extension

    Returns:
        Path to the created temporary file

    Note:
        Caller is responsible for cleaning up the file
    """
    with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix=suffix) as f:
        f.write(content)
        return f.name


def create_temp_dir(structure: Dict[str, Any], prefix: Optional[str] = None) -> str:
    """Create a temporary directory with specified structure.

    Args:
        structure: Dict defining directory/file structure
                  Keys are paths, values are either dicts (subdirs) or strings (file content)
        prefix: Optional prefix for the temp directory name

    Returns:
        Path to the created temporary directory

    Example:
        >>> structure = {
        ...     'src': {
        ...         'main.py': 'print("Hello")',
        ...         'utils': {'helper.py': 'def help(): pass'}
        ...     }
        ... }
        >>> temp_dir = create_temp_dir(structure)
    """
    temp_dir = tempfile.mkdtemp(prefix=prefix)

    def create_structure(base_path: str, struct: Dict[str, Any]) -> None:
        for key, value in struct.items():
            path = os.path.join(base_path, key)
            if isinstance(value, dict):
                os.makedirs(path, exist_ok=True)
                create_structure(path, value)
            else:
                os.makedirs(os.path.dirname(path), exist_ok=True)
                with open(path, 'w') as f:
                    f.write(str(value))

    create_structure(temp_dir, structure)
    return temp_dir


def mock_subprocess_run(returncode: int = 0, stdout: str = '', stderr: str = '') -> MagicMock:
    """Create a mock subprocess.run result."""
    mock_result = MagicMock()
    mock_result.returncode = returncode
    mock_result.stdout = stdout
    mock_result.stderr = stderr
    return mock_result


@contextmanager
def capture_logs(logger_name: str):
    """Context manager to capture log messages."""
    captured = []
    logger = logging.getLogger(logger_name)
    handler = logging.Handler()

    def emit(record):
        captured.append({
            'level': record.levelname,
            'message': record.getMessage()
        })

    handler.emit = emit
    logger.addHandler(handler)
    original_level = logger.level
    logger.setLevel(logging.DEBUG)

    try:
        yield captured
    finally:
        logger.removeHandler(handler)
        logger.setLevel(original_level)


def assert_json_equal(obj1: Any, obj2: Any, ignore_order: bool = False) -> None:
    """Assert two JSON objects are equal.

    Args:
        obj1: First object to compare
        obj2: Second object to compare
        ignore_order: If True, ignore order in lists

    Raises:
        AssertionError: If objects are not equal
    """
    def normalize(obj: Any) -> Any:
        if isinstance(obj, dict):
            return {k: normalize(v) for k, v in sorted(obj.items())}
        elif isinstance(obj, list) and ignore_order:
            return sorted(normalize(item) for item in obj)
        elif isinstance(obj, list):
            return [normalize(item) for item in obj]
        return obj

    norm_obj1 = normalize(obj1) if ignore_order else obj1
    norm_obj2 = normalize(obj2) if ignore_order else obj2

    if norm_obj1 != norm_obj2:
        raise AssertionError(
            f"JSON objects not equal:\n"
            f"{json.dumps(obj1, indent=2)}\n"
            f"!=\n"
            f"{json.dumps(obj2, indent=2)}"
        )


class MockFileOperations:
    """Mock file operations for testing."""

    def __init__(self):
        self.files = {}

    def write(self, path: str, content: str):
        """Mock file write."""
        self.files[path] = content

    def read(self, path: str) -> str:
        """Mock file read."""
        return self.files.get(path, '')

    def exists(self, path: str) -> bool:
        """Mock file existence check."""
        return path in self.files


@contextmanager
def mock_file_operations():
    """Context manager for mocking file operations."""
    mock_ops = MockFileOperations()
    yield mock_ops


def async_test_helper(async_func: AsyncFunc) -> Callable:
    """Helper decorator for async test functions.

    Args:
        async_func: Async function to wrap

    Returns:
        Synchronous wrapper function

    Example:
        >>> @async_test_helper
        ... async def test_async():
        ...     await asyncio.sleep(0.1)
        ...     return "done"
        >>> result = test_async()  # Can call without await
    """
    @functools.wraps(async_func)
    def wrapper(*args, **kwargs):
        loop = asyncio.new_event_loop()
        try:
            return loop.run_until_complete(async_func(*args, **kwargs))
        finally:
            loop.close()
    return wrapper


def benchmark(func: Callable[..., T]) -> Callable[..., Tuple[T, float]]:
    """Decorator to benchmark function execution time.

    Args:
        func: Function to benchmark

    Returns:
        Wrapped function that returns (result, execution_time)

    Example:
        >>> @benchmark
        ... def slow_function():
        ...     time.sleep(0.1)
        ...     return "done"
        >>> result, exec_time = slow_function()
        >>> print(f"Took {exec_time:.2f} seconds")
    """
    @functools.wraps(func)
    def wrapper(*args, **kwargs) -> Tuple[T, float]:
        start_time = time.perf_counter()
        result = func(*args, **kwargs)
        execution_time = time.perf_counter() - start_time
        return result, execution_time
    return wrapper


def parameterized_test(test_cases):
    """Decorator to generate parameterized tests."""
    def decorator(test_func):
        test_func._parameterized = []
        for case in test_cases:
            test_func._parameterized.append(case)
        return test_func
    return decorator


@contextmanager
def environment_mock(env_vars: Dict[str, str]):
    """Context manager to temporarily set environment variables.

    Args:
        env_vars: Dictionary of environment variables to set

    Yields:
        None

    Example:
        >>> with environment_mock({'API_KEY': 'test123'}):
        ...     assert os.environ['API_KEY'] == 'test123'
        >>> # Environment restored after context
    """
    if not isinstance(env_vars, dict):
        raise TypeError("env_vars must be a dictionary")

    original_values = {}

    # Save original values
    for key in env_vars:
        original_values[key] = os.environ.get(key)

    # Set new values
    for key, value in env_vars.items():
        if not isinstance(value, str):
            raise TypeError(f"Environment variable {key} value must be a string")
        os.environ[key] = value

    try:
        yield
    finally:
        # Restore original values
        for key, original_value in original_values.items():
            if original_value is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = original_value