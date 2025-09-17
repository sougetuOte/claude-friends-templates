#!/usr/bin/env python3

"""
Security Manager
統合セキュリティ管理システム
Zero Trust、SBOM、SAST、入力検証、DevSecOpsの統合管理
"""

import os
import json
import sys
import argparse
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional
import logging

# モジュールのインポート
def safe_import_module(module_name, class_name):
    """安全なモジュールインポート"""
    try:
        module_path = Path(__file__).parent / f"{module_name}.py"
        if module_path.exists():
            spec = importlib.util.spec_from_file_location(module_name, module_path)
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)
            return getattr(module, class_name)
    except Exception as e:
        logging.warning(f"Could not import {class_name} from {module_name}: {e}")
    return None

# 動的インポート
import importlib.util
ZeroTrustController = safe_import_module("zero-trust-controller", "ZeroTrustController")
SBOMGenerator = safe_import_module("sbom-generator", "SBOMGenerator")
InputValidator = safe_import_module("input-validator", "InputValidator")

class SecurityManager:
    """統合セキュリティマネージャー"""

    def __init__(self, config_path: str = ".claude/security-config.json"):
        self.config_path = config_path
        self.config = self.load_config()
        self.setup_logging()

        # サブシステムの初期化
        self.zero_trust = ZeroTrustController(config_path) if ZeroTrustController else None
        self.sbom_generator = SBOMGenerator(config_path) if SBOMGenerator else None
        self.input_validator = InputValidator(config_path) if InputValidator else None

        self.security_status = {
            "zero_trust": False,
            "sbom": False,
            "sast": False,
            "input_validation": False,
            "devsecops": False
        }

    def load_config(self) -> dict:
        """設定ファイルの読み込み"""
        if Path(self.config_path).exists():
            with open(self.config_path, 'r') as f:
                return json.load(f)

        # デフォルト設定を生成
        default_config = {
            "enabled": True,
            "auto_initialize": True,
            "log_level": "INFO",
            "security_policy": {
                "zero_trust_required": True,
                "sbom_required": True,
                "sast_required": True,
                "input_validation_required": True,
                "min_security_score": 80
            }
        }

        # 設定ファイルを作成
        Path(self.config_path).parent.mkdir(parents=True, exist_ok=True)
        with open(self.config_path, 'w') as f:
            json.dump(default_config, f, indent=2)

        return default_config

    def setup_logging(self):
        """ログ設定"""
        log_level = getattr(logging, self.config.get('log_level', 'INFO'))
        logging.basicConfig(
            level=log_level,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('.claude/logs/security-manager.log'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger('SecurityManager')

    def initialize_security_systems(self) -> Dict[str, bool]:
        """セキュリティシステムの初期化"""
        results = {}

        self.logger.info("🔒 セキュリティシステム初期化開始...")

        # Zero Trust初期化
        if self.zero_trust:
            try:
                # テストセッション作成で動作確認
                test_session = self.zero_trust.create_session("system_init", ["read"])
                if test_session != "disabled":
                    self.zero_trust.terminate_session(test_session, "init_test")
                    results["zero_trust"] = True
                    self.logger.info("✅ Zero Trust システム初期化完了")
                else:
                    results["zero_trust"] = False
                    self.logger.warning("⚠️ Zero Trust システムが無効化されています")
            except Exception as e:
                results["zero_trust"] = False
                self.logger.error(f"❌ Zero Trust 初期化失敗: {e}")
        else:
            results["zero_trust"] = False

        # SBOM生成器初期化
        if self.sbom_generator:
            try:
                # 簡易テスト
                test_components = len(self.sbom_generator.components)
                results["sbom"] = True
                self.logger.info("✅ SBOM生成器初期化完了")
            except Exception as e:
                results["sbom"] = False
                self.logger.error(f"❌ SBOM生成器初期化失敗: {e}")
        else:
            results["sbom"] = False

        # 入力検証初期化
        if self.input_validator:
            try:
                # テスト検証
                test_result = self.input_validator.validate_input("test input")
                results["input_validation"] = test_result.is_valid
                self.logger.info("✅ 入力検証システム初期化完了")
            except Exception as e:
                results["input_validation"] = False
                self.logger.error(f"❌ 入力検証初期化失敗: {e}")
        else:
            results["input_validation"] = False

        # SAST初期化確認
        sast_script = Path(".claude/scripts/security-audit.py")
        if sast_script.exists():
            results["sast"] = True
            self.logger.info("✅ SAST システム確認完了")
        else:
            results["sast"] = False
            self.logger.warning("⚠️ SAST スクリプトが見つかりません")

        # DevSecOps CI/CD確認
        workflow_file = Path(".github/workflows/security-scan.yml")
        if workflow_file.exists():
            results["devsecops"] = True
            self.logger.info("✅ DevSecOps パイプライン確認完了")
        else:
            results["devsecops"] = False
            self.logger.warning("⚠️ DevSecOps ワークフローが見つかりません")

        self.security_status.update(results)
        return results

    def run_full_security_scan(self) -> Dict:
        """フルセキュリティスキャンの実行"""
        self.logger.info("🔍 フルセキュリティスキャン開始...")

        scan_results = {
            "timestamp": datetime.now().isoformat(),
            "scan_type": "full",
            "results": {},
            "summary": {
                "total_issues": 0,
                "critical_issues": 0,
                "high_issues": 0,
                "medium_issues": 0,
                "low_issues": 0
            },
            "security_score": 0
        }

        # SAST実行
        try:
            self.logger.info("📊 SAST解析実行中...")
            os.system("cd .claude && python scripts/security-audit.py")
            scan_results["results"]["sast"] = {"status": "completed", "issues": []}
        except Exception as e:
            scan_results["results"]["sast"] = {"status": "failed", "error": str(e)}

        # SBOM生成
        if self.sbom_generator:
            try:
                self.logger.info("📋 SBOM生成中...")
                self.sbom_generator.analyze_project()
                sbom_path = self.sbom_generator.save_sbom()
                summary = self.sbom_generator.generate_summary_report()

                scan_results["results"]["sbom"] = {
                    "status": "completed",
                    "path": sbom_path,
                    "components": summary["total_components"],
                    "vulnerabilities": summary.get("vulnerabilities", {})
                }
            except Exception as e:
                scan_results["results"]["sbom"] = {"status": "failed", "error": str(e)}

        # Zero Trust状態確認
        if self.zero_trust:
            try:
                report = self.zero_trust.generate_security_report()
                scan_results["results"]["zero_trust"] = {
                    "status": "completed",
                    "active_sessions": report["active_sessions"],
                    "high_risk_sessions": report["high_risk_sessions"],
                    "anomalies": report["anomalies_detected"]
                }
            except Exception as e:
                scan_results["results"]["zero_trust"] = {"status": "failed", "error": str(e)}

        # 入力検証レポート
        if self.input_validator:
            try:
                report = self.input_validator.generate_security_report()
                scan_results["results"]["input_validation"] = {
                    "status": "completed",
                    "violations": report.get("total_violations", 0),
                    "high_risk_violations": report.get("high_risk_violations", 0)
                }
            except Exception as e:
                scan_results["results"]["input_validation"] = {"status": "failed", "error": str(e)}

        # セキュリティスコア計算
        scan_results["security_score"] = self.calculate_security_score(scan_results)

        # 結果保存
        self.save_scan_results(scan_results)

        self.logger.info(f"🎯 フルセキュリティスキャン完了 - スコア: {scan_results['security_score']}/100")
        return scan_results

    def calculate_security_score(self, scan_results: Dict) -> int:
        """セキュリティスコアの計算"""
        base_score = 100
        deductions = 0

        # 各システムの状態に基づく減点
        for system, status in self.security_status.items():
            if not status:
                if system == "zero_trust":
                    deductions += 25
                elif system == "sbom":
                    deductions += 20
                elif system == "sast":
                    deductions += 20
                elif system == "input_validation":
                    deductions += 15
                elif system == "devsecops":
                    deductions += 10

        # スキャン結果に基づく減点
        results = scan_results.get("results", {})

        # SBOM脆弱性による減点
        sbom_result = results.get("sbom", {})
        if sbom_result.get("status") == "completed":
            vulnerabilities = sbom_result.get("vulnerabilities", {})
            deductions += vulnerabilities.get("vulnerable", 0) * 5

        # Zero Trust高リスクセッションによる減点
        zt_result = results.get("zero_trust", {})
        if zt_result.get("status") == "completed":
            deductions += zt_result.get("high_risk_sessions", 0) * 3

        # 入力検証違反による減点
        iv_result = results.get("input_validation", {})
        if iv_result.get("status") == "completed":
            deductions += iv_result.get("high_risk_violations", 0) * 2

        final_score = max(0, base_score - deductions)
        return final_score

    def save_scan_results(self, results: Dict):
        """スキャン結果の保存"""
        output_dir = Path(".claude/security/scan-results")
        output_dir.mkdir(parents=True, exist_ok=True)

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_file = output_dir / f"security_scan_{timestamp}.json"

        with open(output_file, 'w') as f:
            json.dump(results, f, indent=2, ensure_ascii=False)

        # 最新結果としてシンボリックリンク作成
        latest_link = output_dir / "latest.json"
        if latest_link.exists():
            latest_link.unlink()
        latest_link.symlink_to(output_file.name)

        self.logger.info(f"📄 スキャン結果保存: {output_file}")

    def validate_security_policy(self) -> Dict[str, bool]:
        """セキュリティポリシーの検証"""
        policy = self.config.get("security_policy", {})
        violations = {}

        # 必須システムのチェック
        if policy.get("zero_trust_required", True) and not self.security_status["zero_trust"]:
            violations["zero_trust_missing"] = True

        if policy.get("sbom_required", True) and not self.security_status["sbom"]:
            violations["sbom_missing"] = True

        if policy.get("sast_required", True) and not self.security_status["sast"]:
            violations["sast_missing"] = True

        if policy.get("input_validation_required", True) and not self.security_status["input_validation"]:
            violations["input_validation_missing"] = True

        # 最新スキャン結果の確認
        latest_scan = Path(".claude/security/scan-results/latest.json")
        if latest_scan.exists():
            with open(latest_scan, 'r') as f:
                scan_data = json.load(f)

            min_score = policy.get("min_security_score", 80)
            if scan_data.get("security_score", 0) < min_score:
                violations["security_score_below_threshold"] = True

        return violations

    def generate_security_dashboard(self) -> str:
        """セキュリティダッシュボードの生成"""
        dashboard_content = []

        dashboard_content.append("# Claude Friends Templates セキュリティダッシュボード")
        dashboard_content.append(f"\n**最終更新**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

        # システム状態
        dashboard_content.append("\n## 🛡️ セキュリティシステム状態")
        for system, status in self.security_status.items():
            icon = "✅" if status else "❌"
            system_name = {
                "zero_trust": "Zero Trust アクセス制御",
                "sbom": "SBOM生成・脆弱性管理",
                "sast": "静的アプリケーションセキュリティテスト",
                "input_validation": "入力検証・プロンプトインジェクション対策",
                "devsecops": "DevSecOps CI/CD統合"
            }.get(system, system)

            dashboard_content.append(f"- {icon} **{system_name}**: {'有効' if status else '無効'}")

        # 最新スキャン結果
        latest_scan = Path(".claude/security/scan-results/latest.json")
        if latest_scan.exists():
            with open(latest_scan, 'r') as f:
                scan_data = json.load(f)

            dashboard_content.append("\n## 📊 最新セキュリティスキャン結果")
            dashboard_content.append(f"- **セキュリティスコア**: {scan_data.get('security_score', 'N/A')}/100")
            dashboard_content.append(f"- **スキャン日時**: {scan_data.get('timestamp', 'N/A')}")

            # 各システムの詳細
            results = scan_data.get("results", {})
            for system, result in results.items():
                status_icon = "✅" if result.get("status") == "completed" else "❌"
                dashboard_content.append(f"  - {status_icon} {system}: {result.get('status', 'unknown')}")

        # ポリシー違反
        violations = self.validate_security_policy()
        if violations:
            dashboard_content.append("\n## ⚠️ ポリシー違反")
            for violation, present in violations.items():
                if present:
                    dashboard_content.append(f"- ❌ {violation}")
        else:
            dashboard_content.append("\n## ✅ ポリシー準拠")
            dashboard_content.append("セキュリティポリシーに準拠しています。")

        # 推奨アクション
        dashboard_content.append("\n## 🎯 推奨アクション")
        disabled_systems = [k for k, v in self.security_status.items() if not v]
        if disabled_systems:
            dashboard_content.append("以下のシステムの有効化を推奨します:")
            for system in disabled_systems:
                dashboard_content.append(f"- {system}")
        else:
            dashboard_content.append("現在、特別なアクションは必要ありません。")

        dashboard_content.append("\n---")
        dashboard_content.append("🤖 *Claude Friends Templates Security Manager*")

        return "\n".join(dashboard_content)

    def save_dashboard(self) -> str:
        """ダッシュボードの保存"""
        dashboard_content = self.generate_security_dashboard()
        dashboard_path = Path(".claude/security/dashboard.md")
        dashboard_path.parent.mkdir(parents=True, exist_ok=True)

        with open(dashboard_path, 'w', encoding='utf-8') as f:
            f.write(dashboard_content)

        return str(dashboard_path)

def main():
    """メイン処理"""
    parser = argparse.ArgumentParser(description="Claude Friends Templates Security Manager")
    parser.add_argument('action', choices=['init', 'scan', 'dashboard', 'status'],
                       help='実行するアクション')
    parser.add_argument('--config', default='.claude/security-config.json',
                       help='設定ファイルのパス')

    args = parser.parse_args()

    manager = SecurityManager(args.config)

    if args.action == 'init':
        print("🔒 セキュリティシステム初期化...")
        results = manager.initialize_security_systems()
        for system, status in results.items():
            icon = "✅" if status else "❌"
            print(f"{icon} {system}: {'成功' if status else '失敗'}")

    elif args.action == 'scan':
        print("🔍 フルセキュリティスキャン実行...")
        results = manager.run_full_security_scan()
        print(f"セキュリティスコア: {results['security_score']}/100")

    elif args.action == 'dashboard':
        print("📊 セキュリティダッシュボード生成...")
        dashboard_path = manager.save_dashboard()
        print(f"ダッシュボード保存: {dashboard_path}")

    elif args.action == 'status':
        print("📋 セキュリティシステム状態:")
        for system, status in manager.security_status.items():
            icon = "✅" if status else "❌"
            print(f"  {icon} {system}: {'有効' if status else '無効'}")

        violations = manager.validate_security_policy()
        if violations:
            print("\n⚠️ ポリシー違反:")
            for violation in violations:
                print(f"  - {violation}")
        else:
            print("\n✅ ポリシー準拠")

if __name__ == "__main__":
    main()