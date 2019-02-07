#!/bin/bash

####################
# GLOBAL VARIABLES #
####################
VALIDATOR=accountx
URL=localhost:8545
FROM=accountx
PASSWORD="alicepwd"
CONTRACTBYTECODE=0x608060405234801561001057600080fd5b50610134806100206000396000f30060806040526004361061004c576000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff1680633fa4f24514610051578063db80813f14610084575b600080fd5b34801561005d57600080fd5b506100666100b5565b60405180826000191660001916815260200191505060405180910390f35b34801561009057600080fd5b506100b360048036038101908080356000191690602001909291905050506100bb565b005b60005481565b80600081600019169055507f3e6045ae39bf63e71374331a261d739642ac94c186a19a6e1176f2d73c1880e18160405180826000191660001916815260200191505060405180910390a1505600a165627a7a723058209f6ecc396c677bfe61208da0b1c7bc0357a2cae73271a78ed422cb5eaa2d60d40029

TXSETDATA=0xdb80813f0000000000000000000000000000000000000000000000000000000074657374
TXGETDATA=0x3fa4f245

SLEEP=10

#######################
# Contract Deployment #
#######################

# Compose contract create
COMPOSE=$(curl -s --data '{"method":"parity_composeTransaction","params":[{"from":"'$FROM'", "data":"'$CONTRACTBYTECODE'"}],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST "$URL" | jq .result)
GAS=$(echo $COMPOSE | jq .gas)
NONCE=$(echo $COMPOSE | jq .nonce)

# Sign contract
SIGNED=$(curl -s --data '{"method":"personal_signTransaction","params":[{"condition":null,"data":"'$CONTRACTBYTECODE'","from":"'$FROM'","gas":'$GAS',"gasPrice":"0x0","nonce":'$NONCE',"to":null,"value":"0x0"},"'$PASSWORD'"],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST "$URL" | jq .result)
CONTRACTRAW=$(echo $SIGNED | jq .raw)

# # compose private deploy
COMPOSE=$(curl -s --data '{"method":"private_composeDeploymentTransaction","params":["latest", '$CONTRACTRAW', ["'$VALIDATOR'"], "0x0"],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST "$URL" | jq .result) 
CONTRACT=$(echo $COMPOSE | jq .receipt | jq .contractAddress)
PRIVATETXCONTRACTDATA=$(echo $COMPOSE | jq .transaction | jq .data)
GAS=$(echo $COMPOSE | jq .transaction | jq .gas)
NONCE=$(echo $COMPOSE | jq .transaction | jq .nonce)

# sign private deploy tx
SIGNED=$(curl -s --data '{"method":"personal_signTransaction","params":[{"condition":null,"data":'$PRIVATETXCONTRACTDATA',"from":"'$FROM'","gas":'$GAS',"gasPrice":"0x0","nonce":'$NONCE',"to":null,"value":"0x0"},"'$PASSWORD'"],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST "$URL" | jq .result)
CONTRACTRAW=$(echo $SIGNED | jq .raw)

printf "Sending contract: \n"
curl -s --data '{"method":"eth_sendRawTransaction","params":['$CONTRACTRAW'],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST "$URL"
printf "\n"

sleep $SLEEP

#################
# SETTING VALUE #
#################

# composing transaction
COMPOSE=$(curl -s --data '{"method":"parity_composeTransaction","params":[{"from":"'$FROM'","to":'$CONTRACT',"data":"'$TXSETDATA'"}],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST "$URL" | jq .result)
GAS=$(echo $COMPOSE | jq .gas)
NONCE=$(echo $COMPOSE | jq .nonce)

# Signing transaction
TX=$(curl -s --data '{"method":"personal_signTransaction","params":[{"condition":null,"data":"'$TXSETDATA'","from":"'$FROM'","gas":'$GAS',"gasPrice":"0x0","nonce":'$NONCE',"to":'$CONTRACT',"value":"0x0"},"'$PASSWORD'"],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST "$URL" | jq .result)
RAW=$(echo $TX | jq .raw)

# sending private transaction
printf "Sending private transaction: \n"
curl -s --data '{"method":"private_sendTransaction","params":['$RAW'],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST "$URL" 
printf "\n"

sleep $SLEEP

NONCE=$(curl -s --data '{"method": "eth_getTransactionCount", "params":["'$FROM'"],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST "$URL" | jq .result) 

printf "Getting private transaction: \n"
curl -s --data '{"method":"private_call","params":["latest",{"from":"'$FROM'","to":'$CONTRACT',"data":"'$TXGETDATA'", "nonce":'$NONCE'}],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST "$URL"

