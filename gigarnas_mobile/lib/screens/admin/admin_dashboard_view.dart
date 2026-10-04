import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/connection_provider.dart';
import '../../models/nas_status.dart';
import '../../utils/app_theme.dart';
import 'admin_users_view.dart';
import 'admin_storage_view.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboard();
    });
  }

  void _loadDashboard() {
    final conn = context.read<ConnectionProvider>();
    context.read<AdminProvider>().fetchDashboardData(conn.config);
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final conn = context.watch<ConnectionProvider>();
    final status = admin.status;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: () async => admin.fetchDashboardData(conn.config),
        color: AppTheme.cyberCyan,
        child: admin.isLoading && status == null
            ? const Center(child: CircularProgressIndicator(color: AppTheme.cyberCyan))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Server Health Hero Card
                  _buildServerHero(status, conn),
                  const SizedBox(height: 16),

                  // Quick Admin Navigation Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionTile(
                          icon: Icons.people_alt_rounded,
                          color: AppTheme.primaryBlue,
                          title: 'Usuarios & Cuotas',
                          subtitle: '${admin.users.length} Cuentas',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminUsersView()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildActionTile(
                          icon: Icons.storage_rounded,
                          color: AppTheme.cyberCyan,
                          title: 'Pools & Discos',
                          subtitle: '${admin.pools.length} Pools ZFS',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminStorageView()),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Telemetry Meters (CPU & RAM)
                  if (status != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: 'CPU',
                            value: '${status.cpuPercent.toStringAsFixed(1)}%',
                            subtitle: '${status.cpuCores} núcleos',
                            progress: (status.cpuPercent / 100.0).clamp(0.0, 1.0),
                            color: status.cpuPercent > 80 ? AppTheme.roseDanger : AppTheme.cyberCyan,
                            icon: Icons.speed_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'RAM',
                            value: '${status.ramUsedGb} GB',
                            subtitle: 'de ${status.ramTotalGb} GB (${status.ramPercent}%)',
                            progress: (status.ramPercent / 100.0).clamp(0.0, 1.0),
                            color: status.ramPercent > 85 ? AppTheme.amberWarning : AppTheme.emeraldGreen,
                            icon: Icons.memory_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ARC Cache & Temperature Card
                    _buildArcCacheCard(status),
                    const SizedBox(height: 16),
                  ],

                  // Server Power Controls
                  _buildServerControls(context, admin, conn),
                  const SizedBox(height: 40),
                ],
              ),
      ),
    );
  }

  Widget _buildServerHero(NasSystemStatus? status, ConnectionProvider conn) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF131B29), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withOpacity(0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.cyberCyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.dns_rounded, color: AppTheme.cyberCyan, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status?.hostname ?? conn.config.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      Text(
                        'GigaNas ${status?.version ?? "1.0.0-PRO"}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.cyberCyan),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.emeraldGreen.withOpacity(0.5)),
                ),
                child: Row(
                  children: const [
                    CircleAvatar(radius: 3, backgroundColor: AppTheme.emeraldGreen),
                    SizedBox(width: 5),
                    Text('ONLINE', style: TextStyle(color: AppTheme.emeraldGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeroStat('Uptime', status?.uptime ?? '--', Icons.timer_outlined),
              _buildHeroStat('Kernel', 'Linux 6.12 OpenZFS', Icons.terminal_rounded),
              _buildHeroStat('Temp', '${status?.temperature ?? 36}°C', Icons.thermostat_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required double progress,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: AppTheme.cardSub,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArcCacheCard(NasSystemStatus status) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.bolt_rounded, color: AppTheme.cyberCyan, size: 20),
                    SizedBox(width: 8),
                    Text('Caché Inteligente OpenZFS ARC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.emeraldGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status.arcEfficiency,
                    style: const TextStyle(color: AppTheme.emeraldGreen, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Asignado en RAM: ${status.arcAllocatedGb} GB. El auto-tuning mantiene los discos en reposo (Green Spindown) reduciendo el consumo eléctrico y ruido a 0 dB.',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerControls(BuildContext context, AdminProvider admin, ConnectionProvider conn) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Acciones Rápidas del Servidor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final msg = await admin.applyOptimization(conn.config);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      }
                    },
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                    label: const Text('Optimizar', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.amberWarning),
                    onPressed: () => _confirmAction(
                      context,
                      title: '¿Reiniciar el NAS?',
                      content: 'El servidor GigaNas se reiniciará de inmediato. Las conexiones se pausarán unos instantes.',
                      confirmText: 'Reiniciar',
                      onConfirm: () => admin.rebootServer(conn.config),
                    ),
                    icon: const Icon(Icons.restart_alt_rounded, size: 16),
                    label: const Text('Reiniciar', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.roseDanger),
                    onPressed: () => _confirmAction(
                      context,
                      title: '¿Apagar el NAS?',
                      content: 'Los discos OpenZFS se desmontarán limpiamente antes de apagar el equipo por completo.',
                      confirmText: 'Apagar',
                      onConfirm: () => admin.shutdownServer(conn.config),
                    ),
                    icon: const Icon(Icons.power_settings_new_rounded, size: 16),
                    label: const Text('Apagar', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmAction(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmText,
    required Future<void> Function() onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Text(content, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.roseDanger),
              onPressed: () async {
                Navigator.pop(ctx);
                await onConfirm();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Comando enviado al servidor NAS: $confirmText')),
                  );
                }
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }
}
