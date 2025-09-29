#!/usr/bin/env python3
"""
Design Drift Detector
設計と実装の乖離を検出する
"""

import os
import re
import ast
from datetime import datetime


class DesignDriftDetector:
    def __init__(self):
        self.drift_score = 0
        self.drift_items = []
        self.design_docs = {}
        self.implementation = {}

    def load_design_docs(self, design_paths):
        """設計ドキュメントを読み込む"""
        for path in design_paths:
            if os.path.exists(path):
                with open(path, "r", encoding="utf-8") as f:
                    content = f.read()
                    self.design_docs[path] = self.parse_design_doc(content)

    def parse_design_doc(self, content):
        """設計ドキュメントから重要な要素を抽出"""
        design_elements = {
            "interfaces": [],
            "endpoints": [],
            "data_models": [],
            "components": [],
            "dependencies": [],
        }

        # インターフェース定義を抽出
        interface_pattern = r"interface\s+(\w+)\s*{([^}]+)}"
        interfaces = re.findall(interface_pattern, content, re.MULTILINE)
        design_elements["interfaces"] = interfaces

        # APIエンドポイントを抽出
        endpoint_pattern = r"(GET|POST|PUT|DELETE|PATCH)\s+(/[\w/\-:{}]+)"
        endpoints = re.findall(endpoint_pattern, content)
        design_elements["endpoints"] = endpoints

        # コンポーネント名を抽出
        component_pattern = r"(?:class|component|service)\s+(\w+)"
        components = re.findall(component_pattern, content, re.IGNORECASE)
        design_elements["components"] = components

        return design_elements

    def scan_implementation(self, src_paths):
        """実装コードをスキャン"""
        for src_path in src_paths:
            if os.path.exists(src_path):
                for root, dirs, files in os.walk(src_path):
                    for file in files:
                        if file.endswith((".py", ".js", ".ts", ".java")):
                            file_path = os.path.join(root, file)
                            self.analyze_implementation_file(file_path)

    def analyze_implementation_file(self, file_path):
        """実装ファイルを分析"""
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()

            # 実装されているインターフェースを検出
            if file_path.endswith(".py"):
                self.analyze_python_file(content, file_path)
            elif file_path.endswith((".js", ".ts")):
                self.analyze_javascript_file(content, file_path)

        except (IOError, UnicodeDecodeError):
            # ファイル読み込みエラーは無視
            pass

    def analyze_python_file(self, content, file_path):
        """Pythonファイルの分析"""
        try:
            tree = ast.parse(content)
            for node in ast.walk(tree):
                if isinstance(node, ast.ClassDef):
                    self.implementation.setdefault("classes", []).append(
                        {
                            "name": node.name,
                            "file": file_path,
                            "methods": [
                                m.name
                                for m in node.body
                                if isinstance(m, ast.FunctionDef)
                            ],
                        }
                    )
                elif isinstance(node, ast.FunctionDef):
                    if node.name.startswith("get_") or node.name.startswith("post_"):
                        self.implementation.setdefault("endpoints", []).append(
                            {"name": node.name, "file": file_path}
                        )
        except (SyntaxError, ValueError):
            # Python構文エラーは無視
            pass

    def analyze_javascript_file(self, content, file_path):
        """JavaScript/TypeScriptファイルの分析"""
        # クラス定義
        class_pattern = r"class\s+(\w+)"
        classes = re.findall(class_pattern, content)
        for cls in classes:
            self.implementation.setdefault("classes", []).append(
                {"name": cls, "file": file_path}
            )

        # 関数定義
        func_pattern = (
            r"(?:function|const|let|var)\s+(\w+)\s*(?:=\s*)?(?:\([^)]*\)|async)"
        )
        functions = re.findall(func_pattern, content)
        for func in functions:
            if func.startswith("handle") or func.endswith("Controller"):
                self.implementation.setdefault("endpoints", []).append(
                    {"name": func, "file": file_path}
                )

    def detect_drifts(self):
        """設計と実装の乖離を検出"""
        # インターフェースドリフトの検出
        self.detect_interface_drift()

        # コンポーネントドリフトの検出
        self.detect_component_drift()

        # エンドポイントドリフトの検出
        self.detect_endpoint_drift()

        # スコア計算
        self.calculate_drift_score()

    def detect_interface_drift(self):
        """インターフェースの乖離を検出"""
        design_interfaces = set()
        for doc in self.design_docs.values():
            for interface in doc.get("interfaces", []):
                design_interfaces.add(interface[0])

        impl_interfaces = set()
        for cls in self.implementation.get("classes", []):
            impl_interfaces.add(cls["name"])

        # 設計にあって実装にないもの
        missing_impl = design_interfaces - impl_interfaces
        for item in missing_impl:
            self.drift_items.append(
                {
                    "type": "missing_implementation",
                    "severity": "high",
                    "item": f"Interface '{item}' defined in design but not implemented",
                    "score": 10,
                }
            )

        # 実装にあって設計にないもの
        undocumented = impl_interfaces - design_interfaces
        for item in undocumented:
            self.drift_items.append(
                {
                    "type": "undocumented_implementation",
                    "severity": "medium",
                    "item": f"Class '{item}' implemented but not in design",
                    "score": 5,
                }
            )

    def detect_component_drift(self):
        """コンポーネントの乖離を検出"""
        design_components = set()
        for doc in self.design_docs.values():
            for comp in doc.get("components", []):
                design_components.add(comp.lower())

        impl_components = set()
        for cls in self.implementation.get("classes", []):
            impl_components.add(cls["name"].lower())

        # 大きな乖離を検出
        if design_components and impl_components:
            intersection = design_components & impl_components
            coverage = len(intersection) / len(design_components) * 100

            if coverage < 50:
                self.drift_items.append(
                    {
                        "type": "low_coverage",
                        "severity": "high",
                        "item": f"Only {coverage:.1f}% of designed components are implemented",
                        "score": 15,
                    }
                )

    def detect_endpoint_drift(self):
        """エンドポイントの乖離を検出"""
        design_endpoints = set()
        for doc in self.design_docs.values():
            for method, path in doc.get("endpoints", []):
                design_endpoints.add(f"{method} {path}")

        # 簡易的な実装エンドポイント検出
        impl_endpoints = len(self.implementation.get("endpoints", []))

        if design_endpoints and impl_endpoints == 0:
            self.drift_items.append(
                {
                    "type": "missing_endpoints",
                    "severity": "critical",
                    "item": "API endpoints defined in design but no implementation found",
                    "score": 20,
                }
            )

    def calculate_drift_score(self):
        """ドリフトスコアを計算"""
        total_score = sum(item["score"] for item in self.drift_items)

        # 正規化（0-100の範囲に）
        self.drift_score = min(total_score, 100)

        return self.drift_score

    def generate_report(self):
        """ドリフトレポートを生成"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        score = self.drift_score

        # スコアに基づく状態判定
        if score <= 10:
            status = "🟢 健全"
            status_desc = "設計と実装がよく同期しています"
        elif score <= 30:
            status = "🟡 軽微なドリフト"
            status_desc = "いくつかの不整合がありますが、管理可能です"
        elif score <= 50:
            status = "🟠 要注意"
            status_desc = "設計と実装の乖離が目立ち始めています"
        else:
            status = "🔴 深刻なドリフト"
            status_desc = "設計と実装が大きく乖離しています。即座の対応が必要です"

        report = f"""# 設計ドリフト検出レポート

生成日時: {timestamp}

## 総合評価
**ドリフトスコア: {score}/100**
**状態: {status}**
{status_desc}

## 検出された問題

"""

        # 重要度別に問題を分類
        critical_items = [
            item for item in self.drift_items if item["severity"] == "critical"
        ]
        high_items = [item for item in self.drift_items if item["severity"] == "high"]
        medium_items = [
            item for item in self.drift_items if item["severity"] == "medium"
        ]

        if critical_items:
            report += "### 🔴 Critical\n"
            for item in critical_items:
                report += f"- {item['item']}\n"
            report += "\n"

        if high_items:
            report += "### 🟠 High\n"
            for item in high_items:
                report += f"- {item['item']}\n"
            report += "\n"

        if medium_items:
            report += "### 🟡 Medium\n"
            for item in medium_items:
                report += f"- {item['item']}\n"
            report += "\n"

        # 推奨アクション
        report += """## 推奨アクション

"""
        if score > 50:
            report += """1. **緊急対応**
   - Plannerエージェントと協議し、設計の見直しを実施
   - 実装と設計の不整合箇所を特定し、優先順位付け
   - 修正計画を立案し、段階的に是正

"""
        elif score > 30:
            report += """1. **計画的対応**
   - 次のスプリントで設計ドキュメントの更新
   - 未実装の設計要素の実装計画策定
   - 設計にない実装の文書化

"""
        else:
            report += """1. **継続的改善**
   - 定期的なドリフトチェックの継続
   - 小さな不整合の早期修正
   - 設計と実装の同期プロセスの維持

"""

        return report


def main():
    """メイン処理"""
    import argparse

    parser = argparse.ArgumentParser(description="設計ドリフト検出ツール")
    parser.add_argument(
        "--design-paths",
        nargs="+",
        default=["docs/design", ".claude/shared/templates/design"],
        help="設計ドキュメントのパス",
    )
    parser.add_argument(
        "--src-paths",
        nargs="+",
        default=["src", "lib", "app"],
        help="ソースコードのパス",
    )
    parser.add_argument("--output", help="出力ファイル")
    parser.add_argument(
        "--threshold", type=int, default=30, help="エラー終了する閾値スコア"
    )

    args = parser.parse_args()

    detector = DesignDriftDetector()

    # 設計ドキュメントの読み込み
    print("設計ドキュメントを読み込み中...")
    detector.load_design_docs(args.design_paths)

    # 実装コードのスキャン
    print("実装コードをスキャン中...")
    detector.scan_implementation(args.src_paths)

    # ドリフト検出
    print("ドリフトを検出中...")
    detector.detect_drifts()

    # レポート生成
    report = detector.generate_report()

    if args.output:
        # ディレクトリ作成
        output_dir = os.path.dirname(args.output)
        if output_dir:
            os.makedirs(output_dir, exist_ok=True)

        with open(args.output, "w", encoding="utf-8") as f:
            f.write(report)
        print(f"レポートを {args.output} に出力しました。")
    else:
        print(report)

    # 閾値チェック
    if detector.drift_score > args.threshold:
        print(
            f"\n❌ ドリフトスコア({detector.drift_score})が閾値({args.threshold})を超えています。"
        )
        return 1
    else:
        print(f"\n✅ ドリフトスコア({detector.drift_score})は許容範囲内です。")
        return 0


if __name__ == "__main__":
    exit(main())
