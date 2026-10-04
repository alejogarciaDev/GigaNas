"""
GigaNas Core Configuration Engine
Handles persistent system settings, storage pool configs, tuning policies, and credentials.
"""

import os
import json
from pathlib import Path

DEFAULT_CONFIG_PATH = Path("/etc/gigarnas/config.json")
LOCAL_CONFIG_PATH = Path(__file__).resolve().parent.parent / "gigarnas_config.json"

DEFAULT_CONFIG = {
    "system": {
        "hostname": "gigarnas",
        "webui_port": 8080,
        "language": "es",
        "theme": "dark",
        "version": "1.0.0-PRO",
        "base_os": "Debian Linux (TrueNAS SCALE 25.10 Core Kernel + GigaNas Engine)",
    },
    "optimizer": {
        "auto_arc_tuning": True,
        "arc_min_percent": 15,
        "arc_max_percent": 65,
        "enable_green_spindown": True,
        "spindown_idle_minutes": 20,
        "ram_log_buffer_enabled": True,
        "ram_log_size_mb": 256,
        "io_scheduler_optimization": True,
        "tcp_bbr_enabled": True,
        "auto_trim_nvme": True,
        "trim_schedule": "weekly"
    },
    "storage": {
        "pools": [],
        "datasets": [],
        "flexpools": []
    },
    "shares": {
        "smb": [
            {
                "id": "share-1",
                "name": "Datos",
                "path": "/mnt/gigapool/datos",
                "read_only": False,
                "guest_ok": False,
                "time_machine": False,
                "recycle_bin": True,
                "comment": "Compartición principal de alta velocidad"
            },
            {
                "id": "share-2",
                "name": "Media",
                "path": "/mnt/gigapool/media",
                "read_only": False,
                "guest_ok": True,
                "time_machine": False,
                "recycle_bin": False,
                "comment": "Películas, Series y Música"
            }
        ],
        "nfs": [],
        "webdav": []
    },
    "remote_access": {
        "tailscale_enabled": False,
        "tailscale_authkey": "",
        "wireguard_enabled": False,
        "wireguard_port": 51820
    },
    "cloud_sync": {
        "rclone_enabled": True,
        "tasks": []
    }
}


def get_config_file_path() -> Path:
    if os.name != "nt" and Path("/etc/gigarnas").exists():
        return DEFAULT_CONFIG_PATH
    return LOCAL_CONFIG_PATH


def load_config() -> dict:
    path = get_config_file_path()
    if path.exists():
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
                # merge with defaults if missing keys
                return {**DEFAULT_CONFIG, **data}
        except Exception:
            pass
    return DEFAULT_CONFIG.copy()


def save_config(cfg: dict) -> bool:
    path = get_config_file_path()
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            json.dump(cfg, f, indent=4, ensure_ascii=False)
        return True
    except Exception as e:
        print(f"[Error saving config]: {e}")
        return False
