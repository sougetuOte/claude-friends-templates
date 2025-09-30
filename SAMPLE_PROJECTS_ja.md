# サンプルプロジェクト

🌐 **[English](SAMPLE_PROJECTS.md)** | **日本語**

このドキュメントでは、Claude Friends Templatesを使用して構築された実際の実装とサンプルプロジェクトを紹介します。これらの例は、テンプレートシステムのベストプラクティス、パターン、および実用的なアプリケーションを示しています。

---

## 📋 目次

- [はじめに](#はじめに)
- [サンプルプロジェクトギャラリー](#サンプルプロジェクトギャラリー)
- [ユースケース例](#ユースケース例)
- [実装パターン](#実装パターン)
- [コミュニティプロジェクト](#コミュニティプロジェクト)

---

## 🚀 はじめに

### クイックスタートテンプレート

最も早く始める方法は、基本的なテンプレート構造を使用することです：

```bash
# テンプレートをクローン
git clone https://github.com/sougetuOte/claude-friends-templates.git my-project
cd my-project

# プロジェクト用にカスタマイズ
# 1. README.mdをプロジェクト詳細で更新
# 2. .claude/agents/をワークフロー用に設定
# 3. .claude/scripts/のスクリプトを必要に応じて適応
```

### 最小セットアップ例

最小プロジェクトには以下が必要です：
- `.claude/agents/planner/identity.md` - 戦略計画エージェント
- `.claude/agents/builder/identity.md` - 実装エージェント
- `.claude/scripts/handover-generator.py` - コンテキスト引き継ぎ
- `README.md` - プロジェクトドキュメント

---

## 🎨 サンプルプロジェクトギャラリー

### 1. Webアプリケーションプロジェクト

**説明**: APIバックエンドとReactフロントエンドを持つフルスタックWebアプリケーション

**構造**:
```
my-web-app/
├── .claude/
│   ├── agents/
│   │   ├── planner/
│   │   │   └── identity.md (アーキテクチャ重視)
│   │   └── builder/
│   │       └── identity.md (実装重視)
│   ├── scripts/
│   │   ├── handover-generator.py
│   │   ├── quality-check.py
│   │   └── deploy.py
│   └── guidelines/
│       ├── api-design.md
│       └── frontend-patterns.md
├── backend/
│   ├── src/
│   ├── tests/
│   └── requirements.txt
├── frontend/
│   ├── src/
│   ├── tests/
│   └── package.json
└── docs/
    └── adr/
```

**主要機能**:
- フロントエンド/バックエンドのマルチエージェント協調
- pytestとjestによる自動品質チェック
- ロールバック機能付きデプロイ自動化
- ADR（アーキテクチャ決定記録）追跡

**エージェントワークフロー**:
1. Planner: API契約とコンポーネント構造を設計
2. Builder: バックエンドエンドポイントとReactコンポーネントを実装
3. Handover: JSON引き継ぎファイルでコンテキストを共有
4. Quality: 自動テスト、セキュリティスキャン、パフォーマンスチェック

### 2. CLIツールプロジェクト

**説明**: 豊富な機能と包括的なドキュメントを持つコマンドラインユーティリティ

**構造**:
```
my-cli-tool/
├── .claude/
│   ├── agents/
│   │   └── builder/ (CLIシンプル性のための単一エージェント)
│   ├── scripts/
│   │   ├── quality-check.py
│   │   └── sbom-generator.py
│   └── guidelines/
│       └── cli-ux.md
├── src/
│   ├── commands/
│   ├── utils/
│   └── main.py
├── tests/
├── docs/
└── setup.py
```

**主要機能**:
- 単一Builderエージェント（計画複雑性不要）
- argparse/clickによるリッチCLI
- サプライチェーンセキュリティのためのSBOM生成
- 包括的なテストカバレッジ（>90%）

**開発ワークフロー**:
1. `src/commands/`でコマンド構造を定義
2. Builderエージェントがテスト付きで実装
3. 品質チェック: bandit（セキュリティ）、pytest（テスト）、ruff（スタイル）
4. リリース前のSBOM生成

### 3. データサイエンスプロジェクト

**説明**: 実験追跡とモデルデプロイを備えた機械学習パイプライン

**構造**:
```
ml-pipeline/
├── .claude/
│   ├── agents/
│   │   ├── planner/ (実験設計)
│   │   └── builder/ (実装)
│   ├── scripts/
│   │   ├── handover-generator.py
│   │   ├── experiment-tracker.py
│   │   └── model-validator.py
│   └── guidelines/
│       ├── data-quality.md
│       └── model-evaluation.md
├── data/
│   ├── raw/
│   ├── processed/
│   └── features/
├── notebooks/
├── models/
├── src/
│   ├── preprocessing/
│   ├── training/
│   └── evaluation/
└── experiments/
    └── logs/
```

**主要機能**:
- Plannerが実験と評価メトリクスを設計
- Builderが前処理とトレーニングパイプラインを実装
- 実験追跡とモデル検証のためのカスタムスクリプト
- モデルアーキテクチャ決定のためのADR

**エージェントワークフロー**:
1. Planner: 実験設計、メトリクス定義、ADR作成
2. Builder: データパイプライン実装、モデルトレーニング
3. Validation: 自動モデル評価とパフォーマンスチェック
4. Handover: 実験結果と洞察を共有

### 4. ドキュメントサイトプロジェクト

**説明**: 自動生成とデプロイを備えた静的ドキュメントサイト

**構造**:
```
docs-site/
├── .claude/
│   ├── agents/
│   │   └── builder/
│   ├── scripts/
│   │   ├── api-docs-generator.py
│   │   └── deploy.py
│   └── guidelines/
│       └── documentation-standards.md
├── docs/
│   ├── api/
│   ├── guides/
│   └── tutorials/
├── src/ (APIドキュメント用のソースプロジェクト)
└── build/
```

**主要機能**:
- 単一Builderエージェント（ドキュメント重視）
- 自動APIドキュメント生成
- 静的サイトジェネレータによるMarkdown/MDX
- コミット時の継続的デプロイ

**開発ワークフロー**:
1. `docs/`にコンテンツを書く
2. Builderエージェントがレビューと改善提案
3. ソースコードからAPIドキュメント自動生成
4. デプロイスクリプトがホスティングプラットフォームに公開

---

## 💡 ユースケース例

### ユースケース 1: マイクロサービスアーキテクチャ

**シナリオ**: 複数の独立したサービスを持つマイクロサービスシステムの構築

**テンプレート適応**:
- マイクロサービスごとに1つのテンプレートインスタンス
- 親ディレクトリに共有ガイドライン
- API契約調整のためのクロスサービス引き継ぎ
- CI/CDによる一元化品質チェック

**ディレクトリ構造**:
```
microservices-project/
├── .claude-shared/
│   └── guidelines/
│       ├── api-contracts.md
│       └── security-standards.md
├── service-auth/
│   └── .claude/ (独立テンプレート)
├── service-users/
│   └── .claude/ (独立テンプレート)
└── service-orders/
    └── .claude/ (独立テンプレート)
```

### ユースケース 2: オープンソースライブラリ

**シナリオ**: コミュニティ貢献を伴うオープンソースPythonライブラリの維持

**テンプレート適応**:
- 貢献者向けの強化されたドキュメント
- 厳格な品質チェック（カバレッジ>90%）
- banditとpip-auditによるセキュリティスキャン
- 自動リリースプロセス

**主要なカスタマイズ**:
- 貢献ガイドライン付き`CONTRIBUTING.md`
- 自動リリース用`.claude/scripts/release.py`
- PRレビュー用`.claude/guidelines/code-review.md`
- CI/CDのためのGitHub Actions統合

### ユースケース 3: エンタープライズアプリケーション

**シナリオ**: コンプライアンス要件を持つ大規模エンタープライズアプリケーション

**テンプレート適応**:
- 追加のセキュリティ監査スクリプト
- コンプライアンスドキュメント（SOC2、GDPRなど）
- 監査証跡のための強化されたADRプロセス
- サプライチェーンセキュリティのためのSBOM生成

**主要なカスタマイズ**:
- `.claude/scripts/compliance-checker.py`
- `.claude/scripts/audit-logger.py`
- 規制ドキュメント用`docs/compliance/`
- 引き継ぎプロセスでの必須セキュリティレビュー

---

## 🔧 実装パターン

### パターン 1: テスト駆動開発（TDD）

claude-kiro-template統合とTask 6.4品質監査に基づく：

**Redフェーズ**:
```python
# tests/test_feature.py
def test_new_feature():
    """Test 1: 機能はXを実行すべき"""
    # Arrange
    input_data = create_test_data()

    # Act
    result = new_feature(input_data)

    # Assert
    assert result == expected_output
    # 期待: FAIL（機能未実装）
```

**Greenフェーズ**:
```python
# src/feature.py
def new_feature(input_data):
    """テストをパスする最小実装"""
    return expected_output
```

**Refactorフェーズ**:
```python
# src/feature.py
def new_feature(input_data):
    """本番環境対応実装"""
    # 改善されたアルゴリズム、エラーハンドリングなど
    return process_data(input_data)
```

**品質メトリクス**（Task 6.4.1結果に基づく）:
- **テストカバレッジ**: ≥90%（プロジェクト達成: 98.3%）
- **複雑度**: グレードB（6-10）以上を維持（プロジェクト: B/8.9）
- **保守性**: 全ファイルグレードA（プロジェクト: 100%）

### パターン 2: マルチエージェント引き継ぎ

**Plannerエージェント**（戦略的）:
```json
{
  "from_agent": "planner",
  "to_agent": "builder",
  "timestamp": "2025-09-30T10:00:00Z",
  "current_task": {
    "description": "ユーザー認証APIの実装",
    "requirements": [
      "JWTトークン生成",
      "bcryptによるパスワードハッシング",
      "レート制限"
    ],
    "architecture_decisions": {
      "adr_id": "ADR-001",
      "decision": "非同期サポートのためにFastAPIを使用"
    }
  },
  "blockers": []
}
```

**Builderエージェント**（実装）:
```json
{
  "from_agent": "builder",
  "to_agent": "planner",
  "timestamp": "2025-09-30T12:00:00Z",
  "completed_tasks": [
    "PyJWTによるJWTトークン生成",
    "bcryptによるパスワードハッシング",
    "レート制限ミドルウェア"
  ],
  "test_results": {
    "total": 15,
    "passed": 15,
    "coverage": "94%"
  },
  "next_recommendations": [
    "OAuth2サポート追加",
    "リフレッシュトークンローテーション実装"
  ]
}
```

### パターン 3: 自動品質ゲート

**プリコミットチェック**:
```bash
# .claude/scripts/pre-commit.sh
#!/bin/bash

# 全品質チェックを実行
python .claude/scripts/quality-check.py --strict

if [ $? -ne 0 ]; then
    echo "❌ 品質チェック失敗。コミット拒否。"
    exit 1
fi

echo "✅ 全品質チェック通過。"
```

**品質チェック設定**:
```python
# .claude/scripts/quality-check.py
QUALITY_THRESHOLDS = {
    "test_coverage": 90.0,      # 最小カバレッジ%
    "complexity": 10,            # 最大循環的複雑度
    "maintainability": 20,       # 最小MI スコア（グレードA）
    "security_issues": 0,        # 最大高/中レベル問題数
    "duplication": 5.0,          # 最大重複%
}
```

**強制**:
- プリコミットフックが低品質コミットをブロック
- CI/CDパイプラインがプルリクエストで強制
- 引き継ぎドキュメントでの自動レポート

---

## 🌟 コミュニティプロジェクト

### プロジェクトを投稿

Claude Friends Templatesで構築されたコミュニティプロジェクトを歓迎します！

**投稿ガイドライン**:
1. `community-projects/your-project-name.md`にショーケースドキュメントを作成
2. 含める内容:
   - プロジェクト説明
   - GitHubリポジトリリンク
   - 主要機能とカスタマイズ
   - スクリーンショット（オプション）
   - 学んだ教訓
3. プルリクエストを提出

**投稿例**:
```markdown
# プロジェクト名: CloudSync Manager

**著者**: @username
**リポジトリ**: https://github.com/username/cloudsync-manager
**カテゴリ**: CLIツール

## 説明
複数のクラウドストレージプロバイダー（AWS S3、Google Cloud Storage、Azure Blob Storage）間でファイルを同期するコマンドラインツール。

## 主要機能
- 統一インターフェースによるマルチクラウドサポート
- 変更検出による差分同期
- 進捗追跡とリトライロジック
- 包括的なテストカバレッジ（96%）

## テンプレートカスタマイズ
- 単一Builderエージェント（CLI重視）
- クラウドAPIモッキング付きカスタムquality-check.py
- サプライチェーンセキュリティのためのSBOM生成
- 自動リリースワークフロー

## 学んだ教訓
- TDDアプローチによりバグが80%削減
- 引き継ぎシステムが長時間セッション中の集中維持に貢献
- 品質ゲートが退行を防止
```

### 注目プロジェクト

近日公開！プロジェクトを投稿してここに掲載されましょう。

---

## 📚 追加リソース

### 学習パス

1. **初級**: CLIツールテンプレートから開始（単一エージェント、シンプルなワークフロー）
2. **中級**: Webアプリケーションテンプレートを試す（マルチエージェント、複雑な協調）
3. **上級**: マイクロサービスパターンを適応（分散システム、クロスサービス引き継ぎ）

### ベストプラクティス

以下については[BEST_PRACTICES.md](BEST_PRACTICES_ja.md)を参照:
- コード品質基準（Task 6.4メトリクス）
- TDD方法論（Red-Green-Refactor）
- セキュリティプラクティス（ゼロトラストモデル）
- パフォーマンス最適化ガイドライン

### アーキテクチャガイダンス

以下については[ARCHITECTURE.md](ARCHITECTURE_ja.md)を参照:
- システム概要とC4モデル
- モジュール構成（23の独立スクリプト）
- 依存関係分析（循環依存ゼロ）
- 設計パターン（Command、Strategy、Factory、Singleton）

### 品質メトリクス

Task 6.4最終品質監査（2025年9月）に基づく:
- **テスト成功**: 98.3%（295/300テスト）
- **コード複雑度**: 平均B（8.9）
- **アーキテクチャ**: 循環依存0件、100%モジュラー
- **パフォーマンス**: 350-450ms Handover生成
- **セキュリティ**: 高/中レベル脆弱性0件

---

## 🤝 貢献

サンプルプロジェクトやユースケースを共有したいですか？

1. このリポジトリを**フォーク**
2. `community-projects/`に新しいファイルを**作成**
3. ショーケース付きのプルリクエストを**提出**

詳細なガイドラインは[CONTRIBUTING.md](CONTRIBUTING.md)を参照してください。

---

## 📞 質問？

- **ディスカッション**: `sample-projects`ラベル付きでGitHub Discussionsを使用
- **問題報告**: `documentation`ラベルで問題を報告
- **メール**: dev@claude-friends-templates.localに連絡

**最終更新**: 2025年9月30日
**バージョン**: 2.0.0
