# WiFi Driver and Firmware for Wireless channel data (CSI) collection

This is a modified verison and supplementary code released as part [Linux 802.11n CSI Tool](http://dhalperi.github.io/linux-80211n-csitool/) 

## Hardware Requirements
The driver requires Ubuntu 16.04 and SBC which has a mpcie slot to connect the Intel 5300 WiFi card. Currently tested on the following platforms -

- [x] UP Squared Board (OS installation steps [here](https://github.com/up-board/up-community/wiki/Ubuntu_16.04)). Check Specs [here](https://up-shop.org/up-squared-series.html)
- [x] Intel Apollo Lake N4200 (Same OS installation steps as above). Check specs [here](https://www.onlogic.com/epm163/)
- [ ] Intel NUC8i3BEH (Generic Ubuntu 16.04 installation). Check base specs [here](https://www.intel.com/content/www/us/en/products/sku/126150/intel-nuc-kit-nuc8i3beh/specifications.html)

## Modified Driver and Firmware Setup Steps

1. Prerequisites

Connect to the board directly (using keyboard/mouse) and make sure that it is plugged in to internet via an ethernet cable. 

Before boot up, disable SecureBoot in BIOS (applicable to Intel NUC).

Reference : [Linux 802.11n CSI Tool installation instructions](http://dhalperi.github.io/linux-80211n-csitool/installation.html)

Make sure that the Intel 5300 WiFi card's wifi interface is visible after clicking the WiFi icon (top right corner) and also using ifconfig in the terminal.


Clone this repository in home directory and update script permissions
```
git clone https://github.com/Harvard-REACT/WSR-WifiDriver
chmod +x WSR-WifiDriver/env_setup_1.sh WSR-WifiDriver/env_setup_2.sh WSR-WifiDriver/setup.sh
```

2. Run the first environement setup script
```
./WSR-WifiDriver/env_setup_1.sh <name of intel 5300 network interface> 

e.g. 
./WSR-WifiDriver/env_setup_1.sh wlp59s0
```
This should show the Intel 5300 wifi card as 'device not managed' after clicking the Wifi icon.

3. MAC address setup to enable robot packet identification
Change the MAC address in the iwlwifi/dvm/rx.c on line 44 which is the special_packet variable. (use any text editor)

Change the sub-string 930-935 from 0xff to intended MAC address as source MAC address (obtained for the network interface using ifconfig).
```
vim ~/WSR-WifiDriver/iwlwifi/dvm/rx.c
```

e.g Setting the value to
```
 930     skb->data[16] = 0x0;
 931     skb->data[17] = 0x21;
 932     skb->data[18] = 0x6a;
 933     skb->data[19] = 0x3f;
 934     skb->data[20] = 0x17;
 935     skb->data[21] = 0x5a; 
``` 
enables the TX_Neighbor robot to embed a MAC ID 00:21:6A:3F:17:5A in the packets automatically transmitted. 

Note: Please make the above changes in all robots on which the driver is installed. 

4. Compile the drivers
```
cd ~
cpuCores=`cat /proc/cpuinfo | grep "cpu cores" | uniq | awk '{print $NF}'`
sudo make -j $cpuCores -C /lib/modules/$(uname -r)/build M=~/WSR-WifiDriver/iwlwifi/ modules
```

5. Clone the modified linux-80211n-csitool-supplementary
```
git clone https://github.com/Harvard-REACT/WSR-Toolbox-linux-80211n-csitool-supplementary.git
```

6. Run the second environement setup script
```
./WSR-WifiDriver/env_setup_2.sh
```

7. Build userspace csi data logging tool as per step 4 in [Linux 802.11n CSI Tool installation instructions](http://dhalperi.github.io/linux-80211n-csitool/installation.html) to install the modified firmware
```
cd ~
make -C WSR-Toolbox-linux-80211n-csitool-supplementary/netlink
```

## Verify drivers are working

Load the dirvers and pass the required channel and bandwidth as parameters by running the setup script
```
cd ~
sudo ./WSR-WifiDriver/setup.sh <channel> <bandwidth>
```
e.g
```
sudo ./WSR-WifiDriver/setup.sh 108 HT20
```
To verify that the network interface has been set to monitor mode, the following should be the output when running iwconfig

```
iwconfig

```

Expected output

```
mon0      IEEE 802.11  Mode:Monitor  Frequency:5.54 GHz  Tx-Power=15 dBm   
          Retry short limit:7   RTS thr:off   Fragment thr:off
          Power Management:off
          

wlp1s0    IEEE 802.11  Mode:Monitor  Frequency:5.54 GHz  Tx-Power=15 dBm   
          Retry short limit:7   RTS thr:off   Fragment thr:off
          Power Management:off

```

## Setup of packet injection (Reference [Packet Injection](https://github.com/dhalperi/linux-80211n-csitool-supplementary/tree/master/injection))

1. compile LORCONv1
```
cd lorcon-old
make -j $cpuCores
sudo make install
```

3. Change the source MAC address in random_packet (during packet injection) to the robot's MAC address.

```
vim ~/WSR-Toolbox-linux-80211n-csitool-supplementary/linux-80211n-csitool-supplementary/injection/random_packets.c
```

In file random_packet.c, modify the MAC addres on line 103 with corresponding address that was used in rx.c (Step 3 in 'Modified Driver and Firmware Setup').

4. Compile the packets injection code (make sure that Step 6 of previous section is completed
```
cd ~
make -C WSR-Toolbox-linux-80211n-csitool-supplementary/injection
```

## Collecting CSI data packets
### On the Transmitting robot start packet transmission

1. Load the network interface and set to monitor mode, using a channel (else the following [issue](https://github.com/dhalperi/linux-80211n-csitool-supplementary/issues/132) will be seen
```
cd ~
sudo ./WSR-WifiDriver/setup.sh 108 HT20
```

2. Start packet transmission
```
sudo ./WSR-Toolbox-linux-80211n-csitool-supplementary/injection/random_packets <total_packets to send> <packet_size> 1 <frequency>
```

e.g. To send 10000 packets, each of size 29 with 1000 packets sent every 100 ms

```
sudo ./linux-80211n-csitool-supplementary/injection/random_packets 100000 29 1 1000
```

### On receiving robot
1. Load the network interface (using the same channel) and set to monitor mode
```
cd ~
sudo ./WSR-WifiDriver/setup.sh 108 HT20
```

2. To log CSI data to a file
```
sudo ~/WSR-Toolbox-linux-80211n-csitool-supplementary/netlink/log_to_file csi.dat
```

## Updating MAC IDs in the WSR Toolbox config files
For this step, the [WSR-Toolbox-cpp](https://github.com/Harvard-REACT/WSR-Toolbox-cpp) needs to be installed.

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


## Edimax driver installation
1. Download the official driver for 4.15 kernel
2. unzip and enter the folder
3. run 'sudo make -j4'
4. run 'sudo make install'








