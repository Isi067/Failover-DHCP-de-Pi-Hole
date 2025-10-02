## 📖 Descripción

Pi‑Hole es un bloqueador de anuncios y rastreadores a nivel de red. Cuando lo instalas en una red doméstica o de oficina, normalmente es el único servidor DNS y DHCP. Si el dispositivo que ejecuta Pi‑Hole se apaga o necesita mantenimiento, la red pierde acceso a Internet.

Este proyecto implementa un **failover DHCP** para Pi‑Hole.

- **Primario**: VM de Proxmox (o cualquier servidor Debian/Ubuntu) que actúa como servidor DNS/DHCP principal.
- **Secundario**: Raspberry Pi (o cualquier Raspberry Pi 3/4) que se activa automáticamente cuando el primario falla.

El primer script verifica que el servicio DHCP de el servidor primario este funcionando, si no funciona activa su DCHP y el segundo script sincroniza el archivo de leases y la configuración del primario para garantizar que la transición sea lo más suave posible.

---

## ⚙️ Requisitos

| Requisito         | Versión recomendada                      |
| ----------------- | ---------------------------------------- |
| Sistema operativo | Debian 10/11 o Ubuntu 20.04/22.04        |
| Pi‑Hole           | 5.0+ (con `pihole-FTL` instalado)        |
| `rsync`           | Instalado en ambos hosts                 |
| `ssh`             | Autenticación sin contraseña entre hosts |
| `sed`             | Instalado (incluido por defecto)         |
| `cron`            | Para programar el script de failover     |
| **Privilegios**   | Los scripts deben ejecutarse como root   |

---

## 🚀 Instalación

1. **Clonar el repositorio**

- ```bash
    https://github.com/Isi067/Failover-DHCP-de-Pi-Hole.git
    cd Failover-DHCP-de-Pi-Hole
    ```

- **Modificar las variables del script**
- ```bash
    nano sync_leases_config.sh #Modificar la variable IP
    nano failover_dhcp.sh #Modificar la variable IP
    ```
	
- **Copiar los scripts al directorio de binarios**
- ```bash
    cp failover_dhcp.sh /usr/local/bin/
    cp sync_leases_config.sh /usr/local/bin/
    ```
    
- **Dar permisos de ejecución**
- ```bash
    chmod +x /usr/local/bin/failover_dhcp.sh
    chmod +x /usr/local/bin/sync_leases_config.sh
    ```
- **Configurar los parámetros**
    
	    - En **`failover_dhcp.sh`** cambia la variable `PRIMARY_PIHOLE_IP` por la IP del servidor primario.
    - En **`sync_leases_config.sh`** modifica `PRIMARY_PIHOLE` y las rutas si tu instalación difiere.
- **Configuración SSH (sin contraseña)**
    
    En el Raspberry Pi ejecuta:
1. ```bash
    ssh-keygen -t ed25519 -C "ha-pihole-failover"
    ssh-copy-id -i ~/.ssh/id_ed25519.pub root@192.168.1.35   # IP del primario
    ```

---

## 🗂️ Estructura de archivos

```
Failover-DHCP-de-Pi-Hole/
├── failover_dhcp.sh        # Script de failover DHCP
├── sync_leases_config.sh   # Sincroniza leases y configuración
└── README.md
```

### `failover_dhcp.sh`

- **Objetivo**: Detectar si el primario está online.
- **Acciones**:
    - Si está online → desactiva DHCP en el secundario.
    - Si está offline → activa DHCP en el secundario.
- **Mecanismo**:
    - `ping` al IP del primario.
    - `pihole-FTL dhcp-discover` para saber el estado del DHCP.
    - `sed` para editar `pihole.toml` y cambiar `active = true/false`.

### `sync_leases_config.sh`

- **Objetivo**: Copiar los últimos `dhcp.leases` y `pihole.toml` del primario al secundario.
- **Mecanismo**:
    - `rsync` con SSH.
    - `service pihole-FTL restart` para recargar la configuración.

---

## 🕒 Programación con cron

Para que el failover se verifique cada minuto y que la copia la haga cada 5 min (por si hacemos algunos cambios, si no vas a tocar la config puedes cambiarlo a que haga backup solo 1 vez al dia):

```bash
sudo crontab -e
# Añade la siguiente línea:
* * * * * /usr/local/bin/failover_dhcp.sh >> /var/log/pihole_failover.log 2>&1
*/5 * * * * /usr/local/bin/pi-hole-sync.sh >> /var/log/pihole_failover.log 2>&1
```

---

## 🛠️ Uso manual

1. **Failover DHCP**
    

- ```bash
    sudo /usr/local/bin/failover_dhcp.sh
    ```
    
- **Sincronizar después de un cambio**
    

1. ```bash
    sudo /usr/local/bin/sync_leases_config.sh
    ```
    

---

## 🔧 Solución de problemas

|Problema|Posible causa|Solución|
|---|---|---|
|El DHCP no se desactiva/activa|`pihole-FTL` no responde|Reinicia el servicio: `systemctl restart pihole-FTL`|
|`rsync` falla|Clave SSH incorrecta|Verifica la clave pública en el primario (`/root/.ssh/authorized_keys`)|
|Logs vacíos|Cron no tiene permisos|Ejecuta `sudo chmod u+x /usr/local/bin/*.sh` y revisa permisos del usuario|
|IP del primario cambiada|Configuración estática|Actualiza la variable `PRIMARY_PIHOLE_IP` en el script|

---

## 📌 Diagrama de Arquitectura

```
+---------------------------+        +----------------------------+
|  Pi‑Hole Primario (VM)   | <----> |  Pi‑Hole Secundario (RPI) |
|  (IP: 192.168.1.35)      |        |  (IP estática)             |
+---------------------------+        +----------------------------+
          |                                 |
          |  DHCP/DNS (cuando primario vivo)|
          |                                 |
          |  Failover (cuando primario caído)|
          +---------------------------------+
```


---

## 📜 Licencia

Este proyecto está bajo la licencia MIT. Consulta el archivo `LICENSE` para más información.
