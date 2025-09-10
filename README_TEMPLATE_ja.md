# Claude Friends プロジェクトテンプレート v2.0.0

🌐 **日本語** | **[English](README_TEMPLATE.md)**

**AIパワード・マルチエージェント開発システム - あなた専用のAIチーム**

## 🚀 このテンプレートの主な特徴

### 1. **コスト効率化** - プロンプトキャッシュ最適化
長期的に安定した情報（プロジェクト概要、技術仕様など）に`cache_control`を適用することで、同一プロンプトの再利用時にClaude APIの利用コストとレスポンス時間を削減。AIを日常的に使う開発において、運用効率の改善に貢献します。

### 2. **AIによる問題分析支援** - AI-Friendly Logger (Vibe Logger概念)
従来の「人間が読むログ」から「AIが分析するログ」への転換。構造化されたJSONログが自動的にコンテキスト情報を収集し、デバッグ作業における問題の特定と原因分析を支援します。

### 3. **プロジェクトの記憶を体系化** - Memory Bank システム
プロジェクトの「記憶」を階層的に構造化して保存。新メンバーのオンボーディング時間を短縮し、「あれ何だっけ？」を解消します。AIが体系化された情報に基づいて回答を提供します。

### 4. **既存プロジェクトへの段階的導入が可能**
「今すぐ全部変える」必要はありません。リスクを最小化しながら、必要な機能から段階的に導入できる設計です。

---

個人開発者向けに最適化された、効率的なプロジェクト開発テンプレートです。

## 🎯 特徴

- **軽量設計**: コンテキスト使用量を最小化
- **階層化Memory Bank**: 必要な情報のみ読み込み
- **段階的拡張**: 小規模→大規模プロジェクトに対応
- **日次運用**: 3分で状況更新完了
- **汎用性**: 言語・技術スタックに依存しない設計
- **開発規約統合**: Anthropicベストプラクティスを統合
- **品質管理**: エラー対応ガイド・品質ゲート内蔵
- **セキュリティ強化**: Claude Code hooks による危険なコマンドブロック機能
- **プロジェクト記憶**: 履歴と決定事項の体系的管理
- **自動化ワークフロー**: Hooks機能による品質チェック自動化
- **AI-Friendly Logger**: Vibe Logger概念採用・構造化JSON形式でAI分析最適化

## 📁 テンプレート構成

### 必須ファイル
```
CLAUDE.md                    # プロジェクト設定
.clauderules                 # プロジェクト知見
.gitignore                   # キャッシュファイル除外設定
.claude/settings.json        # キャッシュ環境設定 + セキュリティ設定
.claude/hooks.yaml           # Hooks設定（新規）
.claude/security-README.md   # セキュリティ設定説明
.claude/ai-logger-README.md  # AI Logger設定説明
docs/requirements.md         # 要求仕様書
docs/adr/template.md         # ADRテンプレート
```

### Memory Bank（階層化）
```
.claude/
├── core/                    # 常時参照（軽量）
│   ├── current.md          # 現在の状況（50行以内）
│   ├── next.md             # 次のアクション（30行以内）
│   ├── overview.md         # プロジェクト概要
│   └── templates.md        # クイックテンプレート＆パターン集
├── context/                # 必要時参照
│   ├── tech.md             # 技術詳細
│   ├── history.md          # 履歴・決定事項
│   └── debt.md             # 技術負債トラッキング
├── debug/                  # デバッグ情報
│   └── latest.md           # 最新のデバッグセッション（100行以内）
├── archive/                # 定期整理
├── commands/               # コアコマンド
│   ├── agent-planner.md    # Plannerエージェント（新機能設計含む）
│   ├── agent-builder.md    # Builderエージェント（デバッグ＆レビュー含む）
│   ├── daily.md            # 日次更新
│   └── focus.md            # フォーカスモード
├── scripts/                # セキュリティ＆ログスクリプト
│   ├── deny-check.sh       # 危険コマンドブロック
│   ├── allow-check.sh      # 安全コマンド許可
│   ├── test-security.sh    # セキュリティテスト
│   ├── ai-logger.sh        # AI-Friendly Logger
│   └── analyze-ai-logs.py  # AIログ解析ツール
├── security-README.md      # セキュリティ設定説明
└── settings.json           # プロジェクト設定（キャッシュ+セキュリティ）
```

## 📋 前提条件

- **Claude Code v1.0+** インストール済み
- **Git** バージョン管理用
- **Python 3.7+** (オプション、高度な機能用):
  - リファクタリング分析 (`refactoring-analyzer.py`)
  - 設計ドリフト検出 (`design-drift-detector.py`)
  - 品質チェック (`quality-check.py`)
  - AIログ分析 (`analyze-ai-logs.py`)

## 🚀 使い方

### 1. プロジェクト開始
```bash
# テンプレートをコピー
cp -r claude_file_template/ your-project/
cd your-project/

# 日本語版ファイルを使用（推奨）
mv CLAUDE.md CLAUDE_en.md          # 英語版を保存
mv CLAUDE_ja.md CLAUDE.md           # 日本語版をメインに
mv README_TEMPLATE.md README_TEMPLATE_en.md  # 英語版を保存
mv README_TEMPLATE_ja.md README.md  # 日本語版をメインに
mv .clauderules .clauderules_en     # 英語版を保存
mv .clauderules_ja .clauderules     # 日本語版をメインに
# 必要に応じて他の_jaファイルも同様に置き換え

# プロジェクト情報をカスタマイズ
# - CLAUDE.md の [プロジェクト名] を置換
# - docs/requirements.md を記入
# - .claude/core/ 内のファイルを更新
```

### 2. 日常の開発フロー

#### Claude Friends活用（推奨）
```
朝: /agent:planner    # 今日の作業計画と機能設計
    ↓
    「ユーザー認証機能を追加したい」
    → Plannerが自動で図付きの詳細仕様書を作成
    ↓
作業: /agent:builder    # 計画に基づいて実装開始
      ↓
      エラー発生？ → Builderが自動でデバッグモードへ
      実装完了？ → Builderでレビューモード起動可能
      ↓
集中: /project:focus    # 集中が必要なときに
      ↓
夕方: /project:daily    # 日次振り返り（3分）
```

#### タグ検索（必要時）
```
タグ検索: #urgent #bug #feature #completed  # 関連情報の高速検索
```

## 💡 効率化のポイント

### コンテキスト最小化
- **通常時**: `@.claude/core/*` のみ参照
- **詳細必要時**: `@.claude/context/*` を明示指定
- **過去参照**: `@.claude/archive/*` で履歴確認

### Memory Bank運用
- **core/**: 50行以内を維持
- **context/**: 必要時のみ更新
- **archive/**: 月1回整理

### 時間管理
- 計画立案: 5分以内
- 日次更新: 3分以内
- Memory Bank更新: 必要時のみ

## 🤖 Claude Friends マルチエージェントシステム

ひとり開発をAIエージェントとのチーム開発体験に変えます：

### コアコマンド（たった4つ！）
| コマンド | 用途 | 詳細 |
|---------|------|------|
| `/agent:planner` | 戦略計画＋設計 | Mermaid図付きで仕様書作成 |
| `/agent:builder` | 実装＋デバッグ＋レビュー | すべてのコーディング作業 |
| `/project:focus` | 現在のタスクに集中 | どのエージェントでも使用可 |
| `/project:daily` | 日次振り返り | どのエージェントでも使用可 |

### スマートエージェント機能
- **Planner特殊モード**: 新機能計画時に自動で新機能設計モードへ
- **Builder特殊モード**: 
  - デバッグモード: エラー発生時に自動起動
  - コードレビューモード: 実装後の品質確保
  - TDD厳守: Red→Green→Refactorサイクル必須
- **スムーズな引き継ぎ**: エージェントが次のエージェントに最適なモードを推奨

**[→ Claude Friends 完全ガイド](.claude/claude-friends-guide_ja.md)**

## 🛠 コマンドシステム概要

Claude Friendsシステムは、たった4つのコアコマンドで開発を簡素化します。以前の専門モードはすべてエージェントシステムに統合されました：

### クイックリファレンス
- **計画・設計** → `/agent:planner` （新機能設計モード含む）
- **コーディング・デバッグ・レビュー** → `/agent:builder` （デバッグ＆レビューモード含む）
- **集中作業** → `/project:focus`
- **日次レビュー** → `/project:daily`

### タグ検索
- タグ形式: `#tag_name` でMemory Bank内検索
- 主要タグ: #urgent #bug #feature #completed

## 📋 内蔵機能

### 開発規約（Core Development Rules）
- パッケージ管理統一方針
- コード品質基準・TDD必須要件
- Git/PR規約（コミット形式・トレーラー・レビュー規約）

### 実行コマンド一覧
- 言語非依存の開発フロー（`[tool]`記法）
- セットアップ・テスト・品質チェック・ビルドの統一コマンド
- 主要言語（Node.js/Python/Rust/Go）対応

### エラー対応ガイド
- 問題解決の標準順序（フォーマット→型→リント→テスト）
- 分野別よくある問題と解決策
- 開発・エラー対応・情報収集時のベストプラクティス

### 品質ゲート
- 段階別チェックリスト（コミット前・PR前・デプロイ前）
- 自動化レベル分類（完全自動化・半自動化・手動確認）
- 継続的品質管理の運用指針

### セキュリティ機能
- **Deny List**: 危険なコマンドの自動ブロック（`rm -rf /`, `chmod 777`, `curl | sh`等）
- **Allow List**: 開発に必要な安全コマンドの事前許可（`git`, `npm`, `python`等）
- **セキュリティログ**: 実行コマンドの監査・記録機能
- **テストスイート**: セキュリティ設定の自動検証機能
- **ドキュメント**: 設定方法・緊急時対応ガイド完備

### AI-Friendly Logger（v1.2.0新機能 - Vibe Logger概念採用）
- **構造化ログ**: AI分析に最適化されたJSON形式（`~/.claude/ai-activity.jsonl`）
- **豊富なコンテキスト**: プロジェクト・環境・Git情報を自動収集
- **AIメタデータ**: デバッグヒント・優先度・推奨アクションの自動付与
- **パターン分析**: エラー検出・頻繁な操作・ファイルアクティビティの可視化
- **解析ツール**: `analyze-ai-logs.py`でAI向け洞察生成
- **参考**: [Vibe Logger](https://github.com/fladdict/vibe-logger)概念を採用

## 🎯 適用プロジェクト

### 最適
- 個人開発プロジェクト
- 1-3ヶ月の中期プロジェクト
- Web開発・アプリ開発
- プロトタイプ開発

### 要調整
- 大規模チーム開発
- 1年以上の長期プロジェクト
- 高度な規制要件があるプロジェクト

## 📈 期待効果

### トークン使用量
- **効率的管理**: 階層化Memory Bankによる最適化
- **一定量維持**: プロジェクト規模に関係なく軽量

### 開発効率
- **高速計画**: 段階的情報読み込み
- **集中作業**: フォーカスモードで中断なし
- **継続運用**: 軽量更新で習慣化

### 拡張性
- **段階的成長**: 小→大規模に自然拡張
- **知見蓄積**: `.clauderules`で学習継続
- **再利用**: テンプレート・パターンの活用

## ⚠️ 注意事項

- Memory Bankファイルは簡潔に保つ（各50行以内推奨）
- 定期的なアーカイブでパフォーマンス維持
- プロジェクト固有の内容に確実に置換する
- 重要な決定事項は必ず記録する

## 📋 実際の運用例

### 🚀 初日のフロー

#### Claude Friendsシステムで
```
09:00 テンプレートコピー & カスタマイズ
09:15 /agent:planner - プロジェクト構造と最初の機能を計画
      → PlannerがMermaidアーキテクチャ図付きでプロジェクト概要を作成
09:30 /agent:builder - Plannerの設計に基づいて実装開始
      → Builderが計画に従い、コードを書き、テストする
12:00 Plannerで進捗確認と優先順位調整
16:00 /agent:builder - コード品質を確認（レビューモード）
17:00 /project:daily - 初日の振り返り
```

### 📅 日常運用（2日目以降）

#### Claude Friendsワークフロー
```
09:00 /agent:planner    # 進捗確認と今日の作業計画
      → 「ユーザー通知機能を追加」
      → Plannerがシーケンス図付きの詳細仕様書を作成
      
10:00 /agent:builder    # 新機能の実装開始
      → Builderが通知システムに取り組む
      → エラー？自動的にデバッグモードへ切り替え
      
14:00 /project:focus    # 複雑なロジックに深く集中
      
16:00 /agent:builder    # まとめる前にコードレビュー
      → 「通知実装をレビューして」
      → Builderがコード品質を分析し改善提案
      
17:00 /project:daily    # 振り返りと明日の計画
```

### 👥 人間とAIの役割分担

#### 人間の担当
- **戦略的判断**: Plannerエージェントと高レベル計画を作成
- **要件定義**: Plannerに要望を説明し詳細仕様書を作成
- **品質管理**: Builderのコードレビューモードを要求
- **方向性制御**: 引き継ぎを通じてエージェントを誘導
- **振り返り**: `/project:daily`での進捗管理

#### AIの担当
- **実装作業**: コード作成・修正・テスト
- **技術調査**: ライブラリ選定・実装方法検討
- **ドキュメント**: 技術文書・コメント作成
- **問題解決**: バグ修正・パフォーマンス改善

### ⚡ AI作業中の人間の時間活用
```
AI実装中（30-90分）の並行作業:
- 次のフェーズの企画
- UI/UXデザインの検討
- 外部API・サービスの調査
- ドキュメント整備
- 他プロジェクトの作業
```

### 📊 コマンド使用頻度

| 頻度 | コマンド | タイミング |
|------|---------|------------|
| 毎日 | `/agent:planner` | 朝の計画立案＆設計 |
| 毎日 | `/agent:builder` | 実装＆デバッグ |
| 毎日 | `/project:daily` | 夕方の振り返り |
| 必要時 | `/project:focus` | 深い集中が必要な時 |
| 自動 | Planner新機能モード | 新機能設計時 |
| 自動 | Builderデバッグモード | エラー発生時 |
| 自動 | Builderレビューモード | コード品質確認時 |
| 随時 | `#タグ検索` | 関連情報検索時 |

## 🎉 始めよう

1. テンプレートをコピー
2. CLAUDE.mdをカスタマイズ
3. セキュリティ設定をテスト: `.claude/scripts/test-security.sh`を実行
4. `/agent:planner`でプロジェクトを設計
5. `/agent:builder`でコーディング開始
6. AIパワーのチーム開発を楽しもう！

このテンプレートで、Claude Codeを使った効率的な個人開発を実現しましょう！

## 📚 強化内容・ソース情報

### v1.1.0 強化機能
- **プロンプトキャッシュ最適化**: 同一プロンプト再実行時のコスト削減・レスポンス時間短縮
- **段階的TDD学習パス**: 未経験者向け学習システム
- **ADRシステム**: 技術決定の記録・管理機能
- **技術負債トラッキング**: 体系的な負債管理システム
- **セキュリティ機能**: Claude Code hooks による危険コマンドブロック機能

### ソース・参考文献

#### Claude Code 最適化技法
- **Anthropic 公式**: [Prompt caching - Anthropic API](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching)
- **Anthropic 公式**: [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- **AWS 公式**: [Supercharge your development with Claude Code and Amazon Bedrock prompt caching](https://aws.amazon.com/blogs/machine-learning/supercharge-your-development-with-claude-code-and-amazon-bedrock-prompt-caching/)
- **Medium**: [Unlocking Efficiency: A Practical Guide to Claude Prompt Caching](https://medium.com/@mcraddock/unlocking-efficiency-a-practical-guide-to-claude-prompt-caching-3185805c0eef)

#### TDD & テスト駆動開発
- **Anthropic 公式**: [Claude Code: Best practices for agentic coding](https://www.anthropic.com/engineering/claude-code-best-practices)
- **Reddit**: [Claude Dev can now automatically fix linter, compiler, and build errors](https://www.reddit.com/r/ClaudeAI/comments/1fgzo87/claude_dev_can_now_automatically_fix_linter/)
- **Reddit**: [Generating unit tests with Claude](https://www.reddit.com/r/ClaudeAI/comments/1i17nwn/generating_unit_tests_with_claude/)

#### ADR (Architecture Decision Record)
- **GitHub**: [Architecture decision record (ADR) examples](https://github.com/joelparkerhenderson/architecture-decision-record)
- **MakerX Blog**: [Architecture Decision Records: How we make better technical choices](https://blog.makerx.com.au/architecture-decision-records-how-we-make-better-technical-choices-at-makerx/)
- **Medium**: [Why Every Software Team Should Embrace Architecture Decision Records](https://levelup.gitconnected.com/why-every-software-team-should-embrace-architecture-decision-records-18cd201cc179)

#### Memory Bank & コンテキスト管理
- **Anthropic 公式**: [Manage Claude's memory](https://docs.anthropic.com/en/docs/claude-code/memory)
- **Cloud Artisan**: [Claude Code Tips & Tricks: Maximising Memory](https://cloudartisan.com/posts/2025-04-16-claude-code-tips-memory/)
- **DEV Community**: [Introducing Claude Crew: Enhancing Claude Desktop's Coding Agent Capabilities](https://dev.to/kimuson/introducing-claude-crew-enhancing-claude-desktops-coding-agent-capabilities-36ah)

#### AI-Friendly Logging
- **Vibe Logger**: [GitHub - fladdict/vibe-logger](https://github.com/fladdict/vibe-logger)
- **Vibe Logger解説**: [note - AIエージェント向けログシステム「Vibe Logger」の提案](https://note.com/fladdict/n/n5046f72bdadd)

#### キャッシュ技術詳細
- **Anthropic 公式**: [Long context prompting tips](https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/long-context-tips)
- **LinkedIn**: [How to Use Anthropic Claude Prompt Caching (and RAG)](https://www.linkedin.com/posts/anantharamuavinash_how-to-use-claude-prompt-caching-and-ditch-activity-7230786805590061056-xupU)
- **Reddit**: [Claude Caching Is Fantastic For Iterating Over Code!](https://www.reddit.com/r/ClaudeAI/comments/1ewms42/claude_caching_is_fantastic_for_iterating_over/)

### 実装機能詳細

#### 1. CLAUDE_CACHE設定
```json
// .claude/settings.json
{
  "env": {
    "CLAUDE_CACHE": "./.ccache"
  }
}
```

#### 2. cache_control最適化
以下のファイルにcache_controlが適用済み:
- `.claude/core/overview.md` - プロジェクト概要
- `.claude/core/templates.md` - クイックテンプレート
- `.claude/context/tech.md` - 技術スタック
- `.claude/context/debt.md` - 技術負債トラッキング
- `docs/requirements.md` - 要求仕様

#### 3. TDD段階的学習パス
- **Phase 1 (Week 1-2)**: TDD体験なしでClaude Code習得
- **Phase 2 (Week 3-4)**: 小さな機能でTDD体験
- **Phase 3 (Month 2-3)**: 本格的なTDD適用

#### 4. ADRシステム
- **テンプレート**: `docs/adr/template.md`
- **決定記録**: 技術選択、アーキテクチャ、セキュリティ方針等
- **連携**: GitHub Issue、負債ログ、履歴管理

#### 5. 技術負債トラッキング
- **優先度管理**: 高🔥/中⚠️/低📝
- **コスト試算**: 時間単位で推定・実績記録
- **キャッシュ影響分析**: 削除コスト・最適化効果測定

### 性能効果
- **コスト削減**: プロンプトキャッシュによる同一プロンプト再実行時の削減
- **レイテンシ短縮**: キャッシュヒット時のAPIレスポンス改善
- **TDD学習**: 未経験者でも2-3ヶ月で習得可能
- **知識管理**: ADR・負債ログによる体系的管理
- **セキュリティ強化**: 開発効率を保ちながら安全性を向上

### 注意事項
- `.ccache/`フォルダは`.gitignore`に追加済み
- cache_controlは長期安定情報のみに適用
- TDDは段階的導入で学習曲線を緩やかに
- ADRは重要な技術決定のみ記録し過度な文書化を回避
- **セキュリティ設定**: テスト実行後に本番環境で使用すること
- **ログ監視**: `~/.claude/security.log`を定期的に確認し、不正なアクセスに注意すること

### v1.2.0 新機能（AI-Friendly Logger & 自動化）

#### Hooks自動化システム  
- **品質チェック自動化**: コード変更時に自動でリント・型チェック
- **テスト成功記録**: 成功したテストを自動的にPROJECT_MEMORYに記録
- **進化の自動追跡**: 新機能追加・コミットを自動ログ化

#### プロジェクト健康診断
- **メトリクス収集**: コードサイズ、技術負債、依存関係の健全性
- **総合スコア算出**: A-Fでプロジェクトの健康状態を評価
- **改善提案**: 具体的なアクションプランを自動生成

#### AI-Friendly Logger（Vibe Logger概念採用）
- **構造化ログ形式**: AI分析に最適化されたJSONLファイル
- **自動コンテキスト収集**: プロジェクト・環境・Git状態を自動記録
- **AIメタデータ**: デバッグヒント・優先度・推奨アクション付与
- **パターン分析ツール**: エラー傾向・操作頻度・ファイル活動の可視化
- **既存システムとの共存**: 従来のログも継続生成で段階的移行可能
- **インスピレーション**: [Vibe Logger](https://github.com/fladdict/vibe-logger) by @fladdict
