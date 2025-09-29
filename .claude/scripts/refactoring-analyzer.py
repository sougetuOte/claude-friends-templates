#!/usr/bin/env python3
"""
Refactoring Analyzer
技術負債を検出し、リファクタリングの優先度を算出する
"""

import os
import json
import re
import fnmatch
from datetime import datetime


class RefactoringAnalyzer:
    def __init__(self, config_path=".claude/refactoring-config.json"):
        self.config = self.load_config(config_path)
        self.results = {
            "summary": {},
            "critical": [],
            "high": [],
            "medium": [],
            "low": [],
            "metrics": {},
        }

    def load_config(self, config_path):
        """設定ファイルを読み込む（存在しない場合はデフォルト値）"""
        default_config = {
            "thresholds": {
                "complexity": {
                    "cyclomatic": 10,
                    "cognitive": 15,
                    "maxLines": 100,
                    "maxParams": 5,
                },
                "duplication": {"minLines": 20, "threshold": 0.8},
                "coverage": 80,
            },
            "exclude": [
                "vendor/",
                "node_modules/",
                "build/",
                "dist/",
                "*.min.js",
                "*.generated.*",
                "__pycache__",
                ".git",
            ],
        }

        if os.path.exists(config_path):
            with open(config_path, "r") as f:
                user_config = json.load(f)
                # マージ
                default_config.update(user_config)

        return default_config

    def should_exclude(self, file_path):
        """除外パターンに該当するかチェック"""
        for pattern in self.config["exclude"]:
            if pattern.endswith("/"):
                if pattern in file_path:
                    return True
            elif "*" in pattern:
                if fnmatch.fnmatch(file_path, pattern):
                    return True
            elif pattern in file_path:
                return True
        return False

    def calculate_cyclomatic_complexity(self, code):
        """循環的複雑度を計算（簡易版）"""
        complexity = 1
        # 制御構造をカウント
        control_keywords = [
            r"\bif\b",
            r"\belif\b",
            r"\belse\b",
            r"\bfor\b",
            r"\bwhile\b",
            r"\btry\b",
            r"\bcatch\b",
            r"\bcase\b",
            r"\b\?\s*:",
            r"\&\&",
            r"\|\|",
        ]

        for keyword in control_keywords:
            complexity += len(re.findall(keyword, code))

        return complexity

    def count_parameters(self, code):
        """関数のパラメータ数をカウント"""
        # Python関数
        py_func_pattern = r"def\s+\w+\s*\(([^)]*)\)"
        # JavaScript関数
        js_func_pattern = r"function\s+\w+\s*\(([^)]*)\)"
        js_arrow_pattern = r"(?:const|let|var)\s+\w+\s*=\s*\(([^)]*)\)\s*=>"

        max_params = 0
        for pattern in [py_func_pattern, js_func_pattern, js_arrow_pattern]:
            matches = re.findall(pattern, code)
            for match in matches:
                if match.strip():
                    params = len([p.strip() for p in match.split(",") if p.strip()])
                    max_params = max(max_params, params)

        return max_params

    def find_duplicates(self, files_content):
        """コード重複を検出"""
        duplicates = []
        # 簡易的な重複検出（実際はより高度なアルゴリズムを使用）
        code_blocks = {}

        for file_path, content in files_content.items():
            lines = content.split("\n")
            for i in range(
                len(lines) - self.config["thresholds"]["duplication"]["minLines"]
            ):
                block = "\n".join(
                    lines[i : i + self.config["thresholds"]["duplication"]["minLines"]]
                )
                block_hash = hash(block.strip())

                if block_hash in code_blocks:
                    duplicates.append(
                        {
                            "file1": code_blocks[block_hash]["file"],
                            "line1": code_blocks[block_hash]["line"],
                            "file2": file_path,
                            "line2": i + 1,
                            "lines": self.config["thresholds"]["duplication"][
                                "minLines"
                            ],
                        }
                    )
                else:
                    code_blocks[block_hash] = {"file": file_path, "line": i + 1}

        return duplicates

    def calculate_priority_score(self, complexity, impact, frequency, effort):
        """優先度スコアを計算"""
        return (impact * frequency * complexity) / max(effort, 1)

    def analyze_file(self, file_path):
        """単一ファイルを分析"""
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()

            lines = content.split("\n")
            line_count = len(lines)

            # 複雑度計算
            complexity = self.calculate_cyclomatic_complexity(content)
            params = self.count_parameters(content)

            issues = []

            # 複雑度チェック
            if complexity > self.config["thresholds"]["complexity"]["cyclomatic"]:
                issues.append(
                    {
                        "type": "complexity",
                        "severity": "high",
                        "message": f"循環的複雑度が高い: {complexity}",
                        "score": complexity,
                    }
                )

            # 行数チェック
            if line_count > self.config["thresholds"]["complexity"]["maxLines"]:
                issues.append(
                    {
                        "type": "length",
                        "severity": "medium",
                        "message": f"ファイルが長すぎる: {line_count}行",
                        "score": line_count
                        / self.config["thresholds"]["complexity"]["maxLines"],
                    }
                )

            # パラメータ数チェック
            if params > self.config["thresholds"]["complexity"]["maxParams"]:
                issues.append(
                    {
                        "type": "parameters",
                        "severity": "medium",
                        "message": f"パラメータが多すぎる: {params}個",
                        "score": params,
                    }
                )

            return {
                "file": file_path,
                "metrics": {
                    "complexity": complexity,
                    "lines": line_count,
                    "parameters": params,
                },
                "issues": issues,
            }

        except (IOError, UnicodeDecodeError):
            # ファイル読み込みエラーは無視（バイナリファイルなど）
            return None

    def analyze_project(self, root_path="."):
        """プロジェクト全体を分析"""
        files_content = {}
        file_issues = []

        # ファイルを収集・分析
        for root, dirs, files in os.walk(root_path):
            # 除外ディレクトリをスキップ
            dirs[:] = [
                d for d in dirs if not self.should_exclude(os.path.join(root, d))
            ]

            for file in files:
                file_path = os.path.join(root, file)

                # 除外ファイルをスキップ
                if self.should_exclude(file_path):
                    continue

                # ソースコードファイルのみ対象
                if file.endswith((".py", ".js", ".ts", ".java", ".go", ".rb")):
                    result = self.analyze_file(file_path)
                    if result and result["issues"]:
                        file_issues.append(result)

                    try:
                        with open(file_path, "r", encoding="utf-8") as f:
                            files_content[file_path] = f.read()
                    except (IOError, UnicodeDecodeError):
                        # ファイル読み込みエラーは無視
                        pass

        # 重複検出
        duplicates = self.find_duplicates(files_content)

        # 結果を優先度別に分類
        for issue_data in file_issues:
            for issue in issue_data["issues"]:
                # 優先度スコア計算（簡易版）
                score = self.calculate_priority_score(
                    complexity=issue.get("score", 1),
                    impact=3,  # デフォルト値
                    frequency=2,  # デフォルト値
                    effort=1,  # デフォルト値
                )

                recommendation = {
                    "file": issue_data["file"],
                    "issue": issue["message"],
                    "type": issue["type"],
                    "score": score,
                    "effort": "1時間",  # 簡易見積もり
                    "recommendation": self.get_recommendation(issue["type"]),
                }

                if score > 15:
                    self.results["critical"].append(recommendation)
                elif score > 10:
                    self.results["high"].append(recommendation)
                elif score > 5:
                    self.results["medium"].append(recommendation)
                else:
                    self.results["low"].append(recommendation)

        # 重複を結果に追加
        for dup in duplicates:
            self.results["high"].append(
                {
                    "file": dup["file1"],
                    "issue": f"{dup['file2']}と{dup['lines']}行の重複",
                    "type": "duplication",
                    "score": 12,
                    "effort": "30分",
                    "recommendation": "共通関数として抽出",
                }
            )

        # サマリー作成
        self.results["summary"] = {
            "total_files": len(files_content),
            "critical_count": len(self.results["critical"]),
            "high_count": len(self.results["high"]),
            "medium_count": len(self.results["medium"]),
            "low_count": len(self.results["low"]),
            "timestamp": datetime.now().isoformat(),
        }

        return self.results

    def get_recommendation(self, issue_type):
        """問題タイプに応じた推奨事項を返す"""
        recommendations = {
            "complexity": "関数を分割し、早期リターンを活用",
            "length": "ファイルを複数のモジュールに分割",
            "parameters": "パラメータオブジェクトパターンを使用",
            "duplication": "共通処理を関数として抽出",
        }
        return recommendations.get(issue_type, "リファクタリングを検討")

    def generate_report(self, output_format="markdown"):
        """レポートを生成"""
        if output_format == "markdown":
            return self.generate_markdown_report()
        elif output_format == "json":
            return json.dumps(self.results, indent=2, ensure_ascii=False)
        else:
            return str(self.results)

    def generate_markdown_report(self):
        """Markdown形式のレポートを生成"""
        report = f"""# リファクタリング分析レポート

生成日時: {self.results['summary']['timestamp']}

## サマリー
- 分析ファイル数: {self.results['summary']['total_files']}
- Critical: {self.results['summary']['critical_count']}件
- High: {self.results['summary']['high_count']}件
- Medium: {self.results['summary']['medium_count']}件
- Low: {self.results['summary']['low_count']}件

"""

        # Critical
        if self.results["critical"]:
            report += "## 🔴 Critical（即座に対応）\n\n"
            for item in self.results["critical"]:
                report += f"- [ ] `{item['file']}` - {item['issue']}\n"
                report += f"  - 推奨: {item['recommendation']}\n"
                report += f"  - 見積もり: {item['effort']}\n\n"

        # High
        if self.results["high"]:
            report += "## 🟠 High（今スプリント内）\n\n"
            for item in self.results["high"][:5]:  # 上位5件のみ
                report += f"- [ ] `{item['file']}` - {item['issue']}\n"
                report += f"  - 推奨: {item['recommendation']}\n"
                report += f"  - 見積もり: {item['effort']}\n\n"

        # Medium（件数のみ）
        if self.results["medium"]:
            report += "\n## 🟡 Medium（次スプリント検討）\n\n"
            report += f"{len(self.results['medium'])}件の改善候補があります。\n\n"

        # Low（件数のみ）
        if self.results["low"]:
            report += "## 🟢 Low（時間があるとき）\n\n"
            report += f"{len(self.results['low'])}件の軽微な改善候補があります。\n"

        return report


def main():
    """メイン処理"""
    import argparse

    parser = argparse.ArgumentParser(description="リファクタリング分析ツール")
    parser.add_argument("--path", default=".", help="分析対象のパス")
    parser.add_argument(
        "--format",
        choices=["markdown", "json"],
        default="markdown",
        help="出力フォーマット",
    )
    parser.add_argument("--output", help="出力ファイル（指定なしは標準出力）")

    args = parser.parse_args()

    analyzer = RefactoringAnalyzer()
    analyzer.analyze_project(args.path)
    report = analyzer.generate_report(args.format)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(report)
        print(f"レポートを {args.output} に出力しました。")
    else:
        print(report)


if __name__ == "__main__":
    main()
