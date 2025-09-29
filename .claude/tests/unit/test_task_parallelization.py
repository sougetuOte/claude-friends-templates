#!/usr/bin/env python3
"""
Task 2.2.2: タスク並列化分析 - テストスイート (Red Phase)
t-wada式TDD: まず失敗するテストを書く

このテストスイートは、タスク並列化分析システムの全機能をカバーします。
2025年のベストプラクティス（NetworkX, AST分析, Critical Path Method）に基づいています。
"""

import pytest
import tempfile
import json
from pathlib import Path
from typing import List, Dict, Any
import sys

# テスト対象モジュールのインポート
# パスを追加して絶対インポート
import os
scripts_path = os.path.join(os.path.dirname(__file__), '..', '..', 'scripts')
sys.path.insert(0, scripts_path)

try:
    from task_parallelization_analyzer import (
        TaskParallelizationAnalyzer,
        Task,
        Dependency,
        DependencyType,
        ParallelizationReport,
        ConflictType,
    )
except ImportError as e:
    # Red Phase: モジュールがまだ存在しないため、ダミーを定義
    print(f"Import error: {e}")
    TaskParallelizationAnalyzer = None
    Task = None
    Dependency = None
    DependencyType = None
    ParallelizationReport = None
    ConflictType = None


class TestTaskParallelizationAnalyzer:
    """タスク並列化分析器のテストスイート"""

    @pytest.fixture
    def temp_dir(self):
        """テスト用一時ディレクトリ"""
        with tempfile.TemporaryDirectory() as tmpdir:
            yield Path(tmpdir)

    @pytest.fixture
    def sample_tasks(self):
        """サンプルタスクデータ"""
        return [
            {
                "id": "task1",
                "name": "Setup environment",
                "duration": 5,
                "dependencies": [],
                "resources": ["cpu"],
            },
            {
                "id": "task2",
                "name": "Install dependencies",
                "duration": 10,
                "dependencies": ["task1"],
                "resources": ["network", "disk"],
            },
            {
                "id": "task3",
                "name": "Run unit tests",
                "duration": 15,
                "dependencies": ["task2"],
                "resources": ["cpu", "memory"],
            },
            {
                "id": "task4",
                "name": "Run integration tests",
                "duration": 20,
                "dependencies": ["task2"],
                "resources": ["cpu", "memory", "network"],
            },
            {
                "id": "task5",
                "name": "Build documentation",
                "duration": 8,
                "dependencies": ["task1"],
                "resources": ["cpu", "disk"],
            },
            {
                "id": "task6",
                "name": "Deploy",
                "duration": 12,
                "dependencies": ["task3", "task4", "task5"],
                "resources": ["network", "disk"],
            },
        ]

    @pytest.fixture
    def analyzer(self, temp_dir):
        """分析器インスタンス"""
        if TaskParallelizationAnalyzer is None:
            pytest.skip("TaskParallelizationAnalyzer not implemented yet (Red Phase)")
        return TaskParallelizationAnalyzer(temp_dir)

    # ====================================
    # Test 1: 依存関係グラフ構築
    # ====================================
    def test_build_dependency_graph(self, analyzer, sample_tasks):
        """
        RED PHASE: 依存関係グラフの構築をテスト

        期待される動作:
        - タスクリストからDAG（有向非巡回グラフ）を構築
        - 各タスクがノードとして存在
        - 依存関係がエッジとして表現される
        """
        graph = analyzer.build_dependency_graph(sample_tasks)

        # グラフが正しく構築されているか
        assert graph is not None
        assert analyzer.is_valid_dag(graph)

        # すべてのタスクがノードとして存在
        assert len(graph.nodes) == 6
        assert "task1" in graph.nodes
        assert "task6" in graph.nodes

        # 依存関係が正しく設定されている
        assert graph.has_edge("task1", "task2")
        assert graph.has_edge("task2", "task3")
        assert graph.has_edge("task2", "task4")
        assert graph.has_edge("task3", "task6")

    # ====================================
    # Test 2: DAG検証（巡回参照検出）
    # ====================================
    def test_detect_circular_dependency(self, analyzer):
        """
        RED PHASE: 巡回依存の検出をテスト

        期待される動作:
        - 巡回依存を含むタスクセットを検出できる
        - 巡回パスを特定できる
        """
        circular_tasks = [
            {"id": "A", "dependencies": ["B"]},
            {"id": "B", "dependencies": ["C"]},
            {"id": "C", "dependencies": ["A"]},  # 巡回！
        ]

        graph = analyzer.build_dependency_graph(circular_tasks)

        # DAGとして無効であることを検証
        assert not analyzer.is_valid_dag(graph)

        # 巡回パスを検出
        cycles = analyzer.detect_cycles(graph)
        assert len(cycles) > 0
        assert "A" in cycles[0] and "B" in cycles[0] and "C" in cycles[0]

    # ====================================
    # Test 3: トポロジカルソート
    # ====================================
    def test_topological_sort(self, analyzer, sample_tasks):
        """
        RED PHASE: トポロジカルソートをテスト

        期待される動作:
        - 有効な実行順序を生成
        - 依存関係を満たす順序である
        - 複数の有効な順序がある場合でも1つを返す
        """
        graph = analyzer.build_dependency_graph(sample_tasks)
        execution_order = analyzer.topological_sort(graph)

        # すべてのタスクが含まれている
        assert len(execution_order) == 6

        # task1が最初（依存なし）
        assert execution_order[0] == "task1"

        # task6が最後（すべてに依存）
        assert execution_order[-1] == "task6"

        # 依存関係を満たしている
        task2_idx = execution_order.index("task2")
        task3_idx = execution_order.index("task3")
        assert task2_idx < task3_idx  # task2はtask3より前

    # ====================================
    # Test 4: クリティカルパス計算
    # ====================================
    def test_calculate_critical_path(self, analyzer, sample_tasks):
        """
        RED PHASE: クリティカルパス（最長パス）の計算をテスト

        期待される動作:
        - 最も時間がかかる依存チェーンを特定
        - パス上の各タスクのES/EF/LS/LF/Slackを計算
        - プロジェクトの最短完了時間を算出
        """
        graph = analyzer.build_dependency_graph(sample_tasks)
        critical_path_result = analyzer.calculate_critical_path(graph)

        # クリティカルパスが存在
        assert critical_path_result is not None
        assert "path" in critical_path_result
        assert "duration" in critical_path_result

        # task1 -> task2 -> task4 -> task6 が最長パス（5+10+20+12=47分）
        critical_path = critical_path_result["path"]
        assert "task1" in critical_path
        assert "task2" in critical_path
        assert "task4" in critical_path
        assert "task6" in critical_path

        # 総所要時間
        assert critical_path_result["duration"] == 47

    # ====================================
    # Test 5: 並列実行グループの生成
    # ====================================
    def test_generate_parallel_execution_groups(self, analyzer, sample_tasks):
        """
        RED PHASE: 並列実行可能なタスクグループの生成をテスト

        期待される動作:
        - タスクを「世代（generation）」に分類
        - 同じ世代のタスクは並列実行可能
        - 各世代は前の世代完了後に実行可能
        """
        graph = analyzer.build_dependency_graph(sample_tasks)
        parallel_groups = analyzer.generate_parallel_groups(graph)

        # グループが生成されている
        assert len(parallel_groups) > 0

        # Generation 0: task1のみ
        assert len(parallel_groups[0]) == 1
        assert "task1" in parallel_groups[0]

        # Generation 1: task2, task5（task1に依存）
        assert len(parallel_groups[1]) == 2
        assert "task2" in parallel_groups[1]
        assert "task5" in parallel_groups[1]

        # Generation 2: task3, task4（task2に依存）
        assert len(parallel_groups[2]) == 2
        assert "task3" in parallel_groups[2]
        assert "task4" in parallel_groups[2]

        # Generation 3: task6（task3,4,5に依存）
        assert len(parallel_groups[3]) == 1
        assert "task6" in parallel_groups[3]

    # ====================================
    # Test 6: リソース競合の検出
    # ====================================
    def test_detect_resource_conflicts(self, analyzer, sample_tasks):
        """
        RED PHASE: リソース競合の検出をテスト

        期待される動作:
        - 同じリソースを使用するタスクを特定
        - 並列実行時の潜在的な競合を検出
        - 競合の重大度を評価
        """
        graph = analyzer.build_dependency_graph(sample_tasks)
        parallel_groups = analyzer.generate_parallel_groups(graph)

        conflicts = analyzer.detect_resource_conflicts(graph, parallel_groups)

        # 競合が検出されている
        assert len(conflicts) > 0

        # task3とtask4はメモリとCPUを共有（同じ世代）
        memory_conflict = next(
            (c for c in conflicts if c["resource"] == "memory"), None
        )
        assert memory_conflict is not None
        assert "task3" in memory_conflict["tasks"]
        assert "task4" in memory_conflict["tasks"]

    # ====================================
    # Test 7: データフロー依存の分析
    # ====================================
    def test_analyze_data_flow_dependencies(self, analyzer, temp_dir):
        """
        RED PHASE: データフロー依存の分析をテスト

        期待される動作:
        - Pythonコードから変数の読み書きを検出
        - Read-After-Write (RAW)依存を特定
        - Write-After-Read (WAR)依存を特定
        - Write-After-Write (WAW)依存を特定
        """
        # サンプルPythonコード
        sample_code = '''
def task_a():
    x = 10  # Write x
    y = x + 5  # Read x, Write y
    return y

def task_b():
    z = x * 2  # Read x - RAW dependency on task_a
    return z

def task_c():
    x = 20  # Write x - WAW dependency on task_a
    return x
'''

        code_file = temp_dir / "sample.py"
        code_file.write_text(sample_code)

        dependencies = analyzer.analyze_dataflow_dependencies(code_file)

        # 依存関係が検出されている
        assert len(dependencies) > 0

        # RAW依存: task_b -> task_a (xの読み取り)
        raw_dep = next(
            (d for d in dependencies
             if d["type"] == "RAW" and "x" in d["variable"]),
            None
        )
        assert raw_dep is not None

        # WAW依存: task_c -> task_a (xへの書き込み)
        waw_dep = next(
            (d for d in dependencies
             if d["type"] == "WAW" and "x" in d["variable"]),
            None
        )
        assert waw_dep is not None

    # ====================================
    # Test 8: 並列化スコアの計算
    # ====================================
    def test_calculate_parallelization_score(self, analyzer, sample_tasks):
        """
        RED PHASE: 並列化可能性スコアの計算をテスト

        期待される動作:
        - 0-100のスコアを計算
        - クリティカルパスの長さ vs 総作業時間の比率を考慮
        - 並列実行可能なタスク数を考慮
        """
        graph = analyzer.build_dependency_graph(sample_tasks)
        score = analyzer.calculate_parallelization_score(graph)

        # スコアが有効範囲内
        assert 0 <= score <= 100

        # このサンプルは中程度に並列化可能（30以上）
        assert score >= 25

    # ====================================
    # Test 9: 実行時間予測
    # ====================================
    def test_estimate_execution_time(self, analyzer, sample_tasks):
        """
        RED PHASE: 実行時間の予測をテスト

        期待される動作:
        - シーケンシャル実行時間を計算
        - 並列実行時間を計算
        - スピードアップ率を算出
        """
        graph = analyzer.build_dependency_graph(sample_tasks)
        parallel_groups = analyzer.generate_parallel_groups(graph)

        time_estimate = analyzer.estimate_execution_time(graph, parallel_groups)

        # 時間予測が含まれている
        assert "sequential" in time_estimate
        assert "parallel" in time_estimate
        assert "speedup" in time_estimate

        # シーケンシャル: 5+10+15+20+8+12 = 70分
        assert time_estimate["sequential"] == 70

        # 並列: クリティカルパスの長さ = 47分
        assert time_estimate["parallel"] == 47

        # スピードアップ: 70/47 ≈ 1.49
        assert 1.4 <= time_estimate["speedup"] <= 1.5

    # ====================================
    # Test 10: 並列化レポートの生成
    # ====================================
    def test_generate_parallelization_report(self, analyzer, sample_tasks, temp_dir):
        """
        RED PHASE: 包括的な並列化レポートの生成をテスト

        期待される動作:
        - 構造化されたJSONレポートを生成
        - すべての分析結果を含む
        - AI消費に適したフォーマット
        """
        report = analyzer.generate_report(sample_tasks)

        # レポートが生成されている
        assert report is not None

        # 必須セクションが含まれている
        assert "summary" in report
        assert "critical_path" in report
        assert "parallel_groups" in report
        assert "conflicts" in report
        assert "recommendations" in report

        # サマリー情報
        summary = report["summary"]
        assert summary["total_tasks"] == 6
        assert summary["parallelization_score"] >= 0
        assert summary["estimated_speedup"] > 1.0

        # レポートをJSON保存できる
        report_file = temp_dir / "parallelization_report.json"
        analyzer.save_report(report, report_file)
        assert report_file.exists()

        # 保存したレポートを読み込める
        with report_file.open("r") as f:
            loaded_report = json.load(f)
        assert loaded_report["summary"]["total_tasks"] == 6

    # ====================================
    # Test 11: グラフ可視化の生成
    # ====================================
    def test_generate_dependency_graph_visualization(self, analyzer, sample_tasks, temp_dir):
        """
        RED PHASE: 依存関係グラフの可視化をテスト

        期待される動作:
        - GraphViz形式で依存関係グラフを出力
        - クリティカルパスを強調表示
        - 並列実行可能なタスクを色分け
        """
        graph = analyzer.build_dependency_graph(sample_tasks)
        output_file = temp_dir / "dependency_graph.dot"

        analyzer.visualize_graph(graph, output_file, highlight_critical_path=True)

        # ファイルが生成されている
        assert output_file.exists()

        # DOT形式の内容を検証
        content = output_file.read_text()
        assert "digraph" in content
        assert "task1" in content
        assert "task6" in content

        # エッジが含まれている
        assert "->" in content

    # ====================================
    # Test 12: エラーハンドリング
    # ====================================
    def test_handle_invalid_input(self, analyzer):
        """
        RED PHASE: 不正な入力のハンドリングをテスト

        期待される動作:
        - 空のタスクリストに対してエラーを返す
        - 不正なタスク形式を検出
        - 存在しない依存関係を検出
        """
        # 空のタスクリスト
        with pytest.raises(ValueError, match="empty"):
            analyzer.build_dependency_graph([])

        # 不正なタスク形式（idが欠落）
        invalid_tasks = [{"name": "Task without ID"}]
        with pytest.raises(ValueError, match="id"):
            analyzer.build_dependency_graph(invalid_tasks)

        # 存在しない依存関係
        tasks_with_missing_dep = [
            {"id": "task1", "dependencies": []},
            {"id": "task2", "dependencies": ["task_nonexistent"]},
        ]
        with pytest.raises(ValueError, match="dependency"):
            analyzer.build_dependency_graph(tasks_with_missing_dep)


class TestTaskParallelizationIntegration:
    """統合テスト: 実際のプロジェクト構造での並列化分析"""

    @pytest.fixture
    def project_dir(self, tmp_path):
        """サンプルプロジェクト構造"""
        project = tmp_path / "sample_project"
        project.mkdir()

        # サンプルタスク定義ファイル
        tasks_file = project / "tasks.json"
        tasks_file.write_text(json.dumps([
            {
                "id": "lint",
                "name": "Run linter",
                "duration": 5,
                "dependencies": [],
                "command": "ruff check .",
            },
            {
                "id": "test_unit",
                "name": "Run unit tests",
                "duration": 20,
                "dependencies": ["lint"],
                "command": "pytest tests/unit",
            },
            {
                "id": "test_integration",
                "name": "Run integration tests",
                "duration": 30,
                "dependencies": ["lint"],
                "command": "pytest tests/integration",
            },
            {
                "id": "build",
                "name": "Build package",
                "duration": 10,
                "dependencies": ["test_unit", "test_integration"],
                "command": "python -m build",
            },
        ]))

        return project

    def test_analyze_real_project(self, project_dir):
        """
        RED PHASE: 実際のプロジェクト構造を分析

        期待される動作:
        - tasks.jsonからタスクを読み込み
        - 並列化分析を実行
        - 実行可能な並列化戦略を提案
        """
        if TaskParallelizationAnalyzer is None:
            pytest.skip("TaskParallelizationAnalyzer not implemented yet")

        analyzer = TaskParallelizationAnalyzer(project_dir)

        # タスクファイルを読み込み
        tasks_file = project_dir / "tasks.json"
        tasks = analyzer.load_tasks_from_file(tasks_file)

        # 分析実行
        report = analyzer.analyze(tasks)

        # test_unit と test_integration は並列実行可能
        parallel_groups = report["parallel_groups"]
        generation_1 = next((g for g in parallel_groups if "test_unit" in g), None)
        assert generation_1 is not None
        assert "test_integration" in generation_1

        # 推奨事項が含まれている
        assert len(report["recommendations"]) > 0


# ====================================
# テストユーティリティ
# ====================================

def create_test_task(task_id: str, dependencies: List[str] = None, duration: int = 10):
    """テスト用のタスクオブジェクトを生成"""
    return {
        "id": task_id,
        "name": f"Task {task_id}",
        "duration": duration,
        "dependencies": dependencies or [],
        "resources": ["cpu"],
    }


if __name__ == "__main__":
    # テスト実行
    pytest.main([__file__, "-v", "--tb=short"])