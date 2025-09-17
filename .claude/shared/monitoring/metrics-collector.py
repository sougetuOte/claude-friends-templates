#!/usr/bin/env python3
"""
Enhanced Metrics Collection System for claude-friends-templates
Implements 2025 performance monitoring best practices with AI-assisted analysis
"""

import os
import sys
import time
import json
import psutil
import threading
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Any, Optional, Union
from collections import defaultdict, deque
from contextlib import contextmanager
import uuid

# Memory Bank operations monitoring
class MemoryBankMonitor:
    def __init__(self, metrics_client):
        self.metrics_client = metrics_client
        self.operation_cache = deque(maxlen=1000)

    @contextmanager
    def track_operation(self, operation_type: str, file_path: str = None):
        """Track Memory Bank operation with comprehensive metrics"""
        operation_id = str(uuid.uuid4())
        start_time = time.time()
        start_memory = psutil.Process().memory_info().rss
        start_cpu_times = psutil.Process().cpu_times()

        operation_context = {
            'operation_id': operation_id,
            'operation_type': operation_type,
            'file_path': file_path,
            'start_time': start_time
        }

        try:
            yield operation_context
            success = True
            error_type = None
        except Exception as e:
            success = False
            error_type = type(e).__name__
            raise
        finally:
            end_time = time.time()
            duration = end_time - start_time
            end_memory = psutil.Process().memory_info().rss
            end_cpu_times = psutil.Process().cpu_times()

            memory_delta = end_memory - start_memory
            cpu_time_delta = (end_cpu_times.user - start_cpu_times.user +
                            end_cpu_times.system - start_cpu_times.system)

            # File size analysis if path provided
            file_metrics = {}
            if file_path and os.path.exists(file_path):
                stat = os.stat(file_path)
                file_metrics = {
                    'file_size_bytes': stat.st_size,
                    'file_size_category': self._categorize_file_size(stat.st_size),
                    'file_age_seconds': time.time() - stat.st_mtime
                }

            # Emit detailed metrics
            tags = {
                'operation': operation_type,
                'success': success,
                'error_type': error_type or 'none',
                **file_metrics
            }

            self.metrics_client.emit_metric('memory_bank.operation.duration_ms',
                                          duration * 1000, tags)
            self.metrics_client.emit_metric('memory_bank.memory.delta_mb',
                                          memory_delta / (1024 * 1024), tags)
            self.metrics_client.emit_metric('memory_bank.cpu.time_ms',
                                          cpu_time_delta * 1000, tags)

            # Cache operation for pattern analysis
            self.operation_cache.append({
                'operation_id': operation_id,
                'timestamp': end_time,
                'operation_type': operation_type,
                'duration': duration,
                'memory_delta': memory_delta,
                'cpu_time': cpu_time_delta,
                'success': success,
                'file_metrics': file_metrics
            })

            # Analyze for performance patterns
            self._analyze_operation_patterns()

    def _categorize_file_size(self, size_bytes: int) -> str:
        """Categorize file size for metrics grouping"""
        if size_bytes < 1024:
            return 'tiny'
        elif size_bytes < 1024 * 1024:
            return 'small'
        elif size_bytes < 10 * 1024 * 1024:
            return 'medium'
        elif size_bytes < 100 * 1024 * 1024:
            return 'large'
        else:
            return 'huge'

    def _analyze_operation_patterns(self):
        """Analyze recent operations for performance patterns"""
        if len(self.operation_cache) < 10:
            return

        recent_ops = list(self.operation_cache)[-10:]

        # Calculate operation efficiency trends
        efficiency_scores = []
        for op in recent_ops:
            # Simple efficiency calculation: operation value vs resource cost
            efficiency = 1.0 / (op['duration'] + op['memory_delta'] / (1024*1024*100))
            efficiency_scores.append(efficiency)

        # Detect efficiency degradation
        if len(efficiency_scores) >= 5:
            recent_avg = sum(efficiency_scores[-5:]) / 5
            older_avg = sum(efficiency_scores[-10:-5]) / 5

            degradation_ratio = (older_avg - recent_avg) / older_avg if older_avg > 0 else 0

            if degradation_ratio > 0.2:  # 20% degradation
                self.metrics_client.emit_alert('memory_bank_efficiency_degradation', {
                    'degradation_ratio': degradation_ratio,
                    'recent_operations': recent_ops[-5:],
                    'severity': 'warning' if degradation_ratio < 0.4 else 'critical'
                })

class HookExecutionTracker:
    def __init__(self, metrics_client):
        self.metrics_client = metrics_client
        self.hook_history = defaultdict(list)

    @contextmanager
    def track_hook_execution(self, hook_name: str, operation: str):
        """Track hook execution with comprehensive performance analysis"""
        start_time = time.time()
        start_resources = self._get_resource_snapshot()

        try:
            yield
            success = True
            error_info = None
        except Exception as e:
            success = False
            error_info = {
                'error_type': type(e).__name__,
                'error_message': str(e)[:200]  # Limit message length
            }
            raise
        finally:
            end_time = time.time()
            end_resources = self._get_resource_snapshot()

            duration = end_time - start_time
            resource_delta = self._calculate_resource_delta(start_resources, end_resources)

            # Emit metrics
            tags = {
                'hook_name': hook_name,
                'operation': operation,
                'success': success
            }

            if error_info:
                tags.update(error_info)

            self.metrics_client.emit_metric('hook.execution.duration_ms',
                                          duration * 1000, tags)
            self.metrics_client.emit_metric('hook.memory.peak_mb',
                                          resource_delta['memory_mb'], tags)
            self.metrics_client.emit_metric('hook.cpu.usage_percent',
                                          resource_delta['cpu_percent'], tags)

            # Track hook execution history for performance analysis
            self.hook_history[hook_name].append({
                'timestamp': end_time,
                'duration': duration,
                'success': success,
                'resource_delta': resource_delta
            })

            # Keep only recent history (last 100 executions per hook)
            if len(self.hook_history[hook_name]) > 100:
                self.hook_history[hook_name] = self.hook_history[hook_name][-100:]

            # Analyze hook performance trends
            self._analyze_hook_performance(hook_name)

    def _get_resource_snapshot(self) -> Dict[str, Any]:
        """Get current resource usage snapshot"""
        process = psutil.Process()
        return {
            'memory_rss': process.memory_info().rss,
            'memory_vms': process.memory_info().vms,
            'cpu_times': process.cpu_times(),
            'timestamp': time.time()
        }

    def _calculate_resource_delta(self, start: Dict, end: Dict) -> Dict[str, float]:
        """Calculate resource usage delta between snapshots"""
        memory_delta = (end['memory_rss'] - start['memory_rss']) / (1024 * 1024)
        cpu_delta = ((end['cpu_times'].user - start['cpu_times'].user) +
                    (end['cpu_times'].system - start['cpu_times'].system))
        time_delta = end['timestamp'] - start['timestamp']

        cpu_percent = (cpu_delta / time_delta * 100) if time_delta > 0 else 0

        return {
            'memory_mb': memory_delta,
            'cpu_percent': cpu_percent,
            'time_delta': time_delta
        }

    def _analyze_hook_performance(self, hook_name: str):
        """Analyze hook performance trends and detect anomalies"""
        history = self.hook_history[hook_name]
        if len(history) < 10:
            return

        recent_executions = history[-10:]

        # Calculate performance baseline
        durations = [h['duration'] for h in history[-50:]]  # Last 50 executions
        avg_duration = sum(durations) / len(durations)

        # Detect performance anomalies
        recent_avg = sum(h['duration'] for h in recent_executions) / len(recent_executions)

        if recent_avg > avg_duration * 1.5:  # 50% slower than baseline
            self.metrics_client.emit_alert('hook_performance_degradation', {
                'hook_name': hook_name,
                'baseline_avg_ms': avg_duration * 1000,
                'recent_avg_ms': recent_avg * 1000,
                'degradation_factor': recent_avg / avg_duration,
                'recent_executions': recent_executions,
                'severity': 'warning'
            })

class AgentSwitchPerformanceTracker:
    def __init__(self, metrics_client):
        self.metrics_client = metrics_client
        self.switch_history = deque(maxlen=500)

    @contextmanager
    def track_agent_switch(self, from_agent: str, to_agent: str):
        """Track agent switching performance and quality"""
        switch_id = str(uuid.uuid4())
        start_time = time.time()

        # Pre-switch context analysis
        pre_context = self._analyze_pre_switch_context(from_agent)

        try:
            yield {'switch_id': switch_id, 'start_time': start_time}
            success = True
            error_info = None
        except Exception as e:
            success = False
            error_info = {
                'error_type': type(e).__name__,
                'error_message': str(e)[:200]
            }
            raise
        finally:
            end_time = time.time()
            duration = end_time - start_time

            # Post-switch context analysis
            post_context = self._analyze_post_switch_context(to_agent)

            # Calculate context preservation score
            context_preservation_score = self._calculate_context_preservation(
                pre_context, post_context
            )

            # Analyze handover quality
            handover_metrics = self._analyze_handover_quality()

            # Emit comprehensive metrics
            tags = {
                'from_agent': from_agent,
                'to_agent': to_agent,
                'success': success
            }

            if error_info:
                tags.update(error_info)

            self.metrics_client.emit_metric('agent_switch.duration_ms',
                                          duration * 1000, tags)
            self.metrics_client.emit_metric('agent_switch.context_preservation_score',
                                          context_preservation_score, tags)
            self.metrics_client.emit_metric('agent_switch.handover_size_bytes',
                                          handover_metrics['size'], tags)
            self.metrics_client.emit_metric('agent_switch.handover_quality_score',
                                          handover_metrics['quality'], tags)

            # Store switch history for trend analysis
            switch_record = {
                'switch_id': switch_id,
                'timestamp': end_time,
                'from_agent': from_agent,
                'to_agent': to_agent,
                'duration': duration,
                'success': success,
                'context_preservation': context_preservation_score,
                'handover_metrics': handover_metrics,
                'pre_context': pre_context,
                'post_context': post_context
            }

            self.switch_history.append(switch_record)

            # Analyze switching patterns
            self._analyze_switching_patterns(from_agent, to_agent)

    def _analyze_pre_switch_context(self, agent: str) -> Dict[str, Any]:
        """Analyze context before agent switch"""
        context_info = {}

        # Analyze agent notes file
        notes_path = Path(f".claude/{agent}/notes.md")
        if notes_path.exists():
            stat = notes_path.stat()
            context_info['notes_size'] = stat.st_size
            context_info['notes_modified'] = stat.st_mtime

            # Count recent activity
            with open(notes_path, 'r', encoding='utf-8') as f:
                content = f.read()
                context_info['notes_lines'] = len(content.splitlines())
                context_info['notes_words'] = len(content.split())

        # Analyze active task state
        active_file = Path(".claude/agents/active.json")
        if active_file.exists():
            try:
                with open(active_file, 'r') as f:
                    active_data = json.load(f)
                    context_info['active_agent'] = active_data.get('agent', 'unknown')
                    context_info['session_duration'] = time.time() - active_data.get('started_at', time.time())
            except:
                pass

        return context_info

    def _analyze_post_switch_context(self, agent: str) -> Dict[str, Any]:
        """Analyze context after agent switch"""
        # Similar to pre-switch but captures the new agent's state
        return self._analyze_pre_switch_context(agent)

    def _calculate_context_preservation(self, pre_context: Dict, post_context: Dict) -> float:
        """Calculate how well context was preserved during switch"""
        # Simple heuristic: compare context richness
        score = 1.0

        # Check if important information was maintained
        if 'notes_size' in pre_context and 'notes_size' in post_context:
            size_ratio = post_context['notes_size'] / max(pre_context['notes_size'], 1)
            score *= min(1.0, size_ratio)  # Penalize significant information loss

        return score

    def _analyze_handover_quality(self) -> Dict[str, Any]:
        """Analyze handover file quality"""
        handover_path = Path(".claude/shared/handover-interrupt-template.md")

        if not handover_path.exists():
            return {'size': 0, 'quality': 0.0}

        stat = handover_path.stat()
        size = stat.st_size

        # Analyze handover content quality
        try:
            with open(handover_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # Quality heuristics
            quality_score = 0.0

            # Check for essential sections
            essential_sections = ['context', 'status', 'next', 'priority']
            sections_found = sum(1 for section in essential_sections
                               if section.lower() in content.lower())
            quality_score += (sections_found / len(essential_sections)) * 0.5

            # Check content richness
            words = len(content.split())
            if words > 50:  # Reasonable amount of information
                quality_score += 0.3
            if words > 100:  # Rich information
                quality_score += 0.2

            quality_score = min(1.0, quality_score)

        except Exception:
            quality_score = 0.0

        return {
            'size': size,
            'quality': quality_score
        }

    def _analyze_switching_patterns(self, from_agent: str, to_agent: str):
        """Analyze agent switching patterns for optimization opportunities"""
        if len(self.switch_history) < 20:
            return

        recent_switches = list(self.switch_history)[-20:]

        # Analyze switching frequency
        switch_pairs = defaultdict(int)
        total_duration = 0

        for switch in recent_switches:
            pair = f"{switch['from_agent']}->{switch['to_agent']}"
            switch_pairs[pair] += 1
            total_duration += switch['duration']

        # Detect inefficient switching patterns
        avg_duration = total_duration / len(recent_switches)
        frequent_switches = [(pair, count) for pair, count in switch_pairs.items()
                           if count > len(recent_switches) * 0.3]  # More than 30% of switches

        if frequent_switches and avg_duration > 5.0:  # Frequent switches + slow performance
            self.metrics_client.emit_alert('inefficient_switching_pattern', {
                'frequent_switches': frequent_switches,
                'average_duration_ms': avg_duration * 1000,
                'recent_switches_count': len(recent_switches),
                'severity': 'info',
                'recommendation': 'Consider optimizing handover templates for frequent switch patterns'
            })

class GreenComputingMonitor:
    def __init__(self, metrics_client):
        self.metrics_client = metrics_client
        self.energy_tracker = EnergyTracker()

    def track_operation_sustainability(self, operation_type: str, duration: float,
                                     cpu_usage: float, memory_usage: float):
        """Track environmental impact of operations"""

        # Calculate energy consumption (simplified model)
        energy_wh = self._calculate_energy_consumption(duration, cpu_usage, memory_usage)

        # Estimate carbon footprint
        carbon_footprint_g = self._calculate_carbon_footprint(energy_wh)

        # Calculate efficiency score
        efficiency_score = self._calculate_efficiency_score(operation_type, energy_wh)

        # Emit green computing metrics
        tags = {'operation': operation_type}

        self.metrics_client.emit_metric('green.energy_consumption_wh', energy_wh, tags)
        self.metrics_client.emit_metric('green.carbon_footprint_g', carbon_footprint_g, tags)
        self.metrics_client.emit_metric('green.efficiency_score', efficiency_score, tags)

        # Alert on inefficient operations
        if efficiency_score < 0.6:  # Below 60% efficiency
            self.metrics_client.emit_alert('low_energy_efficiency', {
                'operation_type': operation_type,
                'efficiency_score': efficiency_score,
                'energy_consumption_wh': energy_wh,
                'carbon_footprint_g': carbon_footprint_g,
                'severity': 'info',
                'recommendation': self._get_efficiency_recommendation(operation_type)
            })

    def _calculate_energy_consumption(self, duration: float, cpu_usage: float,
                                    memory_usage: float) -> float:
        """Calculate energy consumption using simplified model"""
        # Simplified energy model for development machine
        base_power_w = 20  # Base system power
        cpu_power_w = 65 * (cpu_usage / 100.0)  # CPU power based on usage
        memory_power_w = 3 * (memory_usage / (1024**3))  # Memory power (3W per GB)

        total_power_w = base_power_w + cpu_power_w + memory_power_w
        energy_wh = total_power_w * (duration / 3600)  # Convert to watt-hours

        return energy_wh

    def _calculate_carbon_footprint(self, energy_wh: float) -> float:
        """Calculate CO2 footprint based on local grid carbon intensity"""
        # Average grid carbon intensity (global average ~475g CO2/kWh)
        grid_carbon_intensity = 475  # g CO2/kWh
        return energy_wh * grid_carbon_intensity / 1000  # Convert Wh to kWh

    def _calculate_efficiency_score(self, operation_type: str, energy_wh: float) -> float:
        """Calculate operation efficiency score"""
        # Define baseline energy consumption for different operations
        baselines = {
            'file_read': 0.001,
            'file_write': 0.002,
            'json_parse': 0.001,
            'agent_switch': 0.005,
            'tdd_cycle': 0.010,
            'hook_execution': 0.003
        }

        baseline = baselines.get(operation_type, 0.005)
        efficiency = min(1.0, baseline / max(energy_wh, 0.0001))

        return efficiency

    def _get_efficiency_recommendation(self, operation_type: str) -> str:
        """Get efficiency improvement recommendations"""
        recommendations = {
            'file_read': 'Consider caching frequently accessed files',
            'file_write': 'Batch multiple write operations when possible',
            'json_parse': 'Cache parsed JSON objects for reuse',
            'agent_switch': 'Optimize handover templates to reduce processing',
            'tdd_cycle': 'Optimize test execution order and parallel testing',
            'hook_execution': 'Review hook complexity and optimize critical paths'
        }

        return recommendations.get(operation_type, 'Review operation implementation for optimization opportunities')

class EnergyTracker:
    """Simplified energy tracking for development environments"""

    def __init__(self):
        self.baseline_measured = False
        self.baseline_power = 0

    def get_current_power_usage(self) -> float:
        """Get current estimated power usage"""
        try:
            # Use psutil to estimate power based on system resources
            cpu_percent = psutil.cpu_percent(interval=0.1)
            memory_info = psutil.virtual_memory()

            # Simplified power estimation
            estimated_power = 20 + (cpu_percent * 0.65) + (memory_info.percent * 0.2)
            return estimated_power
        except Exception:
            return 30.0  # Default estimate

class MetricsClient:
    def __init__(self, output_file: str = None):
        self.output_file = output_file or os.path.join(
            os.path.expanduser("~"), ".claude", "metrics.jsonl"
        )
        self.alerts_file = self.output_file.replace(".jsonl", "-alerts.jsonl")

        # Ensure output directory exists
        os.makedirs(os.path.dirname(self.output_file), exist_ok=True)

        # Initialize metrics buffer for batch writing
        self.metrics_buffer = []
        self.buffer_lock = threading.Lock()

        # Start background flush thread
        self.flush_thread = threading.Thread(target=self._flush_loop, daemon=True)
        self.flush_thread.start()

    def emit_metric(self, metric_name: str, value: Union[int, float], tags: Dict[str, Any] = None):
        """Emit a metric with optional tags"""
        timestamp = datetime.now(timezone.utc).isoformat()

        metric_entry = {
            'timestamp': timestamp,
            'metric': metric_name,
            'value': float(value),
            'tags': tags or {},
            'source': 'claude-friends-templates'
        }

        with self.buffer_lock:
            self.metrics_buffer.append(metric_entry)

    def emit_alert(self, alert_type: str, alert_data: Dict[str, Any]):
        """Emit an alert"""
        timestamp = datetime.now(timezone.utc).isoformat()

        alert_entry = {
            'timestamp': timestamp,
            'alert_type': alert_type,
            'data': alert_data,
            'source': 'claude-friends-templates'
        }

        # Write alerts immediately (they're typically infrequent and important)
        try:
            with open(self.alerts_file, 'a') as f:
                f.write(json.dumps(alert_entry) + '\n')
        except Exception as e:
            print(f"Failed to write alert: {e}", file=sys.stderr)

    def _flush_loop(self):
        """Background thread to flush metrics buffer"""
        while True:
            time.sleep(5)  # Flush every 5 seconds
            self._flush_metrics()

    def _flush_metrics(self):
        """Flush metrics buffer to file"""
        if not self.metrics_buffer:
            return

        with self.buffer_lock:
            metrics_to_write = self.metrics_buffer[:]
            self.metrics_buffer.clear()

        try:
            with open(self.output_file, 'a') as f:
                for metric in metrics_to_write:
                    f.write(json.dumps(metric) + '\n')
        except Exception as e:
            print(f"Failed to write metrics: {e}", file=sys.stderr)
            # Put metrics back in buffer for retry
            with self.buffer_lock:
                self.metrics_buffer.extend(metrics_to_write)

# Global metrics client instance
_metrics_client = None

def get_metrics_client() -> MetricsClient:
    """Get global metrics client instance"""
    global _metrics_client
    if _metrics_client is None:
        _metrics_client = MetricsClient()
    return _metrics_client

# Convenience functions for easy integration
def track_memory_bank_operation(operation_type: str, file_path: str = None):
    """Context manager for tracking Memory Bank operations"""
    return MemoryBankMonitor(get_metrics_client()).track_operation(operation_type, file_path)

def track_hook_execution(hook_name: str, operation: str):
    """Context manager for tracking hook execution"""
    return HookExecutionTracker(get_metrics_client()).track_hook_execution(hook_name, operation)

def track_agent_switch(from_agent: str, to_agent: str):
    """Context manager for tracking agent switches"""
    return AgentSwitchPerformanceTracker(get_metrics_client()).track_agent_switch(from_agent, to_agent)

def track_green_computing(operation_type: str, duration: float, cpu_usage: float, memory_usage: float):
    """Track green computing metrics for an operation"""
    GreenComputingMonitor(get_metrics_client()).track_operation_sustainability(
        operation_type, duration, cpu_usage, memory_usage
    )

if __name__ == "__main__":
    # Example usage
    print("Enhanced Metrics Collection System for claude-friends-templates")
    print("Usage examples:")
    print()
    print("# Track Memory Bank operation:")
    print("with track_memory_bank_operation('read', '/path/to/file.md'):")
    print("    # ... perform memory bank operation")
    print()
    print("# Track hook execution:")
    print("with track_hook_execution('pre-commit', 'code-quality-check'):")
    print("    # ... execute hook")
    print()
    print("# Track agent switch:")
    print("with track_agent_switch('planner', 'builder'):")
    print("    # ... perform agent switch")