#!/usr/bin/sudo /bin/bash
sudo modprobe -r iwldvm cn
modprobe -r iwlwifi mac80211 cfg80211

echo "Loading iwlwifi driver with csi data collection enabled"
modprobe iwlwifi connector_log=0x1
while [ $? -ne 0 ]
do
        modprobe iwlwifi connector_log=0x1
done
echo "Driver loaded successfully"


echo "Setting up monitor mode"
iwconfig wlp1s0 mode monitor 2>/dev/null 1>/dev/null
while [ $? -ne 0 ]
do
	iwconfig wlp1s0 mode monitor 2>/dev/null 1>/dev/null
done
echo "Monitor mode configured"

iw wlp1s0 interface add mon0 type monitor

ifconfig wlp1s0 up
ifconfig mon0 up

echo "Monitor mode interface is up"

if [ "$#" -ne 2 ]; then
        echo "Going to use default settings: channel = 104, bandwidth = HT20"
        chn=104
        bw=HT20
else
        chn=$1
        bw=$2
fi

iw wlp1s0 set channel $chn $bw
iw mon0 set channel $chn $bw

sudo bash -c "echo 0x4100 | sudo tee `sudo find /sys -name monitor_tx_rate`"
((iwconfig wlp1s0|grep "Frequency") 1> /dev/null&&(echo "Setup Successful"))||(echo "Driver Load Error Please Reboot System")
