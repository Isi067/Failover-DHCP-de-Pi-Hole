#!/bin/bash

# IP del Pi-hole primario
PRIMARY_PIHOLE="192.168.1.249"

# Ruta del archivo dhcp.leases en el sistema remoto y local
LEASES_FILE="/etc/pihole/dhcp.leases"
CONFIG_FILE="/etc/pihole/pihole.toml"

# Ruta para respaldo local temporal (opcional)
LOCAL_BACKUP_DIR="/root/pihole_backup"
mkdir -p $LOCAL_BACKUP_DIR

# Eliminar antigua copia (si existe)
rm "$LOCAL_BACKUP_DIR/dhcp.leases" 2>/dev/null && echo "[+] - Backup anterior de log ip local eliminado"
rm "$LOCAL_BACKUP_DIR/pihole.toml" 2>/dev/null && echo "[+] - Backup anterior de config local eliminado"

# Copiar el archivo desde el Pi-hole primario al directorio temporal local
rsync -avz "$PRIMARY_PIHOLE:$LEASES_FILE" "$LOCAL_BACKUP_DIR/" && echo "[+] - Copia de seridor logIP local hecha"
rsync -avz "$PRIMARY_PIHOLE:$CONFIG_FILE" "$LOCAL_BACKUP_DIR/" && echo "[+] - Copia de seridor config local hecha"

# Copiar el archivo al lugar correcto en el sistema local
rsync -avz "$LOCAL_BACKUP_DIR/dhcp.leases" "$LEASES_FILE" && echo "[+] - Copia logIP movida a la config"
rsync -avz "$LOCAL_BACKUP_DIR/pihole.toml" "$CONFIG_FILE" && echo "[+] - Copia config movida a la config"

# Reiniciar DNS de Pi-hole para aplicar cambios (aunque este archivo usualmente no requiere reinicio)
service pihole-FTL restart && echo "[+] - Servicio pihole reiniciado"
