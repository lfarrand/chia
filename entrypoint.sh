#!/usr/bin/env bash

# shellcheck disable=SC2154
if [[ -n "${TZ}" ]]; then
  echo "Setting timezone to ${TZ}"
  ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" > /etc/timezone
fi

echo "keys: ${keys}"
echo "ca: ${ca}"
echo "plots_dir: ${plots_dir}"
echo "farmer: ${farmer}"
echo "harvester: ${harvester}"
echo "farmer_address: ${farmer_address}"
echo "farmer_port: ${farmer_port}"
echo "testnet: ${testnet}"
echo "log_level: ${log_level}"

echo "/chia-blockchain/venv/bin/chia" > /farmr/override-xch-binary.txt

cd /chia-blockchain

# shellcheck disable=SC1091
. ./activate

chia init --fix-ssl-permissions

if [[ ${testnet} == 'true' ]]; then
   echo "configure testnet"
   chia configure --testnet true
fi

if [[ ${keys} == "persistent" ]]; then
  echo "Not touching key directories"
elif [[ ${keys} == "generate" ]]; then
  echo "To use your own keys pass them as a text file -v /path/to/keyfile:/path/in/container and -e keys=\"/path/in/container\""
  chia keys generate
elif [[ ${keys} == "copy" ]]; then
  if [[ -z ${ca} ]]; then
    echo "A path to a copy of the farmer peer's ssl/ca required."
  exit
  else
    echo "Found existing farmer ssl keys in "${ca}", using them to initialize"
    chia init -c "${ca}"
  fi
else
  echo "Adding keys from ${keys}"
  chia keys add -f "${keys}"
fi

for p in ${plots_dir//:/ }; do
    mkdir -p "${p}"
    if [[ ! $(ls -A "$p") ]]; then
        echo "Plots directory '${p}' appears to be empty, try mounting a plot directory with the docker -v command"
    fi
    chia plots add -d "${p}"
done

if [[ -n "${log_level}" ]]; then
  chia configure --log-level "${log_level}"
fi

sed -i 's/localhost/127.0.0.1/g' "$CHIA_ROOT/config/config.yaml"

truncate -s 0 /farmrfarmr-harvester.log
truncate -s 0 /farmrlog.txt

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
