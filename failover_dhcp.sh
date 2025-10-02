#!/bin/bash
 
IP="" #Pon la IP del Pi-hole primario aquí
 
# Comprueba si el Pi-hole principal está en línea
if ping -c 3 $IP &> /dev/null; then
     echo "[+] - (date) - El Pi‑hole principal está encendido."
     
    # Comprueba si el Pi-hole principal está en línea
    if pihole-FTL dhcp-discover | grep -q "Pi-hole DHCP server: active"; then
        echo "[+] - $(date) - Desactivando DHCP en el Raspberry Pi (el principal está encendido)."
        sed -i '/^\[dhcp\]/, /^\[/{ 
  	    s/^\(\s*active\s*=\s*\)true\(.*\)$/\1false\2/
	}' /etc/pihole/pihole.toml

    fi
else
    echo "[+] - $(date) - El Pi‑hole principal está APAGADO."
     
    # Verifique si DHCP se está ejecutando en el Pi; si no es así, habilítelo
    if ! pihole-FTL dhcp-discover | grep -q "Pi-hole DHCP server: active"; then
    echo "[+] - $(date) - Activando DHCP en el Raspberry Pi (el principal está apagado)."
        sed -i '/^\[dhcp\]/, /^\[/{ 
  	    s/^\(\s*active\s*=\s*\)false\(.*\)$/\1true\2/
	}' /etc/pihole/pihole.toml

    fi
fi
