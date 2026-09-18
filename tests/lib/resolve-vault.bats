#!/usr/bin/env bats

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../../scripts/lib/resolve-vault.sh"
  TMP="$(mktemp -d)"
}

teardown() {
  rm -rf "$TMP"
}

@test "prints VAULT_ROOT when set, regardless of filesystem state" {
  VAULT_ROOT="/does/not/exist" run "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" = "/does/not/exist" ]
}

@test "walks up from start_dir to find a directory containing .obsidian" {
  mkdir -p "$TMP/vault/.obsidian"
  mkdir -p "$TMP/vault/sub/deeper"
  run env -u VAULT_ROOT "$SCRIPT" "$TMP/vault/sub/deeper"
  [ "$status" -eq 0 ]
  [ "$output" = "$TMP/vault" ]
}

@test "exits 1 when no .obsidian is found walking up to /" {
  mkdir -p "$TMP/no-vault-here/sub"
  run env -u VAULT_ROOT "$SCRIPT" "$TMP/no-vault-here/sub"
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

@test "a folder name containing spaces is returned intact" {
  mkdir -p "$TMP/My Vault  🌱/.obsidian"
  run env -u VAULT_ROOT "$SCRIPT" "$TMP/My Vault  🌱"
  [ "$status" -eq 0 ]
  [ "$output" = "$TMP/My Vault  🌱" ]
}
