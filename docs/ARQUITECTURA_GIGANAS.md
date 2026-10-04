# 🏗️ Arquitectura Técnica de GigaNas OS

**GigaNas OS** es una plataforma de sistema operativo para servidores NAS (Network Attached Storage) de última generación, nacida con el objetivo de resolver los principales problemas y limitaciones de **TrueNAS SCALE** original, optimizando drásticamente el consumo de recursos y añadiendo capacidades modernas para entornos domésticos, homelabs y pymes.

---

## 1. Comparativa: TrueNAS SCALE vs. GigaNas OS

| Característica | TrueNAS SCALE Original | GigaNas OS (Next-Gen) |
| :--- | :--- | :--- |
| **Consumo de RAM en Reposo** | 8 GB - 16 GB recomendado (~1.2GB consumidos solo por middleware) | **2 GB - 4 GB mínimo** (~38 MB daemon GigaNas) |
| **Daemon / Middleware** | Python síncrono monolítico pesado (`middlewared`) | **Async Micro-Engine ultra-ligero** (FastAPI / Asíncrono) |
| **Interfaz Web (WebUI)** | Angular SPA pesado, tiempos de carga elevados | **Reactive SPA Glassmorphism**, carga en <300ms, móvil nativo |
| **Telemetría en Vivo** | Polling lento cada 5-10 segundos | **WebSockets en tiempo real** (1 Hz de refresco continuo) |
| **Reposo de Discos (Spindown)** | Fallo recurrente: Discos giran 24/7 por escrituras constantes de logs | **Green Spindown + RAM Log Buffer** (Discos duermen de verdad) |
| **Afinación ZFS ARC** | Fija/agresiva (puede congelar equipos de 4GB-8GB por OOM) | **Auto-Tuning Adaptativo** según memoria libre y Docker |
| **Planificadores E/S (Schedulers)** | Genérico de Linux | **Media-Aware**: NVMe (`none`), SSD (`kyber`), HDD (`bfq`) |
| **Topología de Discos** | Exclusivamente ZFS (obliga a discos de idéntica capacidad) | **Dual Engine**: OpenZFS + **FlexPool** (discos de distinto tamaño) |
| **App Store (Docker)** | Sistema de catálogos complejo y rígido | **1-Click Docker & Compose** con catálogo directo y HW Transcoding |
| **Acceso Remoto Seguro** | Requiere abrir puertos o configurar OpenVPN manual | **Tailscale Mesh VPN** integrado sin abrir puertos de router |
| **Samba SMB Tuning** | Configuración estándar | **SMB3 Multi-Channel + Windows Shadow Copies (VSS)** directos |

---

## 2. Subsistemas Clave de GigaNas

### 2.1. Dynamic ZFS ARC Limiter (`gigarnas_core/optimizer.py`)
En TrueNAS tradicional, OpenZFS puede llegar a consumir hasta el 50%-70% de la memoria RAM del sistema. En máquinas con 4GB o 8GB de RAM, esto compite con los contenedores y el middleware, provocando congelamientos o ejecuciones del OOM Killer de Linux.

GigaNas clasifica la memoria del sistema en 4 perfiles automáticos:
1. **Ultra-Light (<= 4GB RAM):** ARC reservado entre 384 MB y 1.2 GB. Garantiza 2.8 GB libres para el kernel, Docker y red.
2. **Equilibrado (8GB RAM):** ARC reservado entre 1 GB y 3.5 GB.
3. **Alto Rendimiento (16GB RAM):** ARC entre 2 GB y 9 GB.
4. **Empresarial (> 32GB RAM):** ARC hasta el 70% de la RAM para máxima velocidad de lectura de VMs y bases de datos.

### 2.2. Green Spindown Engine & Smart RAM Log Buffer
La queja número uno de los usuarios de TrueNAS es el **ruido y consumo eléctrico de los discos duros**:
- En TrueNAS, servicios como syslog, rrdcached y collectd escriben métricas en el pool cada pocos segundos.
- Por tanto, las órdenes `hdparm -y` son inútiles; el disco vuelve a encenderse 5 segundos después.

**Solución GigaNas:**
- Monta un búfer circular en memoria RAM (`tmpfs` de 256MB) para `/var/log`.
- Los registros se consolidan en memoria y se sincronizan en ráfagas programadas (por ejemplo cada 4 horas o durante apagados).
- Permite que los discos mecánicos HDD permanezcan en suspensión real tras 15-20 minutos de inactividad, ahorrando entre **18W y 35W continuos** y eliminando el 100% del ruido en reposo.

### 2.3. Dual Storage: OpenZFS + GigaNas FlexPool
- **OpenZFS:** Recomendado para quienes poseen discos duros idénticos y buscan la máxima integridad de datos (checksums SHA256/fletcher4 contra degradación de bits, instantáneas ZFS y RAIDZ1/2/3).
- **GigaNas FlexPool:** Combina **MergerFS** (unión de directorios) con **SnapRAID** (paridad programada). Ideal para aprovechar discos viejos de diferentes capacidades (ej: 8TB + 4TB + 2TB) sin desperdiciar un solo gigabyte.

### 2.4. Aceleración Multimedia & Hardware Transcoding
En la App Store de GigaNas, aplicaciones como **Jellyfin** y **Plex** vienen preconfiguradas con acceso directo a `/dev/dri`, habilitando de forma automática:
- **Intel QuickSync Video (QSV)** en CPUs Intel Core / Celeron / Pentium.
- **AMD VA-API** en CPUs Ryzen con gráficos integrados.
- **Nvidia NVENC** mediante runtime de contenedor Nvidia.

---

## 3. Redes y Acceso Remoto de Nueva Generación

### TCP BBR v2 & Buffers 10GbE
El kernel de GigaNas incorpora el algoritmo de control de congestión **BBR de Google** (`net.ipv4.tcp_congestion_control = bbr`) junto con una cola `fq`. Esto optimiza la saturación de interfaces Gigabit (1G), 2.5G y 10G con mínima latencia y cero retransmisiones.

### Tailscale Zero-Config
Mediante Tailscale, cada nodo de GigaNas recibe una dirección IP cifrada única en la red Mesh WireGuard del usuario (ej: `100.x.y.z`), permitiendo acceder a los archivos SMB, a la WebUI y a Jellyfin desde cualquier teléfono o portátil sin necesidad de IP pública fija ni abrir puertos en el firewall/router.
