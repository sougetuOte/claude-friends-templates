# Claude Friends Templates ベストプラクティス

🌐 **日本語** | **[English](BEST_PRACTICES.md)**

本ガイドは、本番環境での実践経験と品質メトリクスに基づいた、Claude Friends Templatesでの開発ベストプラクティスを提供します。

---

## 📋 目次

- [コード品質基準](#コード品質基準)
- [テスト駆動開発（TDD）](#テスト駆動開発tdd)
- [アーキテクチャ原則](#アーキテクチャ原則)
- [パフォーマンスガイドライン](#パフォーマンスガイドライン)
- [セキュリティベストプラクティス](#セキュリティベストプラクティス)
- [ドキュメント基準](#ドキュメント基準)
- [Gitワークフロー](#gitワークフロー)

---

## 🎯 コード品質基準

### 複雑度メトリクス

品質監査（2025年9月）に基づき、以下の基準を維持します：

- **循環的複雑度**: 関数を **グレードB（6-10）** 以下に保つ
- **保守性指標**: 全ファイルで **グレードA（20-100）** を達成
- **プロジェクト平均複雑度**: **B（8.9）** 以下を目標

**現在の達成状況**: ✅ 23/23スクリプトがグレードA保守性を維持

### コードスタイル

**ruff**を使用して一貫したフォーマットを維持：

```bash
# コードをフォーマット
ruff format .claude/

# スタイルチェック
ruff check .claude/ --select I
```

**基準**:
- インポート順序: 標準ライブラリ → サードパーティ → ローカル
- 行長: 100文字（可読性のため88から緩和）
- 型ヒント: Python 3.12+ネイティブ型を使用（`Dict`ではなく`dict`、`List`ではなく`list`）

### 静的解析

コミット前に包括的な静的解析を実行：

```bash
# 型チェック
mypy .claude/scripts/ --ignore-missing-imports

# 複雑度分析
radon cc .claude/scripts/ -a -nb

# 保守性指標
radon mi .claude/scripts/ -s
```

**目標スコア**:
- Radon CC: 平均グレードB以上
- Radon MI: 全ファイルグレードA
- Mypy: 新規コードで型エラー0件

---

## 🔴 テスト駆動開発（TDD）

### t-wada式Red-Green-Refactorサイクル

厳格なTDD規律に従います：

#### 🔴 Redフェーズ: 失敗するテストを先に書く
```python
def test_handover_generation():
    """handoverドキュメント生成のテスト"""
    generator = HandoverGenerator("planner", "builder")
    result = generator.create_handover_document()
    assert result is not None
    assert "current_task" in result
```

#### 🟢 Greenフェーズ: テストを通す
```python
def create_handover_document(self):
    return {
        "current_task": self.get_current_task(),
        "recent_activities": self.extract_recent_activities()
    }
```

#### 🔵 Refactorフェーズ: コード品質を改善
- 複雑度<10のためにメソッド抽出
- 設計パターン適用（Command、Strategy、Factory）
- 全テストが引き続き通過することを確認

### テストカバレッジ基準

**現在の達成状況**（2025年9月）:
- **テスト成功率**: 98.3%（295/300テスト通過）
- **E2Eテスト**: 56/56通過（100%）
- **ユニットテスト**: 239/244通過（98%）

**ガイドライン**:
- **クリティカルパス**: 90%以上のカバレッジ
- **新機能**: 80%以上のカバレッジ
- **エッジケース**: エラー条件の明示的なテストケース

### テスト構成

```
.claude/tests/
├── e2e/              # エンドツーエンド統合テスト
│   ├── test_e2e_performance.py
│   └── test_e2e_bash_integration.bats
├── unit/             # 個別モジュールのユニットテスト
│   ├── test_ai_logger.py
│   └── test_handover_generator.py
└── bats/             # bashスクリプトのBATSテスト
    └── test_hooks.bats
```

---

## 🏛️ アーキテクチャ原則

### モジュラー独立性

**達成**: 循環依存0件、100%モジュラー設計

**原則**:
1. **単一責任**: 各スクリプトは明確な目的を1つ持つ
2. **内部依存なし**: スクリプトは相互にインポートしない
3. **標準ライブラリのみ**: 可能な限り外部依存を回避

### 結合度基準

インポート数分析に基づく：

- **低結合（≤8インポート）**: ✅ 理想的（コードベースの56%）
- **中結合（9-15インポート）**: ✅ 許容範囲（コードベースの43%）
- **高結合（>15インポート）**: ❌ 回避（0%達成）

### レイヤー分離

```
┌─────────────────────────────────────┐
│   .claude/scripts/ (CLIツール)      │  ← testsへの依存なし
├─────────────────────────────────────┤
│   .claude/tests/ (テストスイート)   │  ← scriptsからインポート可
├─────────────────────────────────────┤
│   Python標準ライブラリ              │  ← 唯一の外部依存
└─────────────────────────────────────┘
```

**ルール**: スクリプトはtestsディレクトリからインポートしてはならない

---

## ⚡ パフォーマンスガイドライン

### 応答時間目標

本番環境ベンチマーク（2025年9月）に基づく：

| 操作 | 目標 | 現状 |
|-----|------|------|
| フック応答 | < 100ms | 86.368ms (p95) ✅ |
| Handover生成 | < 500ms | 350-450ms ✅ |
| 状態同期 | < 650ms | 400-600ms ✅ |
| 全操作 | < 500ms | ✅ 達成 |

### メモリ効率

- **ピークメモリ**: < 50MB目標、**5MB達成** ✅
- **メモリリーク**: ゼロ許容、**0件検出** ✅

### 最適化優先順位

1. **re.compile**: モジュールレベルで正規表現をプリコンパイル
2. **lru_cache**: 高コストな計算をキャッシュ
3. **ジェネレータ式**: 大規模データセットに使用
4. **文字列結合**: `+=`連結ではなく`"".join(list)`を使用

**例**:
```python
import re
from functools import lru_cache

# 正規表現のプリコンパイル（モジュールレベル）
PATTERN = re.compile(r'[a-zA-Z0-9]+')

@lru_cache(maxsize=128)
def expensive_operation(param: str) -> str:
    """繰り返し呼び出しの結果をキャッシュ"""
    return PATTERN.search(param)
```

---

## 🔒 セキュリティベストプラクティス

### 脆弱性管理

**現在の状況**（2025年9月）:
- **高リスク**: 0件の脆弱性 ✅
- **中リスク**: 0件の脆弱性 ✅
- **セキュリティ監査**: 全スクリプトがグレードA評価

### 入力検証

常にユーザー入力を検証およびサニタイズ：

```python
import tempfile
from pathlib import Path

# ✅ 良い: 安全な一時ディレクトリを使用
temp_dir = tempfile.mkdtemp(prefix="validation_")

# ❌ 悪い: ハードコードされたパス
# temp_dir = "/tmp/validation"  # B108脆弱性
```

### セキュリティスキャン

各リリース前に実行：

```bash
# Banditセキュリティスキャン
bandit -r .claude/ -f json

# 依存関係の脆弱性
pip-audit --requirement requirements.txt

# SBOM生成
python .claude/scripts/sbom-generator.py --format cyclonedx
```

**ゼロ許容**: マージ前に全ての高・中重要度問題を修正

---

## 📝 ドキュメント基準

### バイリンガル同期

英語版と日本語版を同期維持：

- `README.md` ↔ `README_ja.md`
- `SECURITY.md` ↔ `SECURITY_ja.md`
- 全ての主要ドキュメントに `*_ja.md` ペアを用意

**同期チェックリスト**:
- [ ] 同じセクション構造
- [ ] 同じヘッダー階層
- [ ] 内容の等価性（逐語訳ではない）
- [ ] 両バージョンでリンク更新

### Docstring基準

Googleスタイルのdocstringを使用：

```python
def create_handover_document(
    self,
    from_agent: str,
    to_agent: str
) -> dict[str, Any]:
    """エージェント遷移のためのhandoverドキュメントを作成。

    Args:
        from_agent: ソースエージェント名（例: "planner"）
        to_agent: ターゲットエージェント名（例: "builder"）

    Returns:
        以下のキーを含むhandover情報の辞書:
        - current_task: 現在のタスク説明
        - recent_activities: 最近のアクションのリスト
        - blockers: 既知のブロッカーまたは問題

    Raises:
        ValueError: エージェント名が無効な場合
    """
```

### コードコメント

- **理由を説明、処理内容ではない**: 推論を説明し、明白な操作は説明しない
- **TODOs**: `# TODO(username): 説明`形式を使用
- **パフォーマンスノート**: 最適化の決定を文書化

---

## 🌿 Gitワークフロー

### コミットメッセージ形式

Conventional Commitsに従う：

```
<type>(<scope>): <subject>

<body>

<footer>
```

**タイプ**:
- `feat`: 新機能
- `fix`: バグ修正
- `refactor`: コード再構成
- `test`: テスト追加・修正
- `docs`: ドキュメント変更
- `perf`: パフォーマンス改善
- `chore`: メンテナンスタスク

**例**:
```
feat(handover): 大規模コンテキストの圧縮を追加

コンテンツがmax_tokens閾値を超えた場合にzlibを使用した
コンテキスト圧縮を実装。平均でhandoverサイズを40%削減。

Refs: #123
```

### ブランチ戦略

- `main`: 本番対応コード
- `develop`: 統合ブランチ
- `feature/*`: 新機能
- `fix/*`: バグ修正
- `refactor/*`: コード改善

### プルリクエストチェックリスト

- [ ] 全テスト通過（98%以上の成功率）
- [ ] コードカバレッジ維持（新規コードで80%以上）
- [ ] 静的解析通過（mypy、ruff、bandit）
- [ ] ドキュメント更新（該当する場合はバイリンガル）
- [ ] CHANGELOG.md更新

---

## 📊 品質メトリクスダッシュボード

これらのメトリクスを継続的に監視：

| メトリクス | 目標 | 現状 | ステータス |
|-----------|------|------|----------|
| テスト成功率 | ≥95% | 98.3% | ✅ |
| コード複雑度 | グレードB | B (8.9) | ✅ |
| 保守性 | グレードA | 100% A | ✅ |
| 循環依存 | 0 | 0 | ✅ |
| セキュリティ問題 | 0 High/Med | 0 | ✅ |
| パフォーマンス | <500ms | 350-450ms | ✅ |

**最終更新**: 2025年9月30日

---

## 🎓 学習リソース

- [Clean Code](https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882) by Robert C. Martin
- [Test Driven Development](https://www.amazon.com/Test-Driven-Development-Kent-Beck/dp/0321146530) by Kent Beck
- [OWASP Secure Coding Practices](https://owasp.org/www-project-secure-coding-practices-quick-reference-guide/)
- [Python Best Practices](https://docs.python-guide.org/)

---

## 📞 質問？

- **一般的な議論**: GitHub Discussionsを使用
- **バグ報告**: `bug`ラベル付きでイシューを作成
- **セキュリティ問題**: security@claude-friends-templates.localへメール

**覚えておいてください**: 品質は行為ではなく、習慣である。- アリストテレス
