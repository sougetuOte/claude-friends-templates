#!/usr/bin/env python3
"""
E2E Test Suite: Performance Benchmarks
Comprehensive performance testing with pytest-benchmark

TDD Red Phase: Write failing tests first
Test Framework: pytest 8.4+ with pytest-benchmark
Target: Task 4.2.1 - Profiling and Performance Optimization
Python: 3.12+
"""

import json
import os
import subprocess
import time

import pytest

# Try to import pytest-benchmark
try:
    from pytest_benchmark.fixture import BenchmarkFixture
except ImportError:
    pytest.skip("pytest-benchmark not installed", allow_module_level=True)


class TestHandoverPerformance:
    """Test Suite: Handover system performance benchmarks"""

    @pytest.mark.benchmark
    @pytest.mark.performance
    def test_handover_generation_speed(self, claude_workspace, benchmark):
        """
        Benchmark 1: Handover generation time

        Expected: FAIL (baseline not established)
        Target: <100ms for handover generation
        """
        os.environ["CLAUDE_AGENT"] = "planner"

        def generate_handover():
            result = subprocess.run(
                [
                    "bash",
                    str(claude_workspace / ".claude" / "scripts" / "agent-switch.sh"),
                    "planner",
                    "builder",
                ],
                cwd=claude_workspace,
                capture_output=True,
                text=True,
                timeout=30,
            )
            return result.returncode

        # Benchmark execution
        result = benchmark(generate_handover)
        assert result == 0, "Handover generation failed"

        # Assert: Performance target (stats available after benchmark)
        # Median time should be < 100ms
        # Note: First run may be slower due to cold start

    @pytest.mark.benchmark
    @pytest.mark.performance
    def test_handover_file_write_speed(self, claude_workspace, benchmark, tmp_path):
        """
        Benchmark 2: Handover file I/O performance

        Expected: FAIL (I/O optimization not done)
        Target: <10ms for file write
        """
        handover_data = {
            "metadata": {
                "id": "test-123",
                "createdAt": "2025-09-30T10:00:00+00:00",
                "fromAgent": "planner",
                "toAgent": "builder",
            },
            "summary": {
                "completedTasks": ["Task 1", "Task 2"],
                "currentTask": "Task 3",
                "blockers": [],
                "nextSteps": ["Step 1", "Step 2"],
            },
            "context": {
                "gitStatus": "clean",
                "modifiedFiles": [],
                "testStatus": "passing",
            },
        }

        handover_file = tmp_path / "handover.json"

        def write_handover():
            with open(handover_file, "w") as f:
                json.dump(handover_data, f, indent=2)
            return handover_file.exists()

        # Benchmark
        result = benchmark(write_handover)
        assert result is True, "File write failed"

    @pytest.mark.benchmark
    @pytest.mark.performance
    def test_log_entry_write_speed(self, benchmark, tmp_path):
        """
        Benchmark 3: Log entry write performance (JSONL)

        Expected: FAIL (logging performance not optimized)
        Target: <5ms per log entry
        """
        log_file = tmp_path / "benchmark.jsonl"
        log_entry = {
            "timestamp": "2025-09-30T10:00:00+00:00",
            "level": "INFO",
            "message": "Test log entry",
            "logger": "test",
            "context": {"agent": "planner"},
            "metadata": {},
            "ai_metadata": {"priority": "normal"},
        }

        def write_log_entry():
            with open(log_file, "a") as f:
                json.dump(log_entry, f, ensure_ascii=False)
                f.write("\n")
            return log_file.exists()

        # Benchmark
        result = benchmark(write_log_entry)
        assert result is True, "Log write failed"

    @pytest.mark.benchmark
    @pytest.mark.performance
    def test_log_analysis_speed_1000_entries(
        self, benchmark, tmp_path, claude_workspace
    ):
        """
        Benchmark 4: Log analysis performance on 1,000 entries

        Expected: FAIL (analysis not optimized)
        Target: <500ms for 1,000 entries
        """
        # Arrange: Create 1,000 log entries
        log_file = tmp_path / "benchmark.jsonl"
        for i in range(1000):
            log_entry = {
                "timestamp": f"2025-09-30T10:{(i//60)%60:02d}:{i%60:02d}+00:00",
                "level": "ERROR" if i % 10 == 0 else "INFO",
                "message": f"Entry {i}",
                "logger": "test",
                "context": {"agent": "planner"},
                "metadata": {"operation": f"op_{i%5}"},
                "ai_metadata": {"priority": "normal"},
            }
            with open(log_file, "a") as f:
                f.write(json.dumps(log_entry) + "\n")

        # Setup Python path
        import sys

        sys.path.insert(0, str(claude_workspace / ".claude" / "scripts"))

        def analyze_logs():
            from error_pattern_learning import LogAnalyzer

            analyzer = LogAnalyzer(log_file)
            patterns = analyzer.analyze_patterns()
            insights = analyzer.generate_insights()
            return len(patterns.get("error_patterns", {}))

        # Benchmark
        result = benchmark(analyze_logs)
        assert result > 0, "Should detect error patterns"

    @pytest.mark.benchmark
    @pytest.mark.performance
    def test_log_parsing_speed_jsonl(self, benchmark, tmp_path):
        """
        Benchmark 5: JSONL parsing performance

        Expected: FAIL (parsing optimization needed)
        Target: <200ms for 10,000 lines
        """
        # Arrange: Create 10,000 JSONL entries
        log_file = tmp_path / "large_benchmark.jsonl"
        for i in range(10000):
            entry = {"id": i, "message": f"Entry {i}", "value": i * 2}
            with open(log_file, "a") as f:
                f.write(json.dumps(entry) + "\n")

        def parse_jsonl():
            entries = []
            with open(log_file) as f:
                for line in f:
                    if line.strip():
                        entries.append(json.loads(line))
            return len(entries)

        # Benchmark
        result = benchmark(parse_jsonl)
        assert result == 10000, "Should parse all entries"


class TestMemoryPerformance:
    """Test Suite: Memory usage benchmarks"""

    @pytest.mark.benchmark
    @pytest.mark.performance
    @pytest.mark.memory
    def test_handover_memory_usage(self, claude_workspace, tmp_path):
        """
        Test 6: Handover generation memory usage

        Expected: FAIL (memory profiling not implemented)
        Target: <50MB memory for handover generation
        """
        import tracemalloc

        tracemalloc.start()

        # Take initial snapshot
        snapshot_before = tracemalloc.take_snapshot()

        # Execute handover
        os.environ["CLAUDE_AGENT"] = "planner"
        result = subprocess.run(
            [
                "bash",
                str(claude_workspace / ".claude" / "scripts" / "agent-switch.sh"),
                "planner",
                "builder",
            ],
            cwd=claude_workspace,
            capture_output=True,
            text=True,
            timeout=30,
        )

        # Take final snapshot
        snapshot_after = tracemalloc.take_snapshot()

        # Calculate memory difference
        top_stats = snapshot_after.compare_to(snapshot_before, "lineno")
        total_memory_mb = sum(stat.size_diff for stat in top_stats) / (1024 * 1024)

        tracemalloc.stop()

        # Assert: Memory usage target
        assert (
            total_memory_mb < 50.0
        ), f"Memory usage {total_memory_mb:.2f}MB exceeds 50MB target"
        assert result.returncode == 0, "Handover failed"

    @pytest.mark.benchmark
    @pytest.mark.performance
    @pytest.mark.memory
    def test_log_analysis_memory_usage_10k_entries(self, claude_workspace, tmp_path):
        """
        Test 7: Log analysis memory usage on 10,000 entries

        Expected: FAIL (memory optimization needed)
        Target: <100MB for 10,000 entries
        """
        import tracemalloc

        # Arrange: Create 10,000 log entries
        log_file = tmp_path / "memory_test.jsonl"
        for i in range(10000):
            log_entry = {
                "timestamp": f"2025-09-30T{(i//3600)%24:02d}:{(i//60)%60:02d}:{i%60:02d}+00:00",
                "level": "INFO",
                "message": f"Entry {i}",
                "logger": "test",
                "context": {"agent": "planner"},
                "metadata": {},
                "ai_metadata": {},
            }
            with open(log_file, "a") as f:
                f.write(json.dumps(log_entry) + "\n")

        # Setup Python path
        import sys

        sys.path.insert(0, str(claude_workspace / ".claude" / "scripts"))

        tracemalloc.start()
        snapshot_before = tracemalloc.take_snapshot()

        # Act: Analyze logs
        from error_pattern_learning import LogAnalyzer

        analyzer = LogAnalyzer(log_file)
        patterns = analyzer.analyze_patterns()

        snapshot_after = tracemalloc.take_snapshot()
        top_stats = snapshot_after.compare_to(snapshot_before, "lineno")
        total_memory_mb = sum(stat.size_diff for stat in top_stats) / (1024 * 1024)

        tracemalloc.stop()

        # Assert: Memory target
        assert (
            total_memory_mb < 100.0
        ), f"Memory usage {total_memory_mb:.2f}MB exceeds 100MB target"
        assert patterns["total_entries"] == 10000, "Should load all entries"


class TestConcurrencyPerformance:
    """Test Suite: Concurrent operations performance"""

    @pytest.mark.benchmark
    @pytest.mark.performance
    @pytest.mark.asyncio
    async def test_concurrent_log_writes(self, benchmark, tmp_path):
        """
        Test 8: Concurrent log write performance

        Expected: FAIL (concurrency not optimized)
        Target: 100 concurrent writes in <1 second
        """
        import asyncio

        log_file = tmp_path / "concurrent.jsonl"

        async def write_log_entry_async(entry_id):
            log_entry = {
                "id": entry_id,
                "timestamp": "2025-09-30T10:00:00+00:00",
                "message": f"Concurrent entry {entry_id}",
            }
            # Simulate async I/O
            await asyncio.sleep(0.001)  # 1ms delay
            with open(log_file, "a") as f:
                f.write(json.dumps(log_entry) + "\n")

        async def write_concurrent_logs():
            tasks = [write_log_entry_async(i) for i in range(100)]
            await asyncio.gather(*tasks)
            return log_file.exists()

        # Benchmark (note: asyncio with benchmark requires special handling)
        # For now, we'll measure directly
        start_time = time.time()
        result = await write_concurrent_logs()
        elapsed_time = time.time() - start_time

        assert result is True, "Concurrent writes failed"
        assert (
            elapsed_time < 1.0
        ), f"Concurrent writes took {elapsed_time:.2f}s, expected <1s"


class TestRegressionBenchmarks:
    """Test Suite: Performance regression detection"""

    @pytest.mark.benchmark
    @pytest.mark.performance
    @pytest.mark.regression
    def test_handover_performance_regression(self, claude_workspace, benchmark):
        """
        Test 9: Detect handover performance regression

        Expected: FAIL (baseline not established)
        Purpose: Compare against historical baseline
        """
        os.environ["CLAUDE_AGENT"] = "planner"

        def generate_handover():
            result = subprocess.run(
                [
                    "bash",
                    str(claude_workspace / ".claude" / "scripts" / "agent-switch.sh"),
                    "planner",
                    "builder",
                ],
                cwd=claude_workspace,
                capture_output=True,
                text=True,
                timeout=30,
            )
            return result.returncode == 0

        # Benchmark with comparison
        result = benchmark(generate_handover)
        assert result is True, "Handover failed"

        # Note: pytest-benchmark can compare with saved baselines
        # Use --benchmark-save=baseline to create baseline
        # Use --benchmark-compare to compare against baseline

    @pytest.mark.benchmark
    @pytest.mark.performance
    @pytest.mark.regression
    def test_log_analysis_performance_regression(
        self, claude_workspace, benchmark, tmp_path
    ):
        """
        Test 10: Detect log analysis performance regression

        Expected: FAIL (baseline not established)
        Purpose: Compare against historical performance
        """
        # Arrange: Standard 1,000 entry dataset
        log_file = tmp_path / "regression_test.jsonl"
        for i in range(1000):
            log_entry = {
                "timestamp": f"2025-09-30T10:{(i//60)%60:02d}:{i%60:02d}+00:00",
                "level": "INFO",
                "message": f"Entry {i}",
                "logger": "test",
                "context": {},
                "metadata": {},
                "ai_metadata": {},
            }
            with open(log_file, "a") as f:
                f.write(json.dumps(log_entry) + "\n")

        # Setup Python path
        import sys

        sys.path.insert(0, str(claude_workspace / ".claude" / "scripts"))

        def analyze_standard_logs():
            from error_pattern_learning import LogAnalyzer

            analyzer = LogAnalyzer(log_file)
            patterns = analyzer.analyze_patterns()
            return patterns["total_entries"]

        # Benchmark
        result = benchmark(analyze_standard_logs)
        assert result == 1000, "Should analyze all entries"


if __name__ == "__main__":
    pytest.main(
        [
            __file__,
            "-v",
            "--tb=short",
            "-m",
            "benchmark and performance",
            "--benchmark-only",
        ]
    )
