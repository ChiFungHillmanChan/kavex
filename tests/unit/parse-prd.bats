#!/usr/bin/env bats

setup() {
  load "../helpers/test_helper"
  _common_setup

  SANDBOX="$(mktemp -d)"
  cd "$SANDBOX"

  source "$KOVA_ROOT/hooks/lib/parse-prd.sh"
}

teardown() {
  rm -rf "$SANDBOX"
}

# --- detect_prd_format ---

@test "detect_prd_format: markdown checklist detected" {
  cat > prd.md <<'EOF'
# My PRD
- [ ] Build auth module
- [ ] Add unit tests
- [x] Setup repo
EOF
  local fmt
  fmt=$(detect_prd_format prd.md)
  assert_equal "$fmt" "markdown"
}

@test "detect_prd_format: JSON with items array detected" {
  cat > prd.json <<'EOF'
{"items": [{"title": "Task A"}, {"title": "Task B"}]}
EOF
  local fmt
  fmt=$(detect_prd_format prd.json)
  assert_equal "$fmt" "json"
}

@test "detect_prd_format: plain text yields unknown" {
  echo "Just some plain text" > plain.txt
  local fmt
  fmt=$(detect_prd_format plain.txt)
  assert_equal "$fmt" "unknown"
}

@test "detect_prd_format: missing file yields unknown" {
  local fmt
  fmt=$(detect_prd_format nonexistent.md)
  assert_equal "$fmt" "unknown"
}

@test "detect_prd_format: JSON without items yields unknown" {
  echo '{"name": "test"}' > bad.json
  local fmt
  fmt=$(detect_prd_format bad.json)
  assert_equal "$fmt" "unknown"
}

# --- parse_markdown_prd ---

@test "parse_markdown_prd: extracts unchecked items" {
  cat > prd.md <<'EOF'
- [ ] First task
- [ ] Second task
- [x] Done task
EOF
  parse_markdown_prd prd.md
  assert_equal "$PRD_ITEM_COUNT" "2"
  assert_equal "${PRD_ITEMS[0]}" "First task"
  assert_equal "${PRD_ITEMS[1]}" "Second task"
}

@test "parse_markdown_prd: tracks completed items" {
  cat > prd.md <<'EOF'
- [ ] Pending
- [x] Done one
- [X] Done two
EOF
  parse_markdown_prd prd.md
  assert_equal "$PRD_COMPLETED_COUNT" "2"
  assert_equal "${PRD_COMPLETED[0]}" "Done one"
}

@test "parse_markdown_prd: handles indented items" {
  cat > prd.md <<'EOF'
  - [ ] Indented task
    - [ ] Nested task
EOF
  parse_markdown_prd prd.md
  assert_equal "$PRD_ITEM_COUNT" "2"
}

@test "parse_markdown_prd: empty file yields zero items" {
  touch empty.md
  parse_markdown_prd empty.md
  assert_equal "$PRD_ITEM_COUNT" "0"
}

# --- parse_json_prd ---

@test "parse_json_prd: extracts string items" {
  cat > prd.json <<'EOF'
{"items": ["Task A", "Task B", "Task C"]}
EOF
  parse_json_prd prd.json
  assert_equal "$PRD_ITEM_COUNT" "3"
  assert_equal "${PRD_ITEMS[0]}" "Task A"
  assert_equal "${PRD_ITEMS[2]}" "Task C"
}

@test "parse_json_prd: extracts object items with title+description" {
  cat > prd.json <<'EOF'
{"items": [{"title": "Auth", "description": "Build login flow"}]}
EOF
  parse_json_prd prd.json
  assert_equal "$PRD_ITEM_COUNT" "1"
  assert_equal "${PRD_ITEMS[0]}" "Auth: Build login flow"
}

@test "parse_json_prd: skips completed items" {
  cat > prd.json <<'EOF'
{"items": [
  {"title": "Done", "done": true},
  {"title": "Pending", "done": false}
]}
EOF
  parse_json_prd prd.json
  assert_equal "$PRD_ITEM_COUNT" "1"
  assert_equal "${PRD_ITEMS[0]}" "Pending"
  assert_equal "$PRD_COMPLETED_COUNT" "1"
}

@test "parse_json_prd: supports completed flag" {
  cat > prd.json <<'EOF'
{"items": [{"title": "A", "completed": true}, {"title": "B"}]}
EOF
  parse_json_prd prd.json
  assert_equal "$PRD_ITEM_COUNT" "1"
  assert_equal "${PRD_ITEMS[0]}" "B"
}

# --- parse_prd (main entry) ---

@test "parse_prd: fails on missing file" {
  run parse_prd nonexistent.md
  assert_failure
  assert_output --partial "not found"
}

@test "parse_prd: fails on unrecognized format" {
  echo "No checkboxes here" > bad.txt
  run parse_prd bad.txt
  assert_failure
  assert_output --partial "Unrecognized PRD format"
}

@test "parse_prd: fails when all items completed" {
  cat > prd.md <<'EOF'
- [x] Done
- [x] Also done
EOF
  run parse_prd prd.md
  assert_failure
  assert_output --partial "No pending items"
}

@test "parse_prd: succeeds on valid markdown" {
  cat > prd.md <<'EOF'
- [ ] Build feature
- [ ] Write tests
EOF
  parse_prd prd.md
  assert_equal "$PRD_ITEM_COUNT" "2"
}

@test "parse_prd: succeeds on valid JSON" {
  cat > prd.json <<'EOF'
{"items": ["Do thing"]}
EOF
  parse_prd prd.json
  assert_equal "$PRD_ITEM_COUNT" "1"
}
