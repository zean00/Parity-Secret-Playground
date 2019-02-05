#!/bin/bash
docker-compose pull member0
docker-compose up -d member0 member1 member2
sleep 10

alice=$(curl --data '{"jsonrpc":"2.0","method":"parity_newAccountFromPhrase","params":["alicepwd", "alicepwd"],"id":0}' -H "Content-Type: application/json" -X POST localhost:8545|jq .result)
bob=$(curl --data '{"jsonrpc":"2.0","method":"parity_newAccountFromPhrase","params":["bobpwd", "bobpwd"],"id":0}' -H "Content-Type: application/json" -X POST localhost:8544|jq .result)
charlie=$(curl --data '{"jsonrpc":"2.0","method":"parity_newAccountFromPhrase","params":["charliepwd", "charliepwd"],"id":0}' -H "Content-Type: application/json" -X POST localhost:8543|jq .result)

for i in alice bob charlie; do
loc=parity/config/$i.toml
sed -i '' -e  s,accountx,$$i,g $loc
sed -i '' -e "/validators/s/^#//g" $loc
sed -i '' -e "/signer/s/^#//g" $loc
sed -i '' -e "/account/s/^#//g" $loc
sed -i '' -e "/unlock/s/^#//g" $loc
done

docker kill $(docker ps -q)
