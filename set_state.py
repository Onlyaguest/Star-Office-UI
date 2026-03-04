#!/usr/bin/env python3
"""Star Office 状态更新工具（支持对话秒切工作流）

兼容旧用法：
  python set_state.py <state> [detail]

增强用法：
  python set_state.py start "正在回复主人" --ttl 120
  python set_state.py sync "正在 push 代码" --ttl 300
  python set_state.py done "待命中"
"""

import argparse
import json
import os
import sys
from datetime import datetime

STATE_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "state.json")

VALID_STATES = [
    "idle",
    "writing",
    "researching",
    "executing",
    "syncing",
    "error"
]

ALIASES = {
    "start": "writing",
    "work": "writing",
    "working": "writing",
    "research": "researching",
    "run": "executing",
    "exec": "executing",
    "sync": "syncing",
    "done": "idle",
    "stop": "idle",
    "err": "error",
}


def normalize_state(s: str) -> str:
    s = (s or "").strip().lower()
    s = ALIASES.get(s, s)
    return s


def load_state():
    if os.path.exists(STATE_FILE):
        with open(STATE_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    return {
        "state": "idle",
        "detail": "待命中...",
        "progress": 0,
        "updated_at": datetime.now().isoformat(),
        "ttl_seconds": 300,
    }


def save_state(state):
    with open(STATE_FILE, "w", encoding="utf-8") as f:
        json.dump(state, f, ensure_ascii=False, indent=2)


def build_parser():
    p = argparse.ArgumentParser(description="更新 Star Office 状态")
    p.add_argument("state", help=f"状态（支持别名）: {', '.join(VALID_STATES)}")
    p.add_argument("detail", nargs="?", default="", help="状态详情")
    p.add_argument("--ttl", type=int, default=None, help="自动回 idle 的秒数（仅 working 态生效）")
    p.add_argument("--progress", type=int, default=None, help="进度 0-100")
    p.add_argument("--source", default="", help="来源标记，如 chat/tool/sync")
    p.add_argument("--trace-id", default="", help="链路ID（可选）")
    return p


if __name__ == "__main__":
    parser = build_parser()
    args = parser.parse_args()

    state_name = normalize_state(args.state)
    if state_name not in VALID_STATES:
        print(f"无效状态: {args.state}")
        print(f"有效选项: {', '.join(VALID_STATES)}")
        print(f"别名: {', '.join(sorted(ALIASES.keys()))}")
        sys.exit(1)

    state = load_state()
    state["state"] = state_name
    state["detail"] = args.detail or state.get("detail", "")
    state["updated_at"] = datetime.now().isoformat()

    if args.ttl is not None:
        state["ttl_seconds"] = max(5, int(args.ttl))
    elif "ttl_seconds" not in state:
        state["ttl_seconds"] = 300

    if args.progress is not None:
        state["progress"] = max(0, min(100, int(args.progress)))

    if args.source:
        state["source"] = args.source

    if args.trace_id:
        state["trace_id"] = args.trace_id

    save_state(state)
    print(f"状态已更新: {state_name} - {state.get('detail', '')}")
