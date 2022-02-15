#!/usr/bin/sudo /bin/bash
export intfac=$(ls /sys/class/net/ | grep wlp)
sudo modprobe -r iwldvm 
sudo modprobe -r iwlwifi mac80211 cfg80211
echo "Loading iwlwifi driver with csi data collection enabled"
echo "Configuring interface ${intfac}"
sudo modprobe iwlwifi connector_log=0x1
while [ $? -ne 0 ]
do
        modprobe iwlwifi connector_log=0x1
done
echo "Driver loaded successfully"


echo "Setting up monitor mode"
sudo iwconfig $intfac mode monitor 2>/dev/null 1>/dev/null
while [ $? -ne 0 ]
do
	iwconfig $intfac mode monitor 2>/dev/null 1>/dev/null
done
echo "Monitor mode configured"

echo "sudo iw $intfac interface add mon0 type monitor"
sudo iw $intfac interface add mon0 type monitor
echo "Mon0 Interface added"
sudo iwconfig $intfac mode monitor
while [ $? -ne 0 ]
do
	iwconfig $intfac mode monitor 2>/dev/null 1>/dev/null
done
sleep 0.2
sudo ifconfig $intfac up 
sleep 0.5
sudo ifconfig mon0 up

echo "Monitor mode interface is up"

if [ "$#" -ne 2 ]; then
        echo "Going to use default settings: channel = 104, bandwidth = HT20"
        chn=104
        bw=HT20
else
	echo "Manually set channel = $chn, bandwidth $bw"
        chn=$1
        bw=$2
fi

sudo iw $intfac set channel $chn $bw
sudo iw mon0 set channel $chn $bw

sudo bash -c "echo 0x4100 | sudo tee `sudo find /sys -name monitor_tx_rate`"
((iwconfig $intfac|grep "Frequency") 1> /dev/null&&(echo "Setup Successful"))||(echo "Driver Load Error Please Reboot System")
