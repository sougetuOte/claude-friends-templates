# 開発ガイドライン

🌐 **[English](development.md)** | **日本語**

## Claude Friends エージェント運用ルール

### エージェントの役割分担
- **Planner**: 戦略・計画・Phase管理
- **Builder**: 実装・テスト・技術的解決

### エージェント切り替えタイミング
1. **Planner → Builder**
   - 計画が完成し、実装に移る時
   - 具体的なToDoが明確になった時

2. **Builder → Planner**
   - 実装が一段落した時
   - 大きな設計変更が必要な時
   - 次のPhaseの計画が必要な時

### 引き継ぎルール
- **必須**: エージェント切り替え前にhandover.md作成
- **内容**: 完了事項、次のタスク、注意点を明記
- **保管**: 1週間後にarchiveへ移動

### 割り込み処理
- 緊急時は`handover-interrupt-[日時].md`を作成
- 中断した作業の再開方法を詳細に記載

## パッケージ管理
- **推奨ツール**: プロジェクト単位で統一（npm/yarn/pnpm、pip/poetry/uv等）
- **インストール**: `[tool] add package` 形式を推奨
- **実行**: `[tool] run command` 形式を推奨
- **禁止事項**: 
  - 混在使用（複数のパッケージマネージャーを併用）
  - `@latest`構文の使用（バージョン固定推奨）
  - グローバルインストール（プロジェクト内で完結）

## コード品質基準
- **型アノテーション**: すべての関数・変数に型情報を付与
- **ドキュメント**: 公開APIと複雑な処理には必須
  - AI-friendlyコメントガイドラインに従う
  - ビジネスコンテキストと制約を含める
  - パフォーマンスの考慮事項を文書化
- **関数設計**: 単一責任・小さな関数を目指す
- **既存パターン**: 常に既存のコードパターンに従う
- **行長**: 80-120文字（言語・チームで統一）

## コマンド一覧

### 基本開発フロー
```bash
# プロジェクトセットアップ（初回のみ）
[tool] install                   # 依存関係のインストール
[tool] run dev                   # 開発サーバーの起動

# テスト実行
[tool] run test                  # 全テストの実行
[tool] run test:watch           # ウォッチモード

# 品質チェック
[tool] run format               # コードフォーマットの適用
[tool] run lint                 # Lintチェックと自動修正
[tool] run typecheck            # 型チェックの実行（対応言語のみ）

# ビルドとリリース
[tool] run build                # プロダクションビルド
[tool] run check                # 総合チェック（CI前確認）
```

### パッケージ管理
```bash
[tool] add [package-name]       # 依存関係の追加
[tool] remove [package-name]    # 依存関係の削除
[tool] update                   # 全依存関係の更新
```

**注意**: `[tool]`はプロジェクトで使用するパッケージマネージャーに置き換える
- Node.js: `npm`、`yarn`、`pnpm`
- Python: `pip`、`poetry`、`uv`
- Rust: `cargo`
- Go: `go`
- その他の言語: 標準ツール

## エラー対応ガイド

### 標準的な問題解決順序
1. **フォーマットエラー** → `[tool] run format`
2. **型エラー** → `[tool] run typecheck`
3. **Lintエラー** → `[tool] run lint:fix`
4. **テストエラー** → `[tool] run test`

### よくある問題と解決策
- **行長エラー**: 適切な箇所で改行
- **インポート順序**: 自動修正を使用
- **型エラー**: 明示的な型アノテーションを追加

## 品質ゲート

### コミット前チェック
- [ ] `[tool] run format` - フォーマット適用済み
- [ ] `[tool] run lint` - Lint警告解決済み
- [ ] `[tool] run typecheck` - 型チェック通過
- [ ] `[tool] run test` - 全テスト合格

### CI/CD自動化
- コードフォーマット
- Lintチェック
- 型チェック
- ユニットテスト実行