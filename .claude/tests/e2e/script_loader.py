#!/usr/bin/env python3
"""
Script Loader Utility
Task 2.5.4 - Green Phase

Utility to import Python scripts with hyphenated filenames
Solves: Python cannot import files like "handover-generator.py" directly

Example:
    from script_loader import load_script_module

    # Import handover-generator.py
    handover_gen = load_script_module(
        Path(".claude/scripts/handover-generator.py"),
        "handover_generator"
    )

    # Use the module
    generator = handover_gen.HandoverGenerator()
"""

import importlib.util
import sys
from pathlib import Path
from typing import Any


def load_script_module(script_path: Path, module_name: str) -> Any:
    """
    Load a Python script as a module, handling hyphenated filenames

    Python's import system converts hyphens to underscores, causing
    ModuleNotFoundError for files like "handover-generator.py".
    This function uses importlib.util to load such files directly.

    Args:
        script_path: Path to .py file (can contain hyphens)
        module_name: Desired module name (without hyphens, e.g., "handover_generator")

    Returns:
        Loaded module object

    Raises:
        FileNotFoundError: If script_path doesn't exist
        ImportError: If module cannot be loaded

    Example:
        >>> script = Path(".claude/scripts/handover-generator.py")
        >>> module = load_script_module(script, "handover_generator")
        >>> generator = module.HandoverGenerator()
    """
    if not script_path.exists():
        raise FileNotFoundError(f"Script not found: {script_path}")

    # Create module spec from file location
    spec = importlib.util.spec_from_file_location(module_name, script_path)

    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot create module spec for {script_path}")

    # Create module from spec
    module = importlib.util.module_from_spec(spec)

    # Register module in sys.modules for caching
    sys.modules[module_name] = module

    # Execute module (load code)
    spec.loader.exec_module(module)

    return module


# Pre-load commonly used modules for convenience
_COMMON_MODULES = {}


def get_handover_generator_module():
    """Get handover-generator module (cached)"""
    if "handover_generator" not in _COMMON_MODULES:
        script_path = Path(".claude/scripts/handover-generator.py")
        if script_path.exists():
            _COMMON_MODULES["handover_generator"] = load_script_module(
                script_path, "handover_generator"
            )
    return _COMMON_MODULES.get("handover_generator")


def get_state_synchronizer_module():
    """Get state_synchronizer module (cached)"""
    if "state_synchronizer" not in _COMMON_MODULES:
        script_path = Path(".claude/scripts/state_synchronizer.py")
        if script_path.exists():
            _COMMON_MODULES["state_synchronizer"] = load_script_module(
                script_path, "state_synchronizer"
            )
    return _COMMON_MODULES.get("state_synchronizer")
