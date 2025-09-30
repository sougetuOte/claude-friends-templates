# Claude Friends Templatesへの貢献

🌐 **[English](CONTRIBUTING.md)** | **日本語**

Claude Friends Templatesへの貢献に興味を持っていただきありがとうございます！このドキュメントは、プロジェクトへの貢献に関するガイドラインと手順を提供します。

---

## 📋 目次

- [行動規範](#行動規範)
- [はじめに](#はじめに)
- [開発ワークフロー](#開発ワークフロー)
- [コーディング基準](#コーディング基準)
- [テストガイドライン](#テストガイドライン)
- [ドキュメントガイドライン](#ドキュメントガイドライン)
- [変更の提出](#変更の提出)
- [レビュープロセス](#レビュープロセス)

---

## 🤝 行動規範

このプロジェクトは[行動規範](CODE_OF_CONDUCT_ja.md)に従います。参加することにより、このコードを遵守することが期待されます。許容できない行動は conduct@claude-friends-templates.local に報告してください。

---

## 🚀 はじめに

### 前提条件

- **Python**: 3.12以上
- **Git**: バージョン管理用
- **GitHubアカウント**: プルリクエスト提出用

### 開発環境のセットアップ

```bash
# 1. リポジトリをフォークしてクローン
git clone https://github.com/YOUR_USERNAME/claude-friends-templates.git
cd claude-friends-templates

# 2. フィーチャーブランチを作成
git checkout -b feature/your-feature-name

# 3. 開発依存関係をインストール（オプション）
pip install -r requirements-dev.txt  # テストツールが必要な場合

# 4. インストールを確認
python .claude/scripts/quality-check.py --help
```

### プロジェクト構造

```
claude-friends-templates/
├── .claude/
│   ├── agents/        # エージェントIDファイル
│   ├── scripts/       # 自動化スクリプト
│   ├── guidelines/    # 開発ガイドライン
│   └── tests/         # テストスイート
├── docs/              # ドキュメント
├── memo/              # メモリーバンクシステム
└── README.md          # プロジェクトドキュメント
```

---

## 🔄 開発ワークフロー

### 1. イシューを選択

- [オープンイシュー](https://github.com/sougetuOte/claude-friends-templates/issues)を閲覧
- `good first issue`または`help wanted`ラベルのイシューを探す
- イシューにコメントして担当を宣言

### 2. フィーチャーブランチを作成

```bash
git checkout -b feature/issue-123-description
```

ブランチ命名規則:
- `feature/` - 新機能
- `fix/` - バグ修正
- `docs/` - ドキュメント変更
- `refactor/` - コードリファクタリング
- `test/` - テスト追加または改善

### 3. 変更を行う

[TDD方法論](BEST_PRACTICES_ja.md#tdd方法論)に従う:

**Redフェーズ**（失敗するテストを書く）:
```python
# tests/test_new_feature.py
def test_new_feature():
    """Test 1: 機能はXを実行すべき"""
    result = new_feature(input_data)
    assert result == expected_output
    # 期待: FAIL
```

**Greenフェーズ**（最小限のコードを実装）:
```python
# .claude/scripts/new_feature.py
def new_feature(input_data):
    """最小実装"""
    return expected_output
```

**Refactorフェーズ**（コード品質を改善）:
```python
# .claude/scripts/new_feature.py
def new_feature(input_data):
    """本番環境対応実装"""
    # クリーンで保守可能なコード
    return process_data(input_data)
```

### 4. 品質チェックを実行

```bash
# 全品質チェックを実行
python .claude/scripts/quality-check.py --strict

# 個別チェック
pytest tests/                    # テスト実行
bandit -r .claude/scripts/       # セキュリティスキャン
ruff check .                     # リンティング
mypy .claude/scripts/            # 型チェック
```

### 5. 変更をコミット

```bash
# 変更をステージング
git add .

# 説明的なメッセージでコミット
git commit -m "feat: 新機能Xを追加

- YでX機能を実装
- Zのテストを追加
- ドキュメントを更新

Fixes #123"
```

**コミットメッセージ形式**:
```
<type>: <subject>

<body>

<footer>
```

**Types**:
- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメント変更
- `refactor`: コードリファクタリング
- `test`: テスト変更
- `chore`: ビルド/ツール変更

---

## 💻 コーディング基準

### Pythonコード品質

[Task 6.4品質監査](memo/2025-09-30/task-6-4-1-final-quality-report.md)に基づく:

**維持すべきメトリクス**:
- **テストカバレッジ**: ≥90%（プロジェクト: 98.3%）
- **循環的複雑度**: グレードB（6-10）以上（プロジェクト: 8.9）
- **保守性指標**: グレードA（20-100）（プロジェクト: 100%）
- **セキュリティ**: 高/中レベル問題0件

### コードスタイル

```python
# ✅ 良い例: 明確、型付き、文書化
def generate_handover(
    from_agent: str,
    to_agent: str,
    max_tokens: int = 2000
) -> dict[str, Any]:
    """エージェント間の引き継ぎドキュメントを生成。

    Args:
        from_agent: ソースエージェント名
        to_agent: ターゲットエージェント名
        max_tokens: コンテキストの最大トークン数

    Returns:
        辞書形式の引き継ぎドキュメント

    Raises:
        ValueError: エージェント名が無効な場合
    """
    # エラーハンドリング付き実装
    pass

# ❌ 悪い例: 型なし、ドキュメントなし
def gen(a, b):
    return {}
```

### アーキテクチャ原則

[ARCHITECTURE.md](ARCHITECTURE_ja.md)より:

1. **循環依存ゼロ**: ✅ 0サイクルを維持
2. **モジュール独立性**: ✅ 内部スクリプト依存なし
3. **標準ライブラリのみ**: ✅ 外部依存を避ける
4. **クリーンなレイヤー分離**: ✅ Scripts → Tests（一方向）

---

## 🧪 テストガイドライン

### テスト構造

```python
# tests/test_feature.py
import pytest

class TestFeature:
    """テストスイート: 機能の機能性"""

    @pytest.fixture
    def setup_data(self):
        """フィクスチャ: テストデータセットアップ"""
        return {"key": "value"}

    def test_basic_functionality(self, setup_data):
        """Test 1: 基本機能が動作する"""
        # Arrange
        input_data = setup_data

        # Act
        result = feature_function(input_data)

        # Assert
        assert result is not None
        assert "expected_key" in result
```

### テストカテゴリ

- **ユニットテスト**: 個別関数のテスト
- **統合テスト**: コンポーネント相互作用
- **E2Eテスト**: 完全なワークフローシナリオ
- **パフォーマンステスト**: 速度とメモリベンチマーク

### テストの実行

```bash
# 全テスト
pytest tests/ -v

# 特定のテストファイル
pytest tests/test_feature.py -v

# カバレッジ付き
pytest tests/ --cov=.claude/scripts --cov-report=html

# E2Eテストのみ
pytest tests/e2e/ -v -m e2e
```

---

## 📚 ドキュメントガイドライン

### バイリンガルドキュメント

すべてのルートレベルドキュメントは**バイリンガル必須**:

```
README.md         ← 英語（主要）
README_ja.md      ← 日本語（同期）
```

**同期要件**:
- 同一のセクション構造
- 同等のコンテンツ（直訳ではない）
- 同じリンクと参照
- 同じPRで一緒に更新

### ドキュメントタイプ

1. **APIドキュメント**: docstringから生成
2. **ユーザーガイド**: ステップバイステップの手順
3. **アーキテクチャドキュメント**: システム設計とパターン
4. **ADR**: `docs/adr/`のアーキテクチャ決定記録

### 執筆スタイル

- **明確かつ簡潔**: 短い文、能動態
- **コード例**: 動作する例を提供
- **視覚的補助**: 図表、表、コードブロック
- **相互参照**: 関連ドキュメントへのリンク

---

## 📤 変更の提出

### 提出前

**チェックリスト**:
- [ ] すべてのテストがパス（pytest）
- [ ] コードがリンティングをパス（ruff）
- [ ] セキュリティスキャンがクリーン（bandit）
- [ ] 新しいコードのカバレッジ≥90%
- [ ] ドキュメント更新（該当する場合、EN/JA両方）
- [ ] コミットメッセージが規則に従う
- [ ] デバッグコードやコメントなし

### プルリクエストの作成

1. **フォークにプッシュ**:
```bash
git push origin feature/your-feature-name
```

2. **GitHubでプルリクエストを開く**:
- タイトル: `feat: 機能Xを追加`（コミット規則に従う）
- 説明: 何を、なぜ、どのように説明
- 参照: 関連イシューをリンク（`Fixes #123`）
- チェックリスト: 上記のチェックリストを含める

3. **PRテンプレート**:
```markdown
## 説明
変更の簡単な説明

## 動機
この変更はなぜ必要ですか？

## 変更内容
- 変更1
- 変更2

## テスト
どのようにテストされましたか？

## チェックリスト
- [ ] テストパス
- [ ] ドキュメント更新
- [ ] コードレビュー済み
```

---

## 🔍 レビュープロセス

### レビュータイムライン

- **初回レビュー**: 48時間以内
- **フォローアップ**: 更新後24時間以内
- **承認**: 1人以上のメンテナーの承認が必要

### レビュー基準

レビュアーは以下をチェックします:

1. **機能性**: 意図通りに動作するか？
2. **テスト**: テストは包括的か？
3. **コード品質**: 基準を満たしているか？
4. **ドキュメント**: 文書化されているか？
5. **アーキテクチャ**: 設計に適合しているか？

### フィードバックへの対応

```bash
# 要求された変更を行う
git add .
git commit -m "fix: レビューフィードバックに対応"
git push origin feature/your-feature-name
```

### マージプロセス

承認後:
1. メンテナーがPRをマージ
2. フィーチャーブランチが削除される
3. 変更が`main`に表示される

---

## 🎯 貢献領域

### 優先領域

1. **テスト**: テストカバレッジの改善（現在: 98.3%）
2. **ドキュメント**: バイリンガル同期と例
3. **パフォーマンス**: 最適化の機会
4. **セキュリティ**: 強化されたセキュリティ機能

### 初めてのイシュー

以下のラベルのイシューを探してください:
- `good first issue`
- `documentation`
- `help wanted`
- `enhancement`

---

## 📞 ヘルプを受ける

### コミュニケーションチャネル

- **GitHubイシュー**: バグレポート、機能リクエスト
- **GitHubディスカッション**: 質問、アイデア、一般的な議論
- **メール**: dev@claude-friends-templates.local

### リソース

- [ベストプラクティス](BEST_PRACTICES_ja.md) - コード品質ガイドライン
- [アーキテクチャ](ARCHITECTURE_ja.md) - システム設計
- [サンプルプロジェクト](SAMPLE_PROJECTS_ja.md) - 実装例
- [セキュリティポリシー](SECURITY_ja.md) - セキュリティガイドライン

---

## 🏆 認識

貢献者は以下で認識されます:
- [AUTHORS.md](AUTHORS.md) - すべての貢献者
- リリースノート - 各リリースごと
- GitHub貢献者ページ

---

## 📜 ライセンス

貢献することにより、あなたの貢献が[MITライセンス](LICENSE)の下でライセンスされることに同意したことになります。

---

## 🙏 ありがとうございます！

あなたの貢献は、このプロジェクトをみんなにとってより良いものにします。あなたの時間と努力に感謝します！

**質問？** イシューやディスカッションを開いてください - お手伝いします！

---

**最終更新**: 2025年9月30日
**バージョン**: 2.0.0
