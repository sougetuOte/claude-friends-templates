# 🚀 はじめに - プロジェクト初期設定ガイド

claude-friends-templatesを使った新規プロジェクトの始め方を、ステップバイステップで解説します。

## 📋 5分で始める方法

### 1. プロジェクトの初期化
```bash
# 新しいプロジェクトフォルダを作成
mkdir my-awesome-project
cd my-awesome-project

# テンプレートをセットアップ
curl -sSL https://raw.githubusercontent.com/yourusername/claude-friends-templates/main/setup.sh | bash
# または手動でクローン
git clone https://github.com/yourusername/claude-friends-templates.git .

# Gitリポジトリとして初期化
git init
git add .
git commit -m "feat: claude-friends-templatesでプロジェクト初期化"
```

### 2. プロジェクト名の設定
```bash
# CLAUDE.mdとREADME.mdのプロジェクト名を更新
# macOSの場合
sed -i '' 's/\[Project Name\]/私の素晴らしいプロジェクト/g' CLAUDE.md README.md
# Linuxの場合
sed -i 's/\[Project Name\]/私の素晴らしいプロジェクト/g' CLAUDE.md README.md
```

### 3. Claude Codeで開始
```
# Claude Codeを起動して、以下を入力
/agent:planner
「新しいプロジェクトを始めたいです。要件定義から始めてください。」
```

## 🎯 プロジェクトの進め方フローチャート

```mermaid
graph TD
    Start[プロジェクト開始] --> Init[テンプレート初期化]
    Init --> Planner[/agent:planner]

    Planner --> Req[要件定義]
    Req -->|完了| NextQ1{「次どうすればいい？」}
    NextQ1 -->|Plannerが回答| Design[設計フェーズ]

    Design -->|完了| NextQ2{「次どうすればいい？」}
    NextQ2 -->|Plannerが回答| Tasks[タスク生成]

    Tasks -->|完了| NextQ3{「次どうすればいい？」}
    NextQ3 -->|Builderへ切り替え| Builder[/agent:builder]

    Builder --> Impl[TDD実装]
    Impl -->|Phase完了| Review[レビュー]
    Review -->|次Phase| Impl
    Review -->|全Phase完了| Complete[プロジェクト完成！]
```

## 📝 「次どうすればいい？」への自動回答

### 要件定義が終わったら
Plannerは自動的に以下のように答えます：
```
要件定義お疲れ様でした！🎉
次は【設計フェーズ】ですね。

以下を作成していきましょう：
1. アーキテクチャ設計（システム構成図）
2. API設計（エンドポイント定義）
3. データモデル設計（ER図など）

設計フェーズも私（Planner）が担当しますので、
そのまま続けさせていただきますね。
準備はよろしいでしょうか？
```

### 設計が終わったら
```
設計完了です！🎨
次は【タスク生成フェーズ】ですね。

T-wada式TDDに基づいた実装タスクを作成します：
- Phase 1: MVP（最小限動作）
- Phase 2: 機能拡張
- Phase 3: 高度な機能

各Phaseには以下が含まれます：
- 🔴 テスト作成タスク
- 🟢 実装タスク
- ♻️ リファクタリングタスク

タスク生成も私（Planner）が続けて行いますね。
```

### タスク生成が終わったら
```
タスク生成完了です！📋
次は【実装フェーズ】ですね。

ここからはBuilderエージェントの出番です。
以下のコマンドで切り替えてください：

/agent:builder

Builderは私が作成したタスクに従って、
厳格なTDDで実装を進めていきます。
引き継ぎ内容はhandover.mdに記載しました。

頑張ってください！💪
```

## 🏗️ 具体的な作業例

### 例：TODOアプリを作る場合

#### 1. 要件定義での会話
```
ユーザー：「TODOアプリを作りたいです」
Planner：「承知しました！要件を整理させていただきますね。
         いくつか質問があります：
         1. 誰が使うアプリですか？
         2. 主な機能は何が必要ですか？
         3. 技術的な制約はありますか？」
```

#### 2. 設計での成果物
- システム構成図（Mermaid）
- APIエンドポイント一覧
- データモデル定義
- 画面遷移図

#### 3. タスクでの成果物
```markdown
## Phase 1: MVP
### 📋 Phase 1 TODOリスト
1. 🔴 全機能のテストスイート作成
2. 🟢 最小限の実装で全テストを通す
3. ♻️ フェーズ終了時の包括的リファクタリング
4. ✅ フェーズレビューチェックリストの完了
```

## 💡 つまずきポイントと解決策

### 「何から始めればいいかわからない」
→ `/agent:planner`で「要件定義から始めてください」と伝える

### 「次のステップがわからない」
→ そのまま「次どうすればいい？」と聞く（Plannerが誘導）

### 「エージェントの切り替えタイミングがわからない」
→ タスク生成が終わったらBuilder、それ以外はPlanner

### 「TDDのやり方がわからない」
→ Builderが自動的にRed-Green-Refactorサイクルを実施

## 🎯 成功への近道

1. **要件は具体的に**: 曖昧な要件は後で問題になる
2. **設計は視覚的に**: Mermaid図を活用して理解しやすく
3. **タスクは小さく**: 15分で完了できる単位に分割
4. **テストファースト**: 必ず失敗するテストから書く
5. **定期的なレビュー**: Phase終了時は必ずレビュー

## 📚 参考リソース

- [プロジェクト例：TODOアプリ](../examples/todo-app/)を見て具体的なイメージを掴む
- [TDD実践ガイド](../.claude/builder/tdd-cycle.md)でTDDの詳細を学ぶ
- [エージェント連携](../.claude/shared/design-sync.md)で役割分担を理解

---
*わからないことがあれば、遠慮なくPlannerに質問してください！私たちがサポートします。*
