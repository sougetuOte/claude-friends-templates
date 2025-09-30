#!/usr/bin/env python3
"""
Helper script to log agent events from shell scripts
Used by agent-switch.sh to log to AI logger

Usage:
    python3 log_agent_event.py <level> <message> [key=value ...]

Example:
    python3 log_agent_event.py INFO "Agent switch initiated" from_agent=planner to_agent=builder
"""

import sys
import os

# Add scripts directory to path
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, SCRIPT_DIR)

try:
    from ai_logger import logger

    if len(sys.argv) < 3:
        print(
            "Usage: log_agent_event.py <level> <message> [key=value ...]",
            file=sys.stderr,
        )
        sys.exit(1)

    level = sys.argv[1].upper()
    message = sys.argv[2]

    # Parse key=value pairs
    metadata = {}
    agent_name = None
    for arg in sys.argv[3:]:
        if "=" in arg:
            key, value = arg.split("=", 1)
            if key == "agent":
                agent_name = value
            else:
                metadata[key] = value

    # Set context if agent is provided
    if agent_name:
        logger.set_context(agent=agent_name)

    # Log based on level
    if level == "ERROR":
        logger.error(message, **metadata)
    elif level == "WARNING":
        logger.warning(message, **metadata)
    elif level == "DEBUG":
        logger.debug(message, **metadata)
    elif level == "CRITICAL":
        logger.critical(message, **metadata)
    else:  # Default to INFO
        logger.info(message, **metadata)

except Exception as e:
    # Silent failure - don't break shell scripts
    print(f"[WARN] AI logger error: {e}", file=sys.stderr)
    sys.exit(0)
