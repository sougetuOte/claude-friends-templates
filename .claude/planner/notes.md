# Planner Notes

## 現在のPhase: Claude Friends導入
- 開始日: 2025-07-11
- 期限: 未設定（段階的導入）
- 目的: シーケンシャル・マルチエージェントシステムの実装

## Phase内のToDo（優先順）
- [x] Phase 1: 基礎構造の構築（完了）
- [ ] Phase 2: エージェントファイルの実装（進行中）
- [ ] Phase 3: 切り替えコマンドの実装
- [ ] Phase 4: 既存システムとの統合
- [ ] Phase 5: 運用開始と最適化

## 現在作業中
Phase 2のファイル作成を進めています：
- [x] planner/identity.md 作成
- [ ] planner/notes.md 作成（このファイル）
- [ ] planner/handover.md 作成
- [ ] builder/identity.md 作成
- [ ] builder/notes.md 作成
- [ ] builder/handover.md 作成
- [ ] shared/constraints.md 作成
- [ ] shared/phase-todo.md 作成

## 次のPhase候補
- **運用フェーズ**: Claude Friendsを使った実プロジェクト開発
- **拡張フェーズ**: 3つ目のエージェント（UX Designer等）の追加

## メモ
- シンプルさを保つことが重要（個人開発者向け）
- 既存のMemory Bankシステムとの調和を図る
- 段階的な導入で混乱を避ける

## 決定事項
- エージェントは2つ（Planner/Builder）に限定
- Phase/ToDo の2階層管理を採用（SoWは不採用）
- 割り込み処理は専用handoverファイルで対応

## 課題・懸念
- 既存のcore/current.mdとの統合方法
- エージェント切り替えの使い勝手
- 1週間後のアーカイブ処理の自動化
