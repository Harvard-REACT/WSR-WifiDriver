#!/bin/bash

set -e

cpuCores=`cat /proc/cpuinfo | grep "cpu cores" | uniq | awk '{print $NF}'`

sudo cp ~/WSR-WifiDriver/iwlwifi/iwlwifi.ko /lib/modules/$(uname -r)/kernel/drivers/net/wireless/intel/iwlwifi/

sudo cp ~/WSR-WifiDriver/iwlwifi/dvm/iwldvm.ko /lib/modules/$(uname -r)/kernel/drivers/net/wireless/intel/iwlwifi/dvm/

sudo cp ~/WSR-WifiDriver/iwlwifi/mvm/iwlmvm.ko /lib/modules/$(uname -r)/kernel/drivers/net/wireless/intel/iwlwifi/mvm/
sudo depmod

#git clone https://github.com/dhalperi/linux-80211n-csitool-supplementary.git

STR=$((ls -t1 /lib/firmware/*.orig |  head -n 1) 2>&1)
SUB='cannot'

if [[ "$STR" == *"$SUB"* ]]
then
    for file in /lib/firmware/iwlwifi-5000-*.ucode; do sudo mv $file $file.orig; done
    sudo cp  WSR-Toolbox-linux-80211n-csitool-supplementary/firmware/iwlwifi-5000-2.ucode.sigcomm2010 /lib/firmware/

    sudo ln -s iwlwifi-5000-2.ucode.sigcomm2010 /lib/firmware/iwlwifi-5000-2.ucode

    git clone https://github.com/dhalperi/lorcon-old.git

    sudo apt-mark hold $(uname -r)
fi

echo "Setup completed."
