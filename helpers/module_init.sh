#!/bin/bash

# MODULE INIT
# setup or tear down chains
# USAGE:
# module_init [REMOVE]
log() {
	echo "> $1"
}

module_init() {
	# set table name the same as function name
#echo "PARENTCHAIN was $PARENTCHAIN"
	upvar PARENTCHAIN && upvar PARENTCHAIN $CHAIN
#echo "PARENTCHAIN===$PARENTCHAIN"
	upvar CHAIN && upvar CHAIN $1

	if [ "$1" == "off" ]; then
		iptables46 -F $CHAIN
		iptables46 -X $CHAIN
	else
		iptables46 -N $CHAIN || return 1
	fi
	return 0
}

