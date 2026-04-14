#!/bin/bash
# Generate yesterday-memo.json from Roam daily note
set -e
OUTDIR="/data/happyroom"
cd "$HOME/roam-cli"
YESTERDAY=$(date -d "yesterday" +"%B %-dth, %Y" 2>/dev/null || date -v-1d +"%B %-dth, %Y")
YDATE=$(date -d "yesterday" +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d)
RAW=$(bb read yuanvv "$YESTERDAY" 2>/dev/null || echo "")
if [ -z "$RAW" ]; then
  echo '{"success":false,"msg":"没有找到昨日日记"}' > "$OUTDIR/yesterday-memo.json"
else
  python3 -c "
import json,sys
lines=[l.strip() for l in sys.stdin.read().strip().split('\n') if l.strip() and not l.strip().startswith('#')]
bullets=[l[2:].strip() if l.startswith('- ') else l for l in lines][:3]
memo='\n'.join('· '+b[:40] for b in bullets) if bullets else '暂无内容'
json.dump({'success':True,'date':'$YDATE','memo':memo},open('$OUTDIR/yesterday-memo.json','w'),ensure_ascii=False)
" <<< "$RAW"
fi
