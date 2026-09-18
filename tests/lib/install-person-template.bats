#!/usr/bin/env bats

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../../scripts/lib/install-person-template.sh"
  REPO_TEMPLATES="$BATS_TEST_DIRNAME/../../templates"
  TMP="$(mktemp -d)"
}

teardown() {
  rm -rf "$TMP"
}

@test "installs the minimal variant when nothing exists yet" {
  run "$SCRIPT" "$TMP" "_Templates" minimal "$REPO_TEMPLATES"
  [ "$status" -eq 0 ]
  [[ "$output" == INSTALLED:* ]]
  [ -f "$TMP/_Templates/new person template.md" ]
  grep -q "current age" "$TMP/_Templates/new person template.md" && echo "unexpected full-template content" && return 1
  true
}

@test "installs the full variant when requested" {
  run "$SCRIPT" "$TMP" "_Templates" full "$REPO_TEMPLATES"
  [ "$status" -eq 0 ]
  grep -q "current age" "$TMP/_Templates/new person template.md"
}

@test "leaves an existing template untouched" {
  mkdir -p "$TMP/_Templates"
  echo "customized by user" > "$TMP/_Templates/new person template.md"
  run "$SCRIPT" "$TMP" "_Templates" minimal "$REPO_TEMPLATES"
  [ "$status" -eq 0 ]
  [ "$output" = "SKIPPED: already exists" ]
  grep -q "customized by user" "$TMP/_Templates/new person template.md"
}

@test "rejects an unknown variant" {
  run "$SCRIPT" "$TMP" "_Templates" bogus "$REPO_TEMPLATES"
  [ "$status" -eq 2 ]
}
