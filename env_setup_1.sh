#!/bin/sh

set -e

sudo apt-get update 
sudo apt-get install gcc make linux-headers-$(uname -r) git-core
sudo apt-get install iw vim
echo iface $1 inet manual | sudo tee -a /etc/network/interfaces
sudo service network-manager restart

sudo cp /lib/modules/$(uname -r)/kernel/drivers/net/wireless/intel/iwlwifi/iwlwifi.ko /lib/modules/$(uname -r)/kernel/drivers/net/wireless/intel/iwlwifi/iwlwifi.ko.bak

sudo cp /lib/modules/$(uname -r)/kernel/drivers/net/wireless/intel/iwlwifi/mvm/iwlmvm.ko /lib/modules/$(uname -r)/kernel/drivers/net/wireless/intel/iwlwifi/mvm/iwlmvm.ko.bak

sudo cp /lib/modules/$(uname -r)/kernel/drivers/net/wireless/intel/iwlwifi/dvm/iwldvm.ko /lib/modules/$(uname -r)/kernel/drivers/net/wireless/intel/iwlwifi/dvm/iwldvm.ko.bak
