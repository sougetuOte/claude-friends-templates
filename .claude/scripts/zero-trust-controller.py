#!/usr/bin/env python3

"""
Zero Trust Access Controller
Zero Trust原則に基づくアクセス制御とセッション監視
2025年セキュリティベストプラクティス準拠
"""

import os
import json
import time
import hashlib
import logging
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
import uuid

@dataclass
class SecurityContext:
    """セキュリティコンテキスト"""
    session_id: str
    user_id: str
    risk_score: float
    last_activity: datetime
    authentication_level: str
    permissions: List[str]
    anomaly_flags: List[str]

class ZeroTrustController:
    """Zero Trust アクセス制御"""

    def __init__(self, config_path: str = ".claude/security-config.json"):
        self.config = self.load_config(config_path)
        self.sessions: Dict[str, SecurityContext] = {}
        self.access_log: List[Dict] = []
        self.setup_logging()

    def load_config(self, config_path: str) -> dict:
        """設定ファイルの読み込み"""
        if Path(config_path).exists():
            with open(config_path, 'r') as f:
                config = json.load(f)
                return config.get('zero_trust', {})

        # デフォルト設定
        return {
            "enabled": True,
            "access_control": {
                "principle": "least_privilege",
                "session_timeout": 3600,
                "verification_level": "continuous",
                "max_failed_attempts": 3,
                "lockout_duration": 300
            },
            "session_monitoring": {
                "enabled": True,
                "anomaly_detection": True,
                "log_level": "info",
                "alert_threshold": "medium"
            }
        }

    def setup_logging(self):
        """ログ設定"""
        log_level = getattr(logging, self.config.get('session_monitoring', {}).get('log_level', 'INFO').upper())
        logging.basicConfig(
            level=log_level,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('.claude/logs/zero-trust.log'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger('ZeroTrustController')

    def create_session(self, user_id: str, initial_permissions: List[str] = None) -> str:
        """新しいセッションを作成"""
        if not self.config.get('enabled', True):
            return "disabled"

        session_id = str(uuid.uuid4())

        context = SecurityContext(
            session_id=session_id,
            user_id=user_id,
            risk_score=0.0,
            last_activity=datetime.now(),
            authentication_level="basic",
            permissions=initial_permissions or [],
            anomaly_flags=[]
        )

        self.sessions[session_id] = context
        self.log_access("session_created", session_id, {"user_id": user_id})
        self.logger.info(f"Session created: {session_id} for user: {user_id}")

        return session_id

    def validate_session(self, session_id: str) -> Tuple[bool, Optional[SecurityContext]]:
        """セッションの有効性検証"""
        if not self.config.get('enabled', True):
            return True, None

        if session_id not in self.sessions:
            self.logger.warning(f"Invalid session access attempt: {session_id}")
            return False, None

        context = self.sessions[session_id]
        current_time = datetime.now()

        # セッションタイムアウトチェック
        timeout = self.config.get('access_control', {}).get('session_timeout', 3600)
        if (current_time - context.last_activity).seconds > timeout:
            self.terminate_session(session_id, "timeout")
            return False, None

        # リスクスコア評価
        self.evaluate_risk(context)

        # 異常検知
        if self.config.get('session_monitoring', {}).get('anomaly_detection', True):
            self.detect_anomalies(context)

        # 高リスクセッションの処理
        if context.risk_score > 0.8:
            self.logger.warning(f"High risk session detected: {session_id}, risk: {context.risk_score}")
            self.require_reauthentication(session_id)
            return False, context

        # アクティビティ更新
        context.last_activity = current_time
        return True, context

    def authorize_action(self, session_id: str, action: str, resource: str = None) -> bool:
        """アクション認可"""
        valid, context = self.validate_session(session_id)
        if not valid:
            return False

        # 最小権限原則の適用
        if not self.check_permission(context, action, resource):
            self.log_access("access_denied", session_id, {
                "action": action,
                "resource": resource,
                "reason": "insufficient_permissions"
            })
            return False

        self.log_access("access_granted", session_id, {
            "action": action,
            "resource": resource
        })
        return True

    def check_permission(self, context: SecurityContext, action: str, resource: str = None) -> bool:
        """権限チェック"""
        # 基本権限チェック
        if action in context.permissions:
            return True

        # リソース固有の権限チェック
        if resource:
            resource_permission = f"{action}:{resource}"
            if resource_permission in context.permissions:
                return True

        # 管理者権限チェック
        if "admin" in context.permissions:
            return True

        return False

    def evaluate_risk(self, context: SecurityContext):
        """リスクスコア評価"""
        risk_factors = []

        # 時間ベースのリスク
        current_hour = datetime.now().hour
        if current_hour < 6 or current_hour > 22:
            risk_factors.append(0.2)  # 深夜・早朝アクセス

        # アクティビティパターン分析
        recent_activities = [log for log in self.access_log
                           if log['session_id'] == context.session_id
                           and (datetime.now() - datetime.fromisoformat(log['timestamp'])).seconds < 300]

        if len(recent_activities) > 10:
            risk_factors.append(0.3)  # 高頻度アクティビティ

        # 異常フラグの数
        if context.anomaly_flags:
            risk_factors.append(len(context.anomaly_flags) * 0.1)

        # リスクスコア計算
        context.risk_score = min(sum(risk_factors), 1.0)

    def detect_anomalies(self, context: SecurityContext):
        """異常検知"""
        anomalies = []

        # 急激なアクティビティ増加
        recent_activities = [log for log in self.access_log
                           if log['session_id'] == context.session_id
                           and (datetime.now() - datetime.fromisoformat(log['timestamp'])).seconds < 60]

        if len(recent_activities) > 5:
            anomalies.append("rapid_activity")

        # 異常なリソースアクセスパターン
        recent_resources = [log.get('data', {}).get('resource')
                          for log in recent_activities
                          if log.get('data', {}).get('resource')]

        if len(set(recent_resources)) > 10:
            anomalies.append("resource_hopping")

        # 異常フラグの更新
        for anomaly in anomalies:
            if anomaly not in context.anomaly_flags:
                context.anomaly_flags.append(anomaly)
                self.logger.warning(f"Anomaly detected: {anomaly} for session: {context.session_id}")

    def require_reauthentication(self, session_id: str):
        """再認証要求"""
        if session_id in self.sessions:
            context = self.sessions[session_id]
            context.authentication_level = "reauthentication_required"
            self.log_access("reauthentication_required", session_id, {"reason": "high_risk"})

    def terminate_session(self, session_id: str, reason: str = "manual"):
        """セッション終了"""
        if session_id in self.sessions:
            context = self.sessions[session_id]
            self.log_access("session_terminated", session_id, {"reason": reason})
            del self.sessions[session_id]
            self.logger.info(f"Session terminated: {session_id}, reason: {reason}")

    def log_access(self, event_type: str, session_id: str, data: Dict = None):
        """アクセスログ記録"""
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "event_type": event_type,
            "session_id": session_id,
            "data": data or {}
        }

        self.access_log.append(log_entry)

        # ログファイルに保存
        log_file = Path(".claude/logs/access.log")
        log_file.parent.mkdir(parents=True, exist_ok=True)

        with open(log_file, "a") as f:
            f.write(json.dumps(log_entry) + "\n")

    def cleanup_expired_sessions(self):
        """期限切れセッションのクリーンアップ"""
        current_time = datetime.now()
        timeout = self.config.get('access_control', {}).get('session_timeout', 3600)

        expired_sessions = []
        for session_id, context in self.sessions.items():
            if (current_time - context.last_activity).seconds > timeout:
                expired_sessions.append(session_id)

        for session_id in expired_sessions:
            self.terminate_session(session_id, "timeout")

    def generate_security_report(self) -> Dict:
        """セキュリティレポート生成"""
        current_time = datetime.now()
        last_24h = current_time - timedelta(hours=24)

        recent_logs = [log for log in self.access_log
                      if datetime.fromisoformat(log['timestamp']) > last_24h]

        report = {
            "generated_at": current_time.isoformat(),
            "active_sessions": len(self.sessions),
            "last_24h_activities": len(recent_logs),
            "high_risk_sessions": len([s for s in self.sessions.values() if s.risk_score > 0.7]),
            "anomalies_detected": sum(len(s.anomaly_flags) for s in self.sessions.values()),
            "event_breakdown": {}
        }

        # イベント種別の集計
        for log in recent_logs:
            event_type = log['event_type']
            report['event_breakdown'][event_type] = report['event_breakdown'].get(event_type, 0) + 1

        return report

def main():
    """メイン処理（テスト用）"""
    controller = ZeroTrustController()

    # テストセッション作成
    session_id = controller.create_session("test_user", ["read", "write"])
    print(f"Created session: {session_id}")

    # セッション検証
    valid, context = controller.validate_session(session_id)
    print(f"Session valid: {valid}")

    # アクション認可テスト
    authorized = controller.authorize_action(session_id, "read", "test_resource")
    print(f"Action authorized: {authorized}")

    # セキュリティレポート生成
    report = controller.generate_security_report()
    print(f"Security report: {json.dumps(report, indent=2)}")

    # セッション終了
    controller.terminate_session(session_id)

if __name__ == "__main__":
    main()