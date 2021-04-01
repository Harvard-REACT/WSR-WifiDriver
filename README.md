# WiFi Driver and Firmware for Wireless channel data (CSI) collection

This is a modified verison and supplementary code released as part [Linux 802.11n CSI Tool](http://dhalperi.github.io/linux-80211n-csitool/) 

## Hardware Requirements
The driver requires Ubuntu 16.04 and SBC which has a mpcie slot to connect the Intel 5300 WiFi card. Currently tested on the following platforms -

- [x] UP Squared Board (OS installation steps [here](https://github.com/up-board/up-community/wiki/Ubuntu_16.04))
- [ ] OnLogic Board (Same OS installation steps as above)

## Modified Driver and Firmware Setup Steps

1. Prerequisites
```
sudo apt-get update 
sudo apt-get install gcc make linux-headers-$(uname -r) git-core
sudo apt-get install iw vim
echo iface wlp1s0 inet manual | sudo tee -a /etc/network/interfaces
sudo service network-manager restart
```

Reference : [Linux 802.11n CSI Tool installation instructions](http://dhalperi.github.io/linux-80211n-csitool/installation.html)


2. Clone this repository in home directory 
```
git clone https://github.com/Harvard-REACT/WSR-WifiDriver
```

3. Backup the default iwlwifi drivers
```
cd /lib/modules/$(uname -r)/kernel/drivers/net/wireless/intel/iwlwifi/
sudo cp iwlwifi.ko iwlwifi.ko.bak
sudo cp mvm/iwlmvm.ko mvm/iwlmvm.ko.bak
sudo cp dvm/iwldvm.ko dvm/iwldvm.ko.bak
```

4. MAC address setup to enable robot packet identification
Change the MAC address in the iwlwifi/dvm/rx.c on line 44. Change the bytes 17-22 from 0xff to intended MAC address as source MAC address.
```
vim ~/WSR-WifiDriver/iwlwifi/dvm/rx.c
```

e.g Changing    
```
0xff, 0xff, 0xff, 0xff, 0xff, 0xff
``` 
to 

```
0x00, 0x21, 0x6a, 0x39, 0x83, 0xa0
``` 
enables the TX_Neighbor robot to embed a MAC ID 00:21:6A:39:83:A0 in the packets automatically transmitted. 

Note: Please make both the above changes in any robot on which the driver is installed. 

5. Compile the drivers
```
cd ~
sudo make -j4 -C /lib/modules/$(uname -r)/build M=~/wifidrivercsi/iwlwifi/ modules
```

6. Copy the compiled drivers
```
sudo cp ~/wifidrivercsi/iwlwifi/iwlwifi.ko /lib/modules/$(uname -r)/kernel/drivers/net/wireless/intel/iwlwifi/
sudo cp ~/wifidrivercsi/iwlwifi/dvm/iwldvm.ko /lib/modules/$(uname -r)/kernel/drivers/net/wireless/intel/iwlwifi/dvm/
sudo cp ~/wifidrivercsi/iwlwifi/mvm/iwlmvm.ko /lib/modules/$(uname -r)/kernel/drivers/net/wireless/intel/iwlwifi/mvm/
sudo depmod
```

6. Follow step 3 given in given in [Linux 802.11n CSI Tool installation instructions](http://dhalperi.github.io/linux-80211n-csitool/installation.html) to install the modified firmware
```
git clone https://github.com/dhalperi/linux-80211n-csitool-supplementary.git
for file in /lib/firmware/iwlwifi-5000-*.ucode; do sudo mv $file $file.orig; done
sudo cp linux-80211n-csitool-supplementary/firmware/iwlwifi-5000-2.ucode.sigcomm2010 /lib/firmware/
sudo ln -s iwlwifi-5000-2.ucode.sigcomm2010 /lib/firmware/iwlwifi-5000-2.ucode
```

7.
Change the source MAC address in random_packet (during packet injection) to the robot's MAC address. The MAC address is available on the Intel 5300 WiFi chip or can be obtained using the following command (This requires skipping step 4 to continue the driver installation as is):

In file random_packet.c, modify the MAC addres on line 103 with corresponding address on your WiFi chip that you used in rx.c. Compile the code after modification

```
cd linux-80211n-csitool-supplementary/injection
vi random_packets.c
```

7. Build userspace csi data logging tool as per step 4 in [Linux 802.11n CSI Tool installation instructions](http://dhalperi.github.io/linux-80211n-csitool/installation.html) to install the modified firmware
```
make -C linux-80211n-csitool-supplementary/netlink
```

8. Load the dirvers and pass the required channel and bandwidth as parameters by running the setup script
```
cd ~
chmod +x ~/wifidrivercsi/setup.sh
sudo ./wifidrivercsi/setup.sh <channel> <bandwidth>
```
To verify that the network interface has been set to monitor mode, the following should be the output when running iwconfig

```
iwconfig

```

Expected output

```
mon0      IEEE 802.11  Mode:Monitor  Frequency:5.52 GHz  Tx-Power=15 dBm   
          Retry short limit:7   RTS thr:off   Fragment thr:off
          Power Management:off
          

wlp1s0    IEEE 802.11  Mode:Monitor  Frequency:5.52 GHz  Tx-Power=15 dBm   
          Retry short limit:7   RTS thr:off   Fragment thr:off
          Power Management:off

```

## Setup of packet injection (Reference [Packet Injection](https://github.com/dhalperi/linux-80211n-csitool-supplementary/tree/master/injection))
1. Install libpcap-dev
```
sudo apt-get install libpcap-dev
```

2. Download and compile LORCONv1
```
git clone https://github.com/dhalperi/lorcon-old.git
cd lorcon-old
make -j4
sudo make install
```

3. Compile the packets injection code (make sure that Step 6 of previous section is completed
```
$ cd ~
$ make -C linux-80211n-csitool-supplementary/injection
```

## Collecting CSI data packets
### On the Transmitting robot start packet transmission

1. Load the network interface and set to monitor mode (else the following [issue](https://github.com/dhalperi/linux-80211n-csitool-supplementary/issues/132) will be seen
```
$ cd ~
$ sudo ./wificsidriver/setup.sh
```

2. Start packet transmission
```
$ sudo ./linux-80211n-csitool-supplementary/injection/random_packets <total_packets to send> <packet_size> 1 <frequency>
```

e.g. To send 10000 packets, each of size 29 with 1000 packets sent every 100 ms

```
$ sudo ./linux-80211n-csitool-supplementary/injection/random_packets 10000 29 1 100
```

### On receiving robot
1. Load the network interface and set to monitor mode
```
$ cd ~
$ sudo ./wificsidriver/setup.sh
```

2. To log CSI data to a file
```
$ sudo linux-80211n-csitool-supplementary/netlink/log_to_file csi.dat
```

## Updating MAC IDs in the WSR Toolbox config files
1. Add the MAC_ID in the config file for the robot. If its a RX_SAR_robot then use the field MAC_ID :
```
    "MAC_ID":{
        "desc":"MAC ID of RX_SAR robot",
        "value":"00:21:6A:C5:FC:0"
    },
``` 

and if its a TX_Neighbor robot, then use the field input_TX_channel_csi_fn. e.g
```
"input_TX_channel_csi_fn":{
        "desc":"Forward channel csi File for each of the neighboring TX robots",
        "value":{
            "tx_0":{
                "mac_id":"00:16:EA:12:34:56",
                "csi_fn":"/REACT-Projects/WSR-Toolbox-cpp/data/LOS_2D_1_RX_1_TX_RX_P0_TX_P1/2D_TX_dataset_csi_rx_tx/csi_tx_2021-03-04_154912.dat"
            },
        }
```











