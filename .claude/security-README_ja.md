# Claude Code セキュリティ設定

🌐 **[English](security-README.md)** | **日本語**

このプロジェクトには、Claude Codeの安全な使用のためのセキュリティ設定が含まれています。

## 実装内容

### 1. 拒否リスト
危険なコマンドを自動的にブロックする仕組みです。

**ブロックされるコマンド:**
- システム破壊 (`rm -rf /`, `rm -rf /usr`, `chmod -R 777 /`)
- リモートコード実行 (`curl | sh`, `wget | bash`)
- root権限への昇格 (`sudo su`, `sudo -i`)
- ディスクへの直接操作 (`dd if=/dev/zero of=/dev/`, `> /dev/sda`)
- データベース破壊 (`DROP DATABASE`)

### 2. 許可リスト
一般的に使用される安全なコマンドを事前承認する仕組みです。

**許可されたコマンド:**
- すべてのファイル操作 (`ls`, `cat`, `mkdir`, `cp`, `mv`, `rm`等)
- すべてのGit操作 (`git status`, `git config`, `git commit`等)
- 開発ツール (`npm`, `yarn`, `python`, `pip`, `cargo`等)
- モダンCLIツール (`eza`, `batcat`, `rg`, `fd`等)
- テキスト処理 (`awk`, `sed`, `grep`, `jq`等)
- 安全なネットワーク操作 (`curl`, `wget`, `ping`等)

### 3. ファイル構造

```
.claude/
├── settings.json          # メイン設定ファイル
├── scripts/
│   ├── deny-check.sh     # 拒否リストチェッカー
│   └── allow-check.sh    # 許可リストチェッカー
└── security-README_ja.md  # このファイル
```

## セキュリティログ

実行されたコマンドは `~/.claude/security.log` に記録されます：

```
[2024-01-01 12:00:00] BLOCKED: rm -rf / (matched: rm -rf /)
[2024-01-01 12:01:00] ALLOWED: git status
[2024-01-01 12:02:00] DENIED: custom-command (not in allow list)
```

## 設定の変更

### 許可リストへの追加
1. `.claude/scripts/allow-check.sh` の `ALLOWED_PATTERNS` にパターンを追加
2. パターンが期待通りに動作することをテスト

### 拒否リストへの追加
1. `.claude/scripts/deny-check.sh` の `DANGEROUS_PATTERNS` にパターンを追加
2. 正当なコマンドをブロックしないことを確認

## 緊急時の対応

セキュリティ設定が問題を引き起こした場合：

1. **一時的に無効化**
   ```bash
   mv .claude/settings.json .claude/settings.json.backup
   ```

2. **ログを確認**
   ```bash
   tail -f ~/.claude/security.log
   ```

3. **設定を復元**
   ```bash
   mv .claude/settings.json.backup .claude/settings.json
   ```

## 重要な注意事項

- **変更前に**: 必ず設定をバックアップ
- **テスト**: 本番使用前に十分にテスト
- **監視**: セキュリティログを定期的に確認
- **更新**: 脅威情報に基づいて設定を更新

## 設計理念

このセキュリティシステムは以下を目指して設計されています：
- 本当に危険な操作のみをブロック
- 通常の開発ワークフローをすべて許可
- 透明性とデバッグ可能性
- 誤検出の最小化

## サポート

設定に関する問題は、プロジェクト管理者にお問い合わせください。

---

**最終更新日**: 2025-07-10
**バージョン**: 2.0.0
