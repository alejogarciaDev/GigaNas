# ⚡ GigaNas OS

> **El Sistema Operativo para NAS de Próxima Generación**  
> *Basado en el núcleo de TrueNAS SCALE y OpenZFS 2.2, pero optimizado para ser drásticamente más ligero, con menor consumo de RAM y energía, y con más funciones.*

---

## 🚀 ¿Por qué GigaNas es mejor que TrueNAS SCALE original?

TrueNAS SCALE es un sistema robusto, pero adolece de problemas históricos bien conocidos por la comunidad:
1. **Consumo de memoria desmedido:** Requiere un mínimo recomendado de 8 a 16 GB de RAM. Su middleware en Python consume hasta 1.2 GB nada más arrancar, impidiendo su uso en ordenadores modestos.
2. **Los discos duros mecánicos (HDD) nunca duermen:** Debido a que el sistema escribe logs y métricas continuamente en los pools, los discos giran 24/7 generando ruido, calor y consumo eléctrico elevado.
3. **Rigidez en los discos:** Obliga a usar discos del mismo tamaño exacto para los vdevs ZFS.
4. **Interfaz web pesada:** Construida en un Angular SPA clásico que tarda en cargar y consume altos recursos en el navegador.

### 🌟 Soluciones e Innovaciones de GigaNas:
- **Consumo Mínimo de 2GB a 4GB de RAM:** El daemon `gigarnas_core` consume apenas **~38 MB**, dejando toda la memoria libre para lo importante: el caché ARC de ZFS y tus aplicaciones.
- **Green Spindown & Smart RAM Log Buffer:** Buffer de logs en memoria RAM (`tmpfs`). Los discos duros se apagan tras 15-20 minutos de inactividad, logrando **0 dB de ruido** y ahorrando hasta un 70% de electricidad en reposo.
- **Auto-Tuning Adaptativo de ZFS ARC:** Calcula los límites dinámicos de memoria para el ARC de ZFS según la carga real y evita congelamientos por falta de memoria (Out-of-Memory).
- **Almacenamiento Dual: OpenZFS + GigaNas FlexPool:**
  - **OpenZFS:** Máxima integridad empresarial con checksums y RAIDZ para discos homogéneos.
  - **FlexPool (MergerFS + SnapRAID):** Permite combinar discos sueltos de cualquier capacidad (ej: 8TB + 4TB + 2TB) sin perder espacio y con protección de paridad.
- **Panel Web de Control Moderno & Ultra-Rápido:** Interfaz moderna en modo oscuro, responsiva (PC y móvil), con gráficos y métricas por **WebSockets a 1 Hz**.
- **1-Click App Store con Docker Nativo:** Catálogo de aplicaciones preconfiguradas con soporte para transcodificación por GPU (Intel QuickSync, NVIDIA NVENC): Jellyfin, Plex, Nextcloud, Vaultwarden, qBittorrent, AdGuard Home, Home Assistant, etc.
- **Acceso Remoto Seguro Zero-Config:** Tailscale Mesh VPN integrado de fábrica (conéctate desde cualquier lugar sin abrir puertos en tu router).
- **Red de Línea Saturada:** Optimización con Google TCP BBR v2 para saturar enlaces 2.5GbE y 10GbE.

---

## 📁 Estructura del Proyecto

```text
g:\GigaNas\
├── gigarnas_core/             # Motor principal y API REST/WebSockets (FastAPI ultra-ligero)
│   ├── daemon.py              # Servidor API y emisor de telemetría en tiempo real
│   ├── optimizer.py           # Optimizador de ZFS ARC, Green Spindown y TCP BBR
│   ├── storage.py             # Gestor de discos físicos, SMART, ZFS y FlexPools
│   ├── shares.py              # Gestor de Samba SMB3, Windows Shadow Copies y NFS
│   ├── apps_manager.py        # Gestor de Docker Compose y catálogo de Apps
│   └── config.py              # Configuración persistente del sistema
├── gigarnas_mobile/           # App Móvil Oficial en Flutter (Android / iOS / Web)
│   ├── lib/                   # Arquitectura limpia (OneDrive, Galería Fotos, Admin, Providers)
│   └── build/app/outputs/     # APK de Android listo para instalar (app-debug.apk)
├── gigarnas-ui/               # Interfaz Web moderna (HTML5, TailwindCSS, Chart.js, Lucide)
│   ├── index.html             # Dashboard y vistas SPA
│   ├── app.js                 # Lógica reactiva y cliente WebSockets
│   └── style.css              # Estilos glassmorphism y dark mode
├── gigarnas-os-builder/       # Herramientas de construcción y parcheado de la ISO
│   ├── build_iso.py           # Script para generar y parchear la imagen de GigaNas
│   ├── sysctl_tuning.conf     # Parámetros de kernel para alto rendimiento
│   ├── zfs_tuning.conf        # Configuración del módulo OpenZFS
│   └── gigarnas.service       # Servicio Systemd para arranque automático
├── true nas original/         # Imagen oficial descargada (TrueNAS-SCALE-25.10.7.iso)
├── docs/                      # Documentación completa
│   ├── ARQUITECTURA_GIGANAS.md # Manual técnico y comparativa
│   └── GUIA_INSTALACION.md     # Guía paso a paso (Bare metal, Proxmox, VM, Standalone)
├── run_gigarnas.py            # Launcher interactivo para prueba local inmediata
└── README.md                  # Este documento
```

---

## ⚡ Inicio Rápido: Probar GigaNas Ahora Mismo

Puedes arrancar y probar el panel de GigaNas de inmediato en tu máquina:

```bash
python run_gigarnas.py
```

Una vez iniciado, abre en tu navegador:
- **Panel Web:** [http://localhost:8080](http://localhost:8080)
- **Documentación Swagger de la API:** [http://localhost:8080/docs](http://localhost:8080/docs)

---

## 🛠️ Instalación en Servidor Físico o Máquina Virtual

Consulta la [Guía de Instalación Detallada](docs/GUIA_INSTALACION.md) para ver los métodos:
1. **Instalación Bare-Metal (USB booteable con Rufus o Ventoy)**
2. **Máquina Virtual en Proxmox VE / VMware ESXi**
3. **Conversión directa de un TrueNAS SCALE existente a GigaNas en 3 comandos**

---

## 📜 Licencia y Agradecimientos

GigaNas OS utiliza el kernel Linux de alto rendimiento y OpenZFS de TrueNAS SCALE (Debian GNU/Linux) combinado con el nuevo motor de microservicios y panel web de GigaNas. Software libre bajo licencia MIT.
