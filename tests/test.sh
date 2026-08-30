#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/state" "$TMP/runtime"

cat >"$TMP/state/workspaces.json" <<'JSON'
[
  {"id":101,"idx":1,"name":"main","output":"DP-1","is_focused":true,"is_active":true,"active_window_id":1},
  {"id":102,"idx":2,"name":"dev","output":"DP-1","is_focused":false,"is_active":false,"active_window_id":3}
]
JSON

cat >"$TMP/state/windows.json" <<'JSON'
[
  {"id":1,"app_id":"com.mitchellh.ghostty","workspace_id":101,"is_focused":true,"focus_timestamp":{"secs":10,"nanos":0}},
  {"id":2,"app_id":"com.mitchellh.ghostty","workspace_id":101,"is_focused":false,"focus_timestamp":{"secs":20,"nanos":0}},
  {"id":3,"app_id":"com.mitchellh.ghostty","workspace_id":102,"is_focused":false,"focus_timestamp":{"secs":30,"nanos":0}},
  {"id":4,"app_id":"dev.zaviro.tui.yazi","workspace_id":101,"is_focused":false,"focus_timestamp":{"secs":40,"nanos":0}},
  {"id":5,"app_id":"com.openai.chatgpt","workspace_id":102,"is_focused":false,"focus_timestamp":{"secs":50,"nanos":0}},
  {"id":6,"app_id":"dev.zaviro.role.terminal-main","workspace_id":102,"is_focused":false,"focus_timestamp":{"secs":60,"nanos":0}},
  {"id":7,"app_id":"mock.obsidian","workspace_id":102,"is_focused":false,"focus_timestamp":{"secs":61,"nanos":0}},
  {"id":8,"app_id":"mock.obsidian","workspace_id":102,"is_focused":false,"focus_timestamp":{"secs":70,"nanos":0}}
]
JSON

cat >"$TMP/bin/niri" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
D=$WKB_MOCK_DIR

if [[ "$1 $2 $3" == "msg --json windows" ]]; then
  cat "$D/windows.json"
  exit 0
fi
if [[ "$1 $2 $3" == "msg --json workspaces" ]]; then
  cat "$D/workspaces.json"
  exit 0
fi
if [[ "$1 $2 $3" == "msg action focus-window" ]]; then
  id=$5
  echo "focus:$id" >>"$D/actions.log"
  exit 0
fi
if [[ "$1 $2 $3" == "msg action move-window-to-workspace" ]]; then
  id=$5
  ref=$8
  wsid=$(jq -r --arg ref "$ref" '.[] | select((.name // "") == $ref or (.idx | tostring) == $ref) | .id' "$D/workspaces.json" | head -n1)
  echo "move:$id:$ref:$wsid" >>"$D/actions.log"
  tmp=$(mktemp)
  jq --argjson id "$id" --argjson ws "$wsid" 'map(if .id == $id then .workspace_id = $ws else . end)' "$D/windows.json" >"$tmp"
  mv "$tmp" "$D/windows.json"
  exit 0
fi

echo "unexpected niri args: $*" >&2
exit 1
MOCK
chmod +x "$TMP/bin/niri"

cat >"$TMP/bin/mock-spawn" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
D=$WKB_MOCK_DIR
appid=$1
wsid=$(jq -r '.[] | select(.is_focused) | .id' "$D/workspaces.json")
max=$(jq '[.[].id] | max // 0' "$D/windows.json")
id=$((max + 1))
tmp=$(mktemp)
jq --argjson id "$id" --arg app "$appid" --argjson ws "$wsid" '. + [{id:$id,app_id:$app,workspace_id:$ws,is_focused:true,focus_timestamp:{secs:100,nanos:0}}]' "$D/windows.json" >"$tmp"
mv "$tmp" "$D/windows.json"
MOCK
chmod +x "$TMP/bin/mock-spawn"

export PATH="$TMP/bin:$PATH"
export WKB_MOCK_DIR="$TMP/state"
export XDG_RUNTIME_DIR="$TMP/runtime"
: >"$TMP/state/actions.log"

WKB="$ROOT/bin/window-keybindings"

# Local Terminal matches only the default Ghostty identity. The dedicated
# Global Main app_id and TUI app_id are naturally excluded; id=2 wins by MRU.
"$WKB" local terminal '^com[.]mitchellh[.]ghostty$' -- mock-spawn com.mitchellh.ghostty
tail -n1 "$TMP/state/actions.log" | grep -qx 'focus:2'

# Preferred Global Main backend is the window's own app_id. It is summoned
# without creating any runtime identity registration.
"$WKB" global terminal '^dev[.]zaviro[.]role[.]terminal-main$' -- mock-spawn dev.zaviro.role.terminal-main
grep -qx 'move:6:main:101' "$TMP/state/actions.log"
tail -n1 "$TMP/state/actions.log" | grep -qx 'focus:6'
"$WKB" state | jq -e 'length == 0' >/dev/null

# Natural singleton ChatGPT is summoned globally and keeps runtime state empty.
"$WKB" singleton agent '^com[.]openai[.]chatgpt$' -- mock-spawn com.openai.chatgpt
grep -qx 'move:5:main:101' "$TMP/state/actions.log"
tail -n1 "$TMP/state/actions.log" | grep -qx 'focus:5'
"$WKB" state | jq -e 'length == 0' >/dev/null

# A policy singleton may technically have multiple windows. Global MRU is the
# explicit tie-breaker; id=8 wins over id=7 and is summoned.
"$WKB" singleton notes '^mock[.]obsidian$' -- mock-spawn mock.obsidian
grep -qx 'move:8:main:101' "$TMP/state/actions.log"
tail -n1 "$TMP/state/actions.log" | grep -qx 'focus:8'
"$WKB" state | jq -e 'length == 0' >/dev/null

# The old command name remains a compatibility alias.
"$WKB" single agent '^com[.]openai[.]chatgpt$' -- mock-spawn com.openai.chatgpt
tail -n1 "$TMP/state/actions.log" | grep -qx 'focus:5'

# Missing local role spawns a new matching window.
"$WKB" local browser '^google-chrome$' -- mock-spawn google-chrome
tail -n1 "$TMP/state/actions.log" | grep -qx 'focus:9'

# Missing app_id-backed Global Main spawns its dedicated native identity and
# still leaves runtime state empty.
"$WKB" global editor '^dev[.]zaviro[.]role[.]editor-main$' -- mock-spawn dev.zaviro.role.editor-main
tail -n1 "$TMP/state/actions.log" | grep -qx 'focus:10'
"$WKB" state | jq -e 'length == 0' >/dev/null

# Runtime state exists only as an explicit compatibility fallback.
"$WKB" global-state legacy-editor '^dev[.]zed[.]Zed$' -- mock-spawn dev.zed.Zed
"$WKB" state | jq -e '."legacy-editor" == 11 and length == 1' >/dev/null
tail -n1 "$TMP/state/actions.log" | grep -qx 'focus:11'

# A local role sharing the same app_id excludes its state-backed fallback
# Global Main, so it creates a separate local instance instead of focusing id=11.
"$WKB" local legacy-editor '^dev[.]zed[.]Zed$' -- mock-spawn dev.zed.Zed
tail -n1 "$TMP/state/actions.log" | grep -qx 'focus:12'

printf 'ok\n'
