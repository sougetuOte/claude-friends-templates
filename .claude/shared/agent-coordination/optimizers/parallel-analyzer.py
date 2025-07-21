#!/usr/bin/env python3
"""
Parallel Task Analyzer

This script analyzes task dependencies and identifies opportunities for parallel execution.
"""

import argparse
import json
import yaml
from pathlib import Path
from typing import Dict, List, Set, Tuple, Optional, Any
from datetime import datetime
import networkx as nx
import matplotlib.pyplot as plt
from dataclasses import dataclass, field


@dataclass
class Task:
    """Represents a task with its properties."""
    id: str
    name: str
    description: str = ""
    estimated_time: int = 60  # minutes
    dependencies: List[str] = field(default_factory=list)
    tags: List[str] = field(default_factory=list)
    assigned_to: Optional[str] = None
    priority: str = "medium"
    
    def __hash__(self):
        return hash(self.id)


class ParallelTaskAnalyzer:
    """Analyzes tasks for parallel execution opportunities."""
    
    def __init__(self):
        self.tasks: Dict[str, Task] = {}
        self.dependency_graph = nx.DiGraph()
        self.execution_plan: List[List[str]] = []
        
    def load_tasks(self, tasks_data: Dict[str, Any]) -> None:
        """Load tasks from data structure."""
        for task_id, task_info in tasks_data.items():
            task = Task(
                id=task_id,
                name=task_info.get('name', task_id),
                description=task_info.get('description', ''),
                estimated_time=task_info.get('estimated_time', 60),
                dependencies=task_info.get('dependencies', []),
                tags=task_info.get('tags', []),
                priority=task_info.get('priority', 'medium')
            )
            self.add_task(task)
    
    def add_task(self, task: Task) -> None:
        """Add a task to the analyzer."""
        self.tasks[task.id] = task
        self.dependency_graph.add_node(task.id, task=task)
        
        # Add edges for dependencies
        for dep_id in task.dependencies:
            if dep_id in self.tasks:
                self.dependency_graph.add_edge(dep_id, task.id)
    
    def analyze(self) -> Dict[str, Any]:
        """Analyze tasks and create execution plan."""
        # Check for cycles
        if not nx.is_directed_acyclic_graph(self.dependency_graph):
            cycles = list(nx.simple_cycles(self.dependency_graph))
            raise ValueError(f"Circular dependencies detected: {cycles}")
        
        # Find parallel execution phases
        self.execution_plan = self._find_parallel_phases()
        
        # Calculate metrics
        metrics = self._calculate_metrics()
        
        # Find optimization opportunities
        opportunities = self._find_opportunities()
        
        return {
            "execution_plan": self._format_execution_plan(),
            "metrics": metrics,
            "opportunities": opportunities,
            "visualization": self._generate_visualization_data()
        }
    
    def _find_parallel_phases(self) -> List[List[str]]:
        """Find tasks that can be executed in parallel."""
        phases = []
        remaining_tasks = set(self.tasks.keys())
        completed_tasks = set()
        
        while remaining_tasks:
            # Find tasks with all dependencies completed
            phase_tasks = []
            for task_id in remaining_tasks:
                task = self.tasks[task_id]
                if all(dep in completed_tasks for dep in task.dependencies):
                    phase_tasks.append(task_id)
            
            if not phase_tasks:
                # No progress possible - shouldn't happen with DAG
                raise ValueError("Cannot create execution plan - check dependencies")
            
            phases.append(phase_tasks)
            completed_tasks.update(phase_tasks)
            remaining_tasks.difference_update(phase_tasks)
        
        return phases
    
    def _calculate_metrics(self) -> Dict[str, Any]:
        """Calculate execution metrics."""
        # Sequential time (if all tasks run one after another)
        sequential_time = sum(task.estimated_time for task in self.tasks.values())
        
        # Parallel time (considering phases)
        parallel_time = 0
        phase_details = []
        
        for phase_num, phase_tasks in enumerate(self.execution_plan):
            phase_times = [self.tasks[task_id].estimated_time for task_id in phase_tasks]
            phase_time = max(phase_times) if phase_times else 0
            parallel_time += phase_time
            
            phase_details.append({
                "phase": phase_num + 1,
                "tasks": len(phase_tasks),
                "duration": phase_time,
                "bottleneck": max(phase_tasks, key=lambda t: self.tasks[t].estimated_time)
                              if phase_tasks else None
            })
        
        # Critical path
        critical_path = self._find_critical_path()
        critical_path_time = sum(self.tasks[task_id].estimated_time 
                               for task_id in critical_path)
        
        return {
            "total_tasks": len(self.tasks),
            "total_phases": len(self.execution_plan),
            "sequential_time": sequential_time,
            "parallel_time": parallel_time,
            "time_saved": sequential_time - parallel_time,
            "speedup_factor": round(sequential_time / parallel_time, 2) if parallel_time > 0 else 1,
            "critical_path": critical_path,
            "critical_path_time": critical_path_time,
            "phase_details": phase_details,
            "parallelization_efficiency": round(
                (sequential_time - parallel_time) / sequential_time * 100, 1
            ) if sequential_time > 0 else 0
        }
    
    def _find_critical_path(self) -> List[str]:
        """Find the critical path through the task graph."""
        if not self.tasks:
            return []
        
        # Add weights to edges based on task duration
        weighted_graph = nx.DiGraph()
        for task_id, task in self.tasks.items():
            weighted_graph.add_node(task_id, weight=task.estimated_time)
            for dep in task.dependencies:
                if dep in self.tasks:
                    weighted_graph.add_edge(dep, task_id)
        
        # Find longest path (critical path)
        try:
            # Find all source nodes (no incoming edges)
            sources = [n for n in weighted_graph.nodes() if weighted_graph.in_degree(n) == 0]
            # Find all sink nodes (no outgoing edges)
            sinks = [n for n in weighted_graph.nodes() if weighted_graph.out_degree(n) == 0]
            
            if not sources or not sinks:
                return []
            
            # Find longest path from any source to any sink
            longest_path = []
            longest_length = 0
            
            for source in sources:
                for sink in sinks:
                    try:
                        paths = nx.all_simple_paths(weighted_graph, source, sink)
                        for path in paths:
                            path_length = sum(self.tasks[node].estimated_time for node in path)
                            if path_length > longest_length:
                                longest_length = path_length
                                longest_path = path
                    except nx.NetworkXNoPath:
                        continue
            
            return longest_path
        except Exception:
            return []
    
    def _find_opportunities(self) -> List[Dict[str, Any]]:
        """Find optimization opportunities."""
        opportunities = []
        
        # Find long-running tasks that could be split
        for task_id, task in self.tasks.items():
            if task.estimated_time > 120:  # More than 2 hours
                opportunities.append({
                    "type": "split_task",
                    "task_id": task_id,
                    "reason": f"Task takes {task.estimated_time} minutes",
                    "suggestion": "Consider breaking into smaller subtasks"
                })
        
        # Find phases with imbalanced workload
        for phase_num, phase_tasks in enumerate(self.execution_plan):
            if len(phase_tasks) > 1:
                times = [self.tasks[tid].estimated_time for tid in phase_tasks]
                if times:
                    max_time = max(times)
                    min_time = min(times)
                    if max_time > min_time * 2:  # Significant imbalance
                        opportunities.append({
                            "type": "balance_phase",
                            "phase": phase_num + 1,
                            "reason": f"Workload imbalance: {max_time}min vs {min_time}min",
                            "suggestion": "Redistribute tasks or split long tasks"
                        })
        
        # Find independent task groups
        components = list(nx.weakly_connected_components(self.dependency_graph))
        if len(components) > 1:
            opportunities.append({
                "type": "independent_groups",
                "groups": len(components),
                "reason": f"Found {len(components)} independent task groups",
                "suggestion": "These groups can be assigned to different teams"
            })
        
        return opportunities
    
    def _format_execution_plan(self) -> List[Dict[str, Any]]:
        """Format execution plan for output."""
        formatted_plan = []
        
        for phase_num, phase_tasks in enumerate(self.execution_plan):
            phase_info = {
                "phase": phase_num + 1,
                "parallel_tasks": []
            }
            
            for task_id in phase_tasks:
                task = self.tasks[task_id]
                phase_info["parallel_tasks"].append({
                    "id": task_id,
                    "name": task.name,
                    "estimated_time": task.estimated_time,
                    "dependencies": task.dependencies,
                    "priority": task.priority
                })
            
            # Sort by priority and time
            priority_order = {"critical": 0, "high": 1, "medium": 2, "low": 3}
            phase_info["parallel_tasks"].sort(
                key=lambda t: (priority_order.get(t["priority"], 2), -t["estimated_time"])
            )
            
            formatted_plan.append(phase_info)
        
        return formatted_plan
    
    def _generate_visualization_data(self) -> Dict[str, Any]:
        """Generate data for visualization."""
        nodes = []
        edges = []
        
        # Create nodes with positions based on phases
        y_positions = {}
        for phase_num, phase_tasks in enumerate(self.execution_plan):
            for i, task_id in enumerate(phase_tasks):
                task = self.tasks[task_id]
                y_positions[task_id] = phase_num
                
                nodes.append({
                    "id": task_id,
                    "label": f"{task.name}\n({task.estimated_time}min)",
                    "x": i * 2,
                    "y": phase_num * 2,
                    "phase": phase_num + 1,
                    "duration": task.estimated_time,
                    "priority": task.priority
                })
        
        # Create edges
        for task_id, task in self.tasks.items():
            for dep_id in task.dependencies:
                if dep_id in self.tasks:
                    edges.append({
                        "source": dep_id,
                        "target": task_id
                    })
        
        return {
            "nodes": nodes,
            "edges": edges
        }
    
    def visualize(self, output_path: Optional[str] = None) -> None:
        """Create a visual representation of the task graph."""
        plt.figure(figsize=(12, 8))
        
        # Create layout based on phases
        pos = {}
        for phase_num, phase_tasks in enumerate(self.execution_plan):
            for i, task_id in enumerate(phase_tasks):
                pos[task_id] = (i * 2, -phase_num * 2)
        
        # Draw the graph
        nx.draw(self.dependency_graph, pos, with_labels=True, 
                node_color='lightblue', node_size=2000,
                font_size=8, font_weight='bold',
                arrows=True, edge_color='gray')
        
        # Add phase labels
        for phase_num in range(len(self.execution_plan)):
            plt.text(-2, -phase_num * 2, f"Phase {phase_num + 1}",
                    fontsize=12, fontweight='bold')
        
        plt.title("Task Dependency Graph and Parallel Execution Phases")
        plt.axis('off')
        
        if output_path:
            plt.savefig(output_path, dpi=300, bbox_inches='tight')
        else:
            plt.show()


def main():
    parser = argparse.ArgumentParser(
        description="Analyze tasks for parallel execution opportunities"
    )
    parser.add_argument(
        "input",
        help="Input tasks file (YAML or JSON)"
    )
    parser.add_argument(
        "-o", "--output",
        help="Output execution plan file"
    )
    parser.add_argument(
        "-v", "--visualize",
        help="Generate visualization (provide output image path)"
    )
    parser.add_argument(
        "--format",
        choices=["yaml", "json"],
        default="yaml",
        help="Output format"
    )
    
    args = parser.parse_args()
    
    # Load tasks
    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Error: Input file {input_path} not found")
        return 1
    
    with open(input_path, 'r') as f:
        if input_path.suffix.lower() in ['.yaml', '.yml']:
            tasks_data = yaml.safe_load(f)
        else:
            tasks_data = json.load(f)
    
    # Analyze
    analyzer = ParallelTaskAnalyzer()
    
    # Handle different input formats
    if isinstance(tasks_data, dict) and 'tasks' in tasks_data:
        analyzer.load_tasks(tasks_data['tasks'])
    else:
        analyzer.load_tasks(tasks_data)
    
    try:
        results = analyzer.analyze()
    except ValueError as e:
        print(f"Error: {e}")
        return 1
    
    # Output results
    if args.output:
        output_path = Path(args.output)
        with open(output_path, 'w') as f:
            if args.format == "yaml":
                yaml.dump(results, f, default_flow_style=False, sort_keys=False)
            else:
                json.dump(results, f, indent=2)
        print(f"Execution plan written to: {output_path}")
    else:
        # Print summary to console
        metrics = results['metrics']
        print("\nParallel Execution Analysis")
        print("=" * 40)
        print(f"Total tasks: {metrics['total_tasks']}")
        print(f"Execution phases: {metrics['total_phases']}")
        print(f"Sequential time: {metrics['sequential_time']} minutes")
        print(f"Parallel time: {metrics['parallel_time']} minutes")
        print(f"Time saved: {metrics['time_saved']} minutes")
        print(f"Speedup factor: {metrics['speedup_factor']}x")
        print(f"Efficiency: {metrics['parallelization_efficiency']}%")
        
        print("\nExecution Plan:")
        for phase in results['execution_plan']:
            print(f"\nPhase {phase['phase']}:")
            for task in phase['parallel_tasks']:
                deps = f" (depends on: {', '.join(task['dependencies'])})" if task['dependencies'] else ""
                print(f"  - {task['name']} [{task['estimated_time']}min]{deps}")
    
    # Generate visualization if requested
    if args.visualize:
        analyzer.visualize(args.visualize)
        print(f"Visualization saved to: {args.visualize}")
    
    return 0


if __name__ == "__main__":
    exit(main())