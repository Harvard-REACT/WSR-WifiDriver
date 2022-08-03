#!/bin/bash

set -e

sudo apt-get install gcc make linux-headers-$(uname -r) git-core
sudo apt-get install iw vim
#Assumpe the auto-generated interface name starting with wlp.
csi_interface=$(ls /sys/class/net/ | grep wlp)
echo iface $csi_interface inet manual | sudo tee -a /etc/network/interfaces
sudo service network-manager restart

#sudo mv /lib/modules/$(uname -r)/kernel/drivers/net/wireless/intel/iwlwifi/iwlwifi.ko /lib/modules/$(uname -r)/kernel/drivers/net/wireless/intel/iwlwifi/iwlwifi.ko.bak

#sudo mv /lib/modules/$(uname -r)/kernel/drivers/net/wireless/intel/iwlwifi/mvm/iwlmvm.ko /lib/modules/$(uname -r)/kernel/drivers/net/wireless/intel/iwlwifi/mvm/iwlmvm.ko.bak

#sudo mv /lib/modules/$(uname -r)/kernel/drivers/net/wireless/intel/iwlwifi/dvm/iwldvm.ko /lib/modules/$(uname -r)/kernel/drivers/net/wireless/intel/iwlwifi/dvm/iwldvm.ko.bak

cpuCores=`cat /proc/cpuinfo | grep "cpu cores" | uniq | awk '{print $NF}'`
sudo make  -C /lib/modules/$(uname -r)/build M=~/WSR-WifiDriver/iwlwifi/ modules

sudo cp ~/WSR-WifiDriver/iwlwifi/iwlwifi.ko /lib/modules/$(uname -r)/kernel/drivers/net/wireless/intel/iwlwifi/

sudo cp ~/WSR-WifiDriver/iwlwifi/dvm/iwldvm.ko /lib/modules/$(uname -r)/kernel/drivers/net/wireless/intel/iwlwifi/dvm/

sudo cp ~/WSR-WifiDriver/iwlwifi/mvm/iwlmvm.ko /lib/modules/$(uname -r)/kernel/drivers/net/wireless/intel/iwlwifi/mvm/
sudo depmod

cd ~
if [ ! -d "$HOME/WSR-Toolbox-linux-80211n-csitool-supplementary" ]
then
git clone https://github.com/Harvard-REACT/WSR-Toolbox-linux-80211n-csitool-supplementary.git
fi

STR=$((ls -t1 /lib/firmware/*.orig |  head -n 1) 2>&1)
SUB='cannot'

if [[ "$STR" == *"$SUB"* ]]
then
    for file in /lib/firmware/iwlwifi-5000-*.ucode; do sudo mv $file $file.orig; done
    sudo cp  WSR-Toolbox-linux-80211n-csitool-supplementary/firmware/iwlwifi-5000-2.ucode.sigcomm2010 /lib/firmware/

    sudo ln -s iwlwifi-5000-2.ucode.sigcomm2010 /lib/firmware/iwlwifi-5000-2.ucode


    sudo apt-mark hold $(uname -r)
fi
