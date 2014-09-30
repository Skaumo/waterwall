#!/bin/bash

# Reset everything to a known state (cleared)
reset() {
	echo "Reset"
	#iptables -D INPUT -i $IF_INTERNET -p tcp --syn -j syn-flood
	#iptables -F syn-flood
	#iptables -X syn-flood
	iptables46 -t mangle -F PREROUTING 2>$STDERR > /dev/null
	iptables46 -t mangle -P PREROUTING ACCEPT 2>$STDERR > /dev/null
	iptables46 -t mangle -F INPUT 2>$STDERR > /dev/null
	iptables46 -t mangle -P INPUT ACCEPT 2>$STDERR > /dev/null
	iptables46 -t mangle -F FORWARD 2>$STDERR > /dev/null
	iptables46 -t mangle -P FORWARD ACCEPT 2>$STDERR > /dev/null
	iptables46 -t mangle -F OUTPUT 2>$STDERR > /dev/null
	iptables46 -t mangle -P OUTPUT ACCEPT 2>$STDERR > /dev/null
	iptables46 -t mangle -F POSTROUTING 2>$STDERR > /dev/null
	iptables46 -t mangle -P POSTROUTING ACCEPT 2>$STDERR > /dev/null

	iptables46 -t nat -F PREROUTING 2>$STDERR > /dev/null
	iptables46 -t nat -P PREROUTING ACCEPT 2>$STDERR > /dev/null
	iptables46 -t nat -F FORWARD 2>$STDERR > /dev/null
	iptables46 -t nat -P FORWARD ACCEPT 2>$STDERR > /dev/null
	iptables46 -t nat -F POSTROUTING 2>$STDERR > /dev/null
	iptables46 -t nat -P POSTROUTING ACCEPT 2>$STDERR > /dev/null

	iptables46 -t filter -F INPUT 2>$STDERR > /dev/null
	iptables46 -t filter -P INPUT ACCEPT 2>$STDERR > /dev/null
	iptables46 -t filter -F FORWARD 2>$STDERR > /dev/null
	iptables46 -t filter -P FORWARD ACCEPT 2>$STDERR > /dev/null
	iptables46 -t filter -F OUTPUT 2>$STDERR > /dev/null
	iptables46 -t filter -P OUTPUT ACCEPT 2>$STDERR > /dev/null

	route delete -net 10.0.0.0/8     dev $IF_INTERNET reject 2>$STDERR
	route delete -net 172.16.0.0/12  dev $IF_INTERNET reject 2>$STDERR
	route delete -net 192.168.0.0/16 dev $IF_INTERNET reject 2>$STDERR


	for i in `iptables -L | grep Chain | cut -d " " -f 2`; do
		iptables46 -F $i
		iptables46 -X $i
	done

	iptables46 -t filter -F i_$TRUSTED 2>$STDERR > /dev/null
	iptables46 -t filter -F i_$IF_INTERNET 2>$STDERR > /dev/null

	iptables46 -F syn-flood 2>$STDERR > /dev/null
	iptables46 -X syn-flood 2>$STDERR > /dev/null
	iptables46 -F voip-filter 2>$STDERR > /dev/null
	iptables46 -X voip-filter 2>$STDERR > /dev/null
	iptables46 -t filter -X i_$TRUSTED 2>$STDERR > /dev/null
	iptables46 -t filter -X i_$IF_INTERNET 2>$STDERR > /dev/null
exit
}
