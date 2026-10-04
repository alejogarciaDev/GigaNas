"""
GigaNas Cloud Drive & User Partition Subsystem (OneDrive / Google Drive Style)
Handles:
1. Multi-tenant isolated storage partitions per user (/users/{username})
2. Quota enforcement (GB limits, usage calculations, warnings)
3. Photo gallery indexing & thumbnail generation
4. File management: upload, download, delete, create folder, search
5. High-speed streaming and chunked upload support
"""

import os
import io
import time
import shutil
import mimetypes
from pathlib import Path
from typing import List, Dict, Optional, Tuple

try:
    from PIL import Image
    HAS_PIL = True
except ImportError:
    HAS_PIL = False

STORAGE_ROOT = Path(__file__).resolve().parent.parent / "storage_data" / "users"
THUMBNAILS_CACHE = Path(__file__).resolve().parent.parent / "storage_data" / ".thumbnails"

IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".gif", ".bmp", ".tiff", ".svg", ".heic"}
VIDEO_EXTENSIONS = {".mp4", ".mkv", ".mov", ".avi", ".webm", ".m4v"}
DOCUMENT_EXTENSIONS = {".pdf", ".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx", ".txt", ".md", ".csv"}


class GigaNasDriveManager:
    def __init__(self):
        STORAGE_ROOT.mkdir(parents=True, exist_ok=True)
        THUMBNAILS_CACHE.mkdir(parents=True, exist_ok=True)
        self._ensure_sample_data()

    def _get_user_base_dir(self, username: str) -> Path:
        clean_user = username.strip().lower()
        user_path = STORAGE_ROOT / clean_user
        user_path.mkdir(parents=True, exist_ok=True)
        (user_path / "Fotos").mkdir(parents=True, exist_ok=True)
        (user_path / "Documentos").mkdir(parents=True, exist_ok=True)
        (user_path / "Cargas Móvil").mkdir(parents=True, exist_ok=True)
        return user_path

    def _ensure_sample_data(self):
        """Creates initial demo files for default users so testing is immediate."""
        for user in ["root", "familia", "invitado"]:
            u_dir = self._get_user_base_dir(user)
            welcome_file = u_dir / "Documentos" / "Bienvenido_a_GigaNas_Drive.txt"
            if not welcome_file.exists():
                with open(welcome_file, "w", encoding="utf-8") as f:
                    f.write(
                        f"¡Bienvenido a tu almacenamiento personal GigaNas Drive, {user}!\n\n"
                        "Aquí puedes guardar tus documentos, sincronizar fotos de tu móvil,\n"
                        "organizar carpetas y acceder a tus archivos de forma privada y segura.\n\n"
                        "- Encriptación y redundancia OpenZFS activa.\n"
                        "- Copia de seguridad sin límite de velocidad.\n"
                    )

    def _resolve_safe_path(self, username: str, rel_path: str = "") -> Optional[Path]:
        """Prevents directory traversal attacks and validates path within user partition."""
        base = self._get_user_base_dir(username).resolve()
        clean_rel = rel_path.lstrip("/\\")
        target = (base / clean_rel).resolve()
        try:
            target.relative_to(base)
            return target
        except ValueError:
            return None

    def get_user_quota(self, username: str, quota_gb: int) -> dict:
        """Calculates storage consumption for a given user partition."""
        user_dir = self._get_user_base_dir(username)
        total_bytes = 0
        file_count = 0
        photo_count = 0

        for root, dirs, files in os.walk(user_dir):
            for f in files:
                f_path = Path(root) / f
                try:
                    f_size = f_path.stat().st_size
                    total_bytes += f_size
                    file_count += 1
                    if f_path.suffix.lower() in IMAGE_EXTENSIONS:
                        photo_count += 1
                except Exception:
                    pass

        # Quota in bytes. 0 means unlimited (or physical disk size)
        max_bytes = (quota_gb * (1024 ** 3)) if quota_gb > 0 else (1000 * (1024 ** 3)) # 1TB visual max for admin
        is_unlimited = (quota_gb == 0)
        percent = round((total_bytes / max_bytes) * 100, 1) if max_bytes > 0 else 0.0
        free_bytes = max(0, max_bytes - total_bytes)

        return {
            "username": username,
            "quota_gb": quota_gb,
            "is_unlimited": is_unlimited,
            "used_bytes": total_bytes,
            "used_human": self._human_size(total_bytes),
            "max_bytes": max_bytes,
            "max_human": "Sin Límite" if is_unlimited else f"{quota_gb} GB",
            "free_bytes": free_bytes,
            "free_human": "Espacio Ilimitado" if is_unlimited else self._human_size(free_bytes),
            "percent_used": min(100.0, percent),
            "file_count": file_count,
            "photo_count": photo_count,
            "partition_name": f"Partición /users/{username}"
        }

    def list_files(self, username: str, rel_path: str = "") -> dict:
        """Returns files and directories inside a folder."""
        target_dir = self._resolve_safe_path(username, rel_path)
        if not target_dir or not target_dir.exists() or not target_dir.is_dir():
            return {"success": False, "error": "Ruta no encontrada", "items": []}

        base = self._get_user_base_dir(username).resolve()
        current_rel = str(target_dir.relative_to(base)).replace("\\", "/")
        if current_rel == ".":
            current_rel = ""

        items = []
        try:
            with os.scandir(target_dir) as entries:
                for entry in entries:
                    if entry.name.startswith("."):
                        continue
                    item_rel = f"{current_rel}/{entry.name}".strip("/")
                    is_dir = entry.is_dir()
                    size = 0
                    modified = 0
                    try:
                        stat = entry.stat()
                        size = stat.st_size if not is_dir else 0
                        modified = int(stat.st_mtime)
                    except Exception:
                        pass

                    ext = Path(entry.name).suffix.lower()
                    is_photo = ext in IMAGE_EXTENSIONS
                    is_video = ext in VIDEO_EXTENSIONS
                    is_doc = ext in DOCUMENT_EXTENSIONS

                    mime, _ = mimetypes.guess_type(entry.name)
                    mime = mime or ("directory" if is_dir else "application/octet-stream")

                    items.append({
                        "name": entry.name,
                        "path": item_rel,
                        "is_dir": is_dir,
                        "size": size,
                        "size_human": self._human_size(size) if not is_dir else "--",
                        "modified_timestamp": modified,
                        "modified_human": time.strftime("%d/%m/%Y %H:%M", time.localtime(modified)) if modified else "--",
                        "mime_type": mime,
                        "extension": ext.lstrip("."),
                        "is_photo": is_photo,
                        "is_video": is_video,
                        "is_document": is_doc,
                    })
        except Exception as e:
            return {"success": False, "error": str(e), "items": []}

        # Sort: directories first, then alphabetically
        items.sort(key=lambda x: (not x["is_dir"], x["name"].lower()))

        return {
            "success": True,
            "current_path": current_rel,
            "parent_path": str(Path(current_rel).parent).replace("\\", "/") if current_rel else "",
            "items": items
        }

    def list_all_photos(self, username: str) -> list:
        """Recursively lists all photos in user partition for the Photo Gallery."""
        user_dir = self._get_user_base_dir(username)
        base = user_dir.resolve()
        photos = []

        for root, _, files in os.walk(user_dir):
            for f in files:
                ext = Path(f).suffix.lower()
                if ext in IMAGE_EXTENSIONS or ext in VIDEO_EXTENSIONS:
                    f_path = Path(root) / f
                    try:
                        stat = f_path.stat()
                        rel = str(f_path.relative_to(base)).replace("\\", "/")
                        modified = int(stat.st_mtime)
                        photos.append({
                            "name": f,
                            "path": rel,
                            "size": stat.st_size,
                            "size_human": self._human_size(stat.st_size),
                            "modified_timestamp": modified,
                            "date_iso": time.strftime("%Y-%m-%d", time.localtime(modified)),
                            "date_human": time.strftime("%d de %B, %Y", time.localtime(modified)),
                            "is_video": ext in VIDEO_EXTENSIONS,
                            "is_photo": ext in IMAGE_EXTENSIONS,
                            "extension": ext.lstrip(".")
                        })
                    except Exception:
                        pass

        # Sort newest first
        photos.sort(key=lambda x: x["modified_timestamp"], reverse=True)
        return photos

    def upload_file(self, username: str, rel_dir: str, filename: str, file_bytes: bytes, quota_gb: int) -> dict:
        """Saves an uploaded file with quota validation."""
        target_dir = self._resolve_safe_path(username, rel_dir)
        if not target_dir:
            return {"success": False, "error": "Directorio destino inválido"}

        target_dir.mkdir(parents=True, exist_ok=True)
        new_size = len(file_bytes)

        # Quota check (if quota_gb > 0)
        if quota_gb > 0:
            quota = self.get_user_quota(username, quota_gb)
            if quota["used_bytes"] + new_size > quota["max_bytes"]:
                return {
                    "success": False,
                    "error": f"Límite de cuota superado. Tu espacio es de {quota_gb} GB y no hay espacio suficiente."
                }

        # Secure filename
        safe_filename = Path(filename).name
        dest_file = target_dir / safe_filename
        try:
            with open(dest_file, "wb") as f:
                f.write(file_bytes)
        except Exception as e:
            return {"success": False, "error": f"Error al escribir archivo: {e}"}

        base = self._get_user_base_dir(username).resolve()
        rel_file_path = str(dest_file.relative_to(base)).replace("\\", "/")

        return {
            "success": True,
            "message": f"'{safe_filename}' subido exitosamente a GigaNas Drive",
            "file": {
                "name": safe_filename,
                "path": rel_file_path,
                "size": new_size,
                "size_human": self._human_size(new_size),
                "is_photo": dest_file.suffix.lower() in IMAGE_EXTENSIONS,
                "is_video": dest_file.suffix.lower() in VIDEO_EXTENSIONS
            }
        }

    def create_folder(self, username: str, rel_dir: str, folder_name: str) -> dict:
        clean_name = folder_name.strip().replace("/", "_").replace("\\", "_")
        if not clean_name:
            return {"success": False, "error": "Nombre de carpeta inválido"}

        parent_dir = self._resolve_safe_path(username, rel_dir)
        if not parent_dir:
            return {"success": False, "error": "Ruta no encontrada"}

        new_folder = parent_dir / clean_name
        if new_folder.exists():
            return {"success": False, "error": "Ya existe una carpeta con ese nombre"}

        try:
            new_folder.mkdir(parents=True, exist_ok=True)
            return {"success": True, "message": f"Carpeta '{clean_name}' creada con éxito"}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def delete_item(self, username: str, rel_path: str) -> dict:
        target = self._resolve_safe_path(username, rel_path)
        if not target or not target.exists():
            return {"success": False, "error": "Elemento no encontrado"}

        # Prevent root partition deletion
        base = self._get_user_base_dir(username).resolve()
        if target == base:
            return {"success": False, "error": "No se puede eliminar la partición raíz"}

        try:
            if target.is_dir():
                shutil.rmtree(target)
            else:
                target.unlink()
            return {"success": True, "message": f"'{target.name}' eliminado correctamente"}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def rename_item(self, username: str, rel_path: str, new_name: str) -> dict:
        clean_name = new_name.strip().replace("/", "_").replace("\\", "_")
        target = self._resolve_safe_path(username, rel_path)
        if not target or not target.exists():
            return {"success": False, "error": "Elemento no encontrado"}

        new_target = target.parent / clean_name
        if new_target.exists():
            return {"success": False, "error": "Ya existe un elemento con ese nombre"}

        try:
            target.rename(new_target)
            return {"success": True, "message": "Elemento renombrado correctamente"}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def get_thumbnail(self, username: str, rel_path: str, size: Tuple[int, int] = (250, 250)) -> Optional[bytes]:
        """Generates or retrieves cached thumbnail for photos."""
        target = self._resolve_safe_path(username, rel_path)
        if not target or not target.exists() or not target.is_file():
            return None

        ext = target.suffix.lower()
        if ext not in IMAGE_EXTENSIONS:
            return None

        cache_name = f"{username}_{hash(str(target))}_{size[0]}x{size[1]}.jpg"
        cached_path = THUMBNAILS_CACHE / cache_name

        if cached_path.exists():
            try:
                return cached_path.read_bytes()
            except Exception:
                pass

        if HAS_PIL:
            try:
                with Image.open(target) as img:
                    img = img.convert("RGB")
                    img.thumbnail(size)
                    buf = io.BytesIO()
                    img.save(buf, format="JPEG", quality=80)
                    thumb_data = buf.getvalue()
                    cached_path.write_bytes(thumb_data)
                    return thumb_data
            except Exception:
                pass

        # Fallback to original bytes
        try:
            return target.read_bytes()
        except Exception:
            return None

    def _human_size(self, size_bytes: int) -> str:
        for unit in ['B', 'KB', 'MB', 'GB', 'TB', 'PB']:
            if size_bytes < 1024.0:
                return f"{size_bytes:.1f} {unit}"
            size_bytes /= 1024.0
        return f"{size_bytes:.1f} PB"
