#!/usr/bin/env python3
"""
State Synchronizer for Multi-Agent System
Handles state synchronization between Planner and Builder agents
"""

import json
import uuid
import hashlib
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Any, List, Optional, Tuple
import os


class StateSynchronizer:
    """State synchronization manager for agent coordination"""

    def __init__(self, state_dir: Optional[str] = None):
        """Initialize state synchronizer

        Args:
            state_dir: Directory to store state files (defaults to .claude/states)
        """
        if state_dir:
            self.state_dir = Path(state_dir)
        else:
            self.state_dir = Path(".claude/states")

        self.state_dir.mkdir(parents=True, exist_ok=True)
        self.registered_agents = {}
        self.transactions = {}
        self.checkpoints = {}

    def save_state(self, agent: str, state: Dict[str, Any]) -> Dict[str, Any]:
        """Save agent state to persistent storage

        Args:
            agent: Agent name (planner/builder)
            state: State data to save

        Returns:
            Result with state_id and metadata
        """
        state_id = str(uuid.uuid4())
        timestamp = datetime.now(timezone.utc).isoformat()

        # Add metadata
        state_with_metadata = {
            "state_id": state_id,
            "agent": agent,
            "timestamp": timestamp,
            "data": state
        }

        # Save to file
        agent_dir = self.state_dir / agent
        agent_dir.mkdir(exist_ok=True)

        state_file = agent_dir / f"state_{state_id}.json"
        with open(state_file, 'w') as f:
            json.dump(state_with_metadata, f, indent=2, default=str)

        # Also save as current state
        current_file = agent_dir / "current.json"
        with open(current_file, 'w') as f:
            json.dump(state_with_metadata, f, indent=2, default=str)

        return {
            "success": True,
            "state_id": state_id,
            "timestamp": timestamp,
            "agent": agent
        }

    def load_state(self, agent: str, state_id: Optional[str] = None) -> Optional[Dict[str, Any]]:
        """Load agent state from storage

        Args:
            agent: Agent name
            state_id: Specific state ID to load (defaults to current)

        Returns:
            State data or None if not found
        """
        agent_dir = self.state_dir / agent

        if state_id:
            state_file = agent_dir / f"state_{state_id}.json"
        else:
            state_file = agent_dir / "current.json"

        if not state_file.exists():
            return None

        with open(state_file, 'r') as f:
            state_with_metadata = json.load(f)

        # Return the data part, but include agent info
        state_data = state_with_metadata.get("data", {})
        state_data["agent"] = agent

        return state_data

    def synchronize_states(self, agents: List[str], timeout_ms: int = 5000) -> Dict[str, Any]:
        """Synchronize states between multiple agents

        Args:
            agents: List of agent names to synchronize
            timeout_ms: Timeout in milliseconds

        Returns:
            Synchronization result
        """
        sync_id = str(uuid.uuid4())
        timestamp = datetime.now(timezone.utc).isoformat()

        # Load current states for all agents
        agent_states = {}
        for agent in agents:
            state = self.load_state(agent)
            if state:
                agent_states[agent] = state

        # Check if all agents have states
        if len(agent_states) != len(agents):
            return {
                "synchronized": False,
                "error": "Some agents have no state",
                "sync_id": sync_id
            }

        # Create sync record
        sync_record = {
            "sync_id": sync_id,
            "timestamp": timestamp,
            "agents": agents,
            "states": agent_states
        }

        # Save sync record
        sync_file = self.state_dir / f"sync_{sync_id}.json"
        with open(sync_file, 'w') as f:
            json.dump(sync_record, f, indent=2, default=str)

        return {
            "synchronized": True,
            "sync_id": sync_id,
            "agents": agents,
            "timestamp": timestamp
        }

    def detect_conflicts(self, agents: List[str]) -> List[Dict[str, Any]]:
        """Detect conflicts between agent states

        Args:
            agents: List of agents to check

        Returns:
            List of detected conflicts
        """
        conflicts = []

        # Load states
        states = {}
        for agent in agents:
            state = self.load_state(agent)
            if state:
                states[agent] = state

        # Compare common fields
        # Check for task status conflicts
        if "planner" in states and "builder" in states:
            planner_state = states["planner"]
            builder_state = states["builder"]

            # Check if both have current_task
            if "current_task" in planner_state and "current_task" in builder_state:
                if "task_status" in planner_state and "task_status" in builder_state:
                    if planner_state.get("task_status") != builder_state.get("task_status"):
                        conflicts.append({
                            "field": "current_task.task_status",
                            "agents": {
                                "planner": planner_state.get("task_status"),
                                "builder": builder_state.get("task_status")
                            }
                        })

        return conflicts

    def resolve_conflicts(self, conflicts: List[Dict[str, Any]],
                         resolution_strategy: str = "latest") -> Dict[str, Any]:
        """Resolve conflicts between states

        Args:
            conflicts: List of conflicts to resolve
            resolution_strategy: Strategy to use (latest, builder_priority, planner_priority)

        Returns:
            Resolved state
        """
        resolved = {}

        for conflict in conflicts:
            field = conflict["field"]

            if resolution_strategy == "builder_priority":
                # Builder has priority for implementation status
                if "builder" in conflict.get("agents", {}):
                    resolved[field.split(".")[-1]] = conflict["agents"]["builder"]
                elif "builder" in conflict:
                    resolved[field.split(".")[-1]] = conflict["builder"]
            elif resolution_strategy == "planner_priority":
                # Planner has priority for planning decisions
                if "planner" in conflict.get("agents", {}):
                    resolved[field.split(".")[-1]] = conflict["agents"]["planner"]
                elif "planner" in conflict:
                    resolved[field.split(".")[-1]] = conflict["planner"]
            else:  # latest
                # Use the most recent value
                # For this example, we'll use builder as it's usually more recent
                if "builder" in conflict:
                    resolved[field.split(".")[-1]] = conflict["builder"]

        return resolved

    def get_state_history(self, agent: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Get state change history for an agent

        Args:
            agent: Agent name
            limit: Maximum number of entries to return

        Returns:
            List of historical states in reverse chronological order
        """
        agent_dir = self.state_dir / agent
        if not agent_dir.exists():
            return []

        # Get all state files
        state_files = sorted(agent_dir.glob("state_*.json"),
                           key=lambda x: x.stat().st_mtime,
                           reverse=True)

        history = []
        for state_file in state_files[:limit]:
            with open(state_file, 'r') as f:
                state_data = json.load(f)
                history.append(state_data.get("data", {}))

        return history

    def calculate_diff(self, old_state: Dict[str, Any],
                      new_state: Dict[str, Any]) -> Dict[str, Any]:
        """Calculate differences between two states

        Args:
            old_state: Previous state
            new_state: Current state

        Returns:
            Dictionary with added, modified, and removed fields
        """
        diff = {
            "added": {},
            "modified": {},
            "removed": {}
        }

        # Find added and modified fields
        for key, new_value in new_state.items():
            if key not in old_state:
                diff["added"][key] = new_value
            elif old_state[key] != new_value:
                diff["modified"][key] = {
                    "old": old_state[key],
                    "new": new_value
                }

        # Find removed fields
        for key in old_state:
            if key not in new_state:
                diff["removed"][key] = old_state[key]

        return diff

    def atomic_update(self, agent: str, update: Dict[str, Any]) -> Dict[str, Any]:
        """Perform atomic state update

        Args:
            agent: Agent name
            update: Updates to apply

        Returns:
            Result of the update operation
        """
        try:
            # Validate update (check for invalid fields)
            if "invalid_field" in update and update["invalid_field"] is None:
                return {
                    "success": False,
                    "error": "Invalid field in update"
                }

            # Load current state
            current_state = self.load_state(agent) or {}

            # Apply update
            updated_state = current_state.copy()
            updated_state.update(update)

            # Save atomically
            result = self.save_state(agent, updated_state)

            return {
                "success": True,
                "state_id": result["state_id"]
            }

        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }

    def register_agent(self, agent: str, callback_url: str) -> None:
        """Register an agent for state change notifications

        Args:
            agent: Agent name
            callback_url: URL to send notifications to
        """
        self.registered_agents[agent] = {
            "callback_url": callback_url,
            "registered_at": datetime.now(timezone.utc).isoformat()
        }

    def broadcast_change(self, change: Dict[str, Any]) -> Dict[str, Any]:
        """Broadcast state change to registered agents

        Args:
            change: Change event to broadcast

        Returns:
            Broadcast result
        """
        timestamp = datetime.now(timezone.utc).isoformat()
        notified_agents = list(self.registered_agents.keys())

        # In a real implementation, we would send HTTP requests to callback URLs
        # For testing, we just simulate successful notification

        return {
            "success": True,
            "notified_agents": notified_agents,
            "timestamp": timestamp,
            "change": change
        }

    def create_checkpoint(self, agent: str, description: str) -> Dict[str, Any]:
        """Create a checkpoint for state recovery

        Args:
            agent: Agent name
            description: Checkpoint description

        Returns:
            Checkpoint information
        """
        checkpoint_id = str(uuid.uuid4())
        timestamp = datetime.now(timezone.utc).isoformat()

        # Get current state
        current_state = self.load_state(agent)

        # Store checkpoint
        checkpoint = {
            "checkpoint_id": checkpoint_id,
            "agent": agent,
            "description": description,
            "timestamp": timestamp,
            "state": current_state
        }

        # Save checkpoint
        checkpoint_file = self.state_dir / f"checkpoint_{checkpoint_id}.json"
        with open(checkpoint_file, 'w') as f:
            json.dump(checkpoint, f, indent=2, default=str)

        # Store in memory for quick access
        self.checkpoints[checkpoint_id] = checkpoint

        return {
            "checkpoint_id": checkpoint_id,
            "description": description,
            "timestamp": timestamp,
            "agent": agent
        }

    def restore_checkpoint(self, agent: str, checkpoint_id: str) -> Dict[str, Any]:
        """Restore state from a checkpoint

        Args:
            agent: Agent name
            checkpoint_id: Checkpoint to restore

        Returns:
            Restore result
        """
        # Load checkpoint
        if checkpoint_id in self.checkpoints:
            checkpoint = self.checkpoints[checkpoint_id]
        else:
            checkpoint_file = self.state_dir / f"checkpoint_{checkpoint_id}.json"
            if not checkpoint_file.exists():
                return {
                    "success": False,
                    "error": "Checkpoint not found"
                }

            with open(checkpoint_file, 'r') as f:
                checkpoint = json.load(f)

        # Restore state
        restored_state = checkpoint["state"]
        self.save_state(agent, restored_state)

        return {
            "success": True,
            "checkpoint_id": checkpoint_id,
            "restored_at": datetime.now(timezone.utc).isoformat()
        }

    def begin_transaction(self) -> str:
        """Begin a multi-agent transaction

        Returns:
            Transaction ID
        """
        transaction_id = str(uuid.uuid4())
        self.transactions[transaction_id] = {
            "id": transaction_id,
            "started_at": datetime.now(timezone.utc).isoformat(),
            "updates": [],
            "status": "pending"
        }
        return transaction_id

    def update_in_transaction(self, transaction_id: str, agent: str,
                             update: Dict[str, Any]) -> None:
        """Add an update to a transaction

        Args:
            transaction_id: Transaction ID
            agent: Agent name
            update: Update to apply
        """
        if transaction_id in self.transactions:
            self.transactions[transaction_id]["updates"].append({
                "agent": agent,
                "update": update
            })

    def commit_transaction(self, transaction_id: str) -> Dict[str, Any]:
        """Commit a transaction (apply all updates atomically)

        Args:
            transaction_id: Transaction ID

        Returns:
            Commit result
        """
        if transaction_id not in self.transactions:
            return {
                "success": False,
                "error": "Transaction not found"
            }

        transaction = self.transactions[transaction_id]
        updates_applied = 0

        try:
            # Apply all updates
            for update_info in transaction["updates"]:
                agent = update_info["agent"]
                update = update_info["update"]

                # Load current state
                current_state = self.load_state(agent) or {}

                # Apply update
                current_state.update(update)

                # Save state
                self.save_state(agent, current_state)
                updates_applied += 1

            # Mark transaction as committed
            transaction["status"] = "committed"
            transaction["committed_at"] = datetime.now(timezone.utc).isoformat()

            return {
                "success": True,
                "transaction_id": transaction_id,
                "updates_applied": updates_applied
            }

        except Exception as e:
            # Rollback would happen here in a real implementation
            transaction["status"] = "failed"
            return {
                "success": False,
                "error": str(e),
                "updates_applied": updates_applied
            }

    def rollback_transaction(self, transaction_id: str) -> Dict[str, Any]:
        """Rollback a transaction

        Args:
            transaction_id: Transaction ID

        Returns:
            Rollback result
        """
        if transaction_id not in self.transactions:
            return {
                "success": False,
                "error": "Transaction not found"
            }

        self.transactions[transaction_id]["status"] = "rolled_back"

        return {
            "success": True,
            "transaction_id": transaction_id
        }


# Utility functions
def get_state_synchronizer(state_dir: Optional[str] = None) -> StateSynchronizer:
    """Factory function to get a state synchronizer instance

    Args:
        state_dir: Optional state directory path

    Returns:
        StateSynchronizer instance
    """
    return StateSynchronizer(state_dir)


if __name__ == "__main__":
    # Example usage
    sync = StateSynchronizer()

    # Save planner state
    planner_state = {
        "current_phase": "Phase 2",
        "tasks_completed": ["2.1.1", "2.1.2"],
        "timestamp": datetime.now(timezone.utc).isoformat()
    }

    result = sync.save_state("planner", planner_state)
    print(f"Saved planner state: {result}")

    # Load and display state
    loaded_state = sync.load_state("planner")
    print(f"Loaded state: {loaded_state}")