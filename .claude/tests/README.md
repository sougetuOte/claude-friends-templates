# テストシステムガイド

🌐 **[English](README_en.md)** | **日本語**

## 🎯 重要なお知らせ：Batsは必須ではありません

このディレクトリにはBats（Bash Automated Testing System）を使用したテストファイルが含まれていますが、**一般利用においてBatsのインストールは不要です**。

## 利用者別ガイド

### 📘 一般利用者の方へ

**Batsのインストールは不要です** ✅

- claude-friends-templatesのすべての機能は**Bats無しで正常動作**します
- フックシステム、セキュリティ機能、ロギング等すべて影響なし
- テストファイルは無視して構いません

### 🛠️ 開発者・コントリビューターの方へ

**Batsのインストールを推奨**（必須ではありません）

#### インストール方法

```bash
# npm経由
npm install -g bats

# Homebrew経由（macOS）
brew install bats-core

# apt経由（Ubuntu/Debian）
sudo apt-get install bats

# 手動インストール
git clone https://github.com/bats-core/bats-core.git
cd bats-core
./install.sh /usr/local
```

#### テスト実行方法

```bash
# すべてのテストを実行
bats .claude/tests/bats/*.bats

# 特定のテストを実行
bats .claude/tests/bats/test_agent_switch.bats

# 詳細出力付き
bats --verbose-run .claude/tests/bats/*.bats
```

## テストファイル構成

```
.claude/tests/
├── README.md           # このファイル
├── bats/              # Batsテストファイル
│   ├── test_agent_switch.bats      # エージェント切替テスト
│   ├── test_handover_gen.bats      # 引き継ぎ生成テスト
│   ├── test_json_utils.bats        # JSONユーティリティテスト
│   ├── test_hook_common.bats       # 共通フックテスト
│   └── *_security_*.bats           # セキュリティテスト
├── helpers/           # テストヘルパー関数
└── fixtures/          # テスト用固定データ
```

## テスト実行環境

### CI/CD環境での実行

```yaml
# GitHub Actions例
- name: Install Bats
  run: npm install -g bats

- name: Run Tests
  run: bats .claude/tests/bats/*.bats
```

### ローカル環境での確認

```bash
# Batsがインストールされているか確認
command -v bats >/dev/null 2>&1 && echo "Bats installed" || echo "Bats not installed"

# Bats無しでフックシステムをテスト（一般利用者向け）
.claude/scripts/test-hooks.sh    # Bats不要
.claude/scripts/test-security.sh  # Bats不要
```

## なぜBatsを使用しているか

1. **標準化**: Bashスクリプトのテストのデファクトスタンダード
2. **可読性**: テストケースが明確で理解しやすい
3. **CI/CD統合**: 多くのCI/CDサービスでサポート
4. **独立性**: プロダクションコードに影響を与えない

## トラブルシューティング

### Q: Bats無しでエラーが出る
A: フックシステム自体はBatsに依存していません。エラーは別の原因です。

### Q: テストを実行したいがBatsがインストールできない
A: 代替として通常のbashスクリプトでテスト：
```bash
# 簡易テスト実行
bash .claude/tests/helpers/test-helpers-simple.sh
```

### Q: どのテストが重要？
A: 優先順位：
1. `test_hook_common.bats` - 基本機能
2. `test_agent_switch.bats` - エージェント切替
3. `*_security_*.bats` - セキュリティ

## 貢献ガイドライン

新しいテストを追加する場合：

1. `.claude/tests/bats/` に `test_*.bats` ファイルを作成
2. 既存のテストスタイルに従う
3. CI/CDでの実行を確認
4. READMEのテストファイル一覧を更新

---

**要約**: 一般利用者はBats不要、開発者は推奨。すべての機能はBats無しで動作保証。