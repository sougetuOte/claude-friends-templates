#!/usr/bin/env python3
"""
Task Parallelization Analyzer - Refactored Implementation
タスク並列化分析システム

このモジュールは、タスク間の依存関係を分析し、並列実行可能性を判定します。
2025年のベストプラクティス（NetworkX, Critical Path Method, AST分析）に基づいています。

Features:
- DAG (Directed Acyclic Graph) 構築とバリデーション
- トポロジカルソート（Kahn's Algorithm）
- Critical Path Method (CPM) による最長パス計算
- 並列実行グループの生成（世代分け）
- リソース競合検出
- データフロー依存分析（AST）
- 並列化スコア算出（0-100）
- GraphViz可視化
- パフォーマンスキャッシング
- 構造化ロギング

Performance:
- CPM計算のキャッシング
- O(V+E)のトポロジカルソート
- メモリ効率的なグラフ操作

Author: Claude Friends Templates Team
Created: 2025-09-30
Last Updated: 2025-09-30 (Refactor Phase)
Python: 3.12+
"""

import ast
import json
import logging
from collections import defaultdict, deque
from dataclasses import dataclass, field, asdict
from enum import Enum
from functools import lru_cache
from pathlib import Path
from typing import List, Dict, Any, Optional, Set, Tuple, Final
import networkx as nx

# ロギング設定
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


# ====================================
# データモデル
# ====================================

class DependencyType(Enum):
    """依存関係のタイプ"""
    CONTROL = "control"  # 制御フロー依存
    DATA = "data"        # データフロー依存
    RESOURCE = "resource"  # リソース依存
    RAW = "RAW"          # Read-After-Write
    WAR = "WAR"          # Write-After-Read
    WAW = "WAW"          # Write-After-Write


class ConflictType(Enum):
    """競合のタイプ"""
    RESOURCE = "resource"  # リソース競合
    DATA_RACE = "data_race"  # データ競合
    DEADLOCK = "deadlock"  # デッドロック


@dataclass
class Task:
    """タスク定義"""
    id: str
    name: str = ""
    duration: int = 10
    dependencies: List[str] = field(default_factory=list)
    resources: List[str] = field(default_factory=list)
    command: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class Dependency:
    """依存関係"""
    from_task: str
    to_task: str
    type: DependencyType
    variable: Optional[str] = None


@dataclass
class ParallelizationReport:
    """並列化分析レポート"""
    summary: Dict[str, Any]
    critical_path: Dict[str, Any]
    parallel_groups: List[List[str]]
    conflicts: List[Dict[str, Any]]
    recommendations: List[str]
    metadata: Dict[str, Any] = field(default_factory=dict)


# ====================================
# メインアナライザークラス
# ====================================

class TaskParallelizationAnalyzer:
    """
    タスク並列化分析器

    NetworkXを使用してタスク依存関係をDAGとして表現し、
    並列実行可能性を分析します。
    """

    def __init__(self, working_dir: Optional[Path] = None):
        """
        タスク並列化分析器の初期化

        Args:
            working_dir: 作業ディレクトリ（省略時はカレントディレクトリ）

        Examples:
            >>> analyzer = TaskParallelizationAnalyzer()
            >>> analyzer = TaskParallelizationAnalyzer(Path("/project"))
        """
        self.working_dir = Path(working_dir) if working_dir else Path.cwd()
        self.graph: Optional[nx.DiGraph] = None
        self.tasks: Dict[str, Task] = {}
        self._cpm_cache: Optional[Dict[str, Any]] = None  # CPM結果のキャッシュ
        logger.info(f"TaskParallelizationAnalyzer initialized", extra={
            "working_dir": str(self.working_dir)
        })

    # ====================================
    # グラフ構築
    # ====================================

    def build_dependency_graph(self, tasks: List[Dict[str, Any]]) -> nx.DiGraph:
        """
        タスクリストから依存関係グラフを構築

        依存関係をDAG（有向非巡回グラフ）として表現します。
        各タスクはノード、依存関係はエッジとして追加されます。

        Args:
            tasks: タスクのリスト。各タスクは以下のフィールドを含む：
                - id (str, required): タスクの一意識別子
                - name (str, optional): タスク名
                - duration (int, optional): 所要時間（分）
                - dependencies (List[str], optional): 依存タスクのIDリスト
                - resources (List[str], optional): 使用リソース
                - command (str, optional): 実行コマンド

        Returns:
            nx.DiGraph: 構築された有向グラフ

        Raises:
            ValueError: タスクリストが空、不正な形式、または存在しない依存関係がある場合

        Examples:
            >>> tasks = [
            ...     {"id": "task1", "duration": 10, "dependencies": []},
            ...     {"id": "task2", "duration": 5, "dependencies": ["task1"]}
            ... ]
            >>> graph = analyzer.build_dependency_graph(tasks)
            >>> assert len(graph.nodes) == 2
        """
        if not tasks:
            raise ValueError("Task list is empty")

        logger.info(f"Building dependency graph", extra={
            "task_count": len(tasks)
        })

        # グラフ初期化
        G = nx.DiGraph()

        # タスクをノードとして追加
        for task_data in tasks:
            if "id" not in task_data:
                raise ValueError(f"Task is missing 'id' field: {task_data}")

            task_id = task_data["id"]
            task = Task(
                id=task_id,
                name=task_data.get("name", f"Task {task_id}"),
                duration=task_data.get("duration", 10),
                dependencies=task_data.get("dependencies", []),
                resources=task_data.get("resources", []),
                command=task_data.get("command"),
            )
            self.tasks[task_id] = task

            # ノード追加
            G.add_node(task_id, **asdict(task))

        # エッジ（依存関係）を追加
        for task in self.tasks.values():
            for dep_id in task.dependencies:
                if dep_id not in self.tasks:
                    raise ValueError(
                        f"Task '{task.id}' has dependency on non-existent task '{dep_id}'"
                    )
                # 依存先 -> 依存元 のエッジを追加
                G.add_edge(dep_id, task.id)

        self.graph = G
        self._cpm_cache = None  # キャッシュをクリア

        logger.info(f"Dependency graph built successfully", extra={
            "nodes": len(G.nodes),
            "edges": len(G.edges),
            "is_dag": nx.is_directed_acyclic_graph(G)
        })

        return G

    def is_valid_dag(self, graph: nx.DiGraph) -> bool:
        """
        グラフがDAG（有向非巡回グラフ）か検証

        Args:
            graph: 検証するグラフ

        Returns:
            bool: DAGであればTrue
        """
        return nx.is_directed_acyclic_graph(graph)

    def detect_cycles(self, graph: nx.DiGraph) -> List[List[str]]:
        """
        グラフ内の巡回依存を検出

        Args:
            graph: 検証するグラフ

        Returns:
            List[List[str]]: 巡回パスのリスト
        """
        try:
            cycles = list(nx.simple_cycles(graph))
            return cycles
        except:
            return []

    # ====================================
    # トポロジカルソート
    # ====================================

    def topological_sort(self, graph: nx.DiGraph) -> List[str]:
        """
        トポロジカルソートによる実行順序の決定

        Args:
            graph: 依存関係グラフ

        Returns:
            List[str]: 有効な実行順序のタスクIDリスト

        Raises:
            nx.NetworkXError: グラフが循環している場合
        """
        return list(nx.topological_sort(graph))

    # ====================================
    # Critical Path Method (CPM)
    # ====================================

    def calculate_critical_path(self, graph: nx.DiGraph) -> Dict[str, Any]:
        """
        Critical Path Method (CPM) による最長パスの計算

        プロジェクトの最短完了時間を決定するクリティカルパスを計算します。
        CPMアルゴリズムを使用して各タスクのES, EF, LS, LF, Slackを算出します。

        キャッシング: 同じグラフに対する再計算を回避するためキャッシュを使用

        Args:
            graph: 依存関係グラフ（DAGである必要があります）

        Returns:
            Dict: クリティカルパス情報
                - path (List[str]): クリティカルパス上のタスクID（依存順）
                - duration (int): プロジェクトの最短完了時間
                - task_times (Dict): 各タスクの時間情報
                    - es: Earliest Start（最早開始時刻）
                    - ef: Earliest Finish（最早完了時刻）
                    - ls: Latest Start（最遅開始時刻）
                    - lf: Latest Finish（最遅完了時刻）
                    - slack: 余裕時間（LS - ES）
                    - is_critical: クリティカルパス上か（slack == 0）

        Complexity:
            O(V + E) - トポロジカルソートの複雑度

        Examples:
            >>> cpm = analyzer.calculate_critical_path(graph)
            >>> print(cpm["duration"])  # プロジェクト完了時間
            >>> print(cpm["path"])  # ['task1', 'task2', 'task5']
        """
        # キャッシュチェック
        if self._cpm_cache is not None and self.graph is graph:
            logger.debug("Returning cached CPM result")
            return self._cpm_cache

        logger.info(f"Calculating critical path using CPM")
        # ES (Earliest Start) とEF (Earliest Finish) の計算（前向き計算）
        es = {}
        ef = {}

        for task_id in nx.topological_sort(graph):
            # 先行タスクの最大EFを取得
            predecessors = list(graph.predecessors(task_id))
            if not predecessors:
                es[task_id] = 0
            else:
                es[task_id] = max(ef[pred] for pred in predecessors)

            task_duration = self.tasks[task_id].duration
            ef[task_id] = es[task_id] + task_duration

        # プロジェクト完了時間
        project_duration = max(ef.values()) if ef else 0

        # LS (Latest Start) とLF (Latest Finish) の計算（後ろ向き計算）
        ls = {}
        lf = {}

        for task_id in reversed(list(nx.topological_sort(graph))):
            # 後続タスクの最小LSを取得
            successors = list(graph.successors(task_id))
            if not successors:
                lf[task_id] = project_duration
            else:
                lf[task_id] = min(ls[succ] for succ in successors)

            task_duration = self.tasks[task_id].duration
            ls[task_id] = lf[task_id] - task_duration

        # Slack（余裕時間）の計算
        slack = {task_id: ls[task_id] - es[task_id] for task_id in graph.nodes}

        # クリティカルパス（Slack=0のタスク）
        critical_tasks = [task_id for task_id, s in slack.items() if s == 0]

        # クリティカルパスを依存順に並べる
        critical_subgraph = graph.subgraph(critical_tasks)
        critical_path = list(nx.topological_sort(critical_subgraph))

        task_times = {
            task_id: {
                "es": es[task_id],
                "ef": ef[task_id],
                "ls": ls[task_id],
                "lf": lf[task_id],
                "slack": slack[task_id],
                "is_critical": slack[task_id] == 0,
            }
            for task_id in graph.nodes
        }

        result = {
            "path": critical_path,
            "duration": project_duration,
            "task_times": task_times,
        }

        # キャッシュに保存
        self._cpm_cache = result

        logger.info(f"Critical path calculated", extra={
            "duration": project_duration,
            "critical_tasks": len(critical_path),
            "total_tasks": len(graph.nodes)
        })

        return result

    # ====================================
    # 並列実行グループ生成
    # ====================================

    def generate_parallel_groups(self, graph: nx.DiGraph) -> List[List[str]]:
        """
        並列実行可能なタスクをグループ化（世代分け）

        各グループ内のタスクは並列実行可能。
        グループは依存関係順に並んでいる。

        Args:
            graph: 依存関係グラフ

        Returns:
            List[List[str]]: 並列実行グループのリスト
        """
        # 世代（generation）ごとにタスクを分類
        generations = []
        remaining_tasks = set(graph.nodes)
        processed_tasks = set()

        while remaining_tasks:
            # 現在実行可能なタスク（すべての依存が満たされている）
            current_generation = []

            for task_id in list(remaining_tasks):
                predecessors = set(graph.predecessors(task_id))
                if predecessors.issubset(processed_tasks):
                    current_generation.append(task_id)

            if not current_generation:
                # 無限ループ防止（通常は到達しない）
                break

            generations.append(sorted(current_generation))
            remaining_tasks -= set(current_generation)
            processed_tasks.update(current_generation)

        return generations

    # ====================================
    # リソース競合検出
    # ====================================

    def detect_resource_conflicts(
        self, graph: nx.DiGraph, parallel_groups: List[List[str]]
    ) -> List[Dict[str, Any]]:
        """
        リソース競合の検出

        同じ世代（並列実行）内で同じリソースを使用するタスクを検出

        Args:
            graph: 依存関係グラフ
            parallel_groups: 並列実行グループ

        Returns:
            List[Dict]: 競合情報のリスト
        """
        conflicts = []

        for gen_idx, generation in enumerate(parallel_groups):
            if len(generation) <= 1:
                continue

            # リソースごとにタスクをグループ化
            resource_usage = defaultdict(list)
            for task_id in generation:
                task = self.tasks[task_id]
                for resource in task.resources:
                    resource_usage[resource].append(task_id)

            # 複数タスクが同じリソースを使用している場合は競合
            for resource, task_ids in resource_usage.items():
                if len(task_ids) > 1:
                    conflicts.append({
                        "type": ConflictType.RESOURCE.value,
                        "resource": resource,
                        "tasks": task_ids,
                        "generation": gen_idx,
                        "severity": "medium",
                    })

        return conflicts

    # ====================================
    # データフロー分析
    # ====================================

    def analyze_dataflow_dependencies(self, code_file: Path) -> List[Dict[str, Any]]:
        """
        Pythonコードからデータフロー依存を分析

        Args:
            code_file: 分析するPythonファイル

        Returns:
            List[Dict]: データフロー依存のリスト
        """
        if not code_file.exists():
            return []

        try:
            code = code_file.read_text()
            tree = ast.parse(code)
        except:
            return []

        # 変数の読み書きを追跡
        writes = defaultdict(list)  # 変数名 -> 関数名リスト
        reads = defaultdict(list)   # 変数名 -> 関数名リスト

        for node in ast.walk(tree):
            if isinstance(node, ast.FunctionDef):
                func_name = node.name

                for child in ast.walk(node):
                    # 代入（書き込み）
                    if isinstance(child, ast.Assign):
                        for target in child.targets:
                            if isinstance(target, ast.Name):
                                writes[target.id].append(func_name)

                    # 名前参照（読み取り）
                    if isinstance(child, ast.Name) and isinstance(child.ctx, ast.Load):
                        reads[child.id].append(func_name)

        # 依存関係を生成
        dependencies = []

        for var_name in set(writes.keys()) | set(reads.keys()):
            write_funcs = set(writes.get(var_name, []))
            read_funcs = set(reads.get(var_name, []))

            # RAW (Read-After-Write) 依存
            for write_func in write_funcs:
                for read_func in read_funcs:
                    if write_func != read_func:
                        dependencies.append({
                            "type": "RAW",
                            "variable": var_name,
                            "from": write_func,
                            "to": read_func,
                        })

            # WAW (Write-After-Write) 依存
            write_funcs_list = list(write_funcs)
            for i, func1 in enumerate(write_funcs_list):
                for func2 in write_funcs_list[i+1:]:
                    dependencies.append({
                        "type": "WAW",
                        "variable": var_name,
                        "from": func1,
                        "to": func2,
                    })

        return dependencies

    # ====================================
    # スコア計算
    # ====================================

    def calculate_parallelization_score(self, graph: nx.DiGraph) -> float:
        """
        並列化可能性スコアの計算（0-100）

        以下の要素を考慮:
        - クリティカルパスの長さ vs 総作業時間
        - 並列実行可能なタスク数
        - 依存関係の疎密度

        Args:
            graph: 依存関係グラフ

        Returns:
            float: 並列化スコア（0-100）
        """
        if not graph.nodes:
            return 0.0

        # 総作業時間
        total_work = sum(self.tasks[task_id].duration for task_id in graph.nodes)

        # クリティカルパスの長さ
        cpm_result = self.calculate_critical_path(graph)
        critical_duration = cpm_result["duration"]

        # 理論的な最大並列度
        if critical_duration == 0:
            return 0.0

        max_parallelism = total_work / critical_duration

        # 実際の並列グループの最大サイズ
        parallel_groups = self.generate_parallel_groups(graph)
        actual_max_parallel = max(len(g) for g in parallel_groups) if parallel_groups else 1

        # スコア計算（複数の指標を組み合わせ）
        parallelism_ratio = min(actual_max_parallel / len(graph.nodes), 1.0)
        efficiency_ratio = min(max_parallelism / len(graph.nodes), 1.0)

        score = (parallelism_ratio * 0.6 + efficiency_ratio * 0.4) * 100

        return round(score, 2)

    # ====================================
    # 実行時間予測
    # ====================================

    def estimate_execution_time(
        self, graph: nx.DiGraph, parallel_groups: List[List[str]]
    ) -> Dict[str, Any]:
        """
        実行時間の予測

        Args:
            graph: 依存関係グラフ
            parallel_groups: 並列実行グループ

        Returns:
            Dict: 実行時間予測
                - sequential: シーケンシャル実行時間
                - parallel: 並列実行時間
                - speedup: スピードアップ率
        """
        # シーケンシャル実行時間
        sequential_time = sum(self.tasks[task_id].duration for task_id in graph.nodes)

        # 並列実行時間（各世代の最大時間の合計）
        parallel_time = 0
        for generation in parallel_groups:
            max_duration = max(
                self.tasks[task_id].duration for task_id in generation
            )
            parallel_time += max_duration

        # スピードアップ率
        speedup = sequential_time / parallel_time if parallel_time > 0 else 1.0

        return {
            "sequential": sequential_time,
            "parallel": parallel_time,
            "speedup": round(speedup, 2),
        }

    # ====================================
    # レポート生成
    # ====================================

    def generate_report(self, tasks: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        包括的な並列化分析レポートの生成

        Args:
            tasks: タスクリスト

        Returns:
            Dict: 分析レポート
        """
        # グラフ構築
        graph = self.build_dependency_graph(tasks)

        # 各種分析実行
        critical_path = self.calculate_critical_path(graph)
        parallel_groups = self.generate_parallel_groups(graph)
        conflicts = self.detect_resource_conflicts(graph, parallel_groups)
        time_estimate = self.estimate_execution_time(graph, parallel_groups)
        score = self.calculate_parallelization_score(graph)

        # 推奨事項生成
        recommendations = self._generate_recommendations(
            graph, critical_path, parallel_groups, conflicts
        )

        # レポート構築
        report = {
            "summary": {
                "total_tasks": len(graph.nodes),
                "parallelization_score": score,
                "estimated_speedup": time_estimate["speedup"],
                "sequential_time": time_estimate["sequential"],
                "parallel_time": time_estimate["parallel"],
            },
            "critical_path": critical_path,
            "parallel_groups": parallel_groups,
            "conflicts": conflicts,
            "recommendations": recommendations,
        }

        return report

    def _generate_recommendations(
        self,
        graph: nx.DiGraph,
        critical_path: Dict[str, Any],
        parallel_groups: List[List[str]],
        conflicts: List[Dict[str, Any]],
    ) -> List[str]:
        """推奨事項の生成"""
        recommendations = []

        # クリティカルパス最適化
        if critical_path["duration"] > 0:
            recommendations.append(
                f"Focus on optimizing tasks on the critical path: {', '.join(critical_path['path'])}"
            )

        # 並列化可能性
        max_parallel = max(len(g) for g in parallel_groups) if parallel_groups else 0
        if max_parallel > 1:
            recommendations.append(
                f"Up to {max_parallel} tasks can run in parallel"
            )

        # リソース競合
        if conflicts:
            recommendations.append(
                f"Resolve {len(conflicts)} resource conflicts to improve parallelization"
            )

        return recommendations

    def save_report(self, report: Dict[str, Any], output_file: Path) -> None:
        """
        レポートをJSON形式で保存

        Args:
            report: 分析レポート
            output_file: 出力ファイルパス
        """
        with output_file.open("w") as f:
            json.dump(report, f, indent=2, ensure_ascii=False)

    # ====================================
    # 可視化
    # ====================================

    def visualize_graph(
        self,
        graph: nx.DiGraph,
        output_file: Path,
        highlight_critical_path: bool = False
    ) -> None:
        """
        依存関係グラフの可視化（GraphViz形式）

        Args:
            graph: 依存関係グラフ
            output_file: 出力ファイルパス（.dot形式）
            highlight_critical_path: クリティカルパスを強調するか
        """
        dot_lines = ["digraph dependency_graph {"]
        dot_lines.append('  rankdir=LR;')
        dot_lines.append('  node [shape=box];')

        # クリティカルパスの取得
        critical_tasks = set()
        if highlight_critical_path:
            cpm = self.calculate_critical_path(graph)
            critical_tasks = set(cpm["path"])

        # ノード定義
        for task_id in graph.nodes:
            label = f"{task_id}\\n({self.tasks[task_id].duration}min)"
            style = "filled,bold" if task_id in critical_tasks else "filled"
            color = "lightcoral" if task_id in critical_tasks else "lightblue"

            dot_lines.append(
                f'  "{task_id}" [label="{label}", style="{style}", fillcolor="{color}"];'
            )

        # エッジ定義
        for u, v in graph.edges:
            style = "bold" if u in critical_tasks and v in critical_tasks else "solid"
            dot_lines.append(f'  "{u}" -> "{v}" [style="{style}"];')

        dot_lines.append("}")

        # ファイル保存
        output_file.write_text("\n".join(dot_lines))

    # ====================================
    # ファイルI/O
    # ====================================

    def load_tasks_from_file(self, tasks_file: Path) -> List[Dict[str, Any]]:
        """
        JSONファイルからタスクリストを読み込み

        Args:
            tasks_file: タスク定義ファイル（JSON形式）

        Returns:
            List[Dict]: タスクリスト
        """
        with tasks_file.open("r") as f:
            return json.load(f)

    def analyze(self, tasks: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        タスクリストを分析（エイリアス）

        Args:
            tasks: タスクリスト

        Returns:
            Dict: 分析レポート
        """
        return self.generate_report(tasks)


# ====================================
# CLIエントリーポイント
# ====================================

def main():
    """CLI実行時のエントリポイント"""
    import sys

    if len(sys.argv) < 2:
        print("Usage: python task_parallelization_analyzer.py <tasks.json>")
        sys.exit(1)

    tasks_file = Path(sys.argv[1])
    if not tasks_file.exists():
        print(f"Error: File not found: {tasks_file}")
        sys.exit(1)

    analyzer = TaskParallelizationAnalyzer()
    tasks = analyzer.load_tasks_from_file(tasks_file)
    report = analyzer.analyze(tasks)

    print(json.dumps(report, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()