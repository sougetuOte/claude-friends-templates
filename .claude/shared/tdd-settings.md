# TDD設定ガイド

## 概要
claude-friends-templatesにTDD（テスト駆動開発）を強制・推奨するための設定システムが実装されました。
このシステムは、開発者がTDDプラクティスを習慣化できるよう支援します。

## 設定項目

### settings.jsonのTDD設定
```json
"tdd": {
  "enforcement": "recommended",     // "strict" | "recommended" | "off"
  "skipReasonRequired": true,       // スキップ理由の記録を必須にする
  "testFirstWarning": true,         // テスト未作成時に警告を表示
  "coverageThreshold": 80,          // カバレッジ目標値（%）
  "skipReasonLog": ".claude/tdd-skip-reasons.log"  // スキップ理由のログファイル
}
```

### 強制レベル（enforcement）

#### "strict"（厳格モード）
- テストがない場合、実装の続行を中断
- スキップする場合は理由の入力が必須
- チーム全体でTDDを徹底する場合に使用

#### "recommended"（推奨モード）- デフォルト
- テストがない場合、警告を表示
- スキップ理由は自動的に記録
- TDDを学習中のチームに最適

#### "off"（無効）
- TDDチェックを完全に無効化
- レガシーコードのメンテナンス時などに使用

## 動作の仕組み

### 1. ファイル編集時のチェック
Edit、Write、MultiEditツール使用時に以下をチェック：
- 対応するテストファイルの存在確認
- テストファイルがない場合の警告表示
- スキップ理由の記録

### 2. テストファイルの検索パターン
以下のパターンでテストファイルを検索：
```
# Pythonの場合
tests/test_filename.py
tests/filename_test.py

# JavaScript/TypeScriptの場合
__tests__/filename.test.js
__tests__/filename.spec.js

# Javaの場合
test/FilenameTest.java
```

### 3. スキップ理由の分類
- Prototype/Experimental code（プロトタイプ）
- Simple configuration change（設定変更）
- Refactoring existing tested code（リファクタリング）
- Documentation or non-functional change（ドキュメント）
- Other（その他）

## 使用例

### 新機能開発時（推奨フロー）
1. テストファイルを作成
```bash
touch tests/test_new_feature.py
```

2. 失敗するテストを書く（Red Phase）
3. 実装ファイルを作成して編集
4. テストが通る最小実装（Green Phase）
5. リファクタリング（Refactor Phase）

### 警告が表示された場合
```
⚠️  TDD Warning: No test found for src/new_feature.py
```

対応オプション：
1. テストを作成してから実装を続ける（推奨）
2. 正当な理由がある場合はスキップ（理由は記録される）

### スキップログの確認
```bash
cat .claude/tdd-skip-reasons.log
```

出力例：
```
[2025-07-21 15:30:00] File: src/config.py | Reason: Configuration change
[2025-07-21 16:00:00] File: src/prototype.py | Reason: Prototype/Experimental
```

## カスタマイズ

### プロジェクト固有の設定
1. settings.jsonを編集して強制レベルを変更
2. カバレッジ目標値を調整
3. スキップログの保存先を変更

### チーム運用ルール例
- 新機能：strictモードで必須
- バグ修正：recommendedモードで推奨
- リファクタリング：既存テストの維持を確認

## トラブルシューティング

### Q: 警告が表示されない
A: settings.jsonのtdd.testFirstWarningがtrueになっているか確認

### Q: テストファイルが見つからないと言われる
A: テストファイルの命名規則と配置場所を確認

### Q: スキップログが記録されない
A: ログファイルへの書き込み権限を確認

## 関連ドキュメント
- TDDサイクル実践ガイド: `.claude/builder/tdd-cycle.md`
- タスクステータス管理: `.claude/shared/task-status.md`
- Builderエージェントガイド: `.claude/builder/identity.md`

---
*TDDは品質の高いコードを生み出す実証された手法です。このシステムを活用して、チーム全体でTDDを実践しましょう。*
