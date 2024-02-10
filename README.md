# WiFi Driver and Firmware for Wireless channel data (CSI) collection

This is a modified verison and supplementary code released as part [Linux 802.11n CSI Tool](http://dhalperi.github.io/linux-80211n-csitool/) 

### Ubuntu version tested
- [x] Ubuntu 16.04 
- [x] Ubuntu 18.04.1 (kernal 4.15 only)

## Hardware Requirements
The driver requires Ubuntu kernal 4.15 and SBC which has a mpcie slot to connect the Intel 5300 WiFi card. Currently tested on the following platforms -

- [x] UP Squared Board (OS installation steps [here](https://github.com/up-board/up-community/wiki/Ubuntu_16.04)). Check Specs [here](https://up-shop.org/up-squared-series.html)
- [x] Intel Apollo Lake N4200 (Same OS installation steps as above). Check specs [here](https://www.onlogic.com/epm163/)
- [x] Intel NUC8i3BEH (Generic Ubuntu 16.04 installation). Check base specs [here](https://www.intel.com/content/www/us/en/products/sku/126150/intel-nuc-kit-nuc8i3beh/specifications.html)

## Modified Driver and Firmware Setup Steps

1. Prerequisites

Connect to the board directly (using keyboard/mouse) and make sure that it is plugged in to internet via an ethernet cable. 

Before boot up, disable SecureBoot in BIOS (applicable to Intel NUC).

Reference : [Linux 802.11n CSI Tool installation instructions](http://dhalperi.github.io/linux-80211n-csitool/installation.html)

Make sure that the Intel 5300 WiFi card's wifi interface is visible after clicking the WiFi icon (top right corner) and also using ifconfig in the terminal.


Clone this repository in home directory and update script permissions
```
sudo apt update
git clone https://github.com/Harvard-REACT/WSR-WifiDriver
chmod +x WSR-WifiDriver/*.sh
```

2. Run the first environement setup script
```
./WSR-WifiDriver/env_setup_1.sh 
```
This should show the Intel 5300 wifi card as 'device not managed' after clicking the Wifi icon.


3. Run the second environement setup script
```
./WSR-WifiDriver/env_setup_2.sh
```


## Verify drivers are working

Load the dirvers and pass the required channel and bandwidth as parameters by running the setup script
```
cd ~
sudo ./WSR-WifiDriver/setup.sh <packet-length> <channel> <bandwidth>
```
e.g
```
sudo ./WSR-WifiDriver/setup.sh 57 108 HT20
```

When the drivers are loaded on the transmitting robot, it uses the packet-length as an identifier to decide whether to send [backward-packets](https://github.com/Harvard-REACT/WSR-Toolbox/wiki/Terminology#phase-correction-using-forward-backward-packets) or not. The packet-length value starts from 57 and is updated in increments of 2 i.e 57, 59, 61 etc. Each robot in the system should have a unique packet-length when using the [forward-backward channel method for cancelling CFO](https://github.com/Harvard-REACT/WSR-Toolbox/wiki/Terminology#phase-correction-using-forward-backward-packets).

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


## Collecting CSI data packets
Before continuing with the next steps, ensure that the driver has been loaded on all the robots (signal receivers and transmitters) are using the same WiFi channel.

### On TX robot (robot in the neighborhood that will transmit backward packets)
1. Load the network interface (using the same channel) and set to monitor mode
```
cd ~
sudo ./WSR-WifiDriver/setup.sh 57 108 HT20
```

2. Log CSI data for the packets broadcasted by RX to a file
```
sudo ~/WSR-Toolbox-linux-80211n-csitool-supplementary/netlink/log_to_file csi_tx.dat
```

### On the RX robot (that need to obtain Angle-of-Arrival to its neighbors) start packet broadcasting

1. Load the network interface and set to monitor mode, using a channel (else the following [issue](https://github.com/dhalperi/linux-80211n-csitool-supplementary/issues/132) will be seen
```
cd ~
sudo ./WSR-WifiDriver/setup.sh 59 108 HT20
```
Note that the packet length (e.g. 59) is checked by the driver when only sending the backward packets. Ensure that the packet length on each robot is unique. 

2. To log CSI data for the backward packets that will be sent by TX 
```
sudo ~/WSR-Toolbox-linux-80211n-csitool-supplementary/netlink/log_to_file csi_rx.dat
```

3. Start packet broadcasting.
```
sudo ./WSR-Toolbox-linux-80211n-csitool-supplementary/injection/random_packets <total_packets to send> <packet_size_of_TX> 1 <frequency>
```
If there are multiple neighboring robots, the packets of varying lengths (corresponding to different robots) are iteratively broadcasted. To increase the number of robots, please update the code in [random_packets.c](https://github.com/Harvard-REACT/WSR-Toolbox-linux-80211n-csitool-supplementary/blob/main/injection/random_packets.c)  accordingly.

e.g. To send 10000 packets, each of size 57, every 1 ms

```
sudo ./WSR-Toolbox-linux-80211n-csitool-supplementary/injection/random_packets 100000 57 1 1000
```

## Updating MAC IDs in the WSR Toolbox config files
For this step, the [WSR-Toolbox-cpp](https://github.com/Harvard-REACT/WSR-Toolbox-cpp) needs to be installed.
Note that you the previous steps assume your csi files are generated in the home directory. Edit the config_3D_SAR.json file in WSR-Toolbox-cpp config sub-folder.

1.For the csi data of RX robot update the input_RX_channel_csi_fn:
```
    "input_RX_channel_csi_fn":{
        "desc":"Reverse channel csi File stored on the RX robot which is performing 3D SAR",
        "value":{           
            "mac_id":"00:21:6A:53:89:D2",
            "csi_fn":"csi_rx.dat"
        }
    },
``` 

for any TX robot, use the field input_TX_channel_csi_fn. e.g
```
"input_TX_channel_csi_fn":{
        "desc":"Forward channel csi File for each of the neighboring TX robots",
        "value":{
            "tx_0":{
                "mac_id":"00:16:EA:12:34:56",
                "csi_fn":"csi_tx"
            },
        }
```

Follow these steps for [testing CSI data](https://github.com/Harvard-REACT/WSR-Toolbox-cpp#test-sample-csi-data-files) and use this script for [visualizing the signal phase output](https://github.com/Harvard-REACT/WSR-Toolbox-cpp#visualization).









