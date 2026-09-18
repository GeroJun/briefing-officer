#!/usr/bin/env bats

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../../scripts/lib/audit-wikilinks.sh"
  TMP="$(mktemp -d)"
}

teardown() {
  rm -rf "$TMP"
}

@test "reports no missing links when every target exists" {
  mkdir -p "$TMP/07 References" "$TMP/04 People"
  echo "" > "$TMP/07 References/Python.md"
  echo "" > "$TMP/04 People/Ada Lovelace.md"
  cat > "$TMP/note.md" <<'EOF'
Some text about [[Python]] and [[Ada Lovelace]].
EOF
  run "$SCRIPT" "$TMP" "$TMP/note.md"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "reports a dangling wikilink" {
  cat > "$TMP/note.md" <<'EOF'
Mentions [[Nonexistent Concept]] with no note behind it.
EOF
  run "$SCRIPT" "$TMP" "$TMP/note.md"
  [ "$status" -eq 0 ]
  [ "$output" = "MISSING: Nonexistent Concept" ]
}

@test "resolves aliased links to their canonical target" {
  mkdir -p "$TMP/04 People"
  echo "" > "$TMP/04 People/Cobie.md"
  cat > "$TMP/note.md" <<'EOF'
[[Cobie|Jordan Fish]] said something.
EOF
  run "$SCRIPT" "$TMP" "$TMP/note.md"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "resolves heading and block references to their canonical target" {
  mkdir -p "$TMP/03 Meetings"
  echo "" > "$TMP/03 Meetings/Call Transcript.md"
  cat > "$TMP/note.md" <<'EOF'
See [[Call Transcript#Intro]] and [[Call Transcript^abc123]].
EOF
  run "$SCRIPT" "$TMP" "$TMP/note.md"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "ignores matches inside .Trash and Clippings" {
  mkdir -p "$TMP/.Trash" "$TMP/Clippings"
  echo "" > "$TMP/.Trash/Ghost Note.md"
  echo "" > "$TMP/Clippings/Ghost Note.md"
  cat > "$TMP/note.md" <<'EOF'
[[Ghost Note]] only exists in trash/clippings.
EOF
  run "$SCRIPT" "$TMP" "$TMP/note.md"
  [ "$status" -eq 0 ]
  [ "$output" = "MISSING: Ghost Note" ]
}

@test "deduplicates repeated mentions of the same missing link" {
  cat > "$TMP/note.md" <<'EOF'
[[Widget]] appears twice: [[Widget]].
EOF
  run "$SCRIPT" "$TMP" "$TMP/note.md"
  [ "$status" -eq 0 ]
  [ "$output" = "MISSING: Widget" ]
}
