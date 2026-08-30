#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/state" "$TMP/runtime/window-keybindings"

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
  {"id":5,"app_id":"com.openai.chatgpt","workspace_id":102,"is_focused":false,"focus_timestamp":{"secs":50,"nanos":0}}
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
printf '{"terminal":2}\n' >"$XDG_RUNTIME_DIR/window-keybindings/global-main.json"
: >"$TMP/state/actions.log"

WKB="$ROOT/bin/window-keybindings"

# Local terminal excludes Global Main id=2 and the TUI app_id, so id=1 wins.
"$WKB" local terminal '^com[.]mitchellh[.]ghostty$' -- mock-spawn com.mitchellh.ghostty
tail -n1 "$TMP/state/actions.log" | grep -qx 'focus:1'

# Registered Global Main focuses directly when already on the current workspace.
"$WKB" global terminal '^com[.]mitchellh[.]ghostty$' -- mock-spawn com.mitchellh.ghostty
tail -n1 "$TMP/state/actions.log" | grep -qx 'focus:2'

# Global-only ChatGPT is summoned from dev to main.
"$WKB" single agent 'chatgpt' -- mock-spawn com.openai.chatgpt
grep -qx 'move:5:main:101' "$TMP/state/actions.log"
tail -n1 "$TMP/state/actions.log" | grep -qx 'focus:5'

# Missing local role spawns a new matching window.
"$WKB" local browser 'google-chrome' -- mock-spawn google-chrome
tail -n1 "$TMP/state/actions.log" | grep -qx 'focus:6'

# Missing Global Main spawns, registers and focuses a new window.
"$WKB" global editor 'zed' -- mock-spawn dev.zed.Zed
jq -e '.editor == 7 and .terminal == 2' "$XDG_RUNTIME_DIR/window-keybindings/global-main.json" >/dev/null
tail -n1 "$TMP/state/actions.log" | grep -qx 'focus:7'

printf 'ok\n'
