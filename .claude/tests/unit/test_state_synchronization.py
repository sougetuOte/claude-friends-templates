#!/usr/bin/env python3
"""
State Synchronization Tests
TDD Red Phase: テストファースト実装
状態同期メカニズムのテストケース
"""

import json
import uuid
import unittest
from typing import Dict, Any, List, Optional
from pathlib import Path
import sys
import os
from datetime import datetime, timedelta
import tempfile

# Add parent directory to path
scripts_path = Path(__file__).parent.parent.parent / "scripts"
sys.path.insert(0, str(scripts_path))

# Import the module to be tested (will fail initially - Red Phase)
# We'll implement StateSynchronizer class later
try:
    from state_synchronizer import StateSynchronizer
except ImportError:
    # Expected during Red Phase
    class StateSynchronizer:
        pass


class TestStateSynchronization(unittest.TestCase):
    """State synchronization functionality tests"""

    def setUp(self):
        """Set up test environment"""
        self.temp_dir = tempfile.mkdtemp()
        self.sync = StateSynchronizer(state_dir=self.temp_dir)

        # Sample agent states
        self.planner_state = {
            "agent": "planner",
            "current_phase": "Phase 2",
            "tasks_completed": ["2.1.1", "2.1.2"],
            "tasks_in_progress": ["2.2.1"],
            "timestamp": datetime.now().isoformat()
        }

        self.builder_state = {
            "agent": "builder",
            "current_task": "2.2.1",
            "test_status": "red",
            "files_modified": ["test_state_sync.py"],
            "timestamp": datetime.now().isoformat()
        }

    def tearDown(self):
        """Clean up test environment"""
        import shutil
        if os.path.exists(self.temp_dir):
            shutil.rmtree(self.temp_dir)

    def test_save_agent_state(self):
        """Test saving agent state"""
        # Save planner state
        result = self.sync.save_state("planner", self.planner_state)

        self.assertTrue(result["success"])
        self.assertIn("state_id", result)
        self.assertIn("timestamp", result)
        self.assertEqual(result["agent"], "planner")

    def test_load_agent_state(self):
        """Test loading agent state"""
        # Save state first
        save_result = self.sync.save_state("planner", self.planner_state)
        state_id = save_result["state_id"]

        # Load the saved state
        loaded_state = self.sync.load_state("planner", state_id)

        self.assertIsNotNone(loaded_state)
        self.assertEqual(loaded_state["agent"], "planner")
        self.assertEqual(loaded_state["current_phase"], "Phase 2")
        self.assertEqual(loaded_state["tasks_completed"], ["2.1.1", "2.1.2"])

    def test_synchronize_states(self):
        """Test synchronizing states between agents"""
        # Save states for both agents
        self.sync.save_state("planner", self.planner_state)
        self.sync.save_state("builder", self.builder_state)

        # Synchronize states
        sync_result = self.sync.synchronize_states(["planner", "builder"])

        self.assertTrue(sync_result["synchronized"])
        self.assertIn("sync_id", sync_result)
        self.assertIn("agents", sync_result)
        self.assertEqual(len(sync_result["agents"]), 2)
        self.assertIn("timestamp", sync_result)

    def test_detect_state_conflicts(self):
        """Test detecting conflicts in agent states"""
        # Create conflicting states
        planner_state_conflict = {
            "agent": "planner",
            "current_task": "2.2.1",
            "task_status": "completed"
        }

        builder_state_conflict = {
            "agent": "builder",
            "current_task": "2.2.1",
            "task_status": "in_progress"
        }

        self.sync.save_state("planner", planner_state_conflict)
        self.sync.save_state("builder", builder_state_conflict)

        # Check for conflicts
        conflicts = self.sync.detect_conflicts(["planner", "builder"])

        self.assertIsNotNone(conflicts)
        self.assertTrue(len(conflicts) > 0)
        self.assertIn("field", conflicts[0])
        self.assertIn("agents", conflicts[0])
        self.assertEqual(conflicts[0]["field"], "current_task.task_status")

    def test_resolve_conflicts(self):
        """Test resolving conflicts between states"""
        # Create conflicting states
        conflicts = [
            {
                "field": "task_status",
                "planner": "completed",
                "builder": "in_progress"
            }
        ]

        # Resolve conflicts (builder takes precedence for implementation status)
        resolution = self.sync.resolve_conflicts(
            conflicts,
            resolution_strategy="builder_priority"
        )

        self.assertIsNotNone(resolution)
        self.assertEqual(resolution["task_status"], "in_progress")

    def test_state_history_tracking(self):
        """Test tracking state change history"""
        # Save multiple states over time
        for i in range(3):
            state = self.planner_state.copy()
            state["iteration"] = i
            self.sync.save_state("planner", state)

        # Get state history
        history = self.sync.get_state_history("planner", limit=10)

        self.assertIsNotNone(history)
        self.assertEqual(len(history), 3)
        # History should be in reverse chronological order
        self.assertEqual(history[0]["iteration"], 2)
        self.assertEqual(history[2]["iteration"], 0)

    def test_state_diff_calculation(self):
        """Test calculating differences between states"""
        old_state = {
            "tasks_completed": ["2.1.1"],
            "current_phase": "Phase 1",
            "progress": 50
        }

        new_state = {
            "tasks_completed": ["2.1.1", "2.1.2"],
            "current_phase": "Phase 2",
            "progress": 75
        }

        diff = self.sync.calculate_diff(old_state, new_state)

        self.assertIsNotNone(diff)
        self.assertIn("added", diff)
        self.assertIn("modified", diff)
        self.assertIn("removed", diff)

        # Check specific changes
        self.assertIn("tasks_completed", diff["modified"])
        self.assertEqual(diff["modified"]["current_phase"]["old"], "Phase 1")
        self.assertEqual(diff["modified"]["current_phase"]["new"], "Phase 2")

    def test_atomic_state_update(self):
        """Test atomic state updates (all or nothing)"""
        initial_state = self.planner_state.copy()
        self.sync.save_state("planner", initial_state)

        # Try to update with invalid data (should fail)
        invalid_update = {
            "current_phase": "Phase 3",
            "invalid_field": None  # This will cause validation to fail
        }

        result = self.sync.atomic_update("planner", invalid_update)

        self.assertFalse(result["success"])
        self.assertIn("error", result)

        # Verify original state is unchanged
        current_state = self.sync.load_state("planner")
        self.assertEqual(current_state["current_phase"], "Phase 2")

    def test_broadcast_state_changes(self):
        """Test broadcasting state changes to multiple agents"""
        # Register agents for notifications
        self.sync.register_agent("planner", callback_url="http://planner/notify")
        self.sync.register_agent("builder", callback_url="http://builder/notify")

        # Make a state change
        state_change = {
            "event": "task_completed",
            "task": "2.2.1",
            "agent": "builder"
        }

        # Broadcast the change
        broadcast_result = self.sync.broadcast_change(state_change)

        self.assertTrue(broadcast_result["success"])
        self.assertEqual(broadcast_result["notified_agents"], ["planner", "builder"])
        self.assertIn("timestamp", broadcast_result)

    def test_state_checkpoint_creation(self):
        """Test creating checkpoints for state recovery"""
        # Save current state
        self.sync.save_state("planner", self.planner_state)

        # Create checkpoint
        checkpoint = self.sync.create_checkpoint("planner", "Before Phase 3")

        self.assertIsNotNone(checkpoint)
        self.assertIn("checkpoint_id", checkpoint)
        self.assertIn("description", checkpoint)
        self.assertIn("timestamp", checkpoint)

        # Modify state
        modified_state = self.planner_state.copy()
        modified_state["current_phase"] = "Phase 3"
        self.sync.save_state("planner", modified_state)

        # Restore from checkpoint
        restore_result = self.sync.restore_checkpoint("planner", checkpoint["checkpoint_id"])

        self.assertTrue(restore_result["success"])

        # Verify state is restored
        restored_state = self.sync.load_state("planner")
        self.assertEqual(restored_state["current_phase"], "Phase 2")

    def test_multi_agent_transaction(self):
        """Test transactional updates across multiple agents"""
        # Start a transaction
        transaction = self.sync.begin_transaction()

        # Update multiple agents within transaction
        self.sync.update_in_transaction(transaction, "planner", {"current_phase": "Phase 3"})
        self.sync.update_in_transaction(transaction, "builder", {"test_status": "green"})

        # Commit transaction (all updates applied atomically)
        commit_result = self.sync.commit_transaction(transaction)

        self.assertTrue(commit_result["success"])
        self.assertEqual(commit_result["updates_applied"], 2)

        # Verify both states were updated
        planner_state = self.sync.load_state("planner")
        builder_state = self.sync.load_state("builder")

        self.assertEqual(planner_state["current_phase"], "Phase 3")
        self.assertEqual(builder_state["test_status"], "green")

    def test_state_synchronization_with_timeout(self):
        """Test state synchronization with timeout handling"""
        # First save states for both agents so they exist
        self.sync.save_state("planner", self.planner_state)
        self.sync.save_state("builder", self.builder_state)

        # Now test synchronization with timeout
        sync_result = self.sync.synchronize_states(
            ["planner", "builder"],
            timeout_ms=1000  # 1 second timeout
        )

        # Should succeed since states exist and timeout is reasonable
        self.assertTrue(sync_result["synchronized"])
        self.assertIn("sync_id", sync_result)
        self.assertIn("timestamp", sync_result)


if __name__ == '__main__':
    unittest.main()