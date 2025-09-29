# Mermaid図解ガイド（Planner用）

## 概要
このガイドは、Plannerエージェントが設計書で効果的な図を作成するためのMermaid記法の実践的な使い方をまとめています。

## Mermaidとは
- テキストベースの図表作成ツール
- Markdownに埋め込み可能
- バージョン管理しやすい
- 多様な図表タイプをサポート

## 基本的な使い方

### Markdownへの埋め込み
````markdown
```mermaid
graph TD
    A[開始] --> B[処理]
    B --> C[終了]
```
````

## 図表タイプ別ガイド

### 1. フローチャート（処理の流れ）

#### 基本構文
```mermaid
graph TD
    A[開始] --> B{条件分岐}
    B -->|Yes| C[処理A]
    B -->|No| D[処理B]
    C --> E[終了]
    D --> E
```

#### 実践例：ユーザー登録フロー
```mermaid
graph TD
    Start[ユーザー登録開始] --> Input[情報入力]
    Input --> Validate{入力検証}
    Validate -->|OK| CheckDup{重複確認}
    Validate -->|NG| Error1[エラー表示]
    Error1 --> Input
    CheckDup -->|重複なし| Save[DB保存]
    CheckDup -->|重複あり| Error2[重複エラー]
    Error2 --> Input
    Save --> Email[確認メール送信]
    Email --> Complete[登録完了]
```

### 2. シーケンス図（処理の順序）

#### 基本構文
```mermaid
sequenceDiagram
    participant A as クライアント
    participant B as サーバー
    A->>B: リクエスト
    B-->>A: レスポンス
```

#### 実践例：API認証フロー
```mermaid
sequenceDiagram
    participant C as Client
    participant G as API Gateway
    participant A as Auth Service
    participant S as Service

    C->>G: Request + Token
    G->>A: Validate Token
    A-->>G: Token Valid
    G->>S: Forward Request
    S-->>G: Response
    G-->>C: Response

    Note over A: トークン検証には<br/>有効期限チェックも含む
```

### 3. クラス図（構造）

#### 基本構文
```mermaid
classDiagram
    class ClassName {
        +public_property
        -private_property
        +public_method()
        -private_method()
    }
```

#### 実践例：ユーザー管理システム
```mermaid
classDiagram
    class User {
        -id: string
        -email: string
        -password: string
        +getId() string
        +getEmail() string
        +authenticate(password) boolean
    }

    class UserService {
        -userRepository: UserRepository
        +createUser(data) User
        +findUser(id) User
        +updateUser(id, data) User
        +deleteUser(id) void
    }

    class UserRepository {
        <<interface>>
        +save(user) User
        +findById(id) User
        +update(user) User
        +delete(id) void
    }

    UserService --> UserRepository : uses
    UserService --> User : creates
```

### 4. ER図（データベース設計）

#### 基本構文
```mermaid
erDiagram
    ENTITY {
        type name
    }
    ENTITY1 ||--o{ ENTITY2 : relationship
```

#### 実践例：ECサイトのDB設計
```mermaid
erDiagram
    User ||--o{ Order : places
    User {
        string id PK
        string email UK
        string name
        datetime created_at
    }

    Order ||--|{ OrderItem : contains
    Order {
        string id PK
        string user_id FK
        decimal total_amount
        string status
        datetime ordered_at
    }

    Product ||--o{ OrderItem : included_in
    Product {
        string id PK
        string name
        decimal price
        integer stock
    }

    OrderItem {
        string id PK
        string order_id FK
        string product_id FK
        integer quantity
        decimal unit_price
    }
```

### 5. 状態遷移図

#### 基本構文
```mermaid
stateDiagram-v2
    [*] --> State1
    State1 --> State2 : Event
    State2 --> [*]
```

#### 実践例：注文ステータス
```mermaid
stateDiagram-v2
    [*] --> 注文受付
    注文受付 --> 支払待ち : 注文確定
    支払待ち --> 支払完了 : 入金確認
    支払待ち --> キャンセル : 期限切れ
    支払完了 --> 準備中 : 処理開始
    準備中 --> 発送済み : 発送処理
    発送済み --> 配達完了 : 配達確認
    配達完了 --> [*]
    キャンセル --> [*]

    note right of 支払待ち
        24時間以内に
        支払いがない場合
        自動キャンセル
    end note
```

### 6. ガントチャート（スケジュール）

#### 基本構文
```mermaid
gantt
    title プロジェクトスケジュール
    dateFormat YYYY-MM-DD
    section セクション
    タスク1 :a1, 2024-01-01, 30d
    タスク2 :after a1, 20d
```

#### 実践例：開発スケジュール
```mermaid
gantt
    title 新機能開発スケジュール
    dateFormat YYYY-MM-DD

    section 設計フェーズ
    要件定義     :des1, 2024-01-01, 7d
    設計書作成   :des2, after des1, 5d
    設計レビュー :des3, after des2, 2d

    section 開発フェーズ
    環境構築     :dev1, after des3, 3d
    API開発      :dev2, after dev1, 10d
    フロント開発 :dev3, after dev1, 12d

    section テストフェーズ
    単体テスト   :test1, after dev2, 5d
    統合テスト   :test2, after dev3, 5d
    受け入れテスト :test3, after test2, 3d
```

### 7. 円グラフ（割合表示）

#### 基本構文
```mermaid
pie title タイトル
    "項目1" : 30
    "項目2" : 20
    "項目3" : 50
```

#### 実践例：工数配分
```mermaid
pie title 開発工数配分
    "要件定義" : 15
    "設計" : 20
    "実装" : 35
    "テスト" : 20
    "ドキュメント" : 10
```

## 設計書での効果的な使い方

### 1. 図の選び方
- **処理の流れ** → フローチャート
- **時系列の処理** → シーケンス図
- **システム構造** → クラス図
- **データ構造** → ER図
- **状態の変化** → 状態遷移図
- **スケジュール** → ガントチャート

### 2. 図を使うべき場面
- 複雑な処理ロジックの説明
- システム間の連携
- データの関係性
- 時間的な流れ
- 全体像の把握

### 3. 良い図の特徴
- **シンプル**: 一目で理解できる
- **完結**: 必要な情報が含まれている
- **一貫性**: 記号や色の使い方が統一
- **適切な粒度**: 詳細すぎず、粗すぎず

## よく使うパターン集

### システム構成図
```mermaid
graph TB
    subgraph "Frontend"
        Web[Webアプリ]
        Mobile[モバイルアプリ]
    end

    subgraph "Backend"
        LB[ロードバランサー]
        API1[APIサーバー1]
        API2[APIサーバー2]
    end

    subgraph "Data Layer"
        Cache[(Redis)]
        DB[(PostgreSQL)]
    end

    Web --> LB
    Mobile --> LB
    LB --> API1
    LB --> API2
    API1 --> Cache
    API1 --> DB
    API2 --> Cache
    API2 --> DB
```

### 認証フロー
```mermaid
sequenceDiagram
    participant U as User
    participant F as Frontend
    participant B as Backend
    participant D as Database

    U->>F: ログイン情報入力
    F->>B: POST /auth/login
    B->>D: ユーザー検証
    D-->>B: ユーザー情報
    B->>B: パスワード検証
    B->>B: JWT生成
    B-->>F: JWT + ユーザー情報
    F->>F: JWTをローカルストレージに保存
    F-->>U: ダッシュボード表示
```

### エラーハンドリングフロー
```mermaid
graph TD
    Start[処理開始] --> Try{エラー発生?}
    Try -->|No| Success[正常終了]
    Try -->|Yes| ErrorType{エラー種別}
    ErrorType -->|Validation| ValError[400 Bad Request]
    ErrorType -->|NotFound| NotFound[404 Not Found]
    ErrorType -->|Auth| AuthError[401 Unauthorized]
    ErrorType -->|Other| ServerError[500 Server Error]
    ValError --> Log[エラーログ記録]
    NotFound --> Log
    AuthError --> Log
    ServerError --> Alert[アラート通知]
    Alert --> Log
    Log --> Response[エラーレスポンス返却]
```

## Tips & トラブルシューティング

### よくある問題と解決法
1. **矢印が表示されない**: `-->` の前後にスペースを入れない
2. **日本語が文字化け**: エンコーディングをUTF-8に
3. **図が大きすぎる**: 図を分割するか、詳細度を下げる

### パフォーマンスの考慮
- 大きな図は描画に時間がかかる
- ノード数は50個程度まで
- 必要に応じて複数の図に分割

### メンテナンスしやすい図
- ノードにはIDを付ける
- 色は控えめに使用
- コメントを活用する

---
*図は千の言葉に勝る。Mermaidで設計意図を視覚的に伝えましょう。*
