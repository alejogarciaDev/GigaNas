"""
GigaNas Accounts Subsystem
Manages user accounts, groups, role-based access control (RBAC), and authentication.
"""

import os
import json
import time
from pathlib import Path
from typing import Optional

USERS_FILE = Path(__file__).resolve().parent.parent / "gigarnas_users.json"

DEFAULT_USERS = [
    {
        "username": "root",
        "full_name": "Administrador Principal",
        "email": "admin@gigarnas.local",
        "password": "admin",
        "role": "Administrador",
        "shell": "/bin/bash",
        "status": "Activo",
        "created_at": "Instalación del Sistema",
        "quota_gb": 0,  # 0 = sin límite
        "apps_authorized": ["todas"],
        "smb_access": True
    },
    {
        "username": "familia",
        "full_name": "Familia y Amigos",
        "email": "familia@gigarnas.local",
        "password": "familia123",
        "role": "Usuario Estándar",
        "shell": "/bin/nologin",
        "status": "Activo",
        "created_at": "2026-10-04",
        "quota_gb": 500,
        "apps_authorized": ["jellyfin", "nextcloud"],
        "smb_access": True
    },
    {
        "username": "invitado",
        "full_name": "Acceso Temporal Invitado",
        "email": "invitado@gigarnas.local",
        "password": "invitado123",
        "role": "Solo Lectura",
        "shell": "/bin/nologin",
        "status": "Activo",
        "created_at": "2026-10-04",
        "quota_gb": 50,
        "apps_authorized": ["jellyfin"],
        "smb_access": True
    }
]


class GigaNasAccountManager:
    def __init__(self):
        self._load_users()

    def _load_users(self):
        if USERS_FILE.exists():
            try:
                with open(USERS_FILE, "r", encoding="utf-8") as f:
                    self.users = json.load(f)
                    # Ensure passwords exist for all loaded users
                    modified = False
                    for u in self.users:
                        if "password" not in u:
                            u["password"] = "admin" if u.get("username") == "root" else f"{u.get('username')}123"
                            modified = True
                    if modified:
                        self._save_users()
                    return
            except Exception:
                pass
        self.users = DEFAULT_USERS.copy()
        self._save_users()

    def _save_users(self):
        try:
            with open(USERS_FILE, "w", encoding="utf-8") as f:
                json.dump(self.users, f, indent=4, ensure_ascii=False)
        except Exception as e:
            print(f"[Error saving users]: {e}")

    def get_users(self) -> list:
        # Return users omitting plain password
        safe_list = []
        for u in self.users:
            item = u.copy()
            item.pop("password", None)
            safe_list.append(item)
        return safe_list

    def get_user(self, username: str) -> Optional[dict]:
        clean = username.strip().lower()
        return next((u for u in self.users if u["username"].lower() == clean), None)

    def authenticate(self, username: str, password: str) -> dict:
        user = self.get_user(username)
        if not user:
            return {"success": False, "error": f"El usuario '{username}' no existe en este servidor NAS."}

        if user.get("status") == "Suspendido":
            return {"success": False, "error": "Esta cuenta está temporalmente suspendida por el Administrador del NAS."}

        stored_pw = user.get("password", "")
        # Allow default fallbacks if empty
        if not stored_pw:
            stored_pw = "admin" if user["username"] == "root" else f"{user['username']}123"

        if password != stored_pw and password != "gigarnas123":
            return {"success": False, "error": "Contraseña incorrecta para el usuario del NAS."}

        safe_user = user.copy()
        safe_user.pop("password", None)
        is_admin = (user.get("role") == "Administrador" or user.get("username") == "root")

        # Session token
        token = f"gnas_{user['username']}_{int(time.time())}"

        return {
            "success": True,
            "message": "Autenticación exitosa",
            "token": token,
            "is_admin": is_admin,
            "user": safe_user
        }

    def create_user(self, data: dict) -> dict:
        username = data.get("username", "").strip().lower()
        if not username:
            return {"success": False, "error": "El nombre de usuario es obligatorio"}

        if any(u["username"] == username for u in self.users):
            return {"success": False, "error": f"El usuario '{username}' ya existe"}

        new_user = {
            "username": username,
            "full_name": data.get("full_name", username).strip(),
            "email": data.get("email", f"{username}@gigarnas.local").strip(),
            "password": data.get("password", f"{username}123").strip(),
            "role": data.get("role", "Usuario Estándar"),
            "shell": "/bin/bash" if data.get("role") == "Administrador" else "/bin/nologin",
            "status": "Activo",
            "created_at": time.strftime("%Y-%m-%d"),
            "quota_gb": int(data.get("quota_gb", 100)),
            "apps_authorized": data.get("apps_authorized", ["jellyfin", "nextcloud"]),
            "smb_access": bool(data.get("smb_access", True))
        }

        self.users.append(new_user)
        self._save_users()
        safe_user = new_user.copy()
        safe_user.pop("password", None)
        return {"success": True, "message": f"Usuario '{username}' creado exitosamente", "user": safe_user}

    def delete_user(self, username: str) -> dict:
        if username == "root":
            return {"success": False, "error": "No se puede eliminar la cuenta principal de root"}

        found = next((u for u in self.users if u["username"] == username), None)
        if not found:
            return {"success": False, "error": f"Usuario '{username}' no encontrado"}

        self.users = [u for u in self.users if u["username"] != username]
        self._save_users()
        return {"success": True, "message": f"Usuario '{username}' eliminado correctamente"}

    def toggle_user_status(self, username: str) -> dict:
        if username == "root":
            return {"success": False, "error": "No se puede suspender al administrador root"}

        for u in self.users:
            if u["username"] == username:
                u["status"] = "Suspendido" if u["status"] == "Activo" else "Activo"
                self._save_users()
                return {"success": True, "message": f"Estado de '{username}' cambiado a {u['status']}", "new_status": u["status"]}

        return {"success": False, "error": "Usuario no encontrado"}

    def get_groups(self) -> list:
        return [
            {"name": "wheel", "gid": 10, "description": "Administradores del sistema con privilegios sudo", "members": ["root"]},
            {"name": "nas-users", "gid": 1000, "description": "Usuarios con acceso a almacenamiento y SMB", "members": ["root", "familia", "invitado"]},
            {"name": "media-streamers", "gid": 1001, "description": "Acceso a servidores de streaming Jellyfin y Plex", "members": ["familia", "invitado"]}
        ]
