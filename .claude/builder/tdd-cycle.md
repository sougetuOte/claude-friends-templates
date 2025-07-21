# TDD（テスト駆動開発）サイクル実践ガイド

## はじめに
このガイドは、BuilderエージェントがTDDを厳格に実践するための詳細な手順書です。
claude-kiro-templateの優れたTDD手法（t-wada流）を取り入れています。

## TDDの基本原則

### 黄金律
**「実装コードを書く前に、必ず失敗するテストを書く」**

### 3つのフェーズ
1. **🔴 Red Phase**: 失敗するテストを書く
2. **🟢 Green Phase**: テストを通す最小限の実装
3. **🔵 Refactor Phase**: コードの品質向上

## 詳細な実践手順

### 🔴 Red Phase（テストファースト）

#### 1. テストファイルの作成
```bash
# 例: 新機能 calculateTotalPrice の場合
touch tests/test_calculate_total_price.py  # Python
touch __tests__/calculateTotalPrice.test.js # JavaScript
```

#### 2. 失敗するテストを書く
```python
# Python例
def test_calculate_total_price_with_single_item():
    # Arrange
    items = [{"price": 100, "quantity": 2}]
    
    # Act
    result = calculate_total_price(items)  # まだ実装していない関数
    
    # Assert
    assert result == 200
```

#### 3. テストが失敗することを確認
```bash
# テスト実行
pytest tests/test_calculate_total_price.py -v
# または
npm test calculateTotalPrice
```

**重要**: エラーメッセージを確認し、期待通りの理由で失敗していることを確認

#### 4. コミット
```bash
git add tests/
git commit -m "test: add failing test for calculate_total_price"
```

### 🟢 Green Phase（最小実装）

#### 1. 最小限の実装
```python
# 仮実装でOK！
def calculate_total_price(items):
    return 200  # ベタ書きでテストを通す
```

#### 2. テストが通ることを確認
```bash
pytest tests/test_calculate_total_price.py -v
# すべてのテストがGREENになることを確認
```

#### 3. タスクステータスを更新
- builder/notes.mdに記録
- phase-todo.mdのタスクを🔴→🟢に更新

#### 4. コミット
```bash
git add src/
git commit -m "feat: implement calculate_total_price to pass test"
```

### 三角測量（一般化）

#### 1. 2つ目のテストケースを追加
```python
def test_calculate_total_price_with_multiple_items():
    # Arrange
    items = [
        {"price": 100, "quantity": 2},
        {"price": 50, "quantity": 3}
    ]
    
    # Act
    result = calculate_total_price(items)
    
    # Assert
    assert result == 350  # 200 + 150
```

#### 2. 一般化した実装
```python
def calculate_total_price(items):
    total = 0
    for item in items:
        total += item["price"] * item["quantity"]
    return total
```

### 🔵 Refactor Phase（品質向上）

#### 1. リファクタリング候補の検討
- [ ] 可読性の向上
- [ ] 重複の除去
- [ ] パフォーマンスの改善
- [ ] エラーハンドリングの追加

#### 2. リファクタリング実施
```python
def calculate_total_price(items):
    """商品リストから合計金額を計算する
    
    Args:
        items: 商品情報のリスト [{"price": int, "quantity": int}, ...]
        
    Returns:
        int: 合計金額
        
    Raises:
        ValueError: 無効な商品情報の場合
    """
    if not items:
        return 0
        
    return sum(
        item.get("price", 0) * item.get("quantity", 0)
        for item in items
    )
```

#### 3. テストが通り続けることを確認
```bash
# すべてのテストを実行
pytest -v
# カバレッジも確認
pytest --cov=src --cov-report=html
```

#### 4. タスクステータスを更新
- phase-todo.mdのタスクを🟢→✅に更新

#### 5. コミット
```bash
git add -A
git commit -m "refactor: improve calculate_total_price readability and error handling"
```

## TDDのベストプラクティス

### 小さなステップ
- 一度に1つの機能のみ実装
- 15分以内で完了できる単位に分割

### TODOリスト管理
```markdown
## 現在のタスク: 価格計算機能 🔴
- [x] 単一商品の計算
- [ ] 複数商品の計算
- [ ] 割引の適用
- [ ] 税金の計算
- [ ] エラーハンドリング
```

### 不安なところから着手
- 最も複雑な部分
- 最も重要な部分
- 最も不確実な部分

## ⚠️ ブロック時の対応

### 3回失敗したら
1. タスクステータスを⚠️に変更
2. ブロック理由を記録
```markdown
## 現在のタスク: 外部API連携 ⚠️
ブロック理由: APIの仕様が不明確
試行した解決策:
1. ドキュメントの確認 → 記載なし
2. サンプルコードの検索 → 見つからず
3. モックでの仮実装 → 仕様が推測できず
次の対応: Plannerへエスカレーション
```

### Plannerへの引き継ぎ
- handover.mdに詳細を記載
- 技術的な課題と制約を明確に伝える

## チェックリスト

### Red Phase チェック
- [ ] テストファイルを作成した
- [ ] テストが失敗することを確認した
- [ ] エラーメッセージが期待通り
- [ ] テストコードをコミットした

### Green Phase チェック
- [ ] 最小限の実装でテストが通った
- [ ] すべての既存テストも通っている
- [ ] タスクステータスを🟢に更新した
- [ ] 実装コードをコミットした

### Refactor Phase チェック
- [ ] コードの可読性が向上した
- [ ] テストが通り続けている
- [ ] カバレッジが維持/向上している
- [ ] タスクステータスを✅に更新した
- [ ] リファクタリングをコミットした

## 参考リンク
- [t-wada/tdd-bc](https://github.com/t-wada/tdd-bc) - TDDブートキャンプ
- [テスト駆動開発](https://www.amazon.co.jp/dp/4274217884) - Kent Beck著

---
*このガイドは、BuilderエージェントがTDDを確実に実践するための指針です。*