#!/bin/bash
 
# Primary Pi-hole VM IP address
PRIMARY_PIHOLE_IP="192.168.1.249"
 
# Check if the primary Pi-hole is online
if ping -c 3 $PRIMARY_PIHOLE_IP &> /dev/null; then
    echo "$(date) - Primary Pi-hole is up."
     
    # Check if DHCP is running on the Pi - if so, disable it
    if pihole-FTL dhcp-discover | grep -q "Pi-hole DHCP server: active"; then
        echo "$(date) - Disabling DHCP on the Raspberry Pi (primary is up)."
        sed -i '/^\[dhcp\]/, /^\[/{ 
  	    s/^\(\s*active\s*=\s*\)true\(.*\)$/\1false\2/
	}' /etc/pihole/pihole.toml

    fi
else
    echo "$(date) - Primary Pi-hole is DOWN."
     
    # Check if DHCP is running on the Pi - if not, enable it
    if ! pihole-FTL dhcp-discover | grep -q "Pi-hole DHCP server: active"; then
        echo "$(date) - Enabling DHCP on the Raspberry Pi (primary is down)."
        sed -i '/^\[dhcp\]/, /^\[/{ 
  	    s/^\(\s*active\s*=\s*\)false\(.*\)$/\1true\2/
	}' /etc/pihole/pihole.toml

    fi
fi
