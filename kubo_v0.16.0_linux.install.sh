#!/bin/bash
[ $(id -u) -eq 0 ] && echo "LANCEMENT root INTERDIT. Utilisez un simple utilisateur du groupe \"sudo\" SVP" && exit 1

mkdir ~/.zen/tmp
cd  ~/.zen/tmp

# Check processor architecture
architecture=$(uname -m)

# Download appropriate version of kubo
if [ "$architecture" == "x86_64" ]; then
    wget -O kubo.tar.gz https://dist.ipfs.tech/kubo/v0.16.0/kubo_v0.16.0_linux-amd64.tar.gz
elif [ "$architecture" == "aarch64" ]; then
    wget -O kubo.tar.gz https://dist.ipfs.tech/kubo/v0.16.0/kubo_v0.16.0_linux-arm64.tar.gz
elif [ "$architecture" == "armv7l" ]; then
    wget -O kubo.tar.gz https://dist.ipfs.tech/kubo/v0.16.0/kubo_v0.16.0_linux-arm.tar.gz
else
    echo "Error: Unknown architecture"
    exit 1
fi

tar -xvzf kubo.tar.gz

cd kubo

# Install
sudo bash install.sh

# Test & clean
[[ $(ipfs --version) ]] \
&& rm -Rf ~/.zen/tmp/kubo*
