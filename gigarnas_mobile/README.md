# 📱 GigaNas Mobile (Flutter Client)

> **Aplicación móvil oficial en Flutter para servidores GigaNas OS.**  
> Combina un panel de administración del NAS en tiempo real con una experiencia tipo **OneDrive / Google Photos** privada y autoalojada.

---

## 🌟 Características Principales

### 1. 🌐 Configuración Flexible de Conexión al NAS
- **Entrada de Datos del Servidor:** Ingresa la IP, Host o Dominio del NAS, puerto (por defecto `8080`) y protocolo (`http` / `https`).
- **Probador de Conexión con Latencia:** Botón para verificar el estado de salud del servidor y medir la respuesta en milisegundos (ms).
- **Preajustes Rápidos (1-Tap):** Conexión inmediata a `Localhost (127.0.0.1:8080)`, `Red Local (192.168.1.50)` o VPN `Tailscale Mesh (100.92.14.88)`.
- **Persistencia Segura:** Guarda los datos del servidor para que no tengas que escribirlos cada vez.

### 2. 🔐 Autenticación y Control de Acceso (RBAC)
- Ingreso con credenciales de cualquier usuario registrado en el NAS (`root`, `familia`, etc.).
- Detección automática del rol y asignación de partición de almacenamiento.
- Opción de "Recordar sesión" con token persistente.

### 3. 👑 Si eres Administrador (`root` / `Administrador`):
- **Panel Completo de Control del NAS:**
  - **Telemetría en Vivo:** Medidores de CPU (con núcleos lógicos), uso de memoria RAM y eficiencia de caché OpenZFS ARC.
  - **Salud del Sistema:** Temperatura del procesador, Uptime y versión del kernel.
  - **Pools de Almacenamiento & Discos:** Monitoreo de pools ZFS (`gigapool-01`, `nvme-cache-pool`, FlexPools) y estado de salud SMART de discos mecánicos y SSDs.
  - **Gestión de Usuarios y Cuotas:** Ver usuarios del NAS, suspender/activar cuentas y crear nuevos usuarios con cuotas asignadas en GB.
  - **Acciones Rápidas del Servidor:** Optimización en 1 clic (ZFS ARC + TCP BBR), reinicio y apagado seguro del equipo.
- **Tu Propio OneDrive Personal:**
  - Acceso a tu almacenamiento y partición en el NAS.
  - Subida de fotos y archivos directamente desde el móvil.
  - Galería de fotos con miniaturas generadas al vuelo.

### 4. 👥 Si NO eres Administrador (Usuario Estándar con Partición):
- **Experiencia 100% OneDrive Privado:**
  - Si el usuario tiene una cuota o partición asignada en el NAS (ej: 500 GB para `familia`), accede exclusivamente a su espacio personal aislado (`/users/<usuario>/`).
  - **Explorador de Archivos:** Navegación por carpetas (`Fotos`, `Documentos`, `Cargas Móvil`), búsqueda en tiempo real, creación de carpetas, renombrado y eliminación.
  - **Galería de Fotos:** Visualización de fotos sincronizadas con miniaturas optimizadas y visor a pantalla completa con zoom interactivo.
  - **Subida Directa desde el Móvil:** Selector para subir imágenes de la galería o documentos locales con barra de progreso.
  - **Medidor de Cuota Personal:** Muestra con exactitud el espacio utilizado (ej: `24.5 GB de 500 GB`), porcentaje y alerta visual si se alcanza el 90%.
  - **Seguridad Garantizada:** El usuario no puede ver ni modificar los archivos de otros usuarios ni acceder a las funciones administrativas del sistema.

---

## 🚀 Cómo Ejecutar la App

### 1. Iniciar el Servidor GigaNas (Backend)
En la raíz del proyecto:
```bash
python run_gigarnas.py
```
El servidor quedará activo en `http://localhost:8080`.

### 2. Ejecutar la App Móvil en Flutter
Ingresa a la carpeta `gigarnas_mobile` y ejecuta:
```bash
cd gigarnas_mobile
flutter run
```

Puedes seleccionar el dispositivo de tu preferencia:
- **Dispositivo Android conectado / Emulador:** Ejecuta la app nativa en tu teléfono.
- **Navegador Web (Chrome / Edge):** Para probar la app móvil directamente en tu pantalla con `flutter run -d chrome`.

### 3. Instalar el APK en tu Celular Android
El APK ya se encuentra compilado y listo para instalar en:
```text
gigarnas_mobile/build/app/outputs/flutter-apk/app-debug.apk
```
Puedes pasarlo a tu celular por cable USB, WhatsApp o descargarlo directamente.

---

## 🛠️ Estructura del Código Flutter

```text
gigarnas_mobile/lib/
├── main.dart                  # Punto de entrada, MultiProvider y enrutamiento
├── models/
│   ├── auth_user.dart         # Perfil de usuario, rol y permisos
│   ├── drive_file.dart        # Metadatos de archivos y fotos
│   ├── nas_status.dart        # Métricas de telemetría del NAS
│   ├── server_config.dart     # Host, puerto, protocolo y URLs
│   └── user_quota.dart        # Cálculo de cuota y espacio usado
├── providers/
│   ├── admin_provider.dart    # Estado de administración y telemetría
│   ├── auth_provider.dart     # Manejo de login, logout y roles
│   ├── connection_provider.dart # Prueba de ping y conexión al NAS
│   └── drive_provider.dart    # Funcionalidad OneDrive (archivos, fotos, subidas)
├── screens/
│   ├── admin/
│   │   ├── admin_dashboard_view.dart # Métricas y botones de control
│   │   ├── admin_storage_view.dart   # Pools ZFS y discos SMART
│   │   └── admin_users_view.dart     # Lista y creación de usuarios
│   ├── drive/
│   │   ├── drive_browser_view.dart   # Explorador de archivos OneDrive
│   │   ├── photo_gallery_view.dart   # Galería de fotos con miniaturas
│   │   ├── photo_viewer_screen.dart  # Visor a pantalla completa con zoom
│   │   └── quota_badge_widget.dart   # Barra de progreso de cuota
│   ├── connection_screen.dart # Paso 1: Configurar servidor NAS
│   ├── home_screen.dart       # Shell principal con barra de navegación por rol
│   ├── login_screen.dart      # Paso 2: Login de usuario
│   └── settings_screen.dart   # Configuración y cierre de sesión
├── services/
│   ├── api_service.dart       # Cliente HTTP con FastAPI de GigaNas
│   └── storage_service.dart   # Persistencia local con SharedPreferences
└── utils/
    ├── app_theme.dart         # Tema oscuro glassmorphism GigaNas
    └── formatters.dart        # Formateadores de bytes y fechas
```
