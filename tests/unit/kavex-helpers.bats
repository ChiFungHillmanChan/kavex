#!/usr/bin/env bats

setup() {
  load "../helpers/test_helper"
  _common_setup

  SANDBOX="$(mktemp -d)"
  cd "$SANDBOX"

  git init >/dev/null 2>&1
  git config user.name "Test User"
  git config user.email "test@example.com"

  echo "base" > preexisting.txt
  echo "base" > generated.txt
  git add preexisting.txt generated.txt
  git commit -m "init" >/dev/null 2>&1

  LIB_DIR="$KAVEX_ROOT/hooks/lib"
}

teardown() {
  rm -rf "$SANDBOX"
}

# --- kavex_snapshot tests ---

@test "kavex_snapshot: creates state directory if missing" {
  run bash -c "
    set -e
    cd '$SANDBOX'
    source '$LIB_DIR/detect-stack.sh'
    source '$LIB_DIR/kavex-snapshot.sh'
    kavex_snapshot '.kavex-loop'
    [ -d '.kavex-loop' ] && echo 'DIR_EXISTS'
  "
  assert_success
  assert_output --partial "DIR_EXISTS"
}

@test "kavex_snapshot: records tracked file hashes" {
  run bash -c "
    set -e
    cd '$SANDBOX'
    source '$LIB_DIR/detect-stack.sh'
    source '$LIB_DIR/kavex-snapshot.sh'
    # Make a file dirty so it shows in pre-tracked
    echo 'dirty' >> preexisting.txt
    kavex_snapshot '.kavex-loop'
    [ -f '.kavex-loop/.pre-tracked' ] && echo 'TRACKED_OK'
    [ -f '.kavex-loop/.pre-untracked' ] && echo 'UNTRACKED_OK'
    [ -f '.kavex-loop/.pre-tracked-hashes' ] && echo 'HASHES_OK'
    cat '.kavex-loop/.pre-tracked-hashes' | grep -q 'preexisting.txt' && echo 'HAS_FILE'
  "
  assert_success
  assert_output --partial "TRACKED_OK"
  assert_output --partial "UNTRACKED_OK"
  assert_output --partial "HASHES_OK"
  assert_output --partial "HAS_FILE"
}

@test "kavex_snapshot: clears stale verify log" {
  run bash -c "
    set -e
    cd '$SANDBOX'
    source '$LIB_DIR/detect-stack.sh'
    source '$LIB_DIR/kavex-snapshot.sh'
    mkdir -p '.kavex-loop'
    echo 'old result' > '.kavex-loop/verify-output-latest.log'
    kavex_snapshot '.kavex-loop'
    [ ! -f '.kavex-loop/verify-output-latest.log' ] && echo 'CLEARED'
  "
  assert_success
  assert_output --partial "CLEARED"
}

@test "kavex_snapshot: records untracked files" {
  run bash -c "
    set -e
    cd '$SANDBOX'
    source '$LIB_DIR/detect-stack.sh'
    source '$LIB_DIR/kavex-snapshot.sh'
    echo 'new' > newfile.txt
    kavex_snapshot '.kavex-loop'
    cat '.kavex-loop/.pre-untracked' | grep -q 'newfile.txt' && echo 'HAS_UNTRACKED'
  "
  assert_success
  assert_output --partial "HAS_UNTRACKED"
}

# --- kavex_safe_commit tests ---

@test "kavex_safe_commit: stages only changed files since snapshot" {
  run bash -c "
    set -e
    cd '$SANDBOX'
    source '$LIB_DIR/detect-stack.sh'
    source '$LIB_DIR/kavex-snapshot.sh'
    source '$LIB_DIR/kavex-safe-commit.sh'

    # Pre-existing dirty edit
    printf 'user edit\n' >> preexisting.txt
    kavex_snapshot '.kavex-loop'

    # Simulate Claude editing only generated.txt
    printf 'loop edit\n' >> generated.txt
    # Write a fake verify log so commit gate doesn't block
    echo 'PASS' > '.kavex-loop/verify-output-latest.log'

    kavex_safe_commit 1 'test item' false '.kavex-loop'
    git log --oneline -1 --name-only | tail -n +2
  "
  assert_success
  assert_output --partial "generated.txt"
  refute_output --partial "preexisting.txt"
}

@test "kavex_safe_commit: refuses if no snapshot exists" {
  run bash -c "
    set -e
    cd '$SANDBOX'
    source '$LIB_DIR/detect-stack.sh'
    source '$LIB_DIR/kavex-safe-commit.sh'
    mkdir -p '.kavex-loop'
    kavex_safe_commit 1 'test item' false '.kavex-loop'
  "
  assert_failure
  assert_output --partial "No snapshot found"
}

@test "kavex_safe_commit: clears verify log after commit" {
  run bash -c "
    set -e
    cd '$SANDBOX'
    source '$LIB_DIR/detect-stack.sh'
    source '$LIB_DIR/kavex-snapshot.sh'
    source '$LIB_DIR/kavex-safe-commit.sh'

    kavex_snapshot '.kavex-loop'
    echo 'new content' > newfile.txt
    echo 'PASS' > '.kavex-loop/verify-output-latest.log'

    kavex_safe_commit 1 'add newfile' false '.kavex-loop'
    [ ! -f '.kavex-loop/verify-output-latest.log' ] && echo 'VERIFY_CLEARED'
  "
  assert_success
  assert_output --partial "VERIFY_CLEARED"
}

@test "kavex_safe_commit: no-commit mode writes marker file" {
  run bash -c "
    set -e
    cd '$SANDBOX'
    source '$LIB_DIR/detect-stack.sh'
    source '$LIB_DIR/kavex-snapshot.sh'
    source '$LIB_DIR/kavex-safe-commit.sh'

    kavex_snapshot '.kavex-loop'
    kavex_safe_commit 1 'test item' true '.kavex-loop'
    cat '.kavex-loop/commit-item-1.txt'
  "
  assert_success
  assert_output --partial "no-commit"
}

@test "kavex_safe_commit: writes nothing-to-commit when no changes" {
  run bash -c "
    set -e
    cd '$SANDBOX'
    source '$LIB_DIR/detect-stack.sh'
    source '$LIB_DIR/kavex-snapshot.sh'
    source '$LIB_DIR/kavex-safe-commit.sh'

    kavex_snapshot '.kavex-loop'
    # Don't change any files
    echo 'PASS' > '.kavex-loop/verify-output-latest.log'
    kavex_safe_commit 1 'test item' false '.kavex-loop'
    cat '.kavex-loop/commit-item-1.txt'
  "
  assert_success
  assert_output --partial "nothing-to-commit"
}

# --- kavex_cleanup tests ---

@test "kavex_cleanup: removes state directory" {
  run bash -c "
    set -e
    cd '$SANDBOX'
    source '$LIB_DIR/kavex-cleanup.sh'
    mkdir -p '.kavex-loop'
    echo 'data' > '.kavex-loop/some-file.txt'
    kavex_cleanup '.kavex-loop'
    [ ! -d '.kavex-loop' ] && echo 'REMOVED'
  "
  assert_success
  assert_output --partial "REMOVED"
}

@test "kavex_cleanup: succeeds when directory does not exist" {
  run bash -c "
    set -e
    cd '$SANDBOX'
    source '$LIB_DIR/kavex-cleanup.sh'
    kavex_cleanup '.kavex-loop'
    echo 'OK'
  "
  assert_success
  assert_output --partial "OK"
}

# --- commit gate integration ---

@test "commit gate: blocks when .kavex-loop exists but no verify log" {
  run bash -c "
    set -e
    cd '$SANDBOX'
    mkdir -p '.kavex-loop'
    # No verify-output-latest.log exists
    echo '{\"tool_input\":{\"command\":\"git commit -m test\"}}' | bash '$KAVEX_ROOT/hooks/kavex-commit-gate.sh'
  "
  assert_success
  assert_output --partial "block"
  assert_output --partial "no verification"
}

@test "commit gate: allows when .kavex-loop does not exist" {
  run bash -c "
    set -e
    cd '$SANDBOX'
    echo '{\"tool_input\":{\"command\":\"git commit -m test\"}}' | bash '$KAVEX_ROOT/hooks/kavex-commit-gate.sh'
  "
  assert_success
  # Should produce no output (exit 0 with no JSON = allow)
  refute_output --partial "block"
}

@test "commit gate: allows when verify log exists and shows PASS" {
  run bash -c "
    set -e
    cd '$SANDBOX'
    mkdir -p '.kavex-loop'
    echo 'All layers PASS' > '.kavex-loop/verify-output-latest.log'
    echo '{\"tool_input\":{\"command\":\"git commit -m test\"}}' | bash '$KAVEX_ROOT/hooks/kavex-commit-gate.sh'
  "
  assert_success
  refute_output --partial "block"
}

# --- Integration: full snapshot → edit → commit flow ---

@test "integration: snapshot → edit → commit stages only new changes" {
  run bash -c "
    set -e
    cd '$SANDBOX'
    source '$LIB_DIR/detect-stack.sh'
    source '$LIB_DIR/kavex-snapshot.sh'
    source '$LIB_DIR/kavex-safe-commit.sh'
    source '$LIB_DIR/kavex-cleanup.sh'

    # Pre-existing dirty work
    echo 'user wip' >> preexisting.txt

    # Snapshot
    kavex_snapshot '.kavex-loop'

    # Claude implements
    echo 'new feature' > feature.txt
    echo 'loop edit' >> generated.txt

    # Fake verify pass
    echo 'PASS' > '.kavex-loop/verify-output-latest.log'

    # Commit
    kavex_safe_commit 1 'add feature' false '.kavex-loop'

    # Verify: only feature.txt and generated.txt committed, not preexisting.txt
    COMMITTED=\$(git log --oneline -1 --name-only | tail -n +2 | sort)
    echo \"COMMITTED: \$COMMITTED\"

    # Verify: verify log cleared after commit
    [ ! -f '.kavex-loop/verify-output-latest.log' ] && echo 'VERIFY_CLEARED'

    # Cleanup
    kavex_cleanup '.kavex-loop'
    [ ! -d '.kavex-loop' ] && echo 'CLEANED'

    # Verify: preexisting.txt still dirty
    git diff --name-only | grep -q 'preexisting.txt' && echo 'WIP_PRESERVED'
  "
  assert_success
  assert_output --partial "feature.txt"
  assert_output --partial "generated.txt"
  assert_output --partial "VERIFY_CLEARED"
  assert_output --partial "CLEANED"
  assert_output --partial "WIP_PRESERVED"
  refute_output --partial "preexisting.txt
generated.txt
feature.txt"
}
