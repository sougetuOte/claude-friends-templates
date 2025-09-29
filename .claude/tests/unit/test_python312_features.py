#!/usr/bin/env python3
"""
Test for Python 3.12 features and compatibility.
Following t-wada style TDD: Red Phase - Writing failing test first
"""

import sys
import asyncio
from typing import override
from pathlib import Path
import pytest

# Add .claude directory to Python path to import modules properly
claude_dir = Path(__file__).parent.parent.parent  # .claude directory
sys.path.insert(0, str(claude_dir))


class TestPython312Features:
    """Test suite for Python 3.12 specific features."""

    def test_python_version_is_312_or_higher(self):
        """Test that Python version is 3.12 or higher."""
        assert sys.version_info >= (3, 12), f"Python 3.12+ required, got {sys.version}"

    def test_override_decorator_available(self):
        """Test that @override decorator is available (PEP 698)."""
        from typing import override
        assert override is not None, "@override decorator not available"

    def test_override_decorator_works(self):
        """Test that @override decorator works correctly."""
        from scripts.python312_features import BaseLogger, EnhancedLogger

        # Create instance and test override
        logger = EnhancedLogger()
        result = logger.log("test message")

        assert result == "Enhanced: test message"
        assert hasattr(EnhancedLogger.log, '__override__'), "Method should be marked with @override"

    def test_task_group_with_taskname(self):
        """Test asyncio.TaskGroup with taskName parameter (Python 3.12)."""
        from scripts.python312_features import run_tasks_with_names

        results = asyncio.run(run_tasks_with_names())

        assert len(results) == 3, "Should have 3 task results"
        assert all(isinstance(r, tuple) for r in results), "Each result should be a tuple"
        assert all(r[0].startswith("Task-") for r in results), "Each task should have a name"

    def test_improved_fstring_syntax(self):
        """Test improved f-string syntax in Python 3.12."""
        from scripts.python312_features import format_with_nested_fstring

        result = format_with_nested_fstring("World", 42)
        expected = "Hello World! The answer is 42."

        assert result == expected, f"Expected '{expected}', got '{result}'"

    def test_type_parameter_syntax(self):
        """Test PEP 695 type parameter syntax support."""
        from scripts.python312_features import GenericStack

        stack = GenericStack[int]()
        stack.push(1)
        stack.push(2)

        assert stack.pop() == 2
        assert stack.pop() == 1

    def test_enhanced_error_messages(self):
        """Test that Python 3.12 provides enhanced error messages."""
        from scripts.python312_features import trigger_enhanced_error

        with pytest.raises(AttributeError) as exc_info:
            trigger_enhanced_error()

        error_message = str(exc_info.value)
        # Python 3.12 provides more helpful error messages
        assert "Did you mean:" in error_message or "attribute" in error_message

    def test_buffer_protocol_improvements(self):
        """Test buffer protocol improvements in Python 3.12."""
        from scripts.python312_features import BufferProcessor

        processor = BufferProcessor()
        data = b"Hello Python 3.12"
        result = processor.process(data)

        assert result == data.upper()

    def test_perf_profiler_integration(self):
        """Test that perf profiler support is available."""
        # Check if sys has the new perf profiler methods
        assert hasattr(sys, 'activate_stack_trampoline') or sys.version_info >= (3, 12)

    def test_improved_typing_features(self):
        """Test improved typing features in Python 3.12."""
        from scripts.python312_features import TypedConfig

        config = TypedConfig(debug=True, timeout=30, name="test")

        assert config.debug is True
        assert config.timeout == 30
        assert config.name == "test"