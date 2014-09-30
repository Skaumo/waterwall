#!/bin/bash

### GENERAL SETUP ###
	setup() {
		log ${FUNCNAME}
		if [ ! -e /sys/class/net/$UNTRUSTED ]; then
			UNTRUSTED=""
		fi

		if [ ! $IF_INTERNET ]; then
			echo "Please set IF_INTERNET network interface.for your internet connection"
			exit 1
		fi

		if [ ! $TRUSTED ]; then
			echo "Please set IF_TRUSTED as your internal network interface."
			exit 1
		fi

		UNTRUSTED_ROUTER_IP4=`ip addr show $UNTRUSTED | grep "inet " | sed -e "s/^ \+inet \+\([^\/]\+\).*/\\1/"`
		TRUSTED_ROUTER_IP4=`ip addr show $TRUSTED | grep "inet " | sed -e "s/^ \+inet \+\([^\/]\+\).*/\\1/"`
		UNTRUSTED_ROUTER_IP6=`ip -6 addr show $UNTRUSTED | grep "inet " | sed -e "s/^ \+inet \+\([^\/]\+\).*/\\1/"`
		TRUSTED_ROUTER_IP6=`ip -6 addr show $TRUSTED | grep "inet " | sed -e "s/^ \+inet \+\([^\/]\+\).*/\\1/"`

		if [[ -e sysctl && `sysctl -n net.ipv4.ip_forward` = 0 ]]; then
			echo "IP forwarding disabled in kernel. Please enable it.";
			sysctl -w net.ipv4.ip_forward
			exit 1;
		fi

		iptables46 -t filter -N i_$TRUSTED 2>$STDERR > /dev/null
		iptables46 -t filter -N i_$IF_INTERNET 2>$STDERR > /dev/null
	}

	reset() {
		mangle off
		nat off
		filter off
	}

### MANGLE ###
	mangle() {
		log ${FUNCNAME}
		local TABLE=mangle
		local PARENTCHAIN=
		mangle_prerouting
		mangle_input
		mangle_forward
		mangle_output
		mangle_postrouting

		module_done $*
	}

	nat() {
		log ${FUNCNAME}
		local TABLE=nat
		local PARENTCHAIN=
		nat_prerouting
		nat_input
		nat_output
		nat_postrouting

		module_done $*
	}

	filter() {
		log ${FUNCNAME}
		local TABLE=filter
		local PARENTCHAIN=

		module_init ${FUNCNAME} $*

		filter_input
		filter_forward
		filter_output

		module_done $*
	}

	mangle_prerouting() {
		log ${FUNCNAME}
	}

	mangle_input() {
		log ${FUNCNAME}
	}

	mangle_forward() {
		log ${FUNCNAME}
	}

	mangle_output() {
		log ${FUNCNAME}
	}

	mangle_postrouting() {
		log ${FUNCNAME}
	}


### NAT ###
	nat_prerouting() {
		log ${FUNCNAME}
		return
	}

	nat_input() {
		log ${FUNCNAME}
		return
	}

	nat_output() {
		log ${FUNCNAME}
		return
	}

	nat_postrouting() {
		log ${FUNCNAME}
		return
	}


### FILTER ###
	filter_input() {
		log ${FUNCNAME}
		module_init ${FUNCNAME} $* || return
		local TABLE=filter
		local CHAIN=INPUT

		filter_input_internet
		filter_input_lan
		filter_input_vpn
		filter_input_wifi
	}

	filter_forward() {
		log ${FUNCNAME}
		return
	}

	filter_output() {
		log ${FUNCNAME}
		return
	}


### DEPENDENCIES ###
	filter_input_internet() {
		log ${FUNCNAME}
		module_init ${FUNCNAME} $* || return
		local INTERFACE=$IF_INTERNET

		iptables46 -t $TABLE -A $PARENTCHAIN -i $INTERFACE -j $CHAIN

		## INCLUDES
		filter_input_internet_icmp
		filter_input_internet_tcp
		filter_input_internet_udp
		filter_input_internet_other
		## END INCLUDES

		iptables46 -t $TABLE -P INPUT DROP
	}

	filter_input_internet_icmp() {
		log ${FUNCNAME}
		module_init ${FUNCNAME} $* || return
		local PROTOCOL=icmp

		iptables46 -t $TABLE -A $PARENTCHAIN -p $PROTOCOL -j $CHAIN

		iptables46 -t $TABLE -A $CHAIN -p $PROTOCOL -j ACCEPT
	}

	filter_input_internet_tcp() {
		log ${FUNCNAME}
		module_init ${FUNCNAME} $* || return
		local PROTOCOL=tcp

		iptables46 -t $TABLE -A $PARENTCHAIN -p $PROTOCOL -j $CHAIN

		http_filter
		voip_filter
	}

	filter_input_internet_udp() {
		log ${FUNCNAME}
		module_init ${FUNCNAME} $* || return
		local PROTOCOL=udp

		iptables46 -t $TABLE -A $PARENTCHAIN -p $PROTOCOL -j $CHAIN

		# iptables46 -t $TABLE -A $CHAIN -p $PROTOCOL --dport 12345 -j ACCEPT
		http_filter
		voip_filter
	}


	filter_input_internet_sctp() {
		log ${FUNCNAME}
		module_init ${FUNCNAME} $* || return
		local PROTOCOL=sctp
		iptables46 -t $TABLE -A $PARENTCHAIN -p $PROTOCOL -j $CHAIN

		iptables46 -t filter -A $CHAIN -p sctp -m multiport --ports 5060,5066,5080 -j voip-filter
	}

	filter_input_internet_other() {
		log ${FUNCNAME}
		module_init ${FUNCNAME} $* || return

		iptables46 -t $TABLE -A $PARENTCHAIN -p  -j $CHAIN

		iptables46 -t $TABLE -A INPUT -p udplite -j ACCEPT
		# tunnels
		iptables46 -t $TABLE -A INPUT -p esp -j ACCEPT
		iptables46 -t $TABLE -A INPUT -p ah -j ACCEPT
		iptables46 -t $TABLE -A INPUT -p l2tp -j ACCEPT
		iptables46 -t $TABLE -A INPUT -p gre -j ACCEPT

		iptables46 -t $TABLE -A INPUT -p sctp -j ACCEPT
		iptables46 -t $TABLE -A INPUT -p rdp -j ACCEPT
		iptables46 -t $TABLE -A INPUT -p dccp -j ACCEPT
		iptables46 -t $TABLE -A INPUT -p rsvp -j ACCEPT
		iptables46 -t $TABLE -A INPUT -p netblt -j ACCEPT
		iptables46 -t $TABLE -A INPUT -p mtp -j ACCEPT

	}

	filter_input_lan() {
		log ${FUNCNAME}
		module_init ${FUNCNAME} $* || return

		iptables46 -t $TABLE -A $PARENTCHAIN -i $LAN -j $CHAIN

		filter_input_lan_tcp
		filter_input_lan_icmp
		filter_input_lan_udp
		filter_input_lan_other
	}

	filter_input_lan_tcp() {
		log ${FUNCNAME}
		module_init ${FUNCNAME} $* || return
		local PROTOCOL=tcp

		iptables46 -t $TABLE -A $PARENTCHAIN -p $PROTOCOL -j $CHAIN

		# iptables46 -t $TABLE -A $CHAIN -p $PROTOCOL --dport http -j ACCEPT
	}

	filter_input_lan_icmp() {
		log ${FUNCNAME}
		module_init ${FUNCNAME} $* || return
		local PROTOCOL=icmp

		iptables46 -t $TABLE -A $PARENTCHAIN -p $PROTOCOL -j $CHAIN

		# iptables46 -t $TABLE -A $CHAIN -p $PROTOCOL --dport http -j ACCEPT
	}


	filter_input_lan_udp() {
		log ${FUNCNAME}
		module_init ${FUNCNAME} $* || return
		local PROTOCOL=udp

		iptables46 -t $TABLE -A $PARENTCHAIN -p $PROTOCOL -j $CHAIN

		iptables46 -t $TABLE -A $CHAIN -p udp --dport sip -j ACCEPT
	}


# Assign variable one scope above the caller.
# Usage: local "$1" && upvar $1 value [value ...]
# Param: $1  Variable name to assign value to
# Param: $*  Value(s) to assign.  If multiple values, an array is
#            assigned, otherwise a single value is assigned.
# NOTE: For assigning multiple variables, use 'upvars'.  Do NOT
#       use multiple 'upvar' calls, since one 'upvar' call might
#       reassign a variable to be used by another 'upvar' call.
# See: http://fvue.nl/wiki/Bash:_Passing_variables_by_reference
upvar() {
	if [ ! "$2" ]; then
		return 0
	fi
    if unset -v "$2"; then           # Unset & validate varname
        if (( $# == 2 )); then
            eval $1=\"\$2\"          # Return single value
        else
            eval $1=\(\"\${@:2}\"\)  # Return array
         fi
    fi
}

pushvar() {
	echo "pushvar"
}

popvar() {
	echo "pushvar"
}

### MAIN ###
main() {
	echo "Waterwall 0.1"
	# echo "Loading modules"
	for j in config helpers modules; do
		for i in ./$j/*.sh; do
			# echo $i
			source $i
		done
	done

	setup
	reset

	mangle
	nat
	filter
}


main
