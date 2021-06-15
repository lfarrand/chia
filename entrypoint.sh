cd /chiabot
truncate -s 0 chiabot-harvester.log
truncate -s 0 log.txt
./harvester.sh > chiabot-harvester.log 2>&1 &

cd /chia-blockchain

. ./activate

echo "key_path: ${key_path}"
echo "keys: ${keys}"
echo "plot_dirs: ${plot_dirs}"
echo "farmer: ${farmer}"
echo "harvester: ${harvester}"
echo "farmer_address: ${farmer_address}"
echo "farmer_port: ${farmer_port}"
echo "testnet: ${testnet}"

echo "Running chia init"
chia init

if [[ ! -z ${key_path} ]]; then
  echo "Importing keys from ${key_path}"
  chia init -c ${key_path}
else
  if [[ ${keys} == "generate" ]]; then
    echo "Generating keys"
    echo "To use your own keys pass them as a text file -v /path/to/keyfile:/path/in/container and -e keys=\"/path/in/container\""
    chia keys generate
  else
    echo "Adding keys"
    chia keys add -f ${keys}
  fi
fi

if [[ ! "$(ls -A /plots)" ]]; then
  echo "Plots directory appears to be empty and you have not specified another, try mounting a plot directory with the docker -v command "
fi

echo "Adding plot directories ${plot_dirs}"
IFS=';' read -ra ADDR <<< "${plot_dirs}"
for plot_dir in "${ADDR[@]}"; do
  echo "Adding plot directory $plot_dir"
  chia plots add -d $plot_dir
done

sed -i 's/localhost/127.0.0.1/g' ~/.chia/mainnet/config/config.yaml
sed -i 's/log_level: WARNING/log_level: INFO/g' ~/.chia/mainnet/config/config.yaml

if [[ ${farmer} == 'true' ]]; then
  echo "Starting farmer only"
  chia start farmer-only
elif [[ ${harvester} == 'true' ]]; then
  if [[ -z ${farmer_address} || -z ${farmer_port} ]]; then
    echo "A farmer peer address and port are required."
    exit
  else
    echo "Setting farmer peer to ${farmer_address}:${farmer_port}"
    chia configure --set-farmer-peer ${farmer_address}:${farmer_port}
    echo "Starting harvester"
    chia start harvester
  fi
else
  chia start farmer
fi

if [[ ${testnet} == "true" ]]; then
  if [[ -z $full_node_port || $full_node_port == "null" ]]; then
    chia configure --set-fullnode-port 58444
  else
    chia configure --set-fullnode-port ${var.full_node_port}
  fi
fi

while true; do sleep 30; done;
