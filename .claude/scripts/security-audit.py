#!/usr/bin/env python3

"""
Security Audit Script
セキュリティ脆弱性の自動検出と報告
"""

import os
import re
import json
import sys
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Tuple

class SecurityAuditor:
    def __init__(self, config_path: str = ".claude/security-config.json"):
        self.issues = {"critical": [], "high": [], "medium": [], "low": []}
        self.stats = {"files_scanned": 0, "issues_found": 0}
        self.config = self.load_config(config_path)
        
    def load_config(self, config_path: str) -> dict:
        """設定ファイルの読み込み"""
        default_config = {
            "scan": {
                "exclude": ["node_modules", "vendor", ".git", "__pycache__", "dist", "build"],
                "include": ["src", "lib", "api", "app"]
            },
            "checks": {
                "secrets": True,
                "sql_injection": True,
                "xss": True,
                "path_traversal": True,
                "command_injection": True,
                "permissions": True
            },
            "severity_threshold": "medium"
        }
        
        if Path(config_path).exists():
            with open(config_path, 'r') as f:
                return json.load(f)
        return default_config
    
    def scan_file(self, filepath: Path) -> None:
        """ファイルのセキュリティスキャン"""
        self.stats["files_scanned"] += 1
        
        try:
            with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
                filename = str(filepath)
                
                # 各種セキュリティチェック
                if self.config["checks"].get("secrets", True):
                    self.check_secrets(content, filename)
                    
                if self.config["checks"].get("sql_injection", True):
                    self.check_sql_injection(content, filename)
                    
                if self.config["checks"].get("xss", True):
                    self.check_xss(content, filename)
                    
                if self.config["checks"].get("path_traversal", True):
                    self.check_path_traversal(content, filename)
                    
                if self.config["checks"].get("command_injection", True):
                    self.check_command_injection(content, filename)
                    
                if self.config["checks"].get("permissions", True):
                    self.check_file_permissions(filepath, filename)
                    
        except Exception as e:
            print(f"Error scanning {filepath}: {e}", file=sys.stderr)
    
    def check_secrets(self, content: str, filename: str) -> None:
        """秘密情報の検出"""
        patterns = [
            # APIキー系
            (r'["\']?api[_-]?key["\']?\s*[:=]\s*["\'][a-zA-Z0-9]{32,}["\']', "critical", "APIキーがハードコードされています"),
            (r'["\']?secret[_-]?key["\']?\s*[:=]\s*["\'][a-zA-Z0-9]{32,}["\']', "critical", "シークレットキーが露出しています"),
            (r'["\']?token["\']?\s*[:=]\s*["\'][a-zA-Z0-9]{32,}["\']', "critical", "トークンがハードコードされています"),
            
            # AWS関連
            (r'AKIA[0-9A-Z]{16}', "critical", "AWS Access Key IDが検出されました"),
            # 40文字の文字列は誤検出が多いためコメントアウト
            # (r'[a-zA-Z0-9/+=]{40}', "high", "AWS Secret Access Keyの可能性があります"),
            
            # パスワード
            (r'password\s*=\s*["\'][^"\']+["\']', "high", "パスワードがハードコードされています"),
            (r'passwd\s*=\s*["\'][^"\']+["\']', "high", "パスワードがハードコードされています"),
            
            # JWT
            (r'eyJ[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+', "high", "JWTトークンが露出しています"),
            
            # プライベートキー
            (r'-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----', "critical", "秘密鍵が含まれています"),
        ]
        
        for pattern, severity, message in patterns:
            matches = re.finditer(pattern, content, re.IGNORECASE)
            for match in matches:
                self.add_issue(severity, filename, message, match.group(0)[:50] + "...")
    
    def check_sql_injection(self, content: str, filename: str) -> None:
        """SQLインジェクション脆弱性の検出"""
        patterns = [
            (r'query\s*=\s*["\'].*\+.*["\']', "high", "動的SQLクエリの構築（SQLインジェクションリスク）"),
            (r'execute\(["\'].*%s.*["\'].*%', "medium", "パラメータ化されていないSQLクエリ"),
            (r'SELECT.*FROM.*WHERE.*\+', "high", "文字列連結によるSQL構築"),
            (r'f["\']SELECT.*\{.*\}', "high", "f-stringによるSQL構築（危険）"),
        ]
        
        for pattern, severity, message in patterns:
            if re.search(pattern, content, re.IGNORECASE):
                self.add_issue(severity, filename, message)
    
    def check_xss(self, content: str, filename: str) -> None:
        """XSS脆弱性の検出"""
        patterns = [
            (r'innerHTML\s*=\s*[^;]+user', "high", "ユーザー入力をinnerHTMLに直接設定（XSSリスク）"),
            (r'document\.write\([^)]*request', "high", "document.writeにユーザー入力（XSSリスク）"),
            (r'eval\([^)]*request', "critical", "eval()にユーザー入力（危険）"),
            (r'<script>.*\$\{.*\}.*</script>', "high", "テンプレート内でのスクリプト埋め込み"),
        ]
        
        for pattern, severity, message in patterns:
            if re.search(pattern, content, re.IGNORECASE):
                self.add_issue(severity, filename, message)
    
    def check_path_traversal(self, content: str, filename: str) -> None:
        """パストラバーサル脆弱性の検出"""
        patterns = [
            (r'open\([^)]*request\.(GET|POST|params)', "high", "ユーザー入力によるファイルパス指定"),
            (r'readFile.*request\.', "high", "ユーザー入力によるファイル読み込み"),
            (r'\.\./', "medium", "相対パスの使用（パストラバーサルの可能性）"),
            (r'path\.join\([^)]*request', "medium", "ユーザー入力によるパス結合"),
        ]
        
        for pattern, severity, message in patterns:
            if re.search(pattern, content, re.IGNORECASE):
                self.add_issue(severity, filename, message)
    
    def check_command_injection(self, content: str, filename: str) -> None:
        """コマンドインジェクション脆弱性の検出"""
        patterns = [
            (r'os\.system\([^)]*\+', "critical", "os.systemで文字列連結（コマンドインジェクション）"),
            (r'subprocess\.(call|run|Popen)\([^)]*shell=True', "high", "shell=Trueの使用（危険）"),
            (r'exec\([^)]*request', "critical", "exec()にユーザー入力（非常に危険）"),
            (r'eval\([^)]*input', "critical", "eval()にユーザー入力（非常に危険）"),
        ]
        
        for pattern, severity, message in patterns:
            if re.search(pattern, content, re.IGNORECASE):
                self.add_issue(severity, filename, message)
    
    def check_file_permissions(self, filepath: Path, filename: str) -> None:
        """ファイル権限のチェック"""
        try:
            stat_info = filepath.stat()
            mode = oct(stat_info.st_mode)[-3:]
            
            if mode == "777":
                self.add_issue("high", filename, "ファイル権限が777（全員に全権限）")
            elif mode[2] == "7":
                self.add_issue("medium", filename, f"その他ユーザーに書き込み権限（{mode}）")
        except:
            pass
    
    def add_issue(self, severity: str, filename: str, message: str, detail: str = "") -> None:
        """問題を記録"""
        issue = {
            "file": filename,
            "message": message,
            "detail": detail,
            "timestamp": datetime.now().isoformat()
        }
        self.issues[severity].append(issue)
        self.stats["issues_found"] += 1
    
    def scan_directory(self, path: str = ".") -> None:
        """ディレクトリを再帰的にスキャン"""
        root_path = Path(path)
        
        for filepath in root_path.rglob("*"):
            # 除外パターンのチェック
            if any(exclude in str(filepath) for exclude in self.config["scan"]["exclude"]):
                continue
                
            # ファイルのみスキャン
            if filepath.is_file():
                # 対象拡張子のみ
                if filepath.suffix in ['.py', '.js', '.ts', '.java', '.php', '.rb', '.go', '.c', '.cpp', '.sh', '.yml', '.yaml', '.json', '.xml', '.html']:
                    self.scan_file(filepath)
    
    def generate_report(self) -> str:
        """レポート生成"""
        report = []
        report.append("# セキュリティ監査レポート\n")
        report.append(f"日時: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        report.append(f"スキャン対象: {os.getcwd()}\n")
        
        # Critical
        if self.issues["critical"]:
            report.append("## 🔴 Critical（即座に対応が必要）")
            for issue in self.issues["critical"]:
                report.append(f"- **{issue['file']}**: {issue['message']}")
                if issue['detail']:
                    report.append(f"  詳細: `{issue['detail']}`")
            report.append("")
        
        # High
        if self.issues["high"]:
            report.append("## 🟠 High（早急に対応）")
            for issue in self.issues["high"]:
                report.append(f"- **{issue['file']}**: {issue['message']}")
            report.append("")
        
        # Medium
        if self.issues["medium"]:
            report.append("## 🟡 Medium（計画的に対応）")
            for issue in self.issues["medium"]:
                report.append(f"- **{issue['file']}**: {issue['message']}")
            report.append("")
        
        # Low
        if self.issues["low"]:
            report.append("## 🟢 Low（改善推奨）")
            for issue in self.issues["low"]:
                report.append(f"- **{issue['file']}**: {issue['message']}")
            report.append("")
        
        # 統計
        report.append("## 統計")
        report.append(f"- スキャンファイル数: {self.stats['files_scanned']}")
        report.append(f"- 検出された問題: {self.stats['issues_found']}")
        report.append(f"  - Critical: {len(self.issues['critical'])}")
        report.append(f"  - High: {len(self.issues['high'])}")
        report.append(f"  - Medium: {len(self.issues['medium'])}")
        report.append(f"  - Low: {len(self.issues['low'])}")
        
        return "\n".join(report)
    
    def save_report(self, output_path: str = ".claude/security-report.md") -> None:
        """レポートをファイルに保存"""
        report = self.generate_report()
        Path(output_path).parent.mkdir(parents=True, exist_ok=True)
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(report)
        print(f"レポートを保存しました: {output_path}")

def main():
    """メイン処理"""
    auditor = SecurityAuditor()
    
    # スキャン実行
    print("セキュリティスキャンを開始します...")
    auditor.scan_directory()
    
    # レポート生成
    report = auditor.generate_report()
    print("\n" + report)
    
    # レポート保存
    auditor.save_report()
    
    # 終了コード（Critical/Highがあれば1）
    if auditor.issues["critical"] or auditor.issues["high"]:
        sys.exit(1)
    sys.exit(0)

if __name__ == "__main__":
    main()