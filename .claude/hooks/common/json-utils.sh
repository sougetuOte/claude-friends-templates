#!/bin/bash
# json-utils.sh - TDD Refactored
# JSONユーティリティ関数 - セキュリティ強化、エラーハンドリング改善済み

set -euo pipefail

# validate_json - セキュリティ強化されたJSON検証
validate_json() {
    local json_input=""

    # 標準入力からJSONを読み取り（サイズ制限付き）
    if ! [[ -t 0 ]]; then
        # 1MB制限で入力を読み取り
        if ! json_input=$(head -c 1048576 2>/dev/null); then
            return 1
        fi
    fi

    # 空入力チェック
    if [[ -z "$json_input" ]]; then
        return 1
    fi

    # セキュリティチェック：危険なパターンを検出
    local dangerous_patterns=(
        '</script>'     # XSS攻撃
        'javascript:'   # JavaScript実行
        'eval('         # コード実行
        'system('       # システムコール
        'exec('         # コマンド実行
        '$('            # コマンド置換
        '`'             # コマンド置換
        '../'           # ディレクトリトラバーサル
        ';'             # コマンド区切り
        '&'             # バックグラウンド実行
        '|'             # パイプ
        $'\x00'         # ヌルバイト
        $'\u0000'       # ヌルバイト（Unicode）
    )

    for pattern in "${dangerous_patterns[@]}"; do
        if [[ "$json_input" == *"$pattern"* ]]; then
            echo "[ERROR] Dangerous pattern detected in JSON: $pattern" >&2
            return 1
        fi
    done

    # サイズ制限（既存より厳格に）
    if [[ ${#json_input} -gt 1048576 ]]; then  # 1MB制限
        echo "[ERROR] JSON input too large: ${#json_input} bytes" >&2
        return 1
    fi

    # jqが使える場合
    if command -v jq >/dev/null 2>&1; then
        # 安全なオプションでjqを実行
        if ! echo "$json_input" | timeout 10s jq . >/dev/null 2>&1; then
            echo "[ERROR] Invalid JSON format" >&2
            return 1
        fi
    else
        # jqがない場合の簡易チェック（セキュリティ強化）

        # プリント可能文字とホワイトスペースのみ許可
        if [[ ! "$json_input" =~ ^[[:print:][:space:]]*$ ]]; then
            echo "[ERROR] Non-printable characters in JSON" >&2
            return 1
        fi

        # 基本的な構造チェックとバランスチェック
        if [[ "$json_input" =~ ^\{.*\}$ ]]; then
            # 中括弧のバランスを簡易チェック
            local open_count=$(grep -o '{' <<< "$json_input" | wc -l 2>/dev/null || echo 0)
            local close_count=$(grep -o '}' <<< "$json_input" | wc -l 2>/dev/null || echo 0)
            [[ $open_count -eq $close_count ]] && return 0
        elif [[ "$json_input" =~ ^\[.*\]$ ]]; then
            # 角括弧のバランスを簡易チェック
            local open_count=$(grep -o '\[' <<< "$json_input" | wc -l 2>/dev/null || echo 0)
            local close_count=$(grep -o '\]' <<< "$json_input" | wc -l 2>/dev/null || echo 0)
            [[ $open_count -eq $close_count ]] && return 0
        fi
        echo "[ERROR] Invalid JSON structure" >&2
        return 1
    fi
}

# extract_json_value - セキュリティ強化されたJSON値抽出
extract_json_value() {
    local -r key="${1:-}"
    local json_input=""

    # 入力検証
    if [[ -z "$key" ]]; then
        echo "[ERROR] Key parameter required" >&2
        return 1
    fi

    # キー名のセキュリティチェック
    if [[ ${#key} -gt 256 ]]; then
        echo "[ERROR] Key too long: ${#key} chars" >&2
        return 1
    fi

    # 安全なキー名のみ許可
    if [[ ! "$key" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        echo "[ERROR] Invalid key format: $key" >&2
        return 1
    fi

    # 標準入力からJSONを読み取り（サイズ制限付き）
    if ! [[ -t 0 ]]; then
        if ! json_input=$(head -c 1048576 2>/dev/null); then
            echo "[ERROR] Failed to read JSON input" >&2
            return 1
        fi
    fi

    # JSONのセキュリティ検証
    if ! echo "$json_input" | validate_json; then
        echo "[ERROR] Invalid JSON input" >&2
        return 1
    fi

    # jqが使える場合
    if command -v jq >/dev/null 2>&1; then
        local result

        # 安全なオプションでjqを実行（タイムアウト付き）
        if [[ "$key" == *"."* ]]; then
            result=$(echo "$json_input" | timeout 5s jq -r ".$key // \"\"" 2>/dev/null) || {
                echo "[ERROR] JSON extraction failed for key: $key" >&2
                return 1
            }
        else
            result=$(echo "$json_input" | timeout 5s jq -r ".$key // \"\"" 2>/dev/null) || {
                echo "[ERROR] JSON extraction failed for key: $key" >&2
                return 1
            }
        fi

        # 結果のセキュリティチェック
        if [[ ${#result} -gt 10000 ]]; then
            echo "[ERROR] Result too large: ${#result} chars" >&2
            return 1
        fi

        # nullの場合は空文字を返す
        if [[ "$result" == "null" ]]; then
            echo ""
        else
            # 危険な文字列をチェック
            local dangerous_chars=('$(' '`' ';' '&' '|' '../' $'\x00')
            local char
            for char in "${dangerous_chars[@]}"; do
                if [[ "$result" == *"$char"* ]]; then
                    echo "[ERROR] Dangerous character in result: $char" >&2
                    return 1
                fi
            done
            echo "$result"
        fi
    else
        # jqがない場合の簡易実装（セキュリティ強化）
        local pattern="\"$key\"[[:space:]]*:[[:space:]]*\"([^\"]*)\""

        # パターンマッチングの安全性を確認
        if [[ "$json_input" =~ $pattern ]]; then
            local match="${BASH_REMATCH[1]}"

            # 結果のセキュリティチェック
            if [[ ${#match} -gt 1000 ]]; then
                echo "[ERROR] Match too large: ${#match} chars" >&2
                return 1
            fi

            # 危険な文字列をチェック
            if [[ "$match" == *'$('* ]] || [[ "$match" == *'`'* ]] || [[ "$match" == *';'* ]]; then
                echo "[ERROR] Dangerous characters in extracted value" >&2
                return 1
            fi

            echo "$match"
        else
            # 数値やbooleanの場合
            pattern="\"$key\"[[:space:]]*:[[:space:]]*([0-9]+|true|false)"
            if [[ "$json_input" =~ $pattern ]]; then
                echo "${BASH_REMATCH[1]}"
            else
                echo ""
            fi
        fi
    fi
    return 0
}

# create_json_object - JSONオブジェクトを作成
create_json_object() {
    local output="{"
    local first=true

    # 引数を2つずつ処理（key-valueペア）
    while [[ $# -gt 0 ]]; do
        local key="$1"
        local value="${2:-}"

        # カンマを追加（最初以外）
        if [[ "$first" == true ]]; then
            first=false
        else
            output+=","
        fi

        # 値のエスケープ処理（正しい順序で完全なエスケープ）
        value="${value//\\/\\\\}"  # バックスラッシュ
        value="${value//\"/\\\"}"   # ダブルクォート
        value="${value//$'\n'/\\n}"   # 改行
        value="${value//$'\t'/\\t}"   # タブ
        value="${value//$'\r'/\\r}"   # キャリッジリターン

        # key-valueペアを追加
        output+="\"$key\":\"$value\""

        # 次のペアへ
        shift 2 || shift  # 引数が奇数の場合の対策
    done

    output+="}"
    echo "$output"
    return 0
}

# merge_json - 2つのJSONオブジェクトをマージ
merge_json() {
    local json1="$1"
    local json2="$2"

    # 入力験証
    if [[ -z "$json1" ]]; then
        printf '%s' "$json2"
        return 0
    fi
    if [[ -z "$json2" ]]; then
        printf '%s' "$json1"
        return 0
    fi

    # jqが使える場合
    if command -v jq >/dev/null 2>&1; then
        # エラーハンドリングを改善
        local result
        if result=$(printf '%s' "$json1" | jq --argjson obj2 "$json2" '. + $obj2' 2>/dev/null); then
            printf '%s' "$result"
        else
            # jqが失敗した場合は簡易マージにフォールバック
            _simple_merge "$json1" "$json2"
        fi
    else
        _simple_merge "$json1" "$json2"
    fi
    return 0
}

# _simple_merge - jqがない場合の簡易マージ実装
_simple_merge() {
    local json1="$1"
    local json2="$2"

    # 両方ぎJSONから中身を取り出し
    local content1="${json1#\{}"
    content1="${content1%\}}"
    local content2="${json2#\{}"
    content2="${content2%\}}"

    # 簡易的なマージ（重複キーは考慮しない最小実装）
    if [[ -n "$content1" && -n "$content2" ]]; then
        printf '{%s,%s}' "$content1" "$content2"
    elif [[ -n "$content1" ]]; then
        printf '{%s}' "$content1"
    else
        printf '{%s}' "$content2"
    fi
}

# json_to_env - JSONを環境変数にエクスポート
json_to_env() {
    local json_file="$1"
    local prefix="${2:-}"

    if [[ ! -f "$json_file" ]]; then
        return 1
    fi

    # jqが使える場合
    if command -v jq >/dev/null 2>&1; then
        # フラットなJSONの処理
        local json_content
        json_content=$(cat "$json_file")

        # キーと値のペアを処理
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                # プレフィックスを追加
                if [[ -n "$prefix" ]]; then
                    # ネストしたキーの処理（DATABASE_HOST形式に変換）
                    line="${line^^}"  # 大文字に変換
                    line="${line//./_}"  # ドットをアンダースコアに
                    echo "export ${prefix}${line}"
                else
                    echo "export $line"
                fi
            fi
        done < <(jq -r 'to_entries | .[] | "\(.key)=\(.value)"' "$json_file" 2>/dev/null)

        # ネストしたJSONの処理（プレフィックス付き）
        if [[ -n "$prefix" ]]; then
            # ネストしたオブジェクトのフラット化
            while IFS= read -r line; do
                if [[ -n "$line" ]]; then
                    # キー名を大文字に変換し、ドットをアンダースコアに
                    local key="${line%%=*}"
                    local value="${line#*=}"
                    key="${key^^}"
                    key="${key//./_}"
                    echo "export ${prefix}${key}=\"$value\""
                fi
            done < <(jq -r 'paths(scalars) as $p | "\($p | join("_"))=\(getpath($p))"' "$json_file" 2>/dev/null)
        fi
    else
        # jqがない場合の簡易実装
        # 基本的なkey-valueペアのみ対応
        while IFS= read -r line; do
            if [[ "$line" =~ \"([^\"]+)\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
                local key="${BASH_REMATCH[1]}"
                local value="${BASH_REMATCH[2]}"
                if [[ -n "$prefix" ]]; then
                    key="${key^^}"
                    echo "export ${prefix}${key}=\"$value\""
                else
                    echo "export ${key}=\"$value\""
                fi
            fi
        done < "$json_file"
    fi
    return 0
}