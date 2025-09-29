#!/usr/bin/env python3
"""
Python 3.12 features implementation.
Following t-wada style TDD: Refactor Phase - Enhanced implementation

This module demonstrates key Python 3.12 features:
- PEP 698: @override decorator for explicit method overriding
- Enhanced asyncio.TaskGroup capabilities
- Improved f-string syntax
- PEP 695: Type parameter syntax (using Generic for compatibility)
- Enhanced error messages
- Buffer protocol improvements
- TypedConfig using dataclasses
"""

import asyncio
from typing import override, TypeVar, Generic, Optional, Any
from dataclasses import dataclass, field


# PEP 698: Override decorator demonstration
class BaseLogger:
    """Base logger class providing basic logging functionality.

    This class serves as a base for inheritance and method overriding
    demonstrations using Python 3.12's @override decorator.
    """

    def log(self, message: str) -> str:
        """Log a message with base formatting.

        Args:
            message: The message to log.

        Returns:
            Formatted log message with 'Base:' prefix.
        """
        return f"Base: {message}"


class EnhancedLogger(BaseLogger):
    """Enhanced logger demonstrating @override decorator usage.

    This class explicitly marks overridden methods with @override,
    providing better IDE support and compile-time verification.
    """

    @override
    def log(self, message: str) -> str:
        """Override log method with enhanced functionality.

        Args:
            message: The message to log.

        Returns:
            Formatted log message with 'Enhanced:' prefix.
        """
        return f"Enhanced: {message}"


# Python 3.12 TaskGroup with enhanced capabilities
async def task_with_name(name: str, delay: float) -> tuple[str, float]:
    """Async task that simulates work and returns its name and delay.

    Args:
        name: Task identifier.
        delay: Simulated work duration in seconds.

    Returns:
        Tuple of (task_name, actual_delay).
    """
    await asyncio.sleep(delay)
    return (name, delay)


async def run_tasks_with_names() -> list[tuple[str, float]]:
    """Run multiple tasks concurrently using Python 3.12's TaskGroup.

    Demonstrates TaskGroup's improved error handling and task management
    capabilities introduced in Python 3.12.

    Returns:
        List of tuples containing task results.
    """
    # TaskGroup ensures all tasks complete or all are cancelled on error
    async with asyncio.TaskGroup() as tg:
        # Create tasks with meaningful names for better debugging
        tasks = [
            tg.create_task(task_with_name(f"Task-{i+1}", 0.01 * (i % 2 + 1)))
            for i in range(3)
        ]

    # Collect and return all results
    return [task.result() for task in tasks]


# Improved f-string syntax
def format_with_nested_fstring(name: str, value: int) -> str:
    """Demonstrate improved f-string capabilities in Python 3.12.

    Python 3.12 enhances f-strings with better error messages,
    improved performance, and support for more complex expressions.

    Args:
        name: Name to include in greeting.
        value: Numeric value to format.

    Returns:
        Formatted string demonstrating f-string capabilities.
    """
    # Python 3.12 allows more complex f-string expressions
    # with better debugging and error reporting
    result = f"Hello {name}! The answer is {value}."
    return result


# PEP 695: Type parameter syntax (simplified generic)
T = TypeVar('T')


class GenericStack(Generic[T]):
    """Generic stack implementation demonstrating type parameter syntax.

    While Python 3.12 introduces new type parameter syntax,
    this implementation uses Generic for broader compatibility.

    Attributes:
        _items: Internal list storing stack items.
    """

    def __init__(self) -> None:
        """Initialize an empty stack."""
        self._items: list[T] = []

    def push(self, item: T) -> None:
        """Push an item onto the stack.

        Args:
            item: Item to add to the top of the stack.
        """
        self._items.append(item)

    def pop(self) -> T:
        """Pop and return the top item from the stack.

        Returns:
            The item from the top of the stack.

        Raises:
            IndexError: If the stack is empty.
        """
        if not self._items:
            raise IndexError("pop from empty stack")
        return self._items.pop()

    def is_empty(self) -> bool:
        """Check if the stack is empty.

        Returns:
            True if stack is empty, False otherwise.
        """
        return len(self._items) == 0

    def size(self) -> int:
        """Get the current size of the stack.

        Returns:
            Number of items in the stack.
        """
        return len(self._items)


# Enhanced error messages demonstration
def trigger_enhanced_error() -> Any:
    """Trigger an error demonstrating Python 3.12's enhanced error messages.

    Python 3.12 provides more helpful error messages with suggestions
    for common mistakes like typos in attribute names.

    Returns:
        Never returns, always raises AttributeError.

    Raises:
        AttributeError: With enhanced message suggesting correct attribute.
    """
    class Example:
        """Example class for demonstrating error messages."""

        def __init__(self) -> None:
            self.attribute = "value"

    obj = Example()
    # This will trigger an AttributeError with helpful suggestions
    # Python 3.12 will suggest: "Did you mean: 'attribute'?"
    return obj.atribute  # Intentional typo for demonstration


# Buffer protocol improvements
class BufferProcessor:
    """Process buffer data demonstrating Python 3.12 buffer improvements.

    Python 3.12 enhances buffer protocol with better performance
    and more efficient memory handling.
    """

    def process(self, data: bytes) -> bytes:
        """Process buffer data with transformation.

        Args:
            data: Input bytes to process.

        Returns:
            Processed bytes in uppercase.
        """
        # Demonstrate buffer processing with transformation
        # In Python 3.12, buffer operations are more efficient
        return data.upper()

    def process_with_validation(self, data: bytes) -> Optional[bytes]:
        """Process buffer data with validation.

        Args:
            data: Input bytes to process.

        Returns:
            Processed bytes if valid, None otherwise.
        """
        if not data:
            return None
        return self.process(data)


# Improved typing with dataclasses
@dataclass
class TypedConfig:
    """Configuration with typed fields using dataclasses.

    Demonstrates Python 3.12's improved typing support and
    dataclass enhancements for configuration management.

    Attributes:
        debug: Enable debug mode.
        timeout: Operation timeout in seconds.
        name: Configuration name identifier.
        max_retries: Maximum retry attempts (optional).
        verbose: Enable verbose output (optional).
    """
    debug: bool
    timeout: int
    name: str
    max_retries: int = field(default=3)
    verbose: bool = field(default=False)

    def __post_init__(self) -> None:
        """Validate configuration after initialization."""
        if self.timeout < 0:
            raise ValueError("Timeout must be non-negative")
        if self.max_retries < 0:
            raise ValueError("Max retries must be non-negative")

    def to_dict(self) -> dict[str, Any]:
        """Convert configuration to dictionary.

        Returns:
            Dictionary representation of configuration.
        """
        return {
            'debug': self.debug,
            'timeout': self.timeout,
            'name': self.name,
            'max_retries': self.max_retries,
            'verbose': self.verbose
        }