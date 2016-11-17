/*
 * Copyright (C) 2016, Netronome Systems, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 *
 */


#define ETHERTYPE_VLAN 0x8100
#define ETHERTYPE_IPV4 0x0800

/*
 * Header declarations
 */

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type vlan_t {
    fields {
        pcp : 3;
        cfi : 1;
        vid : 12;
        etherType : 16;
    }
}

header_type ipv4_t {
    fields {
        version : 4;
        ihl : 4;
        diffserv : 8;
        totalLen : 16;
        identification : 16;
        flags : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr: 32;
    }
}


header_type extended_meta_t {
    fields {
        vf_meter_color : 2;
    }
}


header ethernet_t ethernet;
header vlan_t vlan;
header ipv4_t ipv4;

metadata extended_meta_t extended_meta;

/*
 * Parser
 */

parser start {
    set_metadata(extended_meta.vf_meter_color, 0); /* precolour green */
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        ETHERTYPE_VLAN : parse_vlan;
        ETHERTYPE_IPV4 : parse_ipv4;
        default: ingress;
    }
}

parser parse_vlan {
    extract(vlan);
    return select(latest.etherType) {
        ETHERTYPE_IPV4 : parse_ipv4;
        default: ingress;
    }
}

parser parse_ipv4 {
    extract(ipv4);
    return select(latest.protocol) {
        default: ingress;
    }
}

/*
 * Ingress
 */

/* attach a pragma that will automatically drop the packet
 * when the meter returns red
 */
@pragma netro meter_drop_red
meter vf_meters {
    type: bytes;			/* bytes or packets */
    result: extended_meta.vf_meter_color;
    instance_count: 4;
}

action do_throttle(meter_idx) {
    execute_meter(vf_meters, meter_idx, extended_meta.vf_meter_color);
}

action do_forward(espec) {
	modify_field(standard_metadata.egress_spec, espec); 
}

action drop_act() {
	drop();
}

table forward {
    reads {
        standard_metadata.ingress_port : exact;
    }
    actions {
		do_forward;
		drop_act;
    }
}

table forward_vlan {
    reads {
        vlan.vid: exact;
    }
    actions {
		do_throttle;
    }
}

control ingress {
    if (valid(vlan)) {
       apply(forward_vlan);		/* do throttle */
	}
    apply(forward);				/* destination port */
}

/*
 * Egress
 */

action translate_vlan(new_vid, new_espec) {
    modify_field(vlan.vid, new_vid);
	modify_field(standard_metadata.egress_spec, new_espec); 
}

table manipulate_vlan {
    reads {
        vlan.vid: exact;
        standard_metadata.ingress_port : exact;
    }
    actions {
		translate_vlan;
    }
}

control egress {
    if (valid(vlan)) {
		apply(manipulate_vlan);
    }
}
