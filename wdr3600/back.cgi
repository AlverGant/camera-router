#!/bin/ash
IFS='=&'          
set -- $QUERY_STRING


#/usr/sbin/tc qdisc del dev eth0.1 root netem delay 100ms
#/usr/sbin/tc qdisc add dev eth0.1 root handle 1:0 netem delay $6ms loss $4%
#/usr/sbin/tc qdisc add dev eth0.1 parent 1:1 handle 10: tbf rate $2kbit buffer 1600 limit 3000

echo "Content-type: text/html"
echo ""
echo "<html><head><title>Demo</title>"
echo "</head><body>"
echo "<script type="text/javascript"><!--"
echo "setTimeout('Redirect()',0);"
echo " function Redirect(){  location.href = '../index.html?limit=$2&loss=$4&delay=$6';}"
