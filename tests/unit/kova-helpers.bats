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

  LIB_DIR="$KOVA_ROOT/hooks/lib"
}

teardown() {
  rm -rf "$SANDBOX"
}

# --- kova_snapshot tests ---

@test "kova_snapshot: creates state directory if missing" {
  run bash -c "
    set -e
    cd '$SANDBOX'
    source '$LIB_DIR/detect-stack.sh'
    source '$LIB_DIR/kova-snapshot.sh'
    kova_snapshot '.kova-loop'
    [ -d '.kova-loop' ] && echo 'DIR_EXISTS'
  "
  assert_success
  assert_output --partial "DIR_EXISTS"
}

@test "kova_snapshot: records tracked file hashes" {
  run bash -c "
    set -e
    cd '$SANDBOX'
    source '$LIB_DIR/detect-stack.sh'
    source '$LIB_DIR/kova-snapshot.sh'
    # Make a file dirty so it shows in pre-tracked
    echo 'dirty' >> preexisting.txt
    kova_snapshot '.kova-loop'
    [ -f '.kova-loop/.pre-tracked' ] && echo 'TRACKED_OK'
    [ -f '.kova-loop/.pre-untracked' ] && echo 'UNTRACKED_OK'
    [ -f '.kova-loop/.pre-tracked-hashes' ] && echo 'HASHES_OK'
    cat '.kova-loop/.pre-tracked-hashes' | grep -q 'preexisting.txt' && echo 'HAS_FILE'
  "
  assert_success
  assert_output --partial "TRACKED_OK"
  assert_output --partial "UNTRACKED_OK"
  assert_output --partial "HASHES_OK"
  assert_output --partial "HAS_FILE"
}

@test "kova_snapshot: clears stale verify log" {
  run bash -c "
    set -e
    cd '$SANDBOX'
    source '$LIB_DIR/detect-stack.sh'
    source '$LIB_DIR/kova-snapshot.sh'
    mkdir -p '.kova-loop'
    echo 'old result' > '.kova-loop/verify-output-latest.log'
    kova_snapshot '.kova-loop'
    [ ! -f '.kova-loop/verify-output-latest.log' ] && echo 'CLEARED'
  "
  assert_success
  assert_output --partial "CLEARED"
}

@test "kova_snapshot: records untracked files" {
  run bash -c "
    set -e
    cd '$SANDBOX'
    source '$LIB_DIR/detect-stack.sh'
    source '$LIB_DIR/kova-snapshot.sh'
    echo 'new' > newfile.txt
    kova_snapshot '.kova-loop'
    cat '.kova-loop/.pre-untracked' | grep -q 'newfile.txt' && echo 'HAS_UNTRACKED'
  "
  assert_success
  assert_output --partial "HAS_UNTRACKED"
}

# --- kova_safe_commit tests ---

@test "kova_safe_commit: stages only changed files since snapshot" {
  run bash -c "
    set -e
    cd '$SANDBOX'
    source '$LIB_DIR/detect-stack.sh'
    source '$LIB_DIR/kova-snapshot.sh'
    source '$LIB_DIR/kova-safe-commit.sh'

    # Pre-existing dirty edit
    printf 'user edit\n' >> preexisting.txt
    kova_snapshot '.kova-loop'

    # Simulate Claude editing only generated.txt
    printf 'loop edit\n' >> generated.txt
    # Write a fake verify log so commit gate doesn't block
    echo 'PASS' > '.kova-loop/verify-output-latest.log'

    kova_safe_commit 1 'test item' false '.kova-loop'
    git log --oneline -1 --name-only | tail -n +2
  "
  assert_success
  assert_output --partial "generated.txt"
  refute_output --partial "preexisting.txt"
}

@test "kova_safe_commit: refuses if no snapshot exists" {
  run bash -c "
    set -e
    cd '$SANDBOX'
    source '$LIB_DIR/detect-stack.sh'
    source '$LIB_DIR/kova-safe-commit.sh'
    mkdir -p '.kova-loop'
    kova_safe_commit 1 'test item' false '.kova-loop'
  "
  assert_failure
  assert_output --partial "No snapshot found"
}

@test "kova_safe_commit: clears verify log after commit" {
  run bash -c "
    set -e
    cd '$SANDBOX'
    source '$LIB_DIR/detect-stack.sh'
    source '$LIB_DIR/kova-snapshot.sh'
    source '$LIB_DIR/kova-safe-commit.sh'

    kova_snapshot '.kova-loop'
    echo 'new content' > newfile.txt
    echo 'PASS' > '.kova-loop/verify-output-latest.log'

    kova_safe_commit 1 'add newfile' false '.kova-loop'
    [ ! -f '.kova-loop/verify-output-latest.log' ] && echo 'VERIFY_CLEARED'
  "
  assert_success
  assert_output --partial "VERIFY_CLEARED"
}

@test "kova_safe_commit: no-commit mode writes marker file" {
  run bash -c "
    set -e
    cd '$SANDBOX'
    source '$LIB_DIR/detect-stack.sh'
    source '$LIB_DIR/kova-snapshot.sh'
    source '$LIB_DIR/kova-safe-commit.sh'

    kova_snapshot '.kova-loop'
    kova_safe_commit 1 'test item' true '.kova-loop'
    cat '.kova-loop/commit-item-1.txt'
  "
  assert_success
  assert_output --partial "no-commit"
}

@test "kova_safe_commit: writes nothing-to-commit when no changes" {
  run bash -c "
    set -e
    cd '$SANDBOX'
    source '$LIB_DIR/detect-stack.sh'
    source '$LIB_DIR/kova-snapshot.sh'
    source '$LIB_DIR/kova-safe-commit.sh'

    kova_snapshot '.kova-loop'
    # Don't change any files
    echo 'PASS' > '.kova-loop/verify-output-latest.log'
    kova_safe_commit 1 'test item' false '.kova-loop'
    cat '.kova-loop/commit-item-1.txt'
  "
  assert_success
  assert_output --partial "nothing-to-commit"
}

# --- kova_cleanup tests ---

@test "kova_cleanup: removes state directory" {
  run bash -c "
    set -e
    cd '$SANDBOX'
    source '$LIB_DIR/kova-cleanup.sh'
    mkdir -p '.kova-loop'
    echo 'data' > '.kova-loop/some-file.txt'
    kova_cleanup '.kova-loop'
    [ ! -d '.kova-loop' ] && echo 'REMOVED'
  "
  assert_success
  assert_output --partial "REMOVED"
}

@test "kova_cleanup: succeeds when directory does not exist" {
  run bash -c "
    set -e
    cd '$SANDBOX'
    source '$LIB_DIR/kova-cleanup.sh'
    kova_cleanup '.kova-loop'
    echo 'OK'
  "
  assert_success
  assert_output --partial "OK"
}

# --- commit gate integration ---

@test "commit gate: blocks when .kova-loop exists but no verify log" {
  run bash -c "
    set -e
    cd '$SANDBOX'
    mkdir -p '.kova-loop'
    # No verify-output-latest.log exists
    echo '{\"tool_input\":{\"command\":\"git commit -m test\"}}' | bash '$KOVA_ROOT/hooks/kova-commit-gate.sh'
  "
  assert_success
  assert_output --partial "block"
  assert_output --partial "no verification"
}

@test "commit gate: allows when .kova-loop does not exist" {
  run bash -c "
    set -e
    cd '$SANDBOX'
    echo '{\"tool_input\":{\"command\":\"git commit -m test\"}}' | bash '$KOVA_ROOT/hooks/kova-commit-gate.sh'
  "
  assert_success
  # Should produce no output (exit 0 with no JSON = allow)
  refute_output --partial "block"
}

@test "commit gate: allows when verify log exists and shows PASS" {
  run bash -c "
    set -e
    cd '$SANDBOX'
    mkdir -p '.kova-loop'
    echo 'All layers PASS' > '.kova-loop/verify-output-latest.log'
    echo '{\"tool_input\":{\"command\":\"git commit -m test\"}}' | bash '$KOVA_ROOT/hooks/kova-commit-gate.sh'
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
    source '$LIB_DIR/kova-snapshot.sh'
    source '$LIB_DIR/kova-safe-commit.sh'
    source '$LIB_DIR/kova-cleanup.sh'

    # Pre-existing dirty work
    echo 'user wip' >> preexisting.txt

    # Snapshot
    kova_snapshot '.kova-loop'

    # Claude implements
    echo 'new feature' > feature.txt
    echo 'loop edit' >> generated.txt

    # Fake verify pass
    echo 'PASS' > '.kova-loop/verify-output-latest.log'

    # Commit
    kova_safe_commit 1 'add feature' false '.kova-loop'

    # Verify: only feature.txt and generated.txt committed, not preexisting.txt
    COMMITTED=\$(git log --oneline -1 --name-only | tail -n +2 | sort)
    echo \"COMMITTED: \$COMMITTED\"

    # Verify: verify log cleared after commit
    [ ! -f '.kova-loop/verify-output-latest.log' ] && echo 'VERIFY_CLEARED'

    # Cleanup
    kova_cleanup '.kova-loop'
    [ ! -d '.kova-loop' ] && echo 'CLEANED'

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
