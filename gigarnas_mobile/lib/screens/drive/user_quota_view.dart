import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connection_provider.dart';
import '../../utils/app_theme.dart';
import 'quota_badge_widget.dart';

class UserQuotaView extends StatelessWidget {
  const UserQuotaView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final conn = context.watch<ConnectionProvider>();
    final user = auth.user;
    final quota = user?.quota;

    if (user == null) {
      return const Center(child: Text('Sesión no iniciada'));
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Mi Espacio de Almacenamiento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => auth.refreshQuota(conn.config),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => auth.refreshQuota(conn.config),
        color: AppTheme.cyberCyan,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Quota Badge
            if (quota != null) ...[
              QuotaBadgeWidget(quota: quota),
              const SizedBox(height: 16),
            ],

            // Partition Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.pie_chart_outline_rounded, color: AppTheme.cyberCyan, size: 20),
                        SizedBox(width: 8),
                        Text('Detalles de tu Partición', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildDetailRow('Ubicación en el NAS', '/users/${user.username}', Icons.folder_shared_rounded),
                    const Divider(color: AppTheme.border, height: 16),
                    _buildDetailRow('Espacio Asignado', user.quotaGb == 0 ? 'Ilimitado' : '${user.quotaGb} GB', Icons.storage_rounded),
                    const Divider(color: AppTheme.border, height: 16),
                    _buildDetailRow('Total de Archivos', '${quota?.fileCount ?? 0} elementos', Icons.file_present_rounded),
                    const Divider(color: AppTheme.border, height: 16),
                    _buildDetailRow('Fotos Guardadas', '${quota?.photoCount ?? 0} imágenes', Icons.photo_library_rounded),
                    const Divider(color: AppTheme.border, height: 16),
                    _buildDetailRow('Sistema de Archivos', 'OpenZFS con Checksums & Autocuración', Icons.security_rounded),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // User Profile Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.person_outline_rounded, color: AppTheme.primaryBlue, size: 20),
                        SizedBox(width: 8),
                        Text('Perfil de Usuario', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildDetailRow('Usuario', user.username, Icons.account_circle_outlined),
                    const Divider(color: AppTheme.border, height: 16),
                    _buildDetailRow('Nombre Completo', user.fullName, Icons.badge_outlined),
                    const Divider(color: AppTheme.border, height: 16),
                    _buildDetailRow('Rol Asignado', user.role, Icons.verified_user_outlined),
                    const Divider(color: AppTheme.border, height: 16),
                    _buildDetailRow('Acceso SMB / Red', user.smbAccess ? 'Habilitado' : 'Deshabilitado', Icons.lan_outlined),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Cloud Drive Features Help Card
            Card(
              color: AppTheme.cardSub,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.cloud_sync_rounded, color: AppTheme.emeraldGreen, size: 20),
                        SizedBox(width: 8),
                        Text('Tu Nube Privada GigaNas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tus archivos y fotos se almacenan directamente en los discos duros de tu servidor NAS. Nadie fuera de tu red o sin autorización puede acceder a tus documentos.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
