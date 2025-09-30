# アーキテクチャ概要

🌐 **日本語** | **[English](ARCHITECTURE.md)**

本ドキュメントは、2025年9月に実施された分析に基づく、Claude Friends Templatesのアーキテクチャの包括的な概要を提供します。

---

## 📋 目次

- [システム概要](#システム概要)
- [アーキテクチャ原則](#アーキテクチャ原則)
- [モジュール構成](#モジュール構成)
- [依存関係分析](#依存関係分析)
- [設計パターン](#設計パターン)
- [品質メトリクス](#品質メトリクス)

---

## 🏗️ システム概要

Claude Friends Templatesは、循環依存ゼロと100%モジュラー設計を特徴とする、クリーンアーキテクチャ原則に基づいて構築されたマルチエージェントAI開発システムです。

### C4モデル - コンテキストレベル

```
┌─────────────────────────────────────────────────────┐
│           Claude Friends Templates System            │
│                                                       │
│  ┌─────────────────────────────────────────────┐   │
│  │         .claude/scripts/ (CLIツール)         │   │
│  │                                               │   │
│  │  ┌──────────────┐  ┌──────────────┐         │   │
│  │  │   Handover   │  │   Quality    │         │   │
│  │  │  Management  │  │  Assurance   │         │   │
│  │  └──────────────┘  └──────────────┘         │   │
│  │                                               │   │
│  │  ┌──────────────┐  ┌──────────────┐         │   │
│  │  │   Security   │  │  Deployment  │         │   │
│  │  │   Analysis   │  │  Automation  │         │   │
│  │  └──────────────┘  └──────────────┘         │   │
│  └─────────────────────────────────────────────┘   │
│                                                       │
│  ┌─────────────────────────────────────────────┐   │
│  │        .claude/tests/ (テストスイート)       │   │
│  │   E2Eテスト | ユニットテスト | 統合テスト     │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
           ↓ 依存関係（標準ライブラリのみ）
┌─────────────────────────────────────────────────────┐
│             Python 3.12 標準ライブラリ               │
│   json | pathlib | typing | datetime | argparse     │
└─────────────────────────────────────────────────────┘
```

---

## 🎯 アーキテクチャ原則

### 1. 循環依存ゼロ

**達成**: ✅ 全23スクリプトで **循環依存0件**

**利点**:
- 独立したモジュール開発
- 分離されたテスト
- 明確な変更影響範囲
- 柔軟なデプロイ

### 2. 完全なモジュール独立性

**達成**: ✅ スクリプト間で **内部依存なし**

全スクリプトが完全に独立 - `.claude/scripts/`内のどのスクリプトも他のスクリプトをインポートしません。

### 3. 標準ライブラリのみ

**達成**: ✅ **100% Python標準ライブラリ依存**

**外部依存**: なし（コア機能に対して）

**利点**:
- セキュリティリスクの低減
- メンテナンス負荷の軽減
- 最大の互換性
- 依存関係の競合なし

### 4. クリーンなレイヤー分離

**達成**: ✅ **レイヤー違反ゼロ**

```
Scriptsレイヤー  →  使用可能: 標準ライブラリ
                    使用不可: Tests

Testsレイヤー   →  使用可能: Scripts、標準ライブラリ
                    使用不可: なし（最上位レイヤー）
```

---

## 📦 モジュール構成

### モジュール責務マトリックス

| カテゴリ | スクリプト | 主要責務 | 結合度 |
|---------|----------|---------|--------|
| **Handover** | handover-generator.py | コンテキスト生成と圧縮 | 中 (14) |
| | handover-generator-optimized.py | 最適化された生成 | 中 (14) |
| | state_synchronizer.py | 状態同期 | 低 (6) |
| **Quality** | quality-check.py | 包括的品質チェック | 中 (9) |
| | quality-metrics.py | メトリクス収集 | 低 (8) |
| | refactoring-analyzer.py | リファクタリング分析 | 低 (6) |
| | design-drift-detector.py | 設計乖離検出 | 低 (5) |
| **Security** | security-manager.py | セキュリティ管理 | 低 (8) |
| | security-audit.py | 監査実行 | 低 (6) |
| | vulnerability-scanner.py | 脆弱性スキャン | 中 (9) |
| | input-validator.py | 入力検証 | 中 (10) |
| | zero-trust-controller.py | ゼロトラスト制御 | 低 (7) |
| **Deployment** | deploy.py | デプロイ自動化 | 中 (11) |
| | sbom-generator.py | SBOM生成 | 中 (9) |
| **Documentation** | api-docs-generator.py | APIドキュメント生成 | 中 (9) |
| **Logging** | ai_logger.py | AI最適化ログ | 中 (10) |
| | log_analysis_tool.py | ログ分析 | 低 (7) |
| | analyze-ai-logs.py | AI駆動分析 | 低 (5) |
| | error_pattern_learning.py | エラーパターン学習 | 低 (5) |
| | log_agent_event.py | エージェントイベントログ | 低 (3) |
| **Analysis** | task_parallelization_analyzer.py | 並列化分析 | 中 (11) |
| **Utility** | python312_features.py | Python 3.12機能 | 低 (3) |
| | \_\_init\_\_.py | パッケージ初期化 | 低 (0) |

**総モジュール数**: 23の独立スクリプト

---

## 🔗 依存関係分析

### 結合度分布

インポート数分析に基づく（2025年9月）:

```
低結合（≤8インポート）:   13/23 (56%) ✅ 優秀
中結合（9-15インポート）:  10/23 (43%) ✅ 良好
高結合（>15インポート）:    0/23 (0%)  ✅ 完璧
```

### 外部依存使用状況

最も使用される標準ライブラリモジュールトップ15:

| ライブラリ | 使用回数 | カテゴリ |
|-----------|---------|---------|
| json | 19スクリプト | データシリアライゼーション |
| pathlib | 19スクリプト | ファイル操作 |
| typing | 17スクリプト | 型ヒント |
| datetime | 16スクリプト | 時間操作 |
| sys | 14スクリプト | システム操作 |
| argparse | 12スクリプト | CLI解析 |
| re | 10スクリプト | 正規表現 |
| os | 10スクリプト | OS操作 |
| dataclasses | 9スクリプト | データ構造 |
| uuid | 6スクリプト | 一意識別子 |
| subprocess | 5スクリプト | プロセス管理 |
| collections | 4スクリプト | データ構造 |
| logging | 4スクリプト | ログ記録 |
| fnmatch | 3スクリプト | パターンマッチング |
| hashlib | 3スクリプト | ハッシング |

**観察**: 全依存関係がPython標準ライブラリ - 外部パッケージ不要

---

## 🎨 設計パターン

### 適用されたパターン

#### 1. Commandパターン
**場所**: [api-docs-generator.py](/.claude/scripts/api-docs-generator.py)

**実装**:
```python
def _handle_schema_generation(generator, args) -> int:
    """スキーマ生成のコマンドハンドラ"""
    if args.input and args.output:
        success = generator.generate_openapi_schema(...)
        return 0 if success else 1
    return -1  # 処理されない
```

**効果**: 複雑度をE (51+) → B (6-10)に削減

#### 2. Strategyパターン
**場所**: [handover-generator.py](/.claude/scripts/handover-generator.py)

**実装**: コンテンツサイズに基づく圧縮戦略選択

```python
def compress_context(self, content: str, max_tokens: int) -> str:
    """サイズに基づいて圧縮戦略を適用"""
    if len(content.split()) > max_tokens:
        return self._apply_compression(content)
    return content  # 圧縮不要
```

#### 3. Factory Methodパターン
**場所**: [ai_logger.py](/.claude/scripts/ai_logger.py)

**実装**: ロガーインスタンスの作成と設定

```python
def get_logger(name: str) -> AILogger:
    """設定済みロガー作成のファクトリメソッド"""
    logger = AILogger(name)
    logger.configure_handlers()
    return logger
```

#### 4. Singletonパターン（暗黙的）
**場所**: 全CLIスクリプト

**実装**: `if __name__ == "__main__":` による単一エントリポイント

**効果**: 並行実行の制御

---

## 📊 品質メトリクス

### アーキテクチャ品質スコア

| メトリクス | 目標 | 実績 | ステータス |
|-----------|------|------|----------|
| 循環依存 | 0 | 0 | ✅ 完璧 |
| レイヤー違反 | 0 | 0 | ✅ 完璧 |
| 低結合モジュール | >40% | 56% | ✅ 優秀 |
| 中結合モジュール | <60% | 43% | ✅ 良好 |
| 高結合モジュール | 0 | 0 | ✅ 完璧 |
| 外部依存 | 最小限 | 0外部 | ✅ 優秀 |
| モジュール独立性 | 100% | 100% | ✅ 完璧 |

**総合アーキテクチャ評価**: ✅ **A+（模範的）**

### コード品質メトリクス

| メトリクス | 目標 | 実績 | ステータス |
|-----------|------|------|----------|
| 平均複雑度 | グレードB | B (8.9) | ✅ 達成 |
| 保守性指標 | グレードA | 100% A | ✅ 完璧 |
| テスト成功率 | ≥95% | 98.3% | ✅ 優秀 |
| セキュリティ問題 | 0 High/Med | 0 | ✅ 完璧 |

---

## 🔄 データフロー

### Handover生成フロー

```
ユーザーリクエスト
    ↓
handover-generator.py
    ↓
1. get_current_task() → プロジェクトファイル読み取り
    ↓
2. extract_recent_activities() → Gitログ解析
    ↓
3. extract_blockers() → エラーログ分析
    ↓
4. compress_context() → 必要に応じて圧縮適用
    ↓
5. create_handover_document() → JSON生成
    ↓
Handoverファイル（JSON）
```

### 品質チェックフロー

```
ユーザーリクエスト
    ↓
quality-check.py
    ↓
├─ check_code_complexity() → radon
├─ check_test_coverage() → pytest-cov
├─ check_security() → bandit
└─ check_duplication() → jscpd
    ↓
結果集約
    ↓
generate_markdown_report()
    ↓
品質レポート（Markdown）
```

---

## 🚀 パフォーマンス特性

### 実行時間（本番環境）

| 操作 | 実績 | 目標 | ステータス |
|-----|------|------|----------|
| Handover生成 | 350-450ms | <500ms | ✅ |
| 品質チェック | 500-800ms | <1000ms | ✅ |
| セキュリティスキャン | 400-600ms | <1000ms | ✅ |
| デプロイ | 1-2s | <5s | ✅ |

### メモリ使用量

- **ピークメモリ**: 5.04 MB ✅（目標: <50MB）
- **平均メモリ**: 3-5 MB ✅
- **メモリリーク**: 0件検出 ✅

---

## 🎯 将来のアーキテクチャ検討事項

### Phase 7以降の機能強化

1. **Adapterパターン導入**
   - 目的: 外部ライブラリ統合の抽象化
   - 優先度: 低（外部依存追加時のみ）

2. **アーキテクチャテスト**
   - ツール: pytest-archtest
   - 目的: レイヤー違反の自動検出
   - 優先度: 中

3. **依存関係の可視化**
   - ツール: CI/CD統合付きpydeps
   - 目的: 定期的な依存関係グラフ生成
   - 優先度: 低

### メンテナンスガイドライン

**維持すべき点**:
- ✅ スクリプトの独立性（相互参照なし）
- ✅ 標準ライブラリのみの使用
- ✅ 低〜中結合レベル
- ✅ レイヤー分離の遵守

**避けるべき点**:
- ❌ 循環依存の導入
- ❌ 正当な理由のない外部依存の追加
- ❌ 高結合の作成（>15インポート）
- ❌ レイヤー違反（scriptsがtestsをインポート）

---

## 📚 参考資料

- **品質監査**: `memo/2025-09-30/task-6-4-1-final-quality-report.md`を参照
- **アーキテクチャ分析**: `memo/2025-09-30/task-6-4-2-architecture-analysis.md`を参照
- **パフォーマンスプロファイリング**: `memo/2025-09-30/task-6-4-3-performance-profiling.md`を参照

---

## 📞 質問？

- **アーキテクチャ議論**: `architecture`ラベル付きでGitHub Discussionsを使用
- **設計提案**: RFC（Request for Comments）イシューを作成
- **技術サポート**: dev@claude-friends-templates.localへメール

**最終更新**: 2025年9月30日
**バージョン**: 2.0.0
