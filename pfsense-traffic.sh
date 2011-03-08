#!/bin/bash
#
# pfsense-traffic.sh v1.0, 2010 by Patrick Stadler <patrick.stadler@gmail.com>
# 
# Get traffic data for an interface from pfSense using its webGUI 
#
# Usage:	./pfsense-traffic.sh <url-to-webgui> <interface> [<interval seconds>]
# Example:	./pfsense-traffic.sh https://192.168.1.1:8080 wan 5
#

host=$1
interface=$2
interval=$3

IFS=\|
if [ -z $host ]; then echo 'No host given' && exit; fi
if [ -z $interface ]; then echo 'No interface given' && exit; fi
if [ -z $interval ]; then interval=3; fi

# get first sample	
start=$(wget -O - -q $host/ifstats.php?if=$interface --no-check-certificate)
for value in $start; do
	result[${#result[@]}]=$value
done

sleep $interval

# get second sample
end=$(wget -O - -q $host/ifstats.php?if=$interface --no-check-certificate)
for value in $end; do
	result2[${#result2[@]}]=$value
done

# calc real diff time
diff_time=$(echo ${result2[0]} - ${result[0]} | bc)

# calc in and out and finally print it
in=$(echo "(${result2[1]} - ${result[1]}) / $diff_time" | bc)
if [ "$in" == "" ]; then
	in="-     "
elif [ $in -lt "125000" ]; then
	in="$(echo "$in / 125"| bc) Kbps"
elif [ $in -lt "125000000" ]; then
	in="$(echo "$in / 125000"| bc) Mbps"
else
	in="$(echo "$in / 125000000"| bc) Gbps"
fi

out=$(echo "(${result2[2]} - ${result[2]}) / $diff_time" | bc)
if [ "$out" == "" ]; then
	out="-     "
elif [ $out -lt "125000" ]; then
	out="$(echo "$out / 125"| bc) Kbps"
elif [ $out -lt "125000000" ]; then
	out="$(echo "$out / 125000"| bc) Mbps"
else
	out="$(echo "$out / 125000000"| bc) Gbps"
fi

printf "[pfSense.$interface] %8s / %8s (in/out)\n" $in $out
