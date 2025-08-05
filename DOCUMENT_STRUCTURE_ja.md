# ドキュメント構造概要

🌐 **[English](DOCUMENT_STRUCTURE.md)** | **日本語**

## 📁 整理原則

このプロジェクトは**役割別のドキュメント整理**に従います：

### .claude/guidelines/
**目的**: 日常開発のクイックリファレンス  
**対象者**: プロジェクトで積極的に作業する開発者  
**特徴**: 簡潔、実用的、頻繁に参照

### docs/
**目的**: 詳細な仕様、ルール、正式なドキュメント  
**対象者**: 新しいチームメンバー、レビュアー、アーキテクト  
**特徴**: 包括的、権威的、バージョン管理

### memo/
**目的**: 作業メモ、分析結果、一時的なドキュメント  
**対象者**: プロジェクトメンテナー、特定タスクオーナー  
**特徴**: 非公式、進化中、タスク固有

## 📋 ドキュメントマッピング

### 開発ガイドライン

| トピック | クイックリファレンス | 詳細ドキュメント |
|---------|-------------------|----------------|
| **開発ルール** | `.claude/guidelines/development.md` | `docs/development-rules.md` |
| **Gitワークフロー** | `.claude/guidelines/git-workflow.md` | 権威ソース |
| **テストと品質** | `.claude/guidelines/testing-quality.md` | 権威ソース |
| **AI親和開発** | `.claude/guidelines/ai-friendly-development.md` | 権威ソース |

### セキュリティとフック

| トピック | 設定 | ドキュメント |
|---------|------|------------|
| **セキュリティ** | `.claude/settings.json` | `.claude/security-README.md` |
| **フック** | `.claude/hooks.yaml` | `.claude/hooks-README.md` |
| **AIロガー** | `.claude/scripts/ai-logger.sh` | `.claude/ai-logger-README.md` |

### プロジェクトドキュメント

| ドキュメントタイプ | 場所 | 目的 |
|----------------|------|------|
| **要件定義** | `docs/requirements/index.md` | プロジェクト仕様 |
| **ADRテンプレート** | `docs/adr/template.md` | アーキテクチャ決定 |
| **はじめに** | `docs/GETTING_STARTED.md` | オンボーディングガイド |
| **例** | `examples/` | サンプル実装 |

### 移行と導入

| ガイド | 場所 | 対象者 |
|-------|------|--------|
| **v2.0移行** | `MIGRATION_GUIDE.md` | 既存のClaude Friendsユーザー |
| **段階的導入** | `memo/gradual-adoption-guide.md` | Memory Bank初心者プロジェクト |
| **ゼロからMemory Bank** | `memo/zero-to-memory-bank.md` | 完全な初心者 |

## 🔍 情報の見つけ方

### 「〜したい」場合

- **コミット形式を素早く確認** → `.claude/guidelines/git-workflow.md`
- **すべての開発ルールを理解** → `docs/development-rules.md`
- **新しいプロジェクトを設定** → `docs/GETTING_STARTED.md`
- **セキュリティフックを追加** → `.claude/security-README.md`
- **TDDについて学ぶ** → `.claude/guidelines/testing-quality.md`
- **アーキテクチャ決定を行う** → `docs/adr/template.md`

### 役割別

**新規開発者**：
1. `README.md`から始める
2. `docs/GETTING_STARTED.md`を読む
3. 日常作業には`.claude/guidelines/`を参照

**アーキテクト/リード**：
1. `docs/development-rules.md`をレビュー
2. 過去の決定は`docs/adr/`を確認
3. プロジェクト設定は`CLAUDE.md`を使用

**メンテナー**：
1. 進行中の作業は`memo/`を監視
2. 必要に応じて`.claude/guidelines/`を更新
3. 正式な変更は`docs/`を管理

## 🚫 避けるべきアンチパターン

1. **内容を重複させない** - 代わりに参照を使用
2. **似たファイル名を作らない** - 説明的でユニークに
3. **役割を混在させない** - クイックリファレンスと詳細ドキュメントを分ける
4. **更新を忘れない** - 参照を同期させる

## 📝 メンテナンスガイドライン

### 新しいドキュメントを追加する時

1. **役割を決定**：クイックリファレンスか詳細ドキュメントか？
2. **既存コンテンツを確認**：重複を避ける
3. **明確な命名**：説明的で混乱しない
4. **このマッピングに追加**：DOCUMENT_STRUCTURE.mdを更新
5. **相互参照を作成**：関連ドキュメントをリンク

### 定期メンテナンス

- **週次**：`memo/`の古いコンテンツをレビュー
- **月次**：壊れた参照をチェック
- **四半期**：重複を監査
- **年次**：主要な構造レビュー

---

*最終更新: 2025-08-05*  
*メンテナー: Claude Friendsテンプレートチーム*