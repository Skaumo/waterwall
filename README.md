waterwall
=========

iptables firewall and traffic shaper framework

What is this?
-------------
I've been hand-writing iptables scripts in .sh files for years. Been fun, indeed!

No plans to try other solutions claiming  to "make iptables easy", though.

iptables are easy once you've learnt them (take a few months to learn, years to forget).
Anything else I have to learn and spend extra time on makes it hard.

I know it is the same for others, and that's why we are here.

So I made this framework to organise a bit better my iptables scripts, using as standard iptables language as possible.

Who is this for?
----------------
Sysadmins, iptables fans, people who'd like to have a more structured approach in their firewall scripts.

Features
--------
The idea is to write fairly well performing firewall scripts, reduce redundancy in rules and tests against packets.

We achieve this first by making a decisional tree that is easy to follow for both the writer and reader.

It`s a framework, so there is a little bit of abstraction, as in any framework. Possibly a bit less than the average, here.


The way we try to achieve the above is by calling the chains with the highest traffic first.


For instance, if your host processes 80% UDP traffic, we create a UDP chain and process that before any SCTP chain.

If your UDP traffic is then broken down into 50% SIP, create a SIP chain and call it first, followed by other less-likely chains.

Planned Features
----------------
* nftables support
* A pre-determined decisional tree is a bit too much of a static configuration, isn't it?
If the project proves popular, a second stage would be a self-balancing feature that checks the actual statistics (iptables -s) and moves the chains across.
* Adding specific filters. There are a few in modules/ folder. It should be easy to add other ones.
* Adding traffic shaping and QoS filters. (have base code, needs converting and reorganising)
* Port knocking chains to help creating hidden services easily (have the code already, just need to port here)


Status
------
Initial, but working.

Warnings
--------
I'm a JavaScript native speaker, and I had considered writing it with Node.js (Ok, ok, I hear you yelling, so I refrained and just used BASH).

So I had to learn BASH tricks like UPVAR, etc to make this work. If you find them awful blame me, or please advise in better solutions.

Usage
-----
git clone ...

cd waterwall

(configure your chains, see below)

sudo waterwall.sh

Configuration
-----
Edit your config/default.sh file and set appropriate values. Comments should explain. If they don't, I've made a poor job :)

Add your own chains into modules/your\_module.sh

How it works
------------
waterwall.sh sets up the root chains for mangle, nat, filter/prerouting, input, output, postrouting, etc.

Each of those are BASH functions which attempt to mimic the actual iptables execution flow. They call other functions for subchains.

Each function sets up the actual chain just as if it was running it.

```
# set up the INPUT chain for the filter table
filter_input() {
	# initialisation
	log ${FUNCNAME}
	module_init ${FUNCNAME} $* || return
	local TABLE=filter
	local CHAIN=INPUT

	# set up sub-chains. The business logic goes here
	filter_input_internet
	filter_input_lan
	filter_input_vpn
	filter_input_wifi
}
```
And the following is a subchain, calling other subchains. The ones with the highest expected traffic are called first, to minimise test conditions

```
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
```

Your filter for the TCP inbound traffic coming from your upstream connection (internet) may look like this:

```
filter_input_internet_tcp() {
	log ${FUNCNAME}
	module_init ${FUNCNAME} $* || return
	local PROTOCOL=tcp

	iptables46 -t $TABLE -A $PARENTCHAIN -p $PROTOCOL -j $CHAIN

	# business logic: call the http chain first, then the voip chain
	http_filter
	voip_filter
	# etc...
}
```

