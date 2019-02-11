#!/bin/bash

# cleanup any previous attempts of running this script

docker-compose down
rm -rf parity/config/secret/db.*
rm -rf parity/config/db.*
docker-compose pull ss1

#create secret accounts

ss1=$(docker run  -i -v $PWD/parity/config:/parity/config kryha/parity-secretstore --config /parity/config/secret/ss1.bak.toml account new)
ss2=$(docker run  -i -v $PWD/parity/config:/parity/config kryha/parity-secretstore --config /parity/config/secret/ss2.bak.toml account new)
ss3=$(docker run  -i -v $PWD/parity/config:/parity/config kryha/parity-secretstore --config /parity/config/secret/ss3.bak.toml account new)

#cutting the 0x 

ss1x=$(echo $ss1|cut -d "x" -f 2)
ss2x=$(echo $ss2|cut -d "x" -f 2)
ss3x=$(echo $ss3|cut -d "x" -f 2)

#generating good config files and replacing dummy variables with accounts

for i in ss1 ss2 ss3; do
loc=parity/config/secret/$i.toml
cp parity/config/secret/$i.bak.toml $loc
sed -i '' -e "/self_secret/s/^#//g" $loc
done

sed -i '' -e  s,accountx,$ss1x,g parity/config/secret/ss1.toml
sed -i '' -e  s,accountx,$ss2x,g parity/config/secret/ss2.toml
sed -i '' -e  s,accountx,$ss3x,g parity/config/secret/ss3.toml

# grabbing the enode and server public key from the logs

ss1log=$(timeout 10s docker-compose up ss1)
ss1p=$(echo "$ss1log"|grep "SecretStore node:"|cut -d "x" -f 2)
ss1E=$(echo "$ss1log"|grep "Public node URL:"|cut -d "/" -f 3)
docker kill $(docker ps -q)

ss2log=$(timeout 10s docker-compose up ss2)
ss2p=$(echo "$ss2log"|grep "SecretStore node:"|cut -d "x" -f 2)
ss2E=$(echo "$ss2log"|grep "Public node URL:"|cut -d "/" -f 3)
docker kill $(docker ps -q)

ss3log=$(timeout 10s docker-compose up ss3)
ss3p=$(echo "$ss3log"|grep "SecretStore node:"|cut -d "x" -f 2)
ss3E=$(echo "$ss3log"|grep "Public node URL:"|cut -d "/" -f 3)
docker kill $(docker ps -q)

#generating good config files and replacing dummy variables with enodes and node public keys

sed -i '' -e  s,ss1E,$ss1E,g -e  s,ss1p,$ss1p,g  -e  s,ss2E,$ss2E,g -e  s,ss2p,$ss2p,g -e  s,ss3E,$ss3E,g -e  s,ss3p,$ss3p,g \
    parity/config/secret/ss1.toml parity/config/secret/ss2.toml parity/config/secret/ss3.toml

# uncommenting the previously ununsed configurations

for i in ss1 ss2 ss3; do
loc=parity/config/secret/$i.toml
sed -i '' -e "/bootnodes/s/^#//g" -e "/nodes/s/^#//g" $loc
done

# setup alice bob and charlie

docker-compose -f docker-compose.setup.yml pull alice

#create accounts

alice=$(docker run  -i -v $PWD/parity/config:/parity/config parity/parity:beta --config /parity/config/alice.bak.toml account new)
bob=$(docker run  -i -v $PWD/parity/config:/parity/config parity/parity:beta --config /parity/config/bob.bak.toml account new)
charlie=$(docker run  -i -v $PWD/parity/config:/parity/config parity/parity:beta --config /parity/config/charlie.bak.toml account new)

docker-compose -f docker-compose.setup.yml up -d alice bob charlie

sleep 10

#get enodes

aliceE=$(curl -s --data '{"method":"parity_enode","params":[],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST localhost:8545|jq .result)
bobE=$(curl -s --data '{"method":"parity_enode","params":[],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST localhost:8544|jq .result)
charlieE=$(curl -s --data '{"method":"parity_enode","params":[],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST localhost:8543|jq .result)
docker kill $(docker ps -q)

# create new config files with the correct accounts

for i in alice bob charlie; do
loc=parity/config/$i.toml
cp parity/config/$i.bak.toml $loc
sed -i '' -e "/validators/s/^#//g" -e "/signer/s/^#//g" -e "/account/s/^#//g" -e "/unlock/s/^#//g" -e "/bootnodes/s/^#//g" $loc
done

sed -i '' -e s,accountx,$alice,g  parity/config/alice.toml 
sed -i '' -e s,accountx,$bob,g parity/config/bob.toml
sed -i '' -e s,accountx,$charlie,g parity/config/charlie.toml

sed -i '' -e s,aliceE,$aliceE,g -e s,bobE,$bobE,g -e s,charlieE,$charlieE,g \
    -e s,ss1E,$ss1E,g -e s,ss2E,$ss2E,g -e s,ss3E,$ss3E,g \
    parity/config/alice.toml parity/config/bob.toml parity/config/charlie.toml

# compile acl contract

docker run -v $PWD/contracts:/solidity ethereum/solc:0.4.24 --bin -o . ACL.sol --overwrite

# deploy acl

docker-compose up -d alice bob charlie ss1 ss2 ss3
sleep 10

printf "Generating Secret Store key\n"

PASSWORD="alicepwd"

DOC=45ce99addb0f8385bd24f30da619ddcc0cadadab73e2a4ffb7801083086b3fc2 # echo mySecretDocument | sha256sum

RES=$(curl -s --data-binary '{"jsonrpc": "2.0", "method": "secretstore_signRawHash", "params": ["'$alice'", "'$PASSWORD'", "'0x$DOC'"], "id":1 }' -H 'content-type: application/json' localhost:8545 |jq .result| tr -d '"'|cut -d "x" -f 2)

sleep 2

SSSKEY=$(curl -s -X POST http://localhost:8010/shadow/$DOC/$RES/1)

echo "$SSSKEY">SSSkey.txt

sleep 3

bytecode="0x$(cat contracts/SSPermissions.bin)"

printf "Compose contract create\n"

COMPOSE=$(curl -s --data '{"method":"parity_composeTransaction","params":[{"from":"'$alice'", "data":"'$bytecode'"}],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST localhost:8545| jq .result)
GAS=$(echo $COMPOSE | jq .gas)
NONCE=$(echo $COMPOSE | jq .nonce)

sleep 2

printf  "Sign contract\n"

SIGNED=$(curl -s --data '{"method":"personal_signTransaction","params":[{"condition":null,"data":"'$bytecode'","from":"'$alice'","gas":'$GAS',"gasPrice":"0x0","nonce":'$NONCE',"to":null,"value":"0x0"},"'$PASSWORD'"],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST localhost:8545 | jq .result)
CONTRACTRAW=$(echo $SIGNED | jq .raw)

sleep 2

printf "Sending contract: \n"
RESULT=$(curl -s --data '{"method":"eth_sendRawTransaction","params":['$CONTRACTRAW'],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST localhost:8545|jq .result)

sleep 2

ADDRESS=$(curl -s --data '{"method":"eth_getTransactionReceipt","params":['$RESULT'],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST localhost:8545|jq '.result .contractAddress')

# cut x again

ADDRESSx=$(echo $ADDRESS|cut -d "x" -f 2)

# insert contract address in ss nodes

docker kill $(docker ps -q)

sed -i '' -e  's,acl_contract = "none",acl_contract = "'$ADDRESSx',g' parity/config/secret/ss1.toml parity/config/secret/ss2.toml parity/config/secret/ss3.toml

