#!/bin/bash

# rotation-config.sh - ローテーション機能の設定ファイル

# ローテーション設定
export ROTATION_MAX_LINES=${ROTATION_MAX_LINES:-500}
export ROTATION_ARCHIVE_DAYS=${ROTATION_ARCHIVE_DAYS:-90}  # アーカイブ保持日数

# 要約抽出パターン
export SUMMARY_PATTERNS=(
    "^##"                    # 見出し2
    "^###"                   # 見出し3
    "^- \[x\]"               # 完了タスク
    "^- \[ \]"               # 未完了タスク
    "決定:"                  # 決定事項
    "重要:"                  # 重要事項
    "TODO:"                  # TODO
    "FIXME:"                 # FIXME
    "問題:"                  # 問題
    "解決:"                  # 解決
    "変更:"                  # 変更
    "追加:"                  # 追加
    "削除:"                  # 削除
    "修正:"                  # 修正
)

# アーカイブディレクトリ名
export ARCHIVE_DIR_NAME="archive"

# テンプレート設定
export NOTES_TEMPLATE_HEADER="# %AGENT% Notes

## 現在の作業
- [ ] 

## メモ


## 参照
- 前回の要約: notes-summary.md
- アーカイブ: ./%ARCHIVE_DIR%/

---
*ローテーション日時: %TIMESTAMP%*"