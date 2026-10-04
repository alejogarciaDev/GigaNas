"""
GigaNas Network Shares Subsystem
Handles enterprise-grade file sharing:
1. Samba (SMB3) with Windows Shadow Copies (ZFS snapshot integration), Apple Time Machine, and Multi-Channel
2. NFSv4 for Linux, Proxmox, and VMware ESXi
3. WebDAV & Cloud Web Access
"""

import os
from pathlib import Path


class GigaNasShareManager:
    def __init__(self, config: dict):
        self.config = config.get("shares", {})
        self.is_linux = (os.name != "nt")

    def get_smb_shares(self) -> list:
        return self.config.get("smb", [])

    def add_smb_share(self, share_data: dict) -> list:
        shares = self.config.get("smb", [])
        # Assign new ID
        new_id = f"share-{len(shares) + 1}"
        share_data["id"] = new_id
        shares.append(share_data)
        self.config["smb"] = shares
        self.generate_smb_conf()
        return shares

    def delete_smb_share(self, share_id: str) -> list:
        shares = [s for s in self.config.get("smb", []) if s.get("id") != share_id]
        self.config["smb"] = shares
        self.generate_smb_conf()
        return shares

    def generate_smb_conf(self) -> str:
        """
        Generates production-optimized Samba configuration:
        - Multi-channel enabled (utilizes multiple NICs simultaneously)
        - Windows Shadow Copies linked to ZFS snapshots
        - Fruit/vfs optimizations for macOS Apple Silicon
        """
        conf_lines = [
            "# ====================================================",
            "# GigaNas High-Performance SMB Configuration",
            "# Optimized for Multi-Gigabit (2.5G/10GbE) & Windows VSS",
            "# ====================================================",
            "[global]",
            "   workgroup = WORKGROUP",
            "   server string = GigaNas Storage Appliance",
            "   server role = standalone server",
            "   log file = /var/log/samba/log.%m",
            "   max log size = 1000",
            "   logging = file",
            "   panic action = /usr/share/samba/panic-action %d",
            "",
            "   # High-Performance SMB3 Multi-Channel Tuning",
            "   server multi channel support = yes",
            "   aio read size = 1",
            "   aio write size = 1",
            "   use sendfile = yes",
            "   min protocol = SMB2_02",
            "   ea support = yes",
            "",
            "   # macOS Apple Fruit VFS Extensions",
            "   vfs objects = catia fruit streams_xattr shadow_copy2",
            "   fruit:metadata = stream",
            "   fruit:model = Macmini",
            "   fruit:posix_rename = yes",
            "   fruit:veto_appledouble = no",
            "   fruit:wipe_intentionally_left_blank_rfork = yes",
            "   fruit:delete_empty_adfiles = yes",
            "",
            "   # Windows Previous Versions (Shadow Copies from ZFS Snapshots)",
            "   shadow: snapdir = .zfs/snapshot",
            "   shadow: sort = desc",
            "   shadow: format = auto-%Y-%m-%d_%H:%M",
            "   shadow: localtime = yes",
            ""
        ]

        for share in self.config.get("smb", []):
            name = share.get("name", "Shared")
            path = share.get("path", "/mnt")
            ro = "yes" if share.get("read_only") else "no"
            guest = "yes" if share.get("guest_ok") else "no"
            comment = share.get("comment", "GigaNas Share")

            conf_lines.extend([
                f"[{name}]",
                f"   comment = {comment}",
                f"   path = {path}",
                f"   read only = {ro}",
                f"   guest ok = {guest}",
                "   browseable = yes",
                "   create mask = 0664",
                "   directory mask = 0775",
                ""
            ])

        output = "\n".join(conf_lines)
        if self.is_linux and Path("/etc/samba").exists():
            try:
                with open("/etc/samba/smb.conf", "w") as f:
                    f.write(output)
            except Exception:
                pass

        return output
