#!/usr/bin/env bash
set -euo pipefail

# 用途：将任意命令包在“状态生命周期”里，保证结束后自动回 idle。
# 示例：
#   bash scripts/state_guard.sh --state syncing --detail "正在 push 代码" --ttl 300 -- git push fork feat/office-art-rebuild

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SET_STATE="python3 $ROOT_DIR/set_state.py"

STATE="writing"
DETAIL="执行任务中"
TTL="300"
IDLE_DETAIL="待命中"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --state)
      STATE="$2"; shift 2 ;;
    --detail)
      DETAIL="$2"; shift 2 ;;
    --ttl)
      TTL="$2"; shift 2 ;;
    --idle-detail)
      IDLE_DETAIL="$2"; shift 2 ;;
    --)
      shift
      break ;;
    *)
      echo "未知参数: $1"
      exit 2 ;;
  esac
done

if [[ $# -eq 0 ]]; then
  echo "用法: bash scripts/state_guard.sh --state writing --detail \"...\" -- <command ...>"
  exit 2
fi

$SET_STATE "$STATE" "$DETAIL" --ttl "$TTL" --source guard >/dev/null || true

EXIT_CODE=0
if "$@"; then
  EXIT_CODE=0
else
  EXIT_CODE=$?
fi

if [[ $EXIT_CODE -eq 0 ]]; then
  $SET_STATE idle "$IDLE_DETAIL" --source guard >/dev/null || true
else
  $SET_STATE error "任务失败(exit=$EXIT_CODE)" --ttl 120 --source guard >/dev/null || true
fi

exit $EXIT_CODE
