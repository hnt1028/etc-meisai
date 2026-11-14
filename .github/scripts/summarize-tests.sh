#!/usr/bin/env bash
# Summarize `flutter test --machine` JSON lines and emit failure annotations.
declare -A names
total=0
failed=0
while IFS= read -r line; do
  [[ "$line" == \{* ]] || continue
  if [[ "$line" == *'"type":"testStart"'* ]]; then
    if [[ "$line" =~ \"test\":\{\"id\":([0-9]+),\"name\":\"([^\"]*)\" ]]; then
      names[${BASH_REMATCH[1]}]="${BASH_REMATCH[2]}"
    fi
  elif [[ "$line" == *'"type":"testDone"'* && "$line" == *'"hidden":false'* ]]; then
    total=$((total + 1))
    id=""
    if [[ "$line" =~ \"testID\":([0-9]+) ]]; then
      id="${BASH_REMATCH[1]}"
    fi
    if [[ "$line" != *'"result":"success"'* && "$line" != *'"skipped":true'* ]]; then
      failed=$((failed + 1))
      echo "::error title=Test failed::${names[$id]:-unknown test}"
    fi
  fi
done < "$1"
passed=$((total - failed))
echo "total=$total passed=$passed failed=$failed"

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    echo "## テスト結果"
    echo ""
    echo "| 合計 | 成功 | 失敗 |"
    echo "|---|---|---|"
    echo "| $total | $passed | $failed |"
  } >> "$GITHUB_STEP_SUMMARY"
fi
