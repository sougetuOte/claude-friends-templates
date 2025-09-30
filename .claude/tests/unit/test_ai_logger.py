#!/usr/bin/env python3
"""
Test for AIOptimizedLogger - AI-friendly structured logging system
Following t-wada style TDD: Red Phase - Writing failing tests first

Test Coverage:
- JSONL format log output
- Context management with contextvars
- AI metadata generation
- Log levels (DEBUG, INFO, WARNING, ERROR, CRITICAL)
- Python 3.12 @override decorator usage
"""

import sys
import json
import tempfile
from pathlib import Path
from datetime import datetime
import pytest

# Add .claude directory to Python path
claude_dir = Path(__file__).parent.parent.parent
sys.path.insert(0, str(claude_dir))


class TestAIOptimizedLogger:
    """Test suite for AI-optimized structured logger."""

    def test_logger_initialization(self):
        """Test that logger can be initialized."""
        from scripts.ai_logger import AIOptimizedLogger

        logger = AIOptimizedLogger("test-logger")

        assert logger is not None
        assert logger.name == "test-logger"
        assert logger.log_file is not None

    def test_logger_creates_log_directory(self):
        """Test that logger creates necessary directories."""
        from scripts.ai_logger import AIOptimizedLogger

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / ".claude" / "ai-activity.jsonl"
            logger = AIOptimizedLogger("test-logger")
            logger.log_file = log_path

            # Directory should be created when writing first log
            logger.info("test message")

            assert log_path.parent.exists()
            assert log_path.exists()

    def test_log_entry_is_valid_jsonl(self):
        """Test that log entries are valid JSONL format."""
        from scripts.ai_logger import AIOptimizedLogger

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "test.jsonl"
            logger = AIOptimizedLogger("test-logger")
            logger.log_file = log_path

            logger.info("Test message", key="value")

            # Read and verify JSONL
            with log_path.open("r") as f:
                line = f.readline()
                entry = json.loads(line)

                assert "timestamp" in entry
                assert "level" in entry
                assert entry["level"] == "INFO"
                assert "message" in entry
                assert entry["message"] == "Test message"
                assert "logger" in entry
                assert entry["logger"] == "test-logger"

    def test_context_management(self):
        """Test context setting and retrieval with contextvars."""
        from scripts.ai_logger import AIOptimizedLogger

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "test.jsonl"
            logger = AIOptimizedLogger("test-logger")
            logger.log_file = log_path

            # Set context
            logger.set_context(agent="planner", task_name="test_task")
            logger.info("Test with context")

            # Verify context in log
            with log_path.open("r") as f:
                entry = json.loads(f.readline())

                assert "context" in entry
                assert entry["context"]["agent"] == "planner"
                assert entry["context"]["task_name"] == "test_task"
                assert "correlation_id" in entry["context"]

    def test_ai_metadata_for_error_logs(self):
        """Test that ERROR logs include AI metadata with high priority."""
        from scripts.ai_logger import AIOptimizedLogger

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "test.jsonl"
            logger = AIOptimizedLogger("test-logger")
            logger.log_file = log_path

            logger.error("Error occurred", error_code=500)

            with log_path.open("r") as f:
                entry = json.loads(f.readline())

                assert "ai_metadata" in entry
                assert entry["ai_metadata"]["priority"] == "high"
                assert entry["ai_metadata"]["requires_human_review"] is True
                assert "hint" in entry["ai_metadata"]

    def test_ai_metadata_for_info_logs(self):
        """Test that INFO logs include AI metadata with normal priority."""
        from scripts.ai_logger import AIOptimizedLogger

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "test.jsonl"
            logger = AIOptimizedLogger("test-logger")
            logger.log_file = log_path

            logger.info("Normal operation")

            with log_path.open("r") as f:
                entry = json.loads(f.readline())

                assert "ai_metadata" in entry
                assert entry["ai_metadata"]["priority"] == "normal"
                assert entry["ai_metadata"]["requires_human_review"] is False

    def test_all_log_levels(self):
        """Test that all log levels work correctly."""
        from scripts.ai_logger import AIOptimizedLogger

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "test.jsonl"
            logger = AIOptimizedLogger("test-logger")
            logger.log_file = log_path

            logger.debug("Debug message")
            logger.info("Info message")
            logger.warning("Warning message")
            logger.error("Error message")
            logger.critical("Critical message")

            # Verify all entries
            with log_path.open("r") as f:
                lines = f.readlines()
                assert len(lines) == 5

                levels = [json.loads(line)["level"] for line in lines]
                assert levels == ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]

    def test_override_decorator_usage(self):
        """Test that @override decorator is used (Python 3.12 feature)."""
        from scripts.ai_logger import AIOptimizedLogger

        logger = AIOptimizedLogger("test-logger")

        # Check that methods have __override__ attribute
        assert hasattr(logger.info, "__override__") or hasattr(
            AIOptimizedLogger.info, "__override__"
        )

    def test_metadata_kwargs_included(self):
        """Test that arbitrary metadata kwargs are included in log."""
        from scripts.ai_logger import AIOptimizedLogger

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "test.jsonl"
            logger = AIOptimizedLogger("test-logger")
            logger.log_file = log_path

            logger.info("Message", custom_key="custom_value", count=42)

            with log_path.open("r") as f:
                entry = json.loads(f.readline())

                assert "metadata" in entry
                assert entry["metadata"]["custom_key"] == "custom_value"
                assert entry["metadata"]["count"] == 42

    def test_timestamp_format(self):
        """Test that timestamp is in ISO8601 format with timezone."""
        from scripts.ai_logger import AIOptimizedLogger

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "test.jsonl"
            logger = AIOptimizedLogger("test-logger")
            logger.log_file = log_path

            logger.info("Test")

            with log_path.open("r") as f:
                entry = json.loads(f.readline())

                # Verify ISO8601 format
                timestamp = entry["timestamp"]
                parsed = datetime.fromisoformat(timestamp)
                assert parsed.tzinfo is not None  # Has timezone info

    def test_context_inheritance(self):
        """Test that context is preserved across multiple log calls."""
        from scripts.ai_logger import AIOptimizedLogger

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "test.jsonl"
            logger = AIOptimizedLogger("test-logger")
            logger.log_file = log_path

            logger.set_context(agent="builder", task_name="implementation")
            logger.info("First message")
            logger.error("Second message")

            with log_path.open("r") as f:
                lines = f.readlines()

                for line in lines:
                    entry = json.loads(line)
                    assert entry["context"]["agent"] == "builder"
                    assert entry["context"]["task_name"] == "implementation"
                    # correlation_id should be the same
                    if len(lines) > 1:
                        first_id = json.loads(lines[0])["context"]["correlation_id"]
                        second_id = json.loads(lines[1])["context"]["correlation_id"]
                        assert first_id == second_id

    def test_context_update(self):
        """Test that context can be updated incrementally."""
        from scripts.ai_logger import AIOptimizedLogger

        with tempfile.TemporaryDirectory() as tmpdir:
            log_path = Path(tmpdir) / "test.jsonl"
            logger = AIOptimizedLogger("test-logger")
            logger.log_file = log_path

            logger.set_context(agent="planner")
            logger.info("Message 1")

            logger.set_context(task_name="design")
            logger.info("Message 2")

            with log_path.open("r") as f:
                lines = f.readlines()

                # First message should have agent only
                entry1 = json.loads(lines[0])
                assert entry1["context"]["agent"] == "planner"
                assert "task_name" not in entry1["context"]

                # Second message should have both
                entry2 = json.loads(lines[1])
                assert entry2["context"]["agent"] == "planner"
                assert entry2["context"]["task_name"] == "design"

    def test_log_context_dataclass(self):
        """Test LogContext dataclass structure."""
        from scripts.ai_logger import LogContext

        context = LogContext(
            correlation_id="test-id", agent="planner", task_name="test"
        )

        assert context.correlation_id == "test-id"
        assert context.agent == "planner"
        assert context.task_name == "test"
        assert context.project == "claude-friends-templates"
        assert context.environment == "development"

        # Test to_dict method
        context_dict = context.to_dict()
        assert context_dict["correlation_id"] == "test-id"
        assert context_dict["agent"] == "planner"

    def test_log_level_enum(self):
        """Test LogLevel enum values."""
        from scripts.ai_logger import LogLevel

        assert LogLevel.DEBUG.value == "DEBUG"
        assert LogLevel.INFO.value == "INFO"
        assert LogLevel.WARNING.value == "WARNING"
        assert LogLevel.ERROR.value == "ERROR"
        assert LogLevel.CRITICAL.value == "CRITICAL"


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
