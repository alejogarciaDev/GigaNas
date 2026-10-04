import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../utils/app_theme.dart';

class AdminStorageView extends StatelessWidget {
  const AdminStorageView({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final pools = admin.pools;
    final disks = admin.disks;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Almacenamiento OpenZFS'),
          bottom: const TabBar(
            indicatorColor: AppTheme.cyberCyan,
            labelColor: AppTheme.cyberCyan,
            unselectedLabelColor: AppTheme.textMuted,
            tabs: [
              Tab(icon: Icon(Icons.storage_rounded), text: 'Pools ZFS'),
              Tab(icon: Icon(Icons.dns_rounded), text: 'Discos Físicos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Pools Tab
            _buildPoolsList(pools),
            // Disks Tab
            _buildDisksList(disks),
          ],
        ),
      ),
    );
  }

  Widget _buildPoolsList(List<dynamic> pools) {
    if (pools.isEmpty) {
      return const Center(child: Text('No hay pools configurados'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: pools.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final pool = pools[index] as Map<String, dynamic>;
        final name = pool['name'] ?? 'pool';
        final status = pool['status'] ?? 'ONLINE';
        final size = pool['size'] ?? '--';
        final free = pool['free'] ?? '--';
        final type = pool['type'] ?? 'OpenZFS RAID';
        final compression = pool['compression_ratio'] ?? 'zstd';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.cyberCyan)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.emeraldGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(color: AppTheme.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(type, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                const SizedBox(height: 12),
                const Divider(color: AppTheme.border, height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricCol('Capacidad', size),
                    _buildMetricCol('Libre', free),
                    _buildMetricCol('Compresión', compression.split(' ').first),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDisksList(List<dynamic> disks) {
    if (disks.isEmpty) {
      return const Center(child: Text('No se encontraron discos físicos'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: disks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final d = disks[index] as Map<String, dynamic>;
        final model = d['model'] ?? 'Disco';
        final dev = d['device'] ?? '';
        final size = d['size_human'] ?? '--';
        final temp = d['temperature'] ?? 35;
        final health = d['smart_status'] ?? 'PASSED';
        final power = d['power_state'] ?? 'Activo';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.storage_rounded, color: Color(0xFF00D2FF), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(model, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1),
                      const SizedBox(height: 2),
                      Text('$dev • $size • $power', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$temp°C', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cyberCyan)),
                    const SizedBox(height: 2),
                    Text(health.contains('PASSED') ? 'Saludable' : health, style: const TextStyle(fontSize: 10, color: AppTheme.emeraldGreen)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
      ],
    );
  }
}
