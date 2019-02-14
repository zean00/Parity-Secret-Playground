#!/bin/bash

# compile private contract
docker run -v $PWD/contracts:/solidity ethereum/solc:0.4.24 --bin -o . private.sol --overwrite

alice=$1
bob=$2
PASSWORD=$3
pbytecode="0x$(cat contracts/Test1.bin)"
TXSETDATA=0xbc64b76d0000000000000000000000000000000000000000000000000000000074657374
TXGETDATA=0x0c55699c

green=`tput setaf 2`
reset=`tput sgr0`

docker-compose up -d alice bob charlie ss1 ss2 ss3

sleep 10

printf "Compose contract create\n"

COMPOSE=$(curl -s --data '{"method":"parity_composeTransaction","params":[{"from":"'$alice'", "data":"'$pbytecode'"}],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST localhost:8545| jq .result)
GAS=$(echo $COMPOSE | jq .gas)
NONCE=$(echo $COMPOSE | jq .nonce)

sleep 3

printf  "Sign contract\n"

SIGNED=$(curl -s --data '{"method":"personal_signTransaction","params":[{"condition":null,"data":"'$pbytecode'","from":"'$alice'","gas":'$GAS',"gasPrice":"0x0","nonce":'$NONCE',"to":null,"value":"0x0"},"'$PASSWORD'"],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST localhost:8545 | jq .result)
CONTRACTRAW=$(echo $SIGNED | jq .raw)

sleep 3

printf "Compose private deploy\n"

COMPOSE=$(curl -s --data '{"method":"private_composeDeploymentTransaction","params":["latest", '$CONTRACTRAW', ["'$bob'"], "0x0"],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST localhost:8545  | jq .result) 
CONTRACT=$(echo $COMPOSE | jq .receipt | jq .contractAddress)
PRIVATETXCONTRACTDATA=$(echo $COMPOSE | jq .transaction | jq .data)
GAS=$(echo $COMPOSE | jq .transaction | jq .gas)
NONCE=$(echo $COMPOSE | jq .transaction | jq .nonce)

sleep 3

printf "Sign private deploy tx\n"

SIGNED=$(curl -s --data '{"method":"personal_signTransaction","params":[{"condition":null,"data":'$PRIVATETXCONTRACTDATA',"from":"'$alice'","gas":'$GAS',"gasPrice":"0x0","nonce":'$NONCE',"to":null,"value":"0x0"},"'$PASSWORD'"],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST localhost:8545 | jq .result)
CONTRACTRAW=$(echo $SIGNED | jq .raw)

sleep 3

printf "Sending contract: \n"
curl -s --data '{"method":"eth_sendRawTransaction","params":['$CONTRACTRAW'],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST localhost:8545

sleep 3

printf "Composing transaction\n"
COMPOSE=$(curl -s --data '{"method":"parity_composeTransaction","params":[{"from":"'$alice'","to":'$CONTRACT',"data":"'$TXSETDATA'"}],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST localhost:8545 | jq .result)
GAS=$(echo $COMPOSE | jq .gas)
NONCE=$(echo $COMPOSE | jq .nonce)

sleep 3

printf "Signing transaction\n"
TX=$(curl -s --data '{"method":"personal_signTransaction","params":[{"condition":null,"data":"'$TXSETDATA'","from":"'$alice'","gas":'$GAS',"gasPrice":"0x0","nonce":'$NONCE',"to":'$CONTRACT',"value":"0x0"},"'$PASSWORD'"],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST localhost:8545 | jq .result)
RAW=$(echo $TX | jq .raw)
sleep 3

printf "Sending private transaction: \n"
curl -s --data '{"method":"private_sendTransaction","params":['$RAW'],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST localhost:8545

sleep 3

printf "Getting nonce\n"

NONCE=$(curl -s --data '{"method": "eth_getTransactionCount", "params":["'$alice'"],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST localhost:8545 | jq .result) 

sleep 3

printf "Getting private transaction \n"
PRES=$(curl -s --data '{"method":"private_call","params":["latest",{"from":"'$alice'","to":'$CONTRACT',"data":"'$TXGETDATA'", "nonce":'$NONCE'}],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST localhost:8545|jq .result)

payload=$(echo $PRES |grep -o '[^0]*$'|cut -d '"' -f 1)
if [ $payload = $(echo $TXSETDATA|grep -o '[^0]*$') ]; then
  echo -e "Received expected payload: ${green}$payload${reset}"
fi
docker kill $(docker ps -q)