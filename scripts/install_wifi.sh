#!/bin/bash
#
# when you use in your env,
# 1. modify MY_SSID
# 2. modify MY_PASS
# 3. remove comment-out in WIFI_PSK
#
MY_SSID=elecom5g-47735b
MY_PASS=""
#echo "" > wifi_psk.txt
WIFI_PSK=`cat wifi_psk.txt`
#WIFI_PSK=`wpa_passphrase $MY_SSID $MY_PASS | grep -E "^\s+psk=" | sed -E "s/^\s+psk=//"`
#echo $WIFI_PSK > wifi_psk.txt
echo "my \$WiFI_PSK = $WIFI_PSK"
echo "check your wifi"
nmcli d wifi list
echo ""
echo "modify your wifi setting to SSID=$MY_SSID"
sudo nmcli d wifi connect $MY_SSID password $WIFI_PSK
echo ""
echo "review your wifi setting"
nmcli d wifi list


