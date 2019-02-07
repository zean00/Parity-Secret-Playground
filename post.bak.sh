#!/bin/bash
alice=alicer
bob=bobr
bytecode=0x608060405234801561001057600080fd5b50610134806100206000396000f30060806040526004361061004c576000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff1680633fa4f24514610051578063db80813f14610084575b600080fd5b34801561005d57600080fd5b506100666100b5565b60405180826000191660001916815260200191505060405180910390f35b34801561009057600080fd5b506100b360048036038101908080356000191690602001909291905050506100bb565b005b60005481565b80600081600019169055507f3e6045ae39bf63e71374331a261d739642ac94c186a19a6e1176f2d73c1880e18160405180826000191660001916815260200191505060405180910390a1505600a165627a7a723058209f6ecc396c677bfe61208da0b1c7bc0357a2cae73271a78ed422cb5eaa2d60d40029
PASSWORD="alicepwd"
TXSETDATA=0xdb80813f0000000000000000000000000000000000000000000000000000000074657374
TXGETDATA=0x3fa4f245

printf "Compose contract create\n"

COMPOSE=$(curl --data '{"method":"parity_composeTransaction","params":[{"from":"'$alice'", "data":"'$bytecode'"}],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST localhost:8545| jq .result)
GAS=$(echo $COMPOSE | jq .gas)
NONCE=$(echo $COMPOSE | jq .nonce)

sleep 5

printf  "Sign contract\n"

SIGNED=$(curl -s --data '{"method":"personal_signTransaction","params":[{"condition":null,"data":"'$bytecode'","from":"'$alice'","gas":'$GAS',"gasPrice":"0x0","nonce":'$NONCE',"to":null,"value":"0x0"},"'$PASSWORD'"],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST localhost:8545 | jq .result)
CONTRACTRAW=$(echo $SIGNED | jq .raw)

sleep 5

printf "compose private deploy\n"

COMPOSE=$(curl -s --data '{"method":"private_composeDeploymentTransaction","params":["latest", '$CONTRACTRAW', ["'$bob'"], "0x0"],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST localhost:8545  | jq .result) 
CONTRACT=$(echo $COMPOSE | jq .receipt | jq .contractAddress)
PRIVATETXCONTRACTDATA=$(echo $COMPOSE | jq .transaction | jq .data)
GAS=$(echo $COMPOSE | jq .transaction | jq .gas)
NONCE=$(echo $COMPOSE | jq .transaction | jq .nonce)

sleep 5

printf "sign private deploy tx\n"

SIGNED=$(curl -s --data '{"method":"personal_signTransaction","params":[{"condition":null,"data":'$PRIVATETXCONTRACTDATA',"from":"'$alice'","gas":'$GAS',"gasPrice":"0x0","nonce":'$NONCE',"to":null,"value":"0x0"},"'$PASSWORD'"],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST localhost:8545 | jq .result)
CONTRACTRAW=$(echo $SIGNED | jq .raw)

sleep 5

printf "Sending contract: \n"
curl -s --data '{"method":"eth_sendRawTransaction","params":['$CONTRACTRAW'],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST localhost:8545
printf "\n"

sleep 5

printf "composing transaction\n"
COMPOSE=$(curl -s --data '{"method":"parity_composeTransaction","params":[{"from":"'$alice'","to":'$CONTRACT',"data":"'$TXSETDATA'"}],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST localhost:8545 | jq .result)
GAS=$(echo $COMPOSE | jq .gas)
NONCE=$(echo $COMPOSE | jq .nonce)

sleep 5

printf "Signing transaction\n"
TX=$(curl -s --data '{"method":"personal_signTransaction","params":[{"condition":null,"data":"'$TXSETDATA'","from":"'$alice'","gas":'$GAS',"gasPrice":"0x0","nonce":'$NONCE',"to":'$CONTRACT',"value":"0x0"},"'$PASSWORD'"],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST localhost:8545 | jq .result)
RAW=$(echo $TX | jq .raw)

sleep 5


printf "Sending private transaction: \n"
curl -s --data '{"method":"private_sendTransaction","params":['$RAW'],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST localhost:8545
printf "\n"

sleep 5

printf "getting nonce\n"

NONCE=$(curl -s --data '{"method": "eth_getTransactionCount", "params":["'$alice'"],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST localhost:8545 | jq .result) 

sleep 5

printf "Getting private transaction: \n"
curl -s --data '{"method":"private_call","params":["latest",{"from":"'$alice'","to":'$CONTRACT',"data":"'$TXGETDATA'", "nonce":'$NONCE'}],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST localhost:8545

