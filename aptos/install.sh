#!/bin/bash

function aptos_username {
  if [ ! ${aptos_username} ]; then
  echo "Введите свое имя ноды(придумайте)"
  line
  read aptos_username
  fi
}

function install_ufw {
  curl -s https://raw.githubusercontent.com/razumv/helpers/main/tools/install_ufw.sh | bash
}

function install_docker {
  curl -s https://raw.githubusercontent.com/razumv/helpers/main/tools/install_docker.sh | bash
}

function set_vars {
  echo "export WORKSPACE=aptos_testnet" >> ${HOME}/.bash_profile
  echo "export PUBLIC_IP=$(curl -s ifconfig.me)" >> ${HOME}/.bash_profile
  echo "export aptos_username=${aptos_username}"  >> ${HOME}/.bash_profile
  source ${HOME}/.bash_profile
}

function update_deps {
  sudo apt update
  sudo apt install mc build-essential wget htop curl jq unzip -y
  sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 &>/dev/null
  sudo chmod a+x /usr/local/bin/yq
}

function download_aptos_cli {
  rm -f /usr/local/bin/aptos
  wget -O $HOME/aptos-cli.zip https://github.com/aptos-labs/aptos-core/releases/download/aptos-cli-0.2.0/aptos-cli-0.2.0-Ubuntu-x86_64.zip
  sudo unzip -o aptos-cli -d /usr/local/bin
  sudo chmod +x /usr/local/bin/aptos
}

function prepare_config {
  mkdir ${HOME}/${WORKSPACE}
  wget -qO $HOME/${WORKSPACE}/docker-compose.yaml https://raw.githubusercontent.com/aptos-labs/aptos-core/main/docker/compose/aptos-node/docker-compose.yaml
  wget -qO $HOME/${WORKSPACE}/validator.yaml https://raw.githubusercontent.com/aptos-labs/aptos-core/main/docker/compose/aptos-node/validator.yaml
}

function generate_keys {
  mkdir -p ${HOME}/${WORKSPACE}/keys
  aptos genesis generate-keys --output-dir ${HOME}/${WORKSPACE}
}

function configure_validator {
  aptos genesis set-validator-configuration \
  --keys-dir ${HOME}/${WORKSPACE} --local-repository-dir ${HOME}/${WORKSPACE} \
  --username $aptos_username \
  --validator-host $PUBLIC_IP:6180 \
  --full-node-host $PUBLIC_IP:6182
}

function generate_root_key {
  aptos key generate --output-file ${HOME}/${WORKSPACE}/keys/root
}

function add_layout {
  ROOT_KEY=F22409A93D1CD12D2FC92B5F8EB84CDCD24C348E32B3E7A720F3D2E288E63394
  tee ${HOME}/${WORKSPACE}/layout.yaml > /dev/null <<EOF
---
root_key: "${ROOT_KEY}"
users:
  - ${aptos_username}
chain_id: 40
min_stake: 0
max_stake: 100000
min_lockup_duration_secs: 0
max_lockup_duration_secs: 2592000
epoch_duration_secs: 86400
initial_lockup_timestamp: 1656615600
min_price_per_gas_unit: 1
allow_new_validators: true
EOF
}

function download_framework {
  wget -qO ${HOME}/${WORKSPACE}/framework.zip https://github.com/aptos-labs/aptos-core/releases/download/aptos-framework-v0.1.0/framework.zip
  unzip -o ${HOME}/${WORKSPACE}/framework.zip -d ${HOME}/${WORKSPACE}/
  rm ${HOME}/${WORKSPACE}/framework.zip
}

function compile_genesis_waypoint {
  aptos genesis generate-genesis --local-repository-dir ${HOME}/${WORKSPACE} --output-dir ${HOME}/${WORKSPACE}
}

function up_validator {
  docker compose -f ${HOME}/${WORKSPACE}/docker-compose.yaml up -d
}
function logo {
  curl -s https://raw.githubusercontent.com/razumv/helpers/main/doubletop.sh | bash
}

function line {
  echo "-----------------------------------------------------------------------------"
}

function colors {
  GREEN="\e[1m\e[32m"
  RED="\e[1m\e[39m"
  NORMAL="\e[0m"
}

colors
line
logo
line
aptos_username
set_vars
line
install_ufw
install_docker
update_deps
line
download_aptos_cli
prepare_config
generate_keys
generate_root_key
configure_validator
add_layout
download_framework
line
compile_genesis_waypoint
line
up_validator
line
echo "Готово"
