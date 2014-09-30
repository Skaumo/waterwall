#!/bin/bash

### VoIP filter chain
# Detect and mitigate SIP attacks

voip_filter() {
	log ${FUNCNAME}
	module_init ${FUNCNAME} $* || return

	iptables46 -t $TABLE -A $PARENTCHAIN -p $PROTOCOL -m multiport --ports 5060,5066,5080 -j $CHAIN

	iptables46 -A $CHAIN -m string --string "User-Agent: VaxSIPUserAgent" --algo bm --to 65535 -j DROP
	iptables46 -A $CHAIN -m string --string "User-Agent: friendly-scanner" --algo bm --to 65535 -j REJECT --reject-with icmp-port-unreachable
	iptables46 -A $CHAIN -m string --string "REGISTER sip:" --algo bm -m recent --set --name SIP_REGISTER --rsource
	iptables46 -A $CHAIN -m string --string "REGISTER sip:" --algo bm -m recent --update --seconds 60 --hitcount 12 --rttl --name SIP_REGISTER --rsource -j DROP
	iptables46 -A $CHAIN -m string --string "INVITE sip:" --algo bm -m recent --set --name SIP_INVITE --rsource
	iptables46 -A $CHAIN -m string --string "INVITE sip:" --algo bm -m recent --update --seconds 60 --hitcount 12 --rttl --name SIP_INVITE --rsource -j DROP
	iptables46 -A $CHAIN -m hashlimit --hashlimit 6/sec --hashlimit-mode srcip,dstport --hashlimit-name tunnel_limit -j ACCEPT

	if [ $LOGGING ]; then
	iptables46 -A $CHAIN -j LOG --log-prefix "VoIP flood: "
	fi

	iptables46 -A $CHAIN -j DROP
}

