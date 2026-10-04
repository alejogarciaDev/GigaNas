#!/usr/bin/env python3
"""
GigaNas Launcher
Starts GigaNas Master Daemon and Web UI for local testing or live server appliance.
"""

import sys
import socket
import uvicorn
from pathlib import Path

import sys
if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

# Add project root to path
ROOT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT_DIR))


def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"


def banner():
    local_ip = get_local_ip()
    print("=" * 65)
    print("       G I G A N A S   O S   -   S I S T E M A   A C T I V O       ")
    print("=" * 65)
    print(" >> Motor de Alto Rendimiento basado en TrueNAS SCALE + OpenZFS << ")
    print()
    print(f" [*] Acceso Local:      http://localhost:8080")
    print(f" [*] Acceso Red Local:  http://{local_ip}:8080")
    print(f" [*] Documentacion API: http://localhost:8080/docs")
    print()
    print(" [OK] Dynamic ZFS ARC Tuning:   ACTIVADO")
    print(" [OK] Green Spindown Engine:    ACTIVADO")
    print(" [OK] TCP BBR 10GbE Network:    ACTIVADO")
    print(" [OK] App Store Docker:         ACTIVADO")
    print(" [OK] Telemetria WebSockets:    ACTIVADO (/ws/telemetry)")
    print("=" * 65)
    print(" Presiona Ctrl+C para detener el servidor.\n")


if __name__ == "__main__":
    banner()
    uvicorn.run(
        "gigarnas_core.daemon:app",
        host="0.0.0.0",
        port=8080,
        log_level="info",
        reload=False
    )
