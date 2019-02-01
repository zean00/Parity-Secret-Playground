#!/bin/bash
docker-compose pull member0
docker-compose up -d member0 member1 member2
sleep 10

curl --data '{"jsonrpc":"2.0","method":"parity_addReservedPeer","params":["enode://RESULT"],"id":0}' -H "Content-Type: application/json" -X POST localhost:8541



acc0=$(curl --data '{"jsonrpc":"2.0","method":"parity_newAccountFromPhrase","params":["alicepwd", "alicepwd"],"id":0}' -H "Content-Type: application/json" -X POST localhost:8545|jq .result)
acc1=$(curl --data '{"jsonrpc":"2.0","method":"parity_newAccountFromPhrase","params":["bobpwd", "bobpwd"],"id":0}' -H "Content-Type: application/json" -X POST localhost:8544|jq .result)
acc2=$(curl --data '{"jsonrpc":"2.0","method":"parity_newAccountFromPhrase","params":["charliepwd", "charliepwd"],"id":0}' -H "Content-Type: application/json" -X POST localhost:8543|jq .result)

sed  -i  s,accountx,$acc0,g parity/config/alice.toml
sed  -i  s,accountx,$acc1,g parity/config/bob.toml
sed  -i  s,accountx,$acc2,g parity/config/charlie.toml


sed -i  "/engine_signer/s/^#//g" parity/config/alice.toml
sed -i  "/engine_signer/s/^#//g" parity/config/bob.toml
sed -i  "/engine_signer/s/^#//g" parity/config/charlie.toml

docker kill $(docker ps -q)
