# 品質ゲート自動化システム

## 概要
コード品質を継続的に監視し、一定の品質基準を満たさないコードの混入を防ぐ自動化システムです。
テストカバレッジ、コード品質メトリクス、ベストプラクティスの遵守を自動的にチェックします。

## 品質ゲートの構成

### 1. テストカバレッジゲート
- **目標**: 80%以上のカバレッジ
- **必須**: 新規ファイルは90%以上
- **除外**: テストファイル、設定ファイル、生成コード

### 2. コード品質ゲート
- **複雑度**: 循環的複雑度 < 10
- **重複**: 重複コード < 5%
- **可読性**: 命名規則、コメント率

### 3. セキュリティゲート
- **脆弱性スキャン**: 既知の脆弱性チェック
- **依存関係**: 古いパッケージの検出
- **機密情報**: ハードコードされた秘密情報の検出

### 4. パフォーマンスゲート
- **ビルド時間**: 5分以内
- **バンドルサイズ**: 増加率 < 5%
- **メモリ使用量**: リーク検出

## 品質レベル定義

### 🟢 Green（合格）
すべての品質ゲートをクリア
- テストカバレッジ: 80%以上
- 複雑度: すべて基準値以下
- セキュリティ: 問題なし
- パフォーマンス: 基準内

### 🟡 Yellow（警告）
軽微な問題あり、マージは可能
- テストカバレッジ: 70-79%
- 複雑度: 一部が基準値超過
- セキュリティ: 低リスクの問題
- パフォーマンス: 軽微な劣化

### 🔴 Red（不合格）
重大な問題あり、マージ不可
- テストカバレッジ: 70%未満
- 複雑度: 多数が基準値超過
- セキュリティ: 高リスクの問題
- パフォーマンス: 大幅な劣化

## 自動チェックの実行タイミング

### Pre-commit（ローカル）
```bash
# .git/hooks/pre-commit
#!/bin/bash
python .claude/scripts/quality-check.py --quick
```

### Pre-push（ローカル）
```bash
# .git/hooks/pre-push
#!/bin/bash
python .claude/scripts/quality-check.py --full
```

### CI/CD（リモート）
```yaml
# .github/workflows/quality-gates.yml
name: Quality Gates
on: [push, pull_request]
jobs:
  quality-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run quality gates
        run: |
          python .claude/scripts/quality-check.py --ci
```

## 品質メトリクスの詳細

### テストカバレッジメトリクス
```yaml
coverage:
  line_coverage: 80%      # 行カバレッジ
  branch_coverage: 75%    # 分岐カバレッジ
  function_coverage: 85%  # 関数カバレッジ

  per_file:
    minimum: 60%         # ファイル単位の最小値
    new_code: 90%        # 新規コードの要求値
```

### コード品質メトリクス
```yaml
quality:
  cyclomatic_complexity: 10    # 循環的複雑度
  cognitive_complexity: 15     # 認知的複雑度
  duplication: 5%             # 重複率
  maintainability_index: 20   # 保守性指標

  naming:
    min_length: 3
    max_length: 50
    style: camelCase          # または snake_case
```

### セキュリティメトリクス
```yaml
security:
  vulnerability_scan: true
  dependency_check: true
  secret_detection: true

  severity_threshold:
    critical: 0    # 許容数
    high: 0
    medium: 3
    low: 10
```

## 品質レポートの形式

### サマリーレポート
```markdown
# 品質チェックレポート

日時: 2025-07-21 17:00:00
結果: 🟢 合格

## サマリー
- テストカバレッジ: 85.3% ✅
- コード品質: 良好 ✅
- セキュリティ: 問題なし ✅
- パフォーマンス: 基準内 ✅

## 詳細
[各項目の詳細結果]
```

### 詳細レポート（JSON形式）
```json
{
  "timestamp": "2025-07-21T17:00:00Z",
  "result": "PASS",
  "metrics": {
    "coverage": {
      "line": 85.3,
      "branch": 78.2,
      "function": 90.1
    },
    "quality": {
      "complexity": {
        "average": 4.2,
        "max": 9
      },
      "duplication": 2.1
    },
    "security": {
      "vulnerabilities": 0,
      "outdated_deps": 2
    }
  }
}
```

## フックシステムとの統合

### 品質チェックフック
```json
// .claude/settings.json に追加
{
  "hooks": {
    "PreCommit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/scripts/quality-pre-commit.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/scripts/quality-incremental.sh"
          }
        ]
      }
    ]
  }
}
```

### 段階的チェック
1. **インクリメンタルチェック**: ファイル編集時（軽量）
2. **プリコミットチェック**: コミット前（中量）
3. **フルチェック**: プッシュ前・CI時（完全）

## カスタマイズと設定

### プロジェクト固有の設定
```json
// .claude/quality-config.json
{
  "thresholds": {
    "coverage": {
      "global": 80,
      "new_code": 90,
      "per_file": 60
    },
    "complexity": {
      "cyclomatic": 10,
      "cognitive": 15
    }
  },
  "exclude": [
    "**/*.test.js",
    "**/*.spec.ts",
    "**/migrations/**",
    "**/vendor/**"
  ],
  "rules": {
    "enforce_tdd": true,
    "require_docs": true,
    "strict_typing": true
  }
}
```

### 例外ルール
```yaml
# .claude/quality-exceptions.yml
exceptions:
  - file: "src/legacy/old-module.js"
    reason: "レガシーコード、段階的改善中"
    until: "2025-12-31"

  - pattern: "**/generated/**"
    reason: "自動生成コード"
    permanent: true
```

## ベストプラクティス

### 段階的導入
1. **Phase 1**: 警告のみ（Yellow許可）
2. **Phase 2**: 新規コードに適用
3. **Phase 3**: 全体に適用（Red禁止）

### 継続的改善
- 週次で品質メトリクスをレビュー
- 月次で閾値の見直し
- 四半期で新しいチェック項目の追加

### チーム運用
- 品質ゲート失敗時の対応フロー確立
- 例外承認プロセスの明確化
- 品質向上の取り組みを可視化

## トラブルシューティング

### よくある問題

#### カバレッジが上がらない
- テストしにくいコードのリファクタリング
- モックの活用
- 統合テストの追加

#### 複雑度が高い
- 関数の分割
- 早期リターンの活用
- ストラテジーパターンの適用

#### ビルド時間が長い
- 並列化の検討
- キャッシュの活用
- 不要な処理の削除

## 関連ツール

### JavaScript/TypeScript
- Jest（テスト・カバレッジ）
- ESLint（品質チェック）
- SonarJS（複雑度分析）

### Python
- pytest（テスト）
- coverage.py（カバレッジ）
- pylint（品質チェック）
- bandit（セキュリティ）

### 共通
- SonarQube（統合品質管理）
- Codecov（カバレッジ追跡）
- Snyk（セキュリティスキャン）

## まとめ
品質ゲートは、コードの品質を客観的に測定し、一定の基準を維持するための重要な仕組みです。
自動化により、人的ミスを防ぎ、継続的な品質向上を実現します。

---
*品質は習慣。品質ゲートで、その習慣を支えます。*
