iptables46() {
	echo "ip[46]tables $*"

	iptables $*
	ip6tables $*
}
