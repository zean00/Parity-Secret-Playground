# Parity Secret Store playground

We really appreciated the ease with which one could set up a [POA network](https://github.com/orbita-center/parity-poa-playground), and decided to build on top of it SecretStore support as the Parity tutorials seemed to be oriented more towards DevOps rather than blockchain developers.

This repository creates all the node configurations required to perform secret transactions on a Parity network.

Just run: `bash setup.sh`

We also recompiled the Parity binaries in docker and offer a separate CI/CD to reduce the possibility of encountering more bugs (due to user permissions). There is also a SecretStore tag which is used in the docker-compose, as building yourself takes a long time:

https://github.com/Kryha/parity-docker

The current version follows the Parity tutorials for SecretStore and Private transactions:

https://wiki.parity.io/Secret-Store-Tutorial-overview

https://wiki.parity.io/Private-Transactions.html

As a result, one can directly start sending private transactions, without the need of manually configuring the network. All accounts are generated on setup script execution, no accounts pre-exist.

We strongly recommended going through the tutorials to understand what the setup does and how to interact with the SecretStore.

Currently, we support the InstantSeal network and will implement POA as soon as I have some more time.

Requirements:

Linux:

jq: `sudo apt-get install jq`

Mac OS:

[Upgrade your bash to >= 4.0](https://akrabat.com/upgrading-to-bash-4-on-macos/) because the setup script uses bash associative arrays.

Jq and Timeout:
```
brew install jq coreutils
sudo ln -s /usr/local/bin/gtimeout /usr/local/bin/timeout
```
