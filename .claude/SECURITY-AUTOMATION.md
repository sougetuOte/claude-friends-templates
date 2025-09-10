# セキュリティ自動化システム

## 概要
claude-friends-templatesに実装されたセキュリティ自動チェックシステムです。
コード内の脆弱性を自動検出し、セキュリティリスクを事前に防ぎます。

## 実装コンポーネント

### 1. Security Auditor Subagent
**場所**: `.claude/agents/security-auditor.md`

専門のセキュリティ監査エージェントで、以下の機能を提供：
- 脆弱性スキャン
- 依存関係チェック
- 秘密情報検出
- セキュリティレビュー自動化

### 2. セキュリティ監査スクリプト
**場所**: `.claude/scripts/security-audit.py`

Pythonで実装された包括的なセキュリティスキャナー：
- SQLインジェクション検出
- XSS脆弱性検出
- パストラバーサル検出
- コマンドインジェクション検出
- ハードコードされた秘密情報の検出
- ファイル権限チェック

### 3. コマンド実行時のブロック
**場所**: `.claude/scripts/deny-check.sh`, `allow-check.sh`

危険なBashコマンドの実行を事前にブロック：
- システム破壊コマンド（`rm -rf /`など）
- リモートコード実行
- 権限昇格
- データ破壊

## 自動実行タイミング

### リアルタイム保護
1. **コマンド実行前**（PreToolUseフック）
   - 危険なコマンドをブロック
   - セキュリティログに記録

2. **セッション終了時**（Stopフック）
   - 全体的なセキュリティ監査
   - レポート生成

3. **コミット前**（pre-commitフック）
   ```bash
   # .git/hooks/pre-commit にリンク
   ln -s ../../.claude/scripts/security-pre-commit.sh .git/hooks/pre-commit
   ```

## セキュリティレポート

### レポート形式
```markdown
# セキュリティ監査レポート

## 🔴 Critical（即座に対応が必要）
- ハードコードされたAPIキー
- 秘密鍵の露出
- eval()やexec()の危険な使用

## 🟠 High（早急に対応）
- SQLインジェクション脆弱性
- XSS脆弱性
- コマンドインジェクション

## 🟡 Medium（計画的に対応）
- パストラバーサルリスク
- 不適切な権限設定

## 🟢 Low（改善推奨）
- ベストプラクティスからの逸脱
```

## 使用方法

### 手動実行
```bash
# セキュリティ監査実行
python3 .claude/scripts/security-audit.py

# レポート確認
cat .claude/security-report.md
```

### 設定カスタマイズ
`.claude/security-config.json`で調整可能：
```json
{
  "checks": {
    "secrets": true,
    "sql_injection": true,
    "xss": true,
    "path_traversal": true,
    "command_injection": true,
    "permissions": true
  },
  "severity_threshold": "medium"
}
```

## 検出パターン例

### 秘密情報
- APIキー: `api_key = "sk-..."`
- AWS認証情報: `AKIA...`
- JWTトークン: `eyJ...`
- 秘密鍵: `-----BEGIN PRIVATE KEY-----`

### 脆弱性
- SQLインジェクション: 文字列連結によるクエリ構築
- XSS: `innerHTML = userInput`
- コマンドインジェクション: `os.system(user_input)`
- パストラバーサル: `open(request.GET['file'])`

## ベストプラクティス

### DO's ✅
- 環境変数で秘密情報を管理
- パラメータ化クエリを使用
- 入力検証とサニタイゼーション
- 最小権限の原則

### DON'Ts ❌
- 秘密情報のハードコーディング
- 文字列連結によるSQL構築
- eval()やexec()の使用
- shell=Trueの使用

## トラブルシューティング

### 誤検出が多い場合
1. `security-config.json`でパターンを調整
2. 除外ディレクトリを追加
3. カスタムルールを定義

### 検出漏れがある場合
1. カスタムパターンを追加
2. チェック項目を有効化
3. スキャン対象を拡大

## 今後の拡張予定

### Phase 3での機能追加
- [ ] 依存関係の脆弱性チェック（npm audit統合）
- [ ] SAST（静的アプリケーションセキュリティテスト）統合
- [ ] セキュリティスコアリング
- [ ] 自動修正提案
- [ ] CVEデータベース連携

## 関連ドキュメント
- [Security Auditor Subagent](.claude/agents/security-auditor.md)
- [セキュリティ設定](.claude/security-config.json)
- [自動更新システム](.claude/AUTOMATIC-UPDATE-SYSTEM.md)

---
*セキュリティは開発の最初から組み込むべき。このシステムで、安全なコードを自動的に保証します。*