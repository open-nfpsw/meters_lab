Meters example

This lab shows how to use meter in P4 by:
	- match vlan traffic with meters
	- update meters dynamically


How to get started:

	1. create a new P4 project 
	2. import meter_lab.p4 (source code)
	3. import meter_lab.p4cfg (configuration file)
	4. download config.sh to your traffic generation server 
	5. follow steps below to configure and test meters


From traffic generation server:

# need to sudo 
su

# to setup config
./config.sh

# configuration:
# namespace nsvf0 and p4vm1
#	interface	ip addr
#	vf0_0 		10.1.10.10/24
#	vf0_0.100	1.1.100.1/24	
#	vf0_0.101	1.1.101.1/24	
#	vf0_0.102	1.1.102.1/24	
#	vf0_0.103	1.1.103.1/24	
#
# namespace nsvf1 and p4vm2
#	interface	ip addr
#	vf0_1 		10.1.10.11/24
#	vf0_1.100	1.1.100.2/24	
#	vf0_1.101	1.1.101.2/24	
#	vf0_1.102	1.1.102.2/24	
#	vf0_1.103	1.1.103.2/24	
#

# vlan100 and 101 are connected to meters indx 0 & 1

# vlan100 from vf0 -> vf1
ip netns exec nsvf0 ping 1.1.100.2

# current meter for vlan101 (index 1)  is configured incorrectly (too low)
# so ping does not return.
# vlan101 from vf0 -> vf1 -- no reply
ip netns exec nsvf0 ping 1.1.101.2

# vlan102 from vf0 -> vf1 - no meter
ip netns exec nsvf0 ping 1.1.102.2

# to change meter from linux RTE server
# to modify meter idx 1 to 128kbpps  and 200k burst
rtecli meters -m 0 -c 1:0=128:200 set
# may have to wait a few minutes for interval to clear & new meter paramenters to take effect
# get meters
rtecli meters -m 0 get

# to dump all meters
rtecli meters -m 0 get
# more info
rtecli meters --help
rtecli --help


# to change meter, go to Windows VM, open Windows PowerShell
cd C:/NFP_SDK_6.0.1/p4/bin/
# to dump all meters  (-r RTE_HOST  use ip address of hardware)
./rtecli.exe -r 10.8.0.202 meters -m 0 get
# to modify meter idx 1 to 128kbpps  and 200k burst
./rtecli.exe -r 10.8.0.202 meters -m 0 -c 1:0=128:200 set
# more info
./rtecli.exe -r 10.8.0.202 meters --help
./rtecli.exe --help


# To start VMs
./startvms.sh

# please use the VM ipaddresses from the red card
# uid=root password=netronome
# vf0_0 is assigned as eth1 in p4vm1
# vf0_1 is assigned as eth1 in p4vm2
#  

# please shutdown VMs when done
virsh shutdown p4vm1
virsh shutdown p4vm2

# additional commands
virsh list

