#!/usr/bin/env python3
"""
TDD Cycle Efficiency Measurement Tools
Implements 2025 best practices for Test-Driven Development monitoring
Integrated with claude-friends-templates TDD framework
"""

import os
import sys
import time
import json
import subprocess
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Any, Optional, Tuple
from contextlib import contextmanager
import uuid
from dataclasses import dataclass, asdict
from collections import defaultdict, deque

@dataclass
class TDDPhaseMetrics:
    """Metrics for a single TDD phase (Red/Green/Refactor)"""
    phase_name: str
    start_time: float
    end_time: float
    duration: float
    file_changes: List[str]
    lines_added: int
    lines_removed: int
    test_count_delta: int
    coverage_delta: float
    complexity_delta: float
    success: bool
    error_message: Optional[str] = None

@dataclass
class TDDCycleMetrics:
    """Complete TDD cycle metrics"""
    cycle_id: str
    start_time: float
    end_time: float
    total_duration: float
    red_phase: TDDPhaseMetrics
    green_phase: TDDPhaseMetrics
    refactor_phase: TDDPhaseMetrics
    efficiency_score: float
    quality_improvement: float
    test_coverage_final: float
    cyclomatic_complexity_final: float
    files_affected: List[str]
    git_commits: List[str]
    success: bool

class CodeAnalyzer:
    """Analyzes code quality, complexity, and test coverage"""

    def __init__(self):
        self.supported_languages = {
            '.py': self._analyze_python,
            '.js': self._analyze_javascript,
            '.ts': self._analyze_typescript,
            '.jsx': self._analyze_javascript,
            '.tsx': self._analyze_typescript
        }

    def analyze_file(self, file_path: str) -> Dict[str, Any]:
        """Analyze a single file for quality metrics"""
        if not os.path.exists(file_path):
            return {'error': 'File not found'}

        file_ext = Path(file_path).suffix.lower()
        analyzer = self.supported_languages.get(file_ext, self._analyze_generic)

        return analyzer(file_path)

    def _analyze_python(self, file_path: str) -> Dict[str, Any]:
        """Analyze Python file using various tools"""
        metrics = {}

        # Cyclomatic complexity using radon
        try:
            result = subprocess.run(
                ['radon', 'cc', file_path, '-j'],
                capture_output=True, text=True, timeout=30
            )
            if result.returncode == 0:
                cc_data = json.loads(result.stdout)
                if file_path in cc_data:
                    complexities = [item['complexity'] for item in cc_data[file_path]]
                    metrics['cyclomatic_complexity'] = sum(complexities) / len(complexities) if complexities else 0
                    metrics['max_complexity'] = max(complexities) if complexities else 0
        except (subprocess.TimeoutExpired, json.JSONDecodeError, FileNotFoundError):
            metrics['cyclomatic_complexity'] = 0

        # Maintainability index using radon
        try:
            result = subprocess.run(
                ['radon', 'mi', file_path],
                capture_output=True, text=True, timeout=30
            )
            if result.returncode == 0:
                # Parse maintainability index from output
                mi_match = re.search(r'(\d+\.\d+)', result.stdout)
                if mi_match:
                    metrics['maintainability_index'] = float(mi_match.group(1))
        except (subprocess.TimeoutExpired, FileNotFoundError):
            metrics['maintainability_index'] = 0

        # Line count and basic metrics
        metrics.update(self._get_basic_metrics(file_path))

        # Test-related metrics for test files
        if self._is_test_file(file_path):
            metrics.update(self._analyze_test_file(file_path))

        return metrics

    def _analyze_javascript(self, file_path: str) -> Dict[str, Any]:
        """Analyze JavaScript/JSX file"""
        metrics = self._get_basic_metrics(file_path)

        # Try to use ESLint for complexity analysis
        try:
            result = subprocess.run(
                ['npx', 'eslint', file_path, '--format', 'json'],
                capture_output=True, text=True, timeout=30
            )
            if result.stdout:
                eslint_data = json.loads(result.stdout)
                if eslint_data and len(eslint_data) > 0:
                    messages = eslint_data[0].get('messages', [])
                    complexity_issues = [m for m in messages if 'complexity' in m.get('ruleId', '')]
                    metrics['complexity_issues'] = len(complexity_issues)
        except (subprocess.TimeoutExpired, json.JSONDecodeError, FileNotFoundError):
            metrics['complexity_issues'] = 0

        if self._is_test_file(file_path):
            metrics.update(self._analyze_test_file(file_path))

        return metrics

    def _analyze_typescript(self, file_path: str) -> Dict[str, Any]:
        """Analyze TypeScript/TSX file"""
        # Similar to JavaScript but with TypeScript-specific analysis
        metrics = self._analyze_javascript(file_path)

        # TypeScript compiler check
        try:
            result = subprocess.run(
                ['npx', 'tsc', '--noEmit', file_path],
                capture_output=True, text=True, timeout=30
            )
            metrics['type_errors'] = len(result.stderr.splitlines()) if result.stderr else 0
        except (subprocess.TimeoutExpired, FileNotFoundError):
            metrics['type_errors'] = 0

        return metrics

    def _analyze_generic(self, file_path: str) -> Dict[str, Any]:
        """Generic analysis for unsupported file types"""
        return self._get_basic_metrics(file_path)

    def _get_basic_metrics(self, file_path: str) -> Dict[str, Any]:
        """Get basic metrics for any text file"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            lines = content.splitlines()
            non_empty_lines = [line for line in lines if line.strip()]
            comment_lines = [line for line in lines if line.strip().startswith(('#', '//', '/*', '*'))]

            return {
                'total_lines': len(lines),
                'code_lines': len(non_empty_lines),
                'comment_lines': len(comment_lines),
                'blank_lines': len(lines) - len(non_empty_lines),
                'file_size_bytes': len(content.encode('utf-8')),
                'comment_ratio': len(comment_lines) / max(len(non_empty_lines), 1)
            }
        except Exception as e:
            return {'error': str(e)}

    def _is_test_file(self, file_path: str) -> bool:
        """Determine if a file is a test file"""
        file_name = Path(file_path).name.lower()
        return any(pattern in file_name for pattern in ['test', 'spec', '_test', '.test'])

    def _analyze_test_file(self, file_path: str) -> Dict[str, Any]:
        """Analyze test-specific metrics"""
        test_metrics = {}

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # Count test cases (heuristic approach)
            test_patterns = [
                r'def test_\w+',  # Python pytest
                r'it\s*\(',       # JavaScript/TypeScript jest/mocha
                r'test\s*\(',     # JavaScript/TypeScript jest
                r'describe\s*\(', # JavaScript/TypeScript describe blocks
                r'@Test',         # Java JUnit
                r'func Test\w+',  # Go tests
            ]

            test_count = 0
            for pattern in test_patterns:
                test_count += len(re.findall(pattern, content, re.IGNORECASE))

            test_metrics['test_cases_count'] = test_count

            # Analyze assertion patterns
            assertion_patterns = [
                r'assert\w*\s*\(',  # Python assertions
                r'expect\s*\(',     # Jest/Chai expectations
                r'\.to\.',          # Chai assertions
                r'\.should\.',      # Should.js assertions
            ]

            assertion_count = 0
            for pattern in assertion_patterns:
                assertion_count += len(re.findall(pattern, content, re.IGNORECASE))

            test_metrics['assertions_count'] = assertion_count
            test_metrics['assertions_per_test'] = assertion_count / max(test_count, 1)

            # Mock usage analysis
            mock_patterns = [
                r'mock\w*\s*\(',    # Mock functions
                r'spy\w*\s*\(',     # Spy functions
                r'stub\w*\s*\(',    # Stub functions
                r'@mock',           # Mock decorators
            ]

            mock_count = 0
            for pattern in mock_patterns:
                mock_count += len(re.findall(pattern, content, re.IGNORECASE))

            test_metrics['mocks_count'] = mock_count

        except Exception as e:
            test_metrics['error'] = str(e)

        return test_metrics

class TestCoverageAnalyzer:
    """Analyzes test coverage using various tools"""

    def __init__(self):
        self.coverage_tools = {
            'python': self._get_python_coverage,
            'javascript': self._get_javascript_coverage,
            'typescript': self._get_javascript_coverage  # Same tools as JS
        }

    def get_coverage(self, project_root: str, language: str = 'auto') -> Dict[str, Any]:
        """Get test coverage for the project"""
        if language == 'auto':
            language = self._detect_language(project_root)

        coverage_func = self.coverage_tools.get(language, self._get_generic_coverage)
        return coverage_func(project_root)

    def _detect_language(self, project_root: str) -> str:
        """Auto-detect project language"""
        root_path = Path(project_root)

        if (root_path / 'package.json').exists():
            return 'javascript'
        elif (root_path / 'requirements.txt').exists() or (root_path / 'pyproject.toml').exists():
            return 'python'
        else:
            return 'generic'

    def _get_python_coverage(self, project_root: str) -> Dict[str, Any]:
        """Get Python test coverage using coverage.py"""
        try:
            # Run coverage
            result = subprocess.run(
                ['python', '-m', 'coverage', 'run', '-m', 'pytest'],
                cwd=project_root, capture_output=True, text=True, timeout=120
            )

            if result.returncode != 0:
                return {'error': 'Test execution failed', 'stderr': result.stderr}

            # Get coverage report
            result = subprocess.run(
                ['python', '-m', 'coverage', 'report', '--format=json'],
                cwd=project_root, capture_output=True, text=True, timeout=30
            )

            if result.returncode == 0:
                coverage_data = json.loads(result.stdout)
                return {
                    'total_coverage': coverage_data.get('totals', {}).get('percent_covered', 0),
                    'files_coverage': coverage_data.get('files', {}),
                    'missing_lines': coverage_data.get('totals', {}).get('missing_lines', 0),
                    'covered_lines': coverage_data.get('totals', {}).get('covered_lines', 0)
                }

        except (subprocess.TimeoutExpired, json.JSONDecodeError, FileNotFoundError) as e:
            return {'error': str(e)}

        return {'error': 'Coverage analysis failed'}

    def _get_javascript_coverage(self, project_root: str) -> Dict[str, Any]:
        """Get JavaScript/TypeScript coverage using Jest or NYC"""
        try:
            # Try Jest with coverage
            result = subprocess.run(
                ['npm', 'test', '--', '--coverage', '--coverageReporters=json'],
                cwd=project_root, capture_output=True, text=True, timeout=120
            )

            if result.returncode == 0:
                # Look for coverage report
                coverage_file = Path(project_root) / 'coverage' / 'coverage-final.json'
                if coverage_file.exists():
                    with open(coverage_file, 'r') as f:
                        coverage_data = json.load(f)

                    total_lines = sum(len(file_data['l']) for file_data in coverage_data.values() if 'l' in file_data)
                    covered_lines = sum(sum(1 for hits in file_data['l'].values() if hits > 0)
                                      for file_data in coverage_data.values() if 'l' in file_data)

                    coverage_percent = (covered_lines / max(total_lines, 1)) * 100

                    return {
                        'total_coverage': coverage_percent,
                        'files_coverage': coverage_data,
                        'covered_lines': covered_lines,
                        'total_lines': total_lines
                    }

        except (subprocess.TimeoutExpired, json.JSONDecodeError, FileNotFoundError) as e:
            return {'error': str(e)}

        return {'error': 'Coverage analysis failed'}

    def _get_generic_coverage(self, project_root: str) -> Dict[str, Any]:
        """Generic coverage estimation for unsupported languages"""
        return {'total_coverage': 0, 'error': 'Coverage analysis not supported for this language'}

class TDDCycleAnalyzer:
    """Main TDD cycle analysis and tracking system"""

    def __init__(self, project_root: str = None):
        self.project_root = project_root or os.getcwd()
        self.code_analyzer = CodeAnalyzer()
        self.coverage_analyzer = TestCoverageAnalyzer()
        self.metrics_dir = Path(self.project_root) / '.claude' / 'metrics'
        self.metrics_dir.mkdir(parents=True, exist_ok=True)
        self.cycle_history = deque(maxlen=100)  # Keep last 100 cycles

    @contextmanager
    def track_tdd_cycle(self, test_files: List[str], implementation_files: List[str]):
        """Track a complete TDD cycle (Red-Green-Refactor)"""
        cycle_id = str(uuid.uuid4())
        cycle_start_time = time.time()

        # Get initial state
        initial_state = self._capture_project_state(test_files + implementation_files)

        try:
            cycle_tracker = TDDCycleTracker(
                cycle_id, cycle_start_time, initial_state,
                test_files, implementation_files, self
            )
            yield cycle_tracker

            # Calculate final metrics
            cycle_end_time = time.time()
            final_state = self._capture_project_state(test_files + implementation_files)

            cycle_metrics = self._calculate_cycle_metrics(
                cycle_tracker, initial_state, final_state, cycle_end_time
            )

            # Store metrics
            self._store_cycle_metrics(cycle_metrics)
            self.cycle_history.append(cycle_metrics)

            # Analyze for patterns and improvements
            self._analyze_cycle_patterns()

        except Exception as e:
            # Log failed cycle
            failed_cycle = {
                'cycle_id': cycle_id,
                'timestamp': datetime.now(timezone.utc).isoformat(),
                'error': str(e),
                'duration': time.time() - cycle_start_time,
                'files': test_files + implementation_files
            }
            self._store_failed_cycle(failed_cycle)
            raise

    def _capture_project_state(self, files: List[str]) -> Dict[str, Any]:
        """Capture current state of project files"""
        state = {
            'timestamp': time.time(),
            'files': {},
            'git_commit': self._get_git_commit(),
            'overall_coverage': self._get_project_coverage()
        }

        for file_path in files:
            if os.path.exists(file_path):
                state['files'][file_path] = self.code_analyzer.analyze_file(file_path)

        return state

    def _get_git_commit(self) -> str:
        """Get current git commit hash"""
        try:
            result = subprocess.run(
                ['git', 'rev-parse', '--short', 'HEAD'],
                cwd=self.project_root, capture_output=True, text=True, timeout=10
            )
            return result.stdout.strip() if result.returncode == 0 else 'unknown'
        except:
            return 'unknown'

    def _get_project_coverage(self) -> float:
        """Get overall project test coverage"""
        coverage_data = self.coverage_analyzer.get_coverage(self.project_root)
        return coverage_data.get('total_coverage', 0)

    def _calculate_cycle_metrics(self, tracker: 'TDDCycleTracker', initial_state: Dict,
                               final_state: Dict, end_time: float) -> TDDCycleMetrics:
        """Calculate comprehensive cycle metrics"""

        # Calculate coverage improvement
        coverage_delta = final_state['overall_coverage'] - initial_state['overall_coverage']

        # Calculate complexity changes
        complexity_delta = self._calculate_complexity_delta(initial_state, final_state)

        # Calculate efficiency score
        efficiency_score = self._calculate_efficiency_score(tracker, coverage_delta, complexity_delta)

        # Get all affected files
        all_files = set()
        for phase in [tracker.red_phase, tracker.green_phase, tracker.refactor_phase]:
            if phase:
                all_files.update(phase.file_changes)

        return TDDCycleMetrics(
            cycle_id=tracker.cycle_id,
            start_time=tracker.start_time,
            end_time=end_time,
            total_duration=end_time - tracker.start_time,
            red_phase=tracker.red_phase,
            green_phase=tracker.green_phase,
            refactor_phase=tracker.refactor_phase,
            efficiency_score=efficiency_score,
            quality_improvement=self._calculate_quality_improvement(initial_state, final_state),
            test_coverage_final=final_state['overall_coverage'],
            cyclomatic_complexity_final=self._get_average_complexity(final_state),
            files_affected=list(all_files),
            git_commits=tracker.git_commits,
            success=all([tracker.red_phase.success, tracker.green_phase.success,
                       tracker.refactor_phase.success])
        )

    def _calculate_complexity_delta(self, initial_state: Dict, final_state: Dict) -> float:
        """Calculate change in cyclomatic complexity"""
        initial_complexity = self._get_average_complexity(initial_state)
        final_complexity = self._get_average_complexity(final_state)
        return final_complexity - initial_complexity

    def _get_average_complexity(self, state: Dict) -> float:
        """Get average cyclomatic complexity from state"""
        complexities = []
        for file_metrics in state['files'].values():
            if 'cyclomatic_complexity' in file_metrics:
                complexities.append(file_metrics['cyclomatic_complexity'])

        return sum(complexities) / len(complexities) if complexities else 0

    def _calculate_efficiency_score(self, tracker: 'TDDCycleTracker',
                                  coverage_delta: float, complexity_delta: float) -> float:
        """Calculate TDD cycle efficiency score (0-1)"""
        total_duration = tracker.get_total_duration()

        # Time efficiency (10 minutes baseline)
        time_efficiency = min(1.0, 600 / max(total_duration, 60))

        # Coverage improvement (15% improvement = 1.0)
        coverage_efficiency = min(1.0, max(0, coverage_delta) / 15.0)

        # Complexity improvement (lower is better)
        complexity_efficiency = min(1.0, max(0, -complexity_delta) / 2.0)

        # Phase balance (ideal: red=20%, green=50%, refactor=30%)
        phase_balance = self._calculate_phase_balance_score(tracker)

        # Weighted combination
        efficiency = (
            time_efficiency * 0.3 +
            coverage_efficiency * 0.3 +
            complexity_efficiency * 0.2 +
            phase_balance * 0.2
        )

        return min(1.0, max(0.0, efficiency))

    def _calculate_phase_balance_score(self, tracker: 'TDDCycleTracker') -> float:
        """Calculate how well balanced the TDD phases are"""
        total_duration = tracker.get_total_duration()
        if total_duration == 0:
            return 0

        red_ratio = tracker.red_phase.duration / total_duration
        green_ratio = tracker.green_phase.duration / total_duration
        refactor_ratio = tracker.refactor_phase.duration / total_duration

        # Ideal ratios
        ideal_red = 0.2
        ideal_green = 0.5
        ideal_refactor = 0.3

        # Calculate deviation from ideal
        red_deviation = abs(red_ratio - ideal_red)
        green_deviation = abs(green_ratio - ideal_green)
        refactor_deviation = abs(refactor_ratio - ideal_refactor)

        # Score based on how close to ideal (lower deviation = higher score)
        balance_score = 1.0 - (red_deviation + green_deviation + refactor_deviation) / 3.0

        return max(0.0, balance_score)

    def _calculate_quality_improvement(self, initial_state: Dict, final_state: Dict) -> float:
        """Calculate overall code quality improvement"""
        initial_quality = self._get_quality_score(initial_state)
        final_quality = self._get_quality_score(final_state)
        return final_quality - initial_quality

    def _get_quality_score(self, state: Dict) -> float:
        """Calculate quality score from state metrics"""
        quality_metrics = []

        for file_metrics in state['files'].values():
            file_quality = 0

            # Comment ratio (good: 0.1-0.3)
            comment_ratio = file_metrics.get('comment_ratio', 0)
            comment_score = 1.0 if 0.1 <= comment_ratio <= 0.3 else max(0, 1.0 - abs(comment_ratio - 0.2) * 5)
            file_quality += comment_score * 0.2

            # Complexity (lower is better, ideal < 5)
            complexity = file_metrics.get('cyclomatic_complexity', 0)
            complexity_score = max(0, 1.0 - complexity / 10.0)
            file_quality += complexity_score * 0.3

            # Maintainability index (higher is better, ideal > 70)
            maintainability = file_metrics.get('maintainability_index', 50)
            maintainability_score = min(1.0, maintainability / 100.0)
            file_quality += maintainability_score * 0.3

            # Test metrics for test files
            if file_metrics.get('test_cases_count', 0) > 0:
                assertions_per_test = file_metrics.get('assertions_per_test', 0)
                test_score = min(1.0, assertions_per_test / 3.0)  # Ideal: 3 assertions per test
                file_quality += test_score * 0.2
            else:
                file_quality += 0.2  # No penalty for non-test files

            quality_metrics.append(file_quality)

        return sum(quality_metrics) / len(quality_metrics) if quality_metrics else 0

    def _store_cycle_metrics(self, metrics: TDDCycleMetrics):
        """Store cycle metrics to file"""
        metrics_file = self.metrics_dir / f"tdd-cycle-{metrics.cycle_id}.json"

        with open(metrics_file, 'w') as f:
            json.dump(asdict(metrics), f, indent=2, default=str)

        # Also append to summary log
        summary_file = self.metrics_dir / "tdd-cycles-summary.jsonl"
        summary_entry = {
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'cycle_id': metrics.cycle_id,
            'duration': metrics.total_duration,
            'efficiency_score': metrics.efficiency_score,
            'coverage_final': metrics.test_coverage_final,
            'success': metrics.success
        }

        with open(summary_file, 'a') as f:
            f.write(json.dumps(summary_entry) + '\n')

    def _store_failed_cycle(self, failed_cycle: Dict):
        """Store failed cycle information"""
        failures_file = self.metrics_dir / "tdd-cycle-failures.jsonl"
        with open(failures_file, 'a') as f:
            f.write(json.dumps(failed_cycle) + '\n')

    def _analyze_cycle_patterns(self):
        """Analyze patterns in recent TDD cycles"""
        if len(self.cycle_history) < 5:
            return

        recent_cycles = list(self.cycle_history)[-10:]  # Last 10 cycles

        # Analyze efficiency trends
        efficiency_scores = [cycle.efficiency_score for cycle in recent_cycles]
        avg_efficiency = sum(efficiency_scores) / len(efficiency_scores)

        # Check for declining efficiency
        if len(efficiency_scores) >= 5:
            recent_avg = sum(efficiency_scores[-5:]) / 5
            older_avg = sum(efficiency_scores[-10:-5]) / 5

            if recent_avg < older_avg * 0.8:  # 20% decline
                self._emit_efficiency_alert(recent_avg, older_avg, recent_cycles[-5:])

        # Analyze phase imbalances
        self._analyze_phase_patterns(recent_cycles)

    def _emit_efficiency_alert(self, recent_avg: float, older_avg: float, recent_cycles: List[TDDCycleMetrics]):
        """Emit alert for declining TDD efficiency"""
        alert = {
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'alert_type': 'tdd_efficiency_decline',
            'severity': 'warning',
            'recent_efficiency': recent_avg,
            'baseline_efficiency': older_avg,
            'decline_percent': ((older_avg - recent_avg) / older_avg) * 100,
            'recent_cycles': [cycle.cycle_id for cycle in recent_cycles],
            'recommendations': self._generate_efficiency_recommendations(recent_cycles)
        }

        alerts_file = self.metrics_dir / "tdd-alerts.jsonl"
        with open(alerts_file, 'a') as f:
            f.write(json.dumps(alert) + '\n')

    def _analyze_phase_patterns(self, cycles: List[TDDCycleMetrics]):
        """Analyze TDD phase patterns for improvement opportunities"""
        phase_ratios = []

        for cycle in cycles:
            total_duration = cycle.total_duration
            if total_duration > 0:
                ratios = {
                    'red': cycle.red_phase.duration / total_duration,
                    'green': cycle.green_phase.duration / total_duration,
                    'refactor': cycle.refactor_phase.duration / total_duration
                }
                phase_ratios.append(ratios)

        if not phase_ratios:
            return

        # Calculate average ratios
        avg_ratios = {
            'red': sum(r['red'] for r in phase_ratios) / len(phase_ratios),
            'green': sum(r['green'] for r in phase_ratios) / len(phase_ratios),
            'refactor': sum(r['refactor'] for r in phase_ratios) / len(phase_ratios)
        }

        # Check for significant deviations from ideal
        ideal_ratios = {'red': 0.2, 'green': 0.5, 'refactor': 0.3}
        significant_deviations = {}

        for phase, avg_ratio in avg_ratios.items():
            deviation = abs(avg_ratio - ideal_ratios[phase])
            if deviation > 0.15:  # 15% deviation
                significant_deviations[phase] = {
                    'actual': avg_ratio,
                    'ideal': ideal_ratios[phase],
                    'deviation': deviation
                }

        if significant_deviations:
            self._emit_phase_balance_alert(significant_deviations, cycles)

    def _emit_phase_balance_alert(self, deviations: Dict, cycles: List[TDDCycleMetrics]):
        """Emit alert for TDD phase imbalances"""
        alert = {
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'alert_type': 'tdd_phase_imbalance',
            'severity': 'info',
            'deviations': deviations,
            'cycles_analyzed': len(cycles),
            'recommendations': self._generate_phase_recommendations(deviations)
        }

        alerts_file = self.metrics_dir / "tdd-alerts.jsonl"
        with open(alerts_file, 'a') as f:
            f.write(json.dumps(alert) + '\n')

    def _generate_efficiency_recommendations(self, cycles: List[TDDCycleMetrics]) -> List[str]:
        """Generate recommendations for improving TDD efficiency"""
        recommendations = []

        # Analyze common issues
        long_cycles = [c for c in cycles if c.total_duration > 1200]  # > 20 minutes
        low_coverage = [c for c in cycles if c.test_coverage_final < 80]
        failed_cycles = [c for c in cycles if not c.success]

        if long_cycles:
            recommendations.append("Consider breaking down complex features into smaller TDD cycles")

        if low_coverage:
            recommendations.append("Focus on improving test coverage in each cycle")

        if failed_cycles:
            recommendations.append("Review and strengthen error handling in TDD process")

        if not recommendations:
            recommendations.append("Continue current TDD practices - efficiency is stable")

        return recommendations

    def _generate_phase_recommendations(self, deviations: Dict) -> List[str]:
        """Generate recommendations for improving TDD phase balance"""
        recommendations = []

        for phase, deviation_info in deviations.items():
            actual = deviation_info['actual']
            ideal = deviation_info['ideal']

            if actual > ideal:
                if phase == 'red':
                    recommendations.append("Red phase taking too long - consider simpler test cases or better test planning")
                elif phase == 'green':
                    recommendations.append("Green phase taking too long - consider simpler implementation approaches")
                elif phase == 'refactor':
                    recommendations.append("Refactor phase taking too long - consider more frequent smaller refactorings")
            else:
                if phase == 'red':
                    recommendations.append("Red phase too short - ensure comprehensive test scenarios")
                elif phase == 'green':
                    recommendations.append("Green phase too short - ensure robust implementation")
                elif phase == 'refactor':
                    recommendations.append("Refactor phase too short - allocate more time for code quality improvements")

        return recommendations

    def generate_tdd_report(self, days: int = 7) -> Dict[str, Any]:
        """Generate comprehensive TDD performance report"""
        cutoff_time = time.time() - (days * 24 * 3600)
        recent_cycles = [cycle for cycle in self.cycle_history if cycle.start_time > cutoff_time]

        if not recent_cycles:
            return {'error': f'No TDD cycles found in the last {days} days'}

        # Calculate summary statistics
        total_cycles = len(recent_cycles)
        successful_cycles = len([c for c in recent_cycles if c.success])
        success_rate = successful_cycles / total_cycles if total_cycles > 0 else 0

        avg_duration = sum(c.total_duration for c in recent_cycles) / total_cycles
        avg_efficiency = sum(c.efficiency_score for c in recent_cycles) / total_cycles
        avg_coverage = sum(c.test_coverage_final for c in recent_cycles) / total_cycles

        # Phase analysis
        avg_phase_durations = {
            'red': sum(c.red_phase.duration for c in recent_cycles) / total_cycles,
            'green': sum(c.green_phase.duration for c in recent_cycles) / total_cycles,
            'refactor': sum(c.refactor_phase.duration for c in recent_cycles) / total_cycles
        }

        # Efficiency trends
        efficiency_trend = self._calculate_efficiency_trend(recent_cycles)

        return {
            'report_period_days': days,
            'generated_at': datetime.now(timezone.utc).isoformat(),
            'summary': {
                'total_cycles': total_cycles,
                'successful_cycles': successful_cycles,
                'success_rate': success_rate,
                'avg_duration_minutes': avg_duration / 60,
                'avg_efficiency_score': avg_efficiency,
                'avg_test_coverage': avg_coverage
            },
            'phase_analysis': {
                'avg_durations_minutes': {k: v/60 for k, v in avg_phase_durations.items()},
                'phase_ratios': {
                    k: v/avg_duration for k, v in avg_phase_durations.items()
                }
            },
            'trends': {
                'efficiency_trend': efficiency_trend,
                'coverage_trend': self._calculate_coverage_trend(recent_cycles)
            },
            'recommendations': self._generate_overall_recommendations(recent_cycles)
        }

    def _calculate_efficiency_trend(self, cycles: List[TDDCycleMetrics]) -> str:
        """Calculate efficiency trend direction"""
        if len(cycles) < 4:
            return 'insufficient_data'

        mid_point = len(cycles) // 2
        first_half_avg = sum(c.efficiency_score for c in cycles[:mid_point]) / mid_point
        second_half_avg = sum(c.efficiency_score for c in cycles[mid_point:]) / (len(cycles) - mid_point)

        if second_half_avg > first_half_avg * 1.05:
            return 'improving'
        elif second_half_avg < first_half_avg * 0.95:
            return 'declining'
        else:
            return 'stable'

    def _calculate_coverage_trend(self, cycles: List[TDDCycleMetrics]) -> str:
        """Calculate coverage trend direction"""
        if len(cycles) < 4:
            return 'insufficient_data'

        mid_point = len(cycles) // 2
        first_half_avg = sum(c.test_coverage_final for c in cycles[:mid_point]) / mid_point
        second_half_avg = sum(c.test_coverage_final for c in cycles[mid_point:]) / (len(cycles) - mid_point)

        if second_half_avg > first_half_avg + 2:  # 2% improvement
            return 'improving'
        elif second_half_avg < first_half_avg - 2:  # 2% decline
            return 'declining'
        else:
            return 'stable'

    def _generate_overall_recommendations(self, cycles: List[TDDCycleMetrics]) -> List[str]:
        """Generate overall recommendations based on cycle analysis"""
        recommendations = []

        if not cycles:
            return ['Start practicing TDD to generate insights']

        avg_efficiency = sum(c.efficiency_score for c in cycles) / len(cycles)
        avg_coverage = sum(c.test_coverage_final for c in cycles) / len(cycles)
        success_rate = len([c for c in cycles if c.success]) / len(cycles)

        if avg_efficiency < 0.6:
            recommendations.append("Focus on improving TDD cycle efficiency through better planning and simpler iterations")

        if avg_coverage < 80:
            recommendations.append("Aim for higher test coverage (target: 80%+) in each TDD cycle")

        if success_rate < 0.8:
            recommendations.append("Review TDD process to reduce cycle failures")

        # Check for long cycles
        long_cycles = [c for c in cycles if c.total_duration > 1800]  # > 30 minutes
        if len(long_cycles) > len(cycles) * 0.3:
            recommendations.append("Break down features into smaller, more focused TDD cycles")

        if not recommendations:
            recommendations.append("Excellent TDD practices! Continue maintaining high standards")

        return recommendations

class TDDCycleTracker:
    """Tracks a single TDD cycle in progress"""

    def __init__(self, cycle_id: str, start_time: float, initial_state: Dict,
                 test_files: List[str], implementation_files: List[str], analyzer: TDDCycleAnalyzer):
        self.cycle_id = cycle_id
        self.start_time = start_time
        self.initial_state = initial_state
        self.test_files = test_files
        self.implementation_files = implementation_files
        self.analyzer = analyzer

        self.red_phase: Optional[TDDPhaseMetrics] = None
        self.green_phase: Optional[TDDPhaseMetrics] = None
        self.refactor_phase: Optional[TDDPhaseMetrics] = None
        self.git_commits: List[str] = []

    @contextmanager
    def track_red_phase(self):
        """Track the Red phase (writing failing tests)"""
        with self._track_phase('red') as phase_tracker:
            yield phase_tracker
            self.red_phase = phase_tracker.get_metrics()

    @contextmanager
    def track_green_phase(self):
        """Track the Green phase (making tests pass)"""
        with self._track_phase('green') as phase_tracker:
            yield phase_tracker
            self.green_phase = phase_tracker.get_metrics()

    @contextmanager
    def track_refactor_phase(self):
        """Track the Refactor phase (improving code quality)"""
        with self._track_phase('refactor') as phase_tracker:
            yield phase_tracker
            self.refactor_phase = phase_tracker.get_metrics()

    @contextmanager
    def _track_phase(self, phase_name: str):
        """Generic phase tracking"""
        phase_tracker = TDDPhaseTracker(phase_name, self.test_files + self.implementation_files, self.analyzer)
        yield phase_tracker

    def add_git_commit(self, commit_hash: str):
        """Add a git commit associated with this cycle"""
        self.git_commits.append(commit_hash)

    def get_total_duration(self) -> float:
        """Get total duration of all completed phases"""
        total = 0
        for phase in [self.red_phase, self.green_phase, self.refactor_phase]:
            if phase:
                total += phase.duration
        return total

class TDDPhaseTracker:
    """Tracks a single TDD phase (Red, Green, or Refactor)"""

    def __init__(self, phase_name: str, files: List[str], analyzer: TDDCycleAnalyzer):
        self.phase_name = phase_name
        self.files = files
        self.analyzer = analyzer
        self.start_time = time.time()
        self.initial_file_states = {}
        self.success = True
        self.error_message = None

        # Capture initial state
        for file_path in files:
            if os.path.exists(file_path):
                self.initial_file_states[file_path] = self.analyzer.code_analyzer.analyze_file(file_path)

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type is not None:
            self.success = False
            self.error_message = str(exc_val)

    def get_metrics(self) -> TDDPhaseMetrics:
        """Get metrics for this phase"""
        end_time = time.time()
        duration = end_time - self.start_time

        # Calculate file changes
        file_changes = []
        lines_added = 0
        lines_removed = 0
        test_count_delta = 0
        coverage_delta = 0
        complexity_delta = 0

        for file_path in self.files:
            if os.path.exists(file_path):
                current_state = self.analyzer.code_analyzer.analyze_file(file_path)
                initial_state = self.initial_file_states.get(file_path, {})

                # Check if file changed
                if current_state != initial_state:
                    file_changes.append(file_path)

                    # Calculate line changes (simplified)
                    current_lines = current_state.get('total_lines', 0)
                    initial_lines = initial_state.get('total_lines', 0)
                    line_delta = current_lines - initial_lines

                    if line_delta > 0:
                        lines_added += line_delta
                    else:
                        lines_removed += abs(line_delta)

                    # Test count changes
                    current_tests = current_state.get('test_cases_count', 0)
                    initial_tests = initial_state.get('test_cases_count', 0)
                    test_count_delta += current_tests - initial_tests

                    # Complexity changes
                    current_complexity = current_state.get('cyclomatic_complexity', 0)
                    initial_complexity = initial_state.get('cyclomatic_complexity', 0)
                    complexity_delta += current_complexity - initial_complexity

        return TDDPhaseMetrics(
            phase_name=self.phase_name,
            start_time=self.start_time,
            end_time=end_time,
            duration=duration,
            file_changes=file_changes,
            lines_added=lines_added,
            lines_removed=lines_removed,
            test_count_delta=test_count_delta,
            coverage_delta=coverage_delta,
            complexity_delta=complexity_delta,
            success=self.success,
            error_message=self.error_message
        )

# Convenience functions for easy integration
def create_tdd_analyzer(project_root: str = None) -> TDDCycleAnalyzer:
    """Create a TDD cycle analyzer instance"""
    return TDDCycleAnalyzer(project_root)

def track_tdd_cycle(test_files: List[str], implementation_files: List[str], project_root: str = None):
    """Context manager for tracking a complete TDD cycle"""
    analyzer = TDDCycleAnalyzer(project_root)
    return analyzer.track_tdd_cycle(test_files, implementation_files)

if __name__ == "__main__":
    # Example usage and CLI interface
    import argparse

    parser = argparse.ArgumentParser(description="TDD Cycle Efficiency Analyzer")
    parser.add_argument('command', choices=['analyze', 'report', 'demo'],
                       help='Command to execute')
    parser.add_argument('--project-root', default='.', help='Project root directory')
    parser.add_argument('--days', type=int, default=7, help='Number of days for report')

    args = parser.parse_args()

    analyzer = TDDCycleAnalyzer(args.project_root)

    if args.command == 'analyze':
        print("TDD Cycle Analyzer - Ready for cycle tracking")
        print("Use the Python API to track TDD cycles in your development workflow")

    elif args.command == 'report':
        report = analyzer.generate_tdd_report(args.days)
        print(json.dumps(report, indent=2, default=str))

    elif args.command == 'demo':
        print("Demo TDD Cycle Analysis")
        print("======================")

        # Simulate a TDD cycle for demonstration
        test_files = ['test_example.py']
        impl_files = ['example.py']

        print("Starting TDD cycle tracking...")
        with analyzer.track_tdd_cycle(test_files, impl_files) as cycle:
            print(f"Cycle ID: {cycle.cycle_id}")

            with cycle.track_red_phase():
                print("Red phase: Writing failing tests...")
                time.sleep(2)  # Simulate work

            with cycle.track_green_phase():
                print("Green phase: Making tests pass...")
                time.sleep(3)  # Simulate work

            with cycle.track_refactor_phase():
                print("Refactor phase: Improving code quality...")
                time.sleep(1)  # Simulate work

        print("TDD cycle completed!")
        print("Check .claude/metrics/ for detailed analytics")