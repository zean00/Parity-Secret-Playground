#!/bin/bash
docker-compose pull authority0
docker-compose up -d authority0 authority1 authority2
sleep 10

acc0=$(curl --data '{"jsonrpc":"2.0","method":"parity_newAccountFromPhrase","params":["node0", "node0"],"id":0}' -H "Content-Type: application/json" -X POST localhost:8545|jq .result)
acc1=$(curl --data '{"jsonrpc":"2.0","method":"parity_newAccountFromPhrase","params":["node1", "node1"],"id":0}' -H "Content-Type: application/json" -X POST localhost:8544|jq .result)
acc2=$(curl --data '{"jsonrpc":"2.0","method":"parity_newAccountFromPhrase","params":["node2", "node2"],"id":0}' -H "Content-Type: application/json" -X POST localhost:8543|jq .result)

sed  -i '' -e s,accountx,$acc0,g parity/config/authority0.toml
sed  -i '' -e s,accountx,$acc1,g parity/config/authority1.toml
sed  -i '' -e s,accountx,$acc2,g parity/config/authority2.toml

for i in `seq 0 2`;
do
sed -i '' -e "/engine_signer/s/^#//g" parity/config/authority$i.toml
done
docker kill $(docker ps -q)


