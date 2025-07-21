#!/usr/bin/env python3
"""
Quality Check Script
コード品質を総合的にチェックする
"""

import os
import json
import subprocess
import sys
import fnmatch
from datetime import datetime
from pathlib import Path
import re

# 定数定義
COVERAGE_YELLOW_THRESHOLD = 0.875  # 70% = 80% * 0.875

class QualityChecker:
    def __init__(self, config_path=".claude/quality-config.json"):
        self.config = self.load_config(config_path)
        self.results = {
            "timestamp": datetime.now().isoformat(),
            "result": "PASS",
            "level": "GREEN",
            "metrics": {},
            "issues": []
        }
        
    def load_config(self, config_path):
        """設定ファイルを読み込む"""
        default_config = {
            "thresholds": {
                "coverage": {
                    "global": 80,
                    "new_code": 90,
                    "per_file": 60
                },
                "complexity": {
                    "cyclomatic": 10,
                    "cognitive": 15
                },
                "duplication": 5,
                "security": {
                    "critical": 0,
                    "high": 0,
                    "medium": 3,
                    "low": 10
                }
            },
            "exclude": [
                "**/*.test.js",
                "**/*.spec.ts",
                "**/test_*.py",
                "**/migrations/**",
                "**/vendor/**",
                "**/node_modules/**",
                "**/__pycache__/**"
            ],
            "rules": {
                "enforce_tdd": True,
                "require_docs": True,
                "strict_typing": True
            }
        }
        
        if os.path.exists(config_path):
            with open(config_path, 'r') as f:
                user_config = json.load(f)
                # 深いマージ
                self.deep_merge(default_config, user_config)
                
        return default_config
    
    def deep_merge(self, base, update):
        """辞書を深くマージ"""
        for key, value in update.items():
            if key in base and isinstance(base[key], dict) and isinstance(value, dict):
                self.deep_merge(base[key], value)
            else:
                base[key] = value
    
    def check_test_coverage(self):
        """テストカバレッジをチェック"""
        print("📊 テストカバレッジをチェック中...")
        
        coverage_data = {
            "line": 0,
            "branch": 0,
            "function": 0,
            "files": {}
        }
        
        # Python プロジェクトの場合
        if os.path.exists("setup.py") or os.path.exists("pyproject.toml"):
            try:
                # カバレッジ計測実行
                subprocess.run(["coverage", "run", "-m", "pytest"], 
                             capture_output=True, check=False)
                
                # JSONレポート生成
                result = subprocess.run(["coverage", "json", "-o", "-"], 
                                      capture_output=True, text=True)
                
                if result.returncode == 0:
                    cov_json = json.loads(result.stdout)
                    coverage_data["line"] = cov_json.get("totals", {}).get("percent_covered", 0)
                    
                    # ファイル別カバレッジ
                    for file, data in cov_json.get("files", {}).items():
                        if not self.should_exclude(file):
                            coverage_data["files"][file] = data.get("summary", {}).get("percent_covered", 0)
                            
            except Exception as e:
                self.add_issue("coverage", f"カバレッジ測定エラー: {str(e)}", "medium")
        
        # JavaScript/TypeScript プロジェクトの場合
        elif os.path.exists("package.json"):
            try:
                # Jestでカバレッジ計測
                result = subprocess.run(["npm", "run", "test", "--", "--coverage", "--json"], 
                                      capture_output=True, text=True)
                
                if result.returncode == 0:
                    # Jest出力から数値を抽出（簡易版）
                    output = result.stdout
                    match = re.search(r'Lines\s*:\s*([\d.]+)%', output)
                    if match:
                        coverage_data["line"] = float(match.group(1))
                        
            except Exception as e:
                self.add_issue("coverage", f"カバレッジ測定エラー: {str(e)}", "medium")
        
        # カバレッジ評価
        global_coverage = coverage_data["line"]
        threshold = self.config["thresholds"]["coverage"]["global"]
        
        if global_coverage < threshold * COVERAGE_YELLOW_THRESHOLD:  # 70%
            self.results["level"] = "RED"
            self.results["result"] = "FAIL"
            self.add_issue("coverage", f"カバレッジが低すぎます: {global_coverage:.1f}%", "critical")
        elif global_coverage < threshold:
            if self.results["level"] == "GREEN":
                self.results["level"] = "YELLOW"
            self.add_issue("coverage", f"カバレッジが目標未達: {global_coverage:.1f}%", "high")
        
        self.results["metrics"]["coverage"] = coverage_data
        return coverage_data
    
    def check_code_complexity(self):
        """コードの複雑度をチェック"""
        print("🧮 コード複雑度をチェック中...")
        
        complexity_data = {
            "average": 0,
            "max": 0,
            "files_exceeded": []
        }
        
        # Pythonファイルの複雑度チェック
        py_files = list(Path(".").rglob("*.py"))
        complexities = []
        
        for file in py_files:
            if not self.should_exclude(str(file)):
                complexity = self.calculate_file_complexity(str(file))
                if complexity > 0:
                    complexities.append(complexity)
                    if complexity > self.config["thresholds"]["complexity"]["cyclomatic"]:
                        complexity_data["files_exceeded"].append({
                            "file": str(file),
                            "complexity": complexity
                        })
        
        if complexities:
            complexity_data["average"] = sum(complexities) / len(complexities)
            complexity_data["max"] = max(complexities)
        
        # 複雑度評価
        if complexity_data["max"] > self.config["thresholds"]["complexity"]["cyclomatic"] * 1.5:
            self.add_issue("complexity", 
                          f"非常に複雑なコードが存在: {complexity_data['max']}", 
                          "high")
        
        self.results["metrics"]["complexity"] = complexity_data
        return complexity_data
    
    def calculate_file_complexity(self, file_path):
        """ファイルの循環的複雑度を計算（簡易版）"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                
            complexity = 1
            # 制御構造をカウント
            control_patterns = [
                r'\bif\b', r'\belif\b', r'\bfor\b', r'\bwhile\b',
                r'\btry\b', r'\bexcept\b', r'\bcase\b', r'\bwhen\b'
            ]
            
            for pattern in control_patterns:
                complexity += len(re.findall(pattern, content))
                
            return complexity
            
        except Exception:
            return 0
    
    def check_security(self):
        """セキュリティチェック"""
        print("🔒 セキュリティをチェック中...")
        
        security_data = {
            "vulnerabilities": {
                "critical": 0,
                "high": 0,
                "medium": 0,
                "low": 0
            },
            "issues": []
        }
        
        # ハードコードされた秘密情報の検出
        secret_patterns = [
            (r'(?i)(api[_-]?key|apikey)\s*=\s*["\'][^"\']+["\']', "APIキー"),
            (r'(?i)(secret|password|passwd|pwd)\s*=\s*["\'][^"\']+["\']', "パスワード"),
            (r'(?i)(token)\s*=\s*["\'][^"\']+["\']', "トークン"),
        ]
        
        for root, dirs, files in os.walk("."):
            # 除外ディレクトリをスキップ
            dirs[:] = [d for d in dirs if not self.should_exclude(os.path.join(root, d))]
            
            for file in files:
                file_path = os.path.join(root, file)
                if file.endswith(('.py', '.js', '.ts', '.java')) and not self.should_exclude(file_path):
                    try:
                        with open(file_path, 'r', encoding='utf-8') as f:
                            content = f.read()
                            
                        for pattern, desc in secret_patterns:
                            if re.search(pattern, content):
                                security_data["vulnerabilities"]["high"] += 1
                                security_data["issues"].append({
                                    "file": file_path,
                                    "type": desc,
                                    "severity": "high"
                                })
                                
                    except Exception:
                        pass
        
        # セキュリティ評価
        thresholds = self.config["thresholds"]["security"]
        for severity in ["critical", "high", "medium", "low"]:
            if security_data["vulnerabilities"][severity] > thresholds[severity]:
                self.add_issue("security", 
                             f"{severity.upper()}セキュリティ問題: {security_data['vulnerabilities'][severity]}件",
                             severity)
                if severity in ["critical", "high"]:
                    self.results["result"] = "FAIL"
                    self.results["level"] = "RED"
        
        self.results["metrics"]["security"] = security_data
        return security_data
    
    def check_duplication(self):
        """コード重複をチェック"""
        print("📋 コード重複をチェック中...")
        
        duplication_data = {
            "percentage": 0,
            "duplicates": []
        }
        
        # 簡易的な重複検出（実際はより高度なツールを使用）
        file_hashes = {}
        total_lines = 0
        duplicate_lines = 0
        
        for root, dirs, files in os.walk("."):
            dirs[:] = [d for d in dirs if not self.should_exclude(os.path.join(root, d))]
            
            for file in files:
                file_path = os.path.join(root, file)
                if file.endswith(('.py', '.js', '.ts')) and not self.should_exclude(file_path):
                    try:
                        with open(file_path, 'r', encoding='utf-8') as f:
                            lines = f.readlines()
                            total_lines += len(lines)
                            
                            # 連続する行のハッシュを計算
                            for i in range(len(lines) - 5):
                                block = ''.join(lines[i:i+5])
                                block_hash = hash(block.strip())
                                
                                if block_hash in file_hashes:
                                    duplicate_lines += 5
                                else:
                                    file_hashes[block_hash] = file_path
                                    
                    except Exception:
                        pass
        
        if total_lines > 0:
            duplication_data["percentage"] = (duplicate_lines / total_lines) * 100
        
        # 重複評価
        if duplication_data["percentage"] > self.config["thresholds"]["duplication"]:
            self.add_issue("duplication",
                          f"コード重複率が高い: {duplication_data['percentage']:.1f}%",
                          "medium")
        
        self.results["metrics"]["duplication"] = duplication_data
        return duplication_data
    
    def should_exclude(self, path):
        """除外パターンに該当するかチェック"""
        for pattern in self.config["exclude"]:
            if fnmatch.fnmatch(path, pattern):
                return True
        return False
    
    def add_issue(self, category, message, severity):
        """問題を追加"""
        self.results["issues"].append({
            "category": category,
            "message": message,
            "severity": severity
        })
    
    def generate_report(self, format="markdown"):
        """レポートを生成"""
        if format == "markdown":
            return self.generate_markdown_report()
        elif format == "json":
            return json.dumps(self.results, indent=2, ensure_ascii=False)
        else:
            return str(self.results)
    
    def generate_markdown_report(self):
        """Markdown形式のレポートを生成"""
        level_emoji = {
            "GREEN": "🟢",
            "YELLOW": "🟡", 
            "RED": "🔴"
        }
        
        report = f"""# 品質チェックレポート

日時: {self.results['timestamp']}
結果: {level_emoji[self.results['level']]} {self.results['result']}

## サマリー
"""
        
        # メトリクスサマリー
        if "coverage" in self.results["metrics"]:
            cov = self.results["metrics"]["coverage"]["line"]
            emoji = "✅" if cov >= self.config["thresholds"]["coverage"]["global"] else "❌"
            report += f"- テストカバレッジ: {cov:.1f}% {emoji}\n"
        
        if "complexity" in self.results["metrics"]:
            comp = self.results["metrics"]["complexity"]
            emoji = "✅" if comp["max"] <= self.config["thresholds"]["complexity"]["cyclomatic"] else "❌"
            report += f"- コード複雑度: 平均 {comp['average']:.1f}, 最大 {comp['max']} {emoji}\n"
        
        if "security" in self.results["metrics"]:
            sec = self.results["metrics"]["security"]["vulnerabilities"]
            total = sum(sec.values())
            emoji = "✅" if total == 0 else "❌"
            report += f"- セキュリティ: {total}件の問題 {emoji}\n"
        
        if "duplication" in self.results["metrics"]:
            dup = self.results["metrics"]["duplication"]["percentage"]
            emoji = "✅" if dup <= self.config["thresholds"]["duplication"] else "❌"
            report += f"- コード重複: {dup:.1f}% {emoji}\n"
        
        # 問題詳細
        if self.results["issues"]:
            report += "\n## 検出された問題\n\n"
            
            # 重要度別に分類
            for severity in ["critical", "high", "medium", "low"]:
                issues = [i for i in self.results["issues"] if i["severity"] == severity]
                if issues:
                    report += f"### {severity.capitalize()}\n"
                    for issue in issues:
                        report += f"- [{issue['category']}] {issue['message']}\n"
                    report += "\n"
        
        # 推奨アクション
        report += "\n## 推奨アクション\n\n"
        if self.results["level"] == "RED":
            report += "- 🚨 重大な品質問題があります。即座の対応が必要です。\n"
        elif self.results["level"] == "YELLOW":
            report += "- ⚠️ 品質改善の余地があります。計画的に対応してください。\n"
        else:
            report += "- ✨ 品質基準を満たしています。この状態を維持してください。\n"
        
        return report
    
    def run_checks(self, check_types=None):
        """品質チェックを実行"""
        if check_types is None:
            check_types = ["coverage", "complexity", "security", "duplication"]
        
        print("🔍 品質チェックを開始します...\n")
        
        if "coverage" in check_types:
            self.check_test_coverage()
            
        if "complexity" in check_types:
            self.check_code_complexity()
            
        if "security" in check_types:
            self.check_security()
            
        if "duplication" in check_types:
            self.check_duplication()
        
        print("\n✅ 品質チェック完了\n")
        
        return self.results


def main():
    """メイン処理"""
    import argparse
    
    parser = argparse.ArgumentParser(description="コード品質チェックツール")
    parser.add_argument("--quick", action="store_true", 
                       help="クイックチェック（複雑度とセキュリティのみ）")
    parser.add_argument("--full", action="store_true",
                       help="フルチェック（すべての項目）")
    parser.add_argument("--ci", action="store_true",
                       help="CI用（エラー時に非ゼロ終了）")
    parser.add_argument("--format", choices=["markdown", "json"], default="markdown",
                       help="出力フォーマット")
    parser.add_argument("--output", help="出力ファイル")
    
    args = parser.parse_args()
    
    # チェックタイプの決定
    if args.quick:
        check_types = ["complexity", "security"]
    else:
        check_types = None  # すべて
    
    # チェック実行
    checker = QualityChecker()
    results = checker.run_checks(check_types)
    
    # レポート生成
    report = checker.generate_report(args.format)
    
    # 出力
    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            f.write(report)
        print(f"レポートを {args.output} に出力しました。")
    else:
        print(report)
    
    # CI モードでの終了コード
    if args.ci and results["result"] == "FAIL":
        return 1
    
    return 0


if __name__ == "__main__":
    sys.exit(main())