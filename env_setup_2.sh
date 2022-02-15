#!/bin/bash

set -e
cd ~
cpuCores=`cat /proc/cpuinfo | grep "cpu cores" | uniq | awk '{print $NF}'`

make -C WSR-Toolbox-linux-80211n-csitool-supplementary/netlink
git clone https://github.com/dhalperi/lorcon-old.git
cd ~/lorcon-old
make -j $cpuCores
sudo make install

cd ~
make -C WSR-Toolbox-linux-80211n-csitool-supplementary/injection


echo "Setup completed."
