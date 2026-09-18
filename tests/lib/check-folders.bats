#!/usr/bin/env bats

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../../scripts/lib/check-folders.sh"
  TMP="$(mktemp -d)"
}

teardown() {
  rm -rf "$TMP"
}

@test "prints nothing when all folders exist" {
  mkdir -p "$TMP/08 Summaries" "$TMP/04 People"
  run "$SCRIPT" "$TMP" "08 Summaries" "04 People"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "reports each missing folder on its own MISSING line" {
  mkdir -p "$TMP/08 Summaries"
  run "$SCRIPT" "$TMP" "08 Summaries" "04 People" "02 Daily"
  [ "$status" -eq 0 ]
  [[ "$output" != *"MISSING: 08 Summaries"* ]]
  [[ "$output" == *"MISSING: 04 People"* ]]
  [[ "$output" == *"MISSING: 02 Daily"* ]]
}

@test "regression: a folder name with spaces and an emoji is checked correctly, not word-split" {
  # This is the exact bug that shipped: the old implementation built a
  # single space-joined string and iterated `for d in $dirs`, which
  # split "400 Learning  🌱/08 Summaries" into three broken tokens and
  # reported false MISSING lines even though the folder existed.
  mkdir -p "$TMP/400 Learning  🌱/08 Summaries"
  run "$SCRIPT" "$TMP" "400 Learning  🌱/08 Summaries"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "regression: reports a genuinely missing space-containing folder exactly once" {
  run "$SCRIPT" "$TMP" "400 Learning  🌱/08 Summaries"
  [ "$status" -eq 0 ]
  [ "$output" = "MISSING: 400 Learning  🌱/08 Summaries" ]
}

@test "requires at least a vault root" {
  run "$SCRIPT"
  [ "$status" -eq 2 ]
}
