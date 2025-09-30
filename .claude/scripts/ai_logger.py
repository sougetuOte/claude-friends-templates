#!/usr/bin/env python3
"""
AI-Optimized Logger Implementation
Structured logging system optimized for AI analysis and debugging

Features:
- JSONL format for easy parsing
- Context management with contextvars
- AI-specific metadata generation
- Python 3.12 features (@override, improved dataclasses)
- Graceful error handling with fallback to stderr

Version: 1.0.0
Python: 3.12+

Usage Example:
    Basic logging:
        >>> from ai_logger import logger
        >>> logger.info("Application started")
        >>> logger.error("Connection failed", host="localhost", port=5432)

    With context:
        >>> logger.set_context(agent="builder", task_name="implementation")
        >>> logger.info("Starting Green phase")
        >>> logger.info("Tests passing", count=15)

    TDD workflow:
        >>> logger.set_context(agent="builder", task_name="test_feature")
        >>> logger.error("Test failed as expected", phase="red", expected=True)
        >>> logger.info("Implementing feature", phase="green")
        >>> logger.info("All tests pass", phase="green", tests=10)
        >>> logger.info("Refactoring complete", phase="refactor")

Output Format (JSONL):
    Each log entry is a complete JSON on a single line:
    {
        "timestamp": "2025-09-30T12:00:00+00:00",
        "level": "INFO",
        "message": "Application started",
        "logger": "claude-friends-templates",
        "context": {
            "correlation_id": "uuid-here",
            "agent": "builder",
            "task_name": "implementation"
        },
        "metadata": {"count": 15},
        "ai_metadata": {
            "hint": "Normal operation, continue monitoring",
            "priority": "normal",
            "requires_human_review": false
        }
    }

Log Files:
    Default location: ~/.claude/ai-activity.jsonl
    Format: JSONL (one JSON object per line)
    Rotation: Manual (consider implementing rotation for production)

Best Practices:
    1. Set context at the start of each task/operation
    2. Use appropriate log levels (DEBUG < INFO < WARNING < ERROR < CRITICAL)
    3. Include relevant metadata with each log entry
    4. For TDD: Mark expected failures with expected=True in metadata
    5. Use correlation_id to trace related operations
"""

import json
import os
import sys
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Any, Optional
import contextvars
from dataclasses import dataclass, asdict
from enum import Enum

# Python 3.12 feature
from typing import override


class LogLevel(Enum):
    """Log severity levels."""

    DEBUG = "DEBUG"
    INFO = "INFO"
    WARNING = "WARNING"
    ERROR = "ERROR"
    CRITICAL = "CRITICAL"


@dataclass
class LogContext:
    """
    Log context dataclass - Python 3.12 dataclass improvements.

    Attributes:
        correlation_id: Unique ID for correlating related log entries
        agent: Agent name (planner/builder/etc)
        task_name: Current task being executed
        project: Project name
        environment: Environment (development/production)
    """

    correlation_id: str
    agent: Optional[str] = None
    task_name: Optional[str] = None
    project: str = "claude-friends-templates"
    environment: str = "development"

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary, excluding None values."""
        return {k: v for k, v in asdict(self).items() if v is not None}


class AIOptimizedLogger:
    """
    AI-optimized structured logger with JSONL output.

    This logger is designed for easy parsing and analysis by AI systems.
    It uses:
    - JSONL format (one JSON per line)
    - contextvars for context management
    - Automatic AI metadata generation
    - Python 3.12 @override decorator

    Example:
        >>> logger = AIOptimizedLogger("my-module")
        >>> logger.set_context(agent="builder", task_name="implementation")
        >>> logger.info("Starting task", phase="green")
        >>> logger.error("Test failed", test_name="test_feature")
    """

    def __init__(self, name: str = __name__):
        """
        Initialize logger.

        Args:
            name: Logger name (typically module name)
        """
        self.name = name

        # Support AI_LOG_FILE environment variable for test isolation
        log_file_path = os.environ.get("AI_LOG_FILE")
        if log_file_path:
            self.log_file = Path(log_file_path)
        else:
            self.log_file = Path.home() / ".claude" / "ai-activity.jsonl"

        self.log_file.parent.mkdir(parents=True, exist_ok=True)
        self.context_var: contextvars.ContextVar[Optional[LogContext]] = (
            contextvars.ContextVar("log_context", default=None)
        )

    def set_context(self, **kwargs) -> None:
        """
        Set or update logging context.

        Context is preserved across multiple log calls using contextvars.
        Updates are incremental - existing context is preserved and updated.

        Args:
            **kwargs: Context fields to set (agent, task_name, etc)

        Example:
            >>> logger.set_context(agent="planner")
            >>> logger.set_context(task_name="design")  # Preserves agent="planner"
        """
        current = self.context_var.get()
        if current:
            # Update existing context
            updated = {**asdict(current), **kwargs}
            self.context_var.set(LogContext(**updated))
        else:
            # Create new context with correlation_id
            self.context_var.set(LogContext(correlation_id=str(uuid.uuid4()), **kwargs))

    def _create_log_entry(
        self, level: LogLevel, message: str, **kwargs
    ) -> Dict[str, Any]:
        """
        Create structured log entry.

        Args:
            level: Log level
            message: Log message
            **kwargs: Additional metadata

        Returns:
            Dict containing structured log entry
        """
        context = self.context_var.get()

        entry = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "level": level.value,
            "message": message,
            "logger": self.name,
            "context": context.to_dict() if context else {},
            "metadata": kwargs,
        }

        # Add AI-specific metadata
        if level in [LogLevel.ERROR, LogLevel.CRITICAL]:
            entry["ai_metadata"] = {
                "hint": "Analyze error pattern and suggest fixes",
                "priority": "high",
                "requires_human_review": True,
            }
        else:
            entry["ai_metadata"] = {
                "hint": "Normal operation, continue monitoring",
                "priority": "normal",
                "requires_human_review": False,
            }

        return entry

    def _log(self, level: LogLevel, message: str, **kwargs) -> None:
        """
        Internal logging method with error handling.

        Gracefully handles write failures to prevent application crashes.
        Falls back to stderr if log file writing fails.

        Args:
            level: Log level
            message: Log message
            **kwargs: Additional metadata
        """
        entry = self._create_log_entry(level, message, **kwargs)

        try:
            # Ensure log directory exists (in case log_file was changed)
            self.log_file.parent.mkdir(parents=True, exist_ok=True)

            # Write in JSONL format (one JSON per line)
            with self.log_file.open("a", encoding="utf-8") as f:
                json.dump(entry, f, ensure_ascii=False)
                f.write("\n")

        except (IOError, OSError, PermissionError) as e:
            # Fallback to stderr if file writing fails
            # This prevents logging errors from crashing the application
            fallback_msg = f"[LOGGER ERROR] Failed to write to {self.log_file}: {e}"
            print(fallback_msg, file=sys.stderr)
            print(f"[{level.value}] {message}", file=sys.stderr)

        # In development, also print to console
        if os.getenv("ENVIRONMENT", "development") == "development":
            # Compact console output for development
            console_msg = f"[{level.value}] {message}"
            if kwargs:
                console_msg += f" | {kwargs}"
            print(console_msg, file=sys.stderr)

    @override
    def debug(self, message: str, **kwargs) -> None:
        """
        Log DEBUG level message.

        Args:
            message: Log message
            **kwargs: Additional metadata
        """
        self._log(LogLevel.DEBUG, message, **kwargs)

    @override
    def info(self, message: str, **kwargs) -> None:
        """
        Log INFO level message.

        Args:
            message: Log message
            **kwargs: Additional metadata
        """
        self._log(LogLevel.INFO, message, **kwargs)

    @override
    def warning(self, message: str, **kwargs) -> None:
        """
        Log WARNING level message.

        Args:
            message: Log message
            **kwargs: Additional metadata
        """
        self._log(LogLevel.WARNING, message, **kwargs)

    @override
    def error(self, message: str, **kwargs) -> None:
        """
        Log ERROR level message.

        Args:
            message: Log message
            **kwargs: Additional metadata
        """
        self._log(LogLevel.ERROR, message, **kwargs)

    @override
    def critical(self, message: str, **kwargs) -> None:
        """
        Log CRITICAL level message.

        Args:
            message: Log message
            **kwargs: Additional metadata
        """
        self._log(LogLevel.CRITICAL, message, **kwargs)


# Global logger instance for convenience
logger = AIOptimizedLogger("claude-friends-templates")


# Usage example
if __name__ == "__main__":
    # Example usage
    logger.set_context(agent="builder", task_name="test_implementation")
    logger.info("Starting TDD Red Phase", phase="red", test_file="test_handover.py")
    logger.error("Test failed as expected", phase="red", expected=True)
    logger.info("Implementing feature", phase="green")
    logger.info("All tests passing", phase="green", tests_passed=15)
    logger.debug("Debug information", variable="value")
    logger.warning("Potential issue detected", issue_type="performance")
    logger.critical("Critical error", error="system_failure")
