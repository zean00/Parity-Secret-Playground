#!/bin/bash

####################
# GLOBAL VARIABLES #
####################
VALIDATOR="0x00ef3648f8e4b58189d7a2c6a0fae3122090b7fc"
URL=localhost:8545
FROM="0x00ef3648f8e4b58189d7a2c6a0fae3122090b7fc"
PASSWORD="alicepwd"
CONTRACTBYTECODE=0x608060405234801561001057600080fd5b50610134806100206000396000f30060806040526004361061004c576000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff1680633fa4f24514610051578063db80813f14610084575b600080fd5b34801561005d57600080fd5b506100666100b5565b60405180826000191660001916815260200191505060405180910390f35b34801561009057600080fd5b506100b360048036038101908080356000191690602001909291905050506100bb565b005b60005481565b80600081600019169055507f3e6045ae39bf63e71374331a261d739642ac94c186a19a6e1176f2d73c1880e18160405180826000191660001916815260200191505060405180910390a1505600a165627a7a723058209f6ecc396c677bfe61208da0b1c7bc0357a2cae73271a78ed422cb5eaa2d60d40029
ServerKey=0x9abd1cb10ffc129b793e235b28c6af82bd89009279e9607986e05d5fbc1cead9c4c2a36a1bf004d7d456357f416215a5fe60d6557e65b8207bf4f459e7fc8abe
TXSETDATA=0xdb80813f0000000000000000000000000000000000000000000000000000000074657374
TXGETDATA=0x3fa4f245

SLEEP=10

#######################
# Document encryption #
#######################


encrypted_key=$(curl --data-binary '{"jsonrpc": "2.0", "method": "secretstore_generateDocumentKey", "params": ["'$FROM'", "alicepwd","'$ServerKey'"], "id":1 }' -H 'content-type: application/json' http://127.0.0.1:8545/ | jq '.result .encrypted_key')

curl --data-binary '{"jsonrpc": "2.0", "method": "secretstore_encrypt", "params": ["'$FROM'", "alicepwd", '$encrypted_key', "0x6d79536563726574446f63756d656e74"], "id":1 }' -H 'content-type: application/json' http://127.0.0.1:8545/

curl -X POST http://localhost:8010/shadow/45ce99addb0f8385bd24f30da619ddcc0cadadab73e2a4ffb7801083086b3fc2/5fcf1622c1301cb8332ab589f4f7abd66a21f27636382d57b5ae6d376bab010a2e47c4ad027c96e8e41660d29292c2844454f212b36a7834b64be71f9bd3ac0400/f0e62b05b68b1847ad948572a1b04a91dee7d7dca2f675fd00c136eb706d491604e0322bb954620dc9145c54729e7b484c0b17a7bda64a1d2392007334f835fd/49808bd32126e1cd78a96a01e2fb931b0b04f6f5123a3f2fd42e20eaa1aac83a157f7ad4be57518137d51d05a47341bd04b6f873dcd00ac533e783f8e2b87e8b


# #######################
# # Contract Deployment #
# #######################

# Compose contract create
COMPOSE=$(curl -s --data '{"method":"parity_composeTransaction","params":[{"from":"'$FROM'", "data":"'$CONTRACTBYTECODE'"}],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST "$URL" | jq .result)
GAS=$(echo $COMPOSE | jq .gas)
NONCE=$(echo $COMPOSE | jq .nonce)

# # Sign contract
# SIGNED=$(curl -s --data '{"method":"personal_signTransaction","params":[{"condition":null,"data":"'$CONTRACTBYTECODE'","from":"'$FROM'","gas":'$GAS',"gasPrice":"0x0","nonce":'$NONCE',"to":null,"value":"0x0"},"'$PASSWORD'"],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST "$URL" | jq .result)
# CONTRACTRAW=$(echo $SIGNED | jq .raw)

# # # compose private deploy
# COMPOSE=$(curl -s --data '{"method":"private_composeDeploymentTransaction","params":["latest", '$CONTRACTRAW', ["'$VALIDATOR'"], "0x0"],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST "$URL" | jq .result) 
# CONTRACT=$(echo $COMPOSE | jq .receipt | jq .contractAddress)
# PRIVATETXCONTRACTDATA=$(echo $COMPOSE | jq .transaction | jq .data)
# GAS=$(echo $COMPOSE | jq .transaction | jq .gas)
# NONCE=$(echo $COMPOSE | jq .transaction | jq .nonce)

# # sign private deploy tx
# SIGNED=$(curl -s --data '{"method":"personal_signTransaction","params":[{"condition":null,"data":'$PRIVATETXCONTRACTDATA',"from":"'$FROM'","gas":'$GAS',"gasPrice":"0x0","nonce":'$NONCE',"to":null,"value":"0x0"},"'$PASSWORD'"],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST "$URL" | jq .result)
# CONTRACTRAW=$(echo $SIGNED | jq .raw)

# printf "Sending contract: \n"
# curl -s --data '{"method":"eth_sendRawTransaction","params":['$CONTRACTRAW'],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST "$URL"
# printf "\n"

# sleep $SLEEP

# #################
# # SETTING VALUE #
# #################

# # composing transaction
# COMPOSE=$(curl -s --data '{"method":"parity_composeTransaction","params":[{"from":"'$FROM'","to":'$CONTRACT',"data":"'$TXSETDATA'"}],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST "$URL" | jq .result)
# GAS=$(echo $COMPOSE | jq .gas)
# NONCE=$(echo $COMPOSE | jq .nonce)

# # Signing transaction
# TX=$(curl -s --data '{"method":"personal_signTransaction","params":[{"condition":null,"data":"'$TXSETDATA'","from":"'$FROM'","gas":'$GAS',"gasPrice":"0x0","nonce":'$NONCE',"to":'$CONTRACT',"value":"0x0"},"'$PASSWORD'"],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST "$URL" | jq .result)
# RAW=$(echo $TX | jq .raw)

# # sending private transaction
# printf "Sending private transaction: \n"
# curl -s --data '{"method":"private_sendTransaction","params":['$RAW'],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST "$URL" 
# printf "\n"

# sleep $SLEEP

# NONCE=$(curl -s --data '{"method": "eth_getTransactionCount", "params":["'$FROM'"],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST "$URL" | jq .result) 

# printf "Getting private transaction: \n"
# curl -s --data '{"method":"private_call","params":["latest",{"from":"'$FROM'","to":'$CONTRACT',"data":"'$TXGETDATA'", "nonce":'$NONCE'}],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST "$URL"

