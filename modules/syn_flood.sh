#!/bin/bash

### SYN flood chain
# Detect and mitigate syn flood attacks

syn_flood() {
	log ${FUNCNAME}
	module_init ${FUNCNAME} $* || return

	iptables46 -A $CHAIN -m limit --limit 10/second --limit-burst 20 -j RETURN

	if [ $LOGGING ]; then
	iptables46 -A $CHAIN -j LOG --log-prefix "SYN flood: "
	fi

	iptables46 -A $CHAIN -j DROP
}

