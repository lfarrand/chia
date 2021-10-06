#!/usr/bin/env bash

# shellcheck disable=SC2154
if [[ ${farmer} == 'true' ]]; then
  chia start farmer-only
elif [[ ${harvester} == 'true' ]]; then
  if [[ -z ${farmer_address} || -z ${farmer_port} || -z ${ca} ]]; then
    echo "A farmer peer address, port, and ca path are required."
    exit
  else
    chia configure --set-farmer-peer "${farmer_address}:${farmer_port}"
    chia start harvester
  fi
else
  chia start farmer
fi

./farmr harvester headless > farmr-harvester.log 2>&1 &

trap "chia stop all -d; exit 0" SIGINT SIGTERM

# Ensures the log file actually exists, so we can tail successfully
touch "$CHIA_ROOT/log/debug.log"
tail -f "$CHIA_ROOT/log/debug.log" &
while true; do sleep 1; done
