#!/bin/bash

LOGGING=1
VERBOSE=0

if (( $VERBOSE == 0 )); then
	STDERR=/dev/null
else
	STDERR=/dev/stdout
fi

IF_INTERNET=ppp0
#IMQ=
STOP=$3

# Trusted (internal) network interface
TRUSTED=enp3s0

# Prefix for VPN connections
VPN="tun+"

# Untrusted (guest?) network interface
UNTRUSTED=null
BACKUP=

# Do SSH through port knocking on the following ports
SSH_STEALTH=https

# Do OPENVPN through port knocking on the following ports
OPENVPN_STEALTH_TCP=https
OPENVPN_STEALTH_UDP=domain

# Force TTL to a specific value
# TTLUP=0x80

# Pick current nameservers
# DNS1=`grep nameserver /etc/resolv.conf | tail -n 2 | head -n 1 | cut -c 12-`
# DNS2=`grep nameserver /etc/resolv.conf | tail -n 1 | cut -c 12-`

# SMTP1=
# SMTP2=

# Alternative ports for known services
SSH_ALT=12222

OPENVPN_TCP=12349
OPENVPN_UDP=12349


