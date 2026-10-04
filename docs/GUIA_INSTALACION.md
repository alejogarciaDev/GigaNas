# 🚀 Guía de Instalación y Despliegue de GigaNas OS

Existen **4 métodos** para utilizar GigaNas OS según tu entorno y necesidades:

---

## 📌 Método 1: Prueba Rápida Inmediata (Modo Standalone / Simulador)
Si deseas explorar la interfaz de usuario, comprobar el comportamiento de la API y ver cómo luce el sistema antes de tocar tu servidor físico:

1. Asegúrate de tener instalado Python 3.10+ en tu equipo.
2. Abre una terminal en la carpeta del proyecto `g:\GigaNas`.
3. Ejecuta el launcher:
   ```bash
   python run_gigarnas.py
   ```
4. Abre tu navegador web en:
   - **Local:** [http://localhost:8080](http://localhost:8080)
   - **Desde otro equipo en tu red:** `http://<IP-DE-TU-PC>:8080`
   - **Documentación Swagger API:** [http://localhost:8080/docs](http://localhost:8080/docs)

---

## 📌 Método 2: Instalación en Servidor Físico (Bare Metal)

### Requisitos Mínimos:
- **Procesador:** CPU de 64 bits (Intel o AMD, 2 núcleos o superior).
- **Memoria RAM:** 2 GB mínimo (Recomendado 4 GB o superior para Docker). *Nota: TrueNAS original requiere 8GB mínimo.*
- **Unidad de Sistema:** 1x SSD SATA o NVMe de al menos 16 GB (para el sistema operativo).
- **Unidades de Almacenamiento:** 1 o más discos duros HDD / SSD para tus pools de datos.
- **Red:** 1x puerto Gigabit Ethernet (1GbE, 2.5GbE o 10GbE).

### Pasos:
1. **Crear el USB Booteable:**
   - Descarga la herramienta gratuita [Ventoy](https://www.ventoy.net/) o [Rufus](https://rufus.ie/).
   - Quema la imagen ISO generada (`TrueNAS-SCALE-25.10.7.iso` o la ISO personalizada de GigaNas) en tu pendrive USB (modo UEFI GPT).
2. **Arrancar el Servidor:**
   - Conecta el USB al servidor NAS y enciende el equipo seleccionando el pendrive en el menú de booteo (tecla F11/F12).
3. **Instalación:**
   - Selecciona **Start TrueNAS / GigaNas Installation**.
   - Escoge el disco de destino para el sistema operativo (tu SSD/NVMe pequeño de arranque).
   - Define la contraseña de administrador (`root`).
   - Una vez finalizada la extracción, retira el pendrive y reinicia el equipo.
4. **Acceso:**
   - El equipo mostrará en pantalla la dirección IP asignada por DHCP (ejemplo: `http://192.168.1.150:8080`).

---

## 📌 Método 3: Despliegue en Proxmox VE o VMware ESXi

Si utilizas un entorno de virtualización:

1. **Crear Máquina Virtual:**
   - **OS:** Linux (Kernel 6.x / Debian 64-bit).
   - **CPU:** 2 a 4 vCPUs (tipo: `host`).
   - **RAM:** 4096 MB (4 GB).
   - **Controlador de Disco:** `VirtIO SCSI single` con emulación iothread.
   - **Disco OS:** 32 GB en SSD.
2. **Passthrough de Discos para ZFS:**
   - Para un rendimiento óptimo de ZFS, se recomienda hacer passthrough directo de la controladora HBA (LSI SAS IT mode) o de los discos físicos SATA/NVMe mediante:
     ```bash
     qm set <VM_ID> -scsi1 /dev/disk/by-id/ata-ST8000VN004...
     ```
3. **Red:** VirtIO (Bridge vmbr0 con MTU 1500 o 9000 para Jumbo Frames).

---

## 📌 Método 4: Conversión Directa de TrueNAS SCALE a GigaNas

Si ya tienes un servidor o máquina virtual con TrueNAS SCALE instalado y funcionando, puedes convertirlo al motor de **GigaNas** en solo 3 minutos sin reinstalar ni formatear tus discos:

1. **Accede por SSH a tu servidor TrueNAS SCALE con usuario root:**
   ```bash
   ssh root@<IP_TRUENAS>
   ```

2. **Copia la carpeta de GigaNas a `/opt/gigarnas`:**
   ```bash
   mkdir -p /opt/gigarnas
   # Copia gigarnas_core y gigarnas-ui a /opt/gigarnas/
   ```

3. **Aplica las optimizaciones de Kernel y ZFS:**
   ```bash
   # 1. Copiar optimizaciones sysctl (BBR y buffers)
   cp /opt/gigarnas/gigarnas-os-builder/sysctl_tuning.conf /etc/sysctl.d/99-gigarnas-performance.conf
   sysctl -p /etc/sysctl.d/99-gigarnas-performance.conf

   # 2. Copiar tuning ZFS
   cp /opt/gigarnas/gigarnas-os-builder/zfs_tuning.conf /etc/modprobe.d/zfs.conf

   # 3. Instalar y activar el servicio GigaNas
   cp /opt/gigarnas/gigarnas-os-builder/gigarnas.service /etc/systemd/system/
   systemctl daemon-reload
   systemctl enable --now gigarnas
   ```

4. **¡Listo!** Abre en tu navegador `http://<IP_TRUENAS>:8080` y disfruta de la nueva interfaz ultrarrápida de GigaNas.
