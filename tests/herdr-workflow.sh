#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SKILL="$ROOT/.agents/skills/herdr/SKILL.md"

assert_contains() {
  value=$1
  expected=$2
  case "$value" in
    *"$expected"*) ;;
    *) printf 'missing: %s\n' "$expected" >&2; exit 1 ;;
  esac
}

skill=$(cat "$SKILL")
assert_contains "$skill" '--until idle --until blocked --until done --until unknown --timeout 120000'
assert_contains "$skill" '--wait --until idle --until done --until blocked --timeout 120000'
assert_contains "$skill" 'agent prompt <pane_id>'
assert_contains "$skill" 'agent send-keys'
assert_contains "$skill" 'opencode debug config'
assert_contains "$skill" 'herdr pane close <pane_id>'

status=$(herdr status)
assert_contains "$status" 'server:'
assert_contains "$status" 'running'

help=$(herdr agent prompt --help)
assert_contains "$help" '--timeout <MS>'
assert_contains "$help" 'idle'
assert_contains "$help" 'blocked'

config=$(opencode debug config)
CONFIG="$config" python3 - <<'PY'
import json
import os

config = json.loads(os.environ["CONFIG"])
assert config["agent"]["staff"]["permission"]["edit"] == "ask"
assert config["agent"]["staff"]["permission"]["bash"] == "ask"
PY

printf 'herdr workflow checks passed\n'
