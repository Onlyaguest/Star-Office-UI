# 对话秒切状态接入指南（核心功能）

目标：让“收到消息→工作中，回复完成→待命，push/同步→syncing”稳定秒切。

## 1) 最小接入（推荐）

### 收到用户消息时
```bash
python3 set_state.py start "正在回复主人..." --ttl 120 --source chat
```

### 执行同步/发布动作时
```bash
python3 set_state.py sync "正在同步代码到远端..." --ttl 300 --source sync
```

### 回复完成时
```bash
python3 set_state.py done "待命中，随时准备" --source chat
```

### 发生异常时
```bash
python3 set_state.py err "处理失败，正在排查" --ttl 120 --source chat
```

---

## 2) 命令型任务推荐用 guard（防漏切）

```bash
bash scripts/state_guard.sh \
  --state syncing \
  --detail "正在 push 分支" \
  --ttl 300 \
  --idle-detail "同步完成，待命中" \
  -- git push fork feat/office-art-rebuild
```

特点：
- 命令开始前自动切状态
- 命令结束后自动回 idle
- 命令失败自动切 error

---

## 3) 验收标准（你可以直接在线看）

1. 你发消息后，角色应在 0.5~1 秒内切到工作态
2. 回复发出后，1 秒内回待命态
3. push/generate 等重操作期间，应切到 syncing 或 executing
4. detail 文案应跟当前动作一致

---

## 4) 注意事项

- 必须保证“每个链路都有 finally 回 idle”
- 不要只在 UI 按钮里切状态；对话链路也必须切
- 长任务务必设置合适 ttl，避免卡死在 working 态
