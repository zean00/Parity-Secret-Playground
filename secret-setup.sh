
#!/bin/bash

# cleanup any previous attempts of running this script

docker-compose down
rm -rf parity/config/secret/db.*

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

sed -i '' -e  s,ss1E,$ss1E,g -e  s,ss1p,$ss1p,g parity/config/secret/ss1.toml parity/config/secret/ss2.toml parity/config/secret/ss3.toml
sed -i '' -e  s,ss2E,$ss2E,g -e  s,ss2p,$ss2p,g parity/config/secret/ss1.toml parity/config/secret/ss2.toml parity/config/secret/ss3.toml
sed -i '' -e  s,ss3E,$ss3E,g -e  s,ss3p,$ss3p,g parity/config/secret/ss1.toml parity/config/secret/ss2.toml parity/config/secret/ss3.toml

# uncommenting the previously ununsed configurations

for i in ss1 ss2 ss3; do
loc=parity/config/secret/$i.toml
sed -i '' -e "/bootnodes/s/^#//g" -e "/nodes/s/^#//g" $loc
done