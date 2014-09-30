module_done() {
	# set table name the same as function name
	upvar CHAIN && upvar CHAIN $1

	if [ "$1" == "off" ]; then
		iptables46 -F $CHAIN
		iptables46 -X $CHAIN
	fi
}

