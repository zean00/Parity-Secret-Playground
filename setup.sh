#!/bin/bash

# cleanup any previous attempts of running this script
docker-compose down
rm -rf parity/config/secret/db.*
rm -rf parity/config/db.*

# get up to speed
docker-compose pull ss1 alice

# setup of 3 secret nodes

for i in {1..3}
do
    # generating good config files 
    loc[$i]=parity/config/secret/ss$i.toml
    cp parity/config/secret/ss$i.bak.toml ${loc[$i]}

    # create secret accounts
    ss[$i]=$(docker-compose run -T  --rm ss$i account new)

    # cutting the 0x 
    ssx[$i]=$(echo ${ss[$i]}|cut -d "x" -f 2)
    
    # replacing dummy variables with accounts
    sed -i '' -e  s,"accountx","${ssx[$i]}",g -e "/self_secret/s/^#//g" ${loc[$i]}

    # grabbing the enode and server public key from the logs

    sslog[$i]=$(timeout 10s docker-compose up ss$i)
    ssp[$i]=$(echo "${sslog[$i]}"|grep "SecretStore node:"|cut -d "x" -f 2)
    ssE[$i]=$(echo "${sslog[$i]}"|grep "Public node URL:"|cut -d "/" -f 3)
    docker kill $(docker ps -q)

done

# replacing dummy variables with enodes and node public keys
for i in {1..3}
do
    for j in {1..3}
    do
        sed -i '' -e  s,ssE$i,${ssE[$i]},g -e  s,ssp$i,${ssp[$i]},g \
                  -e "/bootnodes/s/^#//g"  -e "/nodes/s/^#//g" ${loc[$j]}
    done
done

# setup alice bob and charlie
for i in alice bob charlie; do
    
    #copy configs
    loc["$i"]=parity/config/$i.toml
    cp parity/config/$i.bak.toml ${loc[$i]}
    
    # create accounts
    mm["$i"]=$(docker-compose run -T --rm $i account new)

    # grep enode
    mmlog["$i"]=$(timeout 10s docker-compose up $i)
    mmE["$i"]=$(echo "${mmlog[$i]}"|grep "Public node URL:"|cut -d "/" -f 3)
    echo ${mmE["$i"]}
    docker kill $(docker ps -q)

    # edit new config files with the correct accounts

    sed -i ''   -e "/validators/s/^#//g"   -e "/signer/s/^#//g" \
                -e "/account/s/^#//g"      -e "/unlock/s/^#//g" \
                -e "/bootnodes/s/^#//g"    -e s,accountx,${mm["$i"]},g \
                -e s,mmE$i,${mmE["$i"]},g  ${loc["$i"]}
    
    for j in {1..3}
    do
        sed -i '' -e s,ssE$j,${ssE[$j]},g   ${loc["$i"]}
    done
done

read -p "Do you want to deploy the acl permissioning contract? (RECOMMENDED) (y/n)? " CONT
if [ "$CONT" = "y" ]; then
    
    # deploy acl
    bash acl.sh ${mm["alice"]} ${mm["bob"]}

    #private contract
    read -p "Do you want to deploy the example private contract?  (y/n)? " CONT
    if [ "$CONT" = "y" ]; then

        bash private.sh ${mm["alice"]} ${mm["bob"]}
    else
      echo "Setup done!"
    fi
fi