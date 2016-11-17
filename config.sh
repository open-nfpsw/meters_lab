#!/bin/bash
modprobe 8021q

ip netns del nsvf0
ip netns del nsvf1

ip netns add nsvf0
ip netns add nsvf1

vconfig add vf0_0 100 
vconfig add vf0_0 101
vconfig add vf0_0 102
vconfig add vf0_0 103
vconfig add vf0_1 100
vconfig add vf0_1 101
vconfig add vf0_1 102
vconfig add vf0_1 103

ethtool -K vf0_0 rxvlan off
ethtool -K vf0_0 txvlan off
ethtool -K vf0_1 rxvlan off
ethtool -K vf0_1 txvlan off

ip link set vf0_0 netns nsvf0
ip link set vf0_1 netns nsvf1

ip netns exec nsvf0 ifconfig vf0_0 hw ether 00:15:4d:00:00:00
ip netns exec nsvf0 ifconfig vf0_0 mtu 1500
ip netns exec nsvf1 ifconfig vf0_1 hw ether 00:15:4d:00:00:01
ip netns exec nsvf1 ifconfig vf0_1 mtu 1500
ip netns exec nsvf0 ethtool -K vf0_0 rx off
ip netns exec nsvf0 ethtool -K vf0_0 tx off
ip netns exec nsvf1 ethtool -K vf0_1 rx off
ip netns exec nsvf1 ethtool -K vf0_1 tx off

ip link set vf0_0.100 netns nsvf0
ip link set vf0_0.101 netns nsvf0
ip link set vf0_0.102 netns nsvf0
ip link set vf0_0.103 netns nsvf0
ip link set vf0_1.100 netns nsvf1
ip link set vf0_1.101 netns nsvf1
ip link set vf0_1.102 netns nsvf1
ip link set vf0_1.103 netns nsvf1

ip netns exec nsvf0 ifconfig vf0_0 10.1.1.10/24 up
ip netns exec nsvf1 ifconfig vf0_1 10.1.1.11/24 up

ip netns exec nsvf0 ifconfig vf0_0.100 1.1.100.1/24 up
ip netns exec nsvf0 ifconfig vf0_0.101 1.1.101.1/24 up
ip netns exec nsvf0 ifconfig vf0_0.102 1.1.102.1/24 up
ip netns exec nsvf0 ifconfig vf0_0.103 1.1.103.1/24 up
ip netns exec nsvf1 ifconfig vf0_1.100 1.1.100.2/24 up
ip netns exec nsvf1 ifconfig vf0_1.101 1.1.101.2/24 up
ip netns exec nsvf1 ifconfig vf0_1.102 1.1.102.2/24 up
ip netns exec nsvf1 ifconfig vf0_1.103 1.1.103.2/24 up
