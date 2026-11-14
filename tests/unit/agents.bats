#!/usr/bin/env bats
@test "dual-agent installation lifecycle and project isolation" {
  run python3 "${BATS_TEST_DIRNAME}/../test_agents.py"
  if [ "$status" -ne 0 ]; then printf "%s\n" "$output" >&3; fi
  [ "$status" -eq 0 ]
}
