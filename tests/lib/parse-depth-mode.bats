#!/usr/bin/env bats

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../../scripts/lib/parse-depth-mode.sh"
}

@test "detects minimal mode from a bare token" {
  run "$SCRIPT" "https://youtube.com/watch?v=abc minimal"
  [ "$status" -eq 0 ]
  [ "$output" = "minimal" ]
}

@test "detects minimal mode from -m flag" {
  run "$SCRIPT" "~/call.mp4 -m"
  [ "$output" = "minimal" ]
}

@test "detects detailed mode from a bare token" {
  run "$SCRIPT" "https://youtube.com/watch?v=abc detailed"
  [ "$output" = "detailed" ]
}

@test "detects detailed mode from --detailed flag" {
  run "$SCRIPT" "~/call.mp4 --detailed"
  [ "$output" = "detailed" ]
}

@test "prints nothing when no mode token is present" {
  run "$SCRIPT" "https://youtube.com/watch?v=abc"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "minimal takes precedence when both tokens somehow appear" {
  run "$SCRIPT" "minimal but also detailed"
  [ "$output" = "minimal" ]
}
