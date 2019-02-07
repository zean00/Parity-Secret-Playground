#!/bin/bash

docker-compose  -f docker-compose.setup.yml pull  alice
docker-compose  -f docker-compose.setup.yml up  -d alice bob charlie

sleep 10

#get enodes

aliceE=$(curl --data '{"method":"parity_enode","params":[],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST localhost:8545|jq .result)
bobE=$(curl --data '{"method":"parity_enode","params":[],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST localhost:8544|jq .result)
charlieE=$(curl --data '{"method":"parity_enode","params":[],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST localhost:8543|jq .result)

#create accounts

alice=$(curl --data '{"jsonrpc":"2.0","method":"parity_newAccountFromPhrase","params":["alicepwd", "alicepwd"],"id":0}' -H "Content-Type: application/json" -X POST localhost:8545|jq .result)
bob=$(curl --data '{"jsonrpc":"2.0","method":"parity_newAccountFromPhrase","params":["bobpwd", "bobpwd"],"id":0}' -H "Content-Type: application/json" -X POST localhost:8544|jq .result)
charlie=$(curl --data '{"jsonrpc":"2.0","method":"parity_newAccountFromPhrase","params":["charliepwd", "charliepwd"],"id":0}' -H "Content-Type: application/json" -X POST localhost:8543|jq .result)

# create new config files with the correct accounts

for i in alice bob charlie; do
loc=parity/config/$i.toml
cp parity/config/$i.bak.toml $loc
sed -i '' -e "/validators/s/^#//g" -e "/signer/s/^#//g" -e "/account/s/^#//g" -e "/unlock/s/^#//g" -e "/bootnodes/s/^#//g" $loc
done

sed -i '' -e  s,accountx,$alice,g parity/config/alice.toml
sed -i '' -e  s,accountx,$bob,g parity/config/bob.toml
sed -i '' -e  s,accountx,$charlie,g parity/config/charlie.toml


#fix test script

sed -i '' -e  s,accountx,$alice,g test.sh

docker kill $(docker ps -q)
