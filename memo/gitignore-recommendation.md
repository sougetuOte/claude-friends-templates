# memo/.gitignore 改善提案

## 現状分析

### 現在のmemo/ディレクトリの役割
1. **テンプレート向けガイド** - 汎用的で他プロジェクトでも有用
2. **プロジェクト固有の作業記録** - 特定プロジェクトの分析・計画・進捗

### 現在Gitに追跡されているファイル

#### ✅ テンプレートに含めるべき（汎用ガイド）
- `gradual-adoption-guide.md` - 既存プロジェクトへの段階的導入ガイド
- `gradual-adoption-guide_ja.md` - 同上（日本語版）
- `zero-to-memory-bank.md` - ゼロからの導入ガイド
- `zero-to-memory-bank_ja.md` - 同上（日本語版）

#### ❌ プロジェクト固有（除外推奨）
- `hooks-optimization-plan.md` - 特定の最適化計画
- `hooks-system-research.md` - 特定の調査結果
- `tdd-progress-tracker.md` - TDD進捗管理
- `handover.md` / `handover-fallback.md` - 引き継ぎ記録
- `sync-error.md` - エラー記録
- `軽量レビュー結果_20250915.md` - レビュー結果

## 推奨する.gitignore設定

```gitignore
# =============================================================================
# memo/.gitignore - Memory Bank作業記録の除外設定
# =============================================================================

# -----------------------------------------------------------------------------
# プロジェクト固有の作業記録（除外）
# -----------------------------------------------------------------------------

# 分析・調査・レビュー結果
*-analysis.md
*-analysis-*.md
*-research.md
*-review.md
*レビュー*.md
*-report.md

# 計画・進捗・タスク管理
*-plan.md
*-planning.md
*-progress.md
*-tracker.md
*-todo.md
*-task*.md

# 引き継ぎ・同期記録
handover*.md
sync-*.md
*-error.md

# リファクタリング記録
refactoring-*.md
optimization-*.md

# フェーズ別記録
phase-*.md
sprint-*.md

# -----------------------------------------------------------------------------
# 一時ファイル（除外）
# -----------------------------------------------------------------------------

# 作業中ファイル
WIP-*
wip-*
draft-*
temp-*
tmp-*

# 日付付きファイル（レポート系）
*_[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9].md
*-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9].md

# ノート・メモ
*-note.md
*-notes.md
*-memo.md
personal-*.md

# -----------------------------------------------------------------------------
# エディタ・IDE関連（除外）
# -----------------------------------------------------------------------------

# バックアップファイル
*.swp
*.swo
*~
*.bak
.DS_Store

# IDE設定
.vscode/
.idea/
*.iml

# -----------------------------------------------------------------------------
# 明示的に含める（テンプレートの一部として共有）
# -----------------------------------------------------------------------------
# 以下のファイルは!で除外から除外（= 含める）

# 汎用導入ガイド
!gradual-adoption-guide.md
!gradual-adoption-guide_ja.md
!zero-to-memory-bank.md
!zero-to-memory-bank_ja.md

# テンプレート利用ガイド（将来追加する場合）
!template-usage-guide.md
!getting-started.md
```

## 移行手順

### 1. 既存の追跡ファイルを整理
```bash
# プロジェクト固有ファイルの追跡を停止
git rm --cached memo/hooks-optimization-plan.md
git rm --cached memo/hooks-system-research.md
git rm --cached memo/tdd-progress-tracker.md
git rm --cached memo/handover.md
git rm --cached memo/handover-fallback.md
git rm --cached memo/sync-error.md
git rm --cached "memo/軽量レビュー結果_20250915.md"
```

### 2. 新しい.gitignoreを適用
```bash
# 上記の内容でmemo/.gitignoreを更新
```

### 3. コミット
```bash
git add memo/.gitignore
git commit -m "refactor: improve memo/.gitignore to exclude project-specific files

- Keep only generic guides in version control
- Exclude project-specific analysis, plans, and progress files
- Add explicit includes for template guides"
```

## 判断基準

### テンプレートに含めるべきファイル
- ✅ 他のプロジェクトでも使える汎用的なガイド
- ✅ テンプレート自体の使い方説明
- ✅ ベストプラクティスの共有

### 除外すべきファイル
- ❌ 特定プロジェクトの分析結果
- ❌ 作業計画・進捗管理
- ❌ リファクタリング記録
- ❌ エラーログ・デバッグ記録
- ❌ 個人的なメモ・TODO

## メリット

1. **テンプレートの軽量化** - 不要なプロジェクト固有ファイルを含まない
2. **プライバシー保護** - プロジェクト固有の情報が漏れない
3. **使いやすさ向上** - 必要なガイドのみが含まれる
4. **柔軟性** - 各プロジェクトで自由にmemo/を使える

この設定により、memo/ディレクトリは「テンプレート利用者向けガイド置き場」と「プロジェクト固有の作業記録置き場」の両方として機能します。