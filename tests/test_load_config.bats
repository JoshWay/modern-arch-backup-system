#!/usr/bin/env bats

@test "load-config sets dev mode paths" {
  run bash -c 'source scripts/common/load-config.sh && echo "$BACKUP_DEV_MODE $BTRBK_CONFIG"'
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" == true* ]]
  [[ "${lines[0]}" == *"configs/btrbk.conf" ]]
}

