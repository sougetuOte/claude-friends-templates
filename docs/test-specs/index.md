# テスト仕様書

## 概要
プロジェクトのテスト戦略とテスト仕様を管理するディレクトリです。

## テスト戦略

### テストレベル
1. **単体テスト（Unit Test）**
   - カバレッジ目標: 80%以上
   - TDD必須

2. **統合テスト（Integration Test）**
   - 主要な連携部分をカバー
   - APIテスト含む

3. **E2Eテスト（End-to-End Test）**
   - 主要なユーザーシナリオをカバー
   - 必要に応じて実施

## テスト仕様一覧

| テスト仕様 | 対象 | 種別 | ステータス |
|-----------|------|------|-----------|
| - | - | - | - |

## TDDサイクル
1. 🔴 **Red**: 失敗するテストを書く
2. 🟢 **Green**: テストを通す最小実装
3. 🔵 **Refactor**: コードの品質向上

## テスト作成ガイドライン
- テストは仕様を表現するように書く
- 1つのテストは1つの振る舞いをテスト
- テスト名は何をテストしているか明確に
- Arrange-Act-Assertパターンを使用

## 注意事項
- 新機能実装時は必ずテストファーストで
- 既存コード修正時も回帰テストを追加
- テストが通らない実装はマージしない