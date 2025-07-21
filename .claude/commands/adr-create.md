# ADR作成コマンド

## /adr:create - 新しいADRの作成

### 実行内容
1. 次のADR番号を決定（既存のADRを確認）
2. テンプレートから新しいADRファイルを作成
3. 基本情報の入力を促す
4. Design Syncとの連携を確認

### プロンプト
```
### ADR（Architecture Decision Record）作成

新しい技術的決定を記録します。

#### ADR番号の確認
docs/adr/ディレクトリを確認し、次の番号は: ADR-[XXX]

#### 基本情報の入力
1. **決定のタイトル**: [簡潔で分かりやすいタイトル]
2. **決定者**: [Planner/Builder/両方]
3. **ステータス**: Proposed（提案中）

#### テンプレートの使用
以下のテンプレートを使用します：
- @.claude/shared/templates/adr/adr-template.md

#### 作成手順
1. `docs/adr/ADR-[XXX]-[title-in-kebab-case].md`を作成
2. テンプレートの内容をコピー
3. 基本情報を記入
4. コンテキストと背景を詳述

#### Design Syncチェック
- [ ] この決定は設計に影響するか？
- [ ] 既存の設計との整合性は確認したか？
- [ ] 設計ドキュメントの更新が必要か？

それでは、どのような技術的決定を記録しますか？
```

---

## /adr:list - ADR一覧の表示

### 実行内容
1. docs/adr/ディレクトリのADRをリスト
2. ステータスごとに分類
3. 関連性のあるADRをグループ化

### プロンプト
```
### ADR一覧

#### Accepted（承認済み）
- ADR-001: [タイトル] - [日付]
- ADR-002: [タイトル] - [日付]

#### Proposed（提案中）
- ADR-003: [タイトル] - [日付]

#### Deprecated（非推奨）
- ADR-004: [タイトル] - [日付] → Superseded by ADR-005

#### 最近の決定（過去30日）
- ADR-00X: [タイトル] - [重要度]

詳細を見たいADRがあれば番号を指定してください。
```

---

## /adr:review - ADRレビュー

### 実行内容
1. 指定されたADRの内容を確認
2. 実装状況をチェック
3. 成功指標の評価
4. 見直しの必要性を判断

### プロンプト
```
### ADRレビュー: ADR-[XXX]

#### 実装状況
- [ ] 実装計画通りに進行
- [ ] 予期しない問題の発生
- [ ] 成功指標の達成度

#### Design Sync確認
- [ ] 設計と実装の一致
- [ ] ドキュメントの更新状況
- [ ] 技術的負債の発生

#### 推奨アクション
[現在の状況に基づく推奨事項]
```

---

## 使用例

### 新しいADRを作成する場合
```
User: /adr:create
Assistant: [ADR作成プロンプトを表示し、ユーザーを誘導]
```

### ADR一覧を確認する場合
```
User: /adr:list
Assistant: [現在のADR一覧をステータス別に表示]
```

### 特定のADRをレビューする場合
```
User: /adr:review ADR-001
Assistant: [ADR-001の実装状況と評価を表示]
```

## 関連ファイル
- ADRテンプレート: @.claude/shared/templates/adr/adr-template.md
- 既存のADR: @docs/adr/
- Design Sync: @.claude/shared/design-sync.md
- 技術的負債: @.claude/context/debt.md

## 注意事項
- ADRは重要な技術的決定のみに使用（日常的な実装判断は不要）
- 番号は連番で管理（欠番を作らない）
- Deprecatedにする際は必ず後継のADRを指定
- レビュースケジュールを守る（3-6ヶ月ごと）