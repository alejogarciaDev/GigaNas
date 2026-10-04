import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/connection_provider.dart';
import '../utils/app_theme.dart';
import 'connection_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final conn = context.watch<ConnectionProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Configuración & Servidor'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Card
          if (user != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: user.isAdmin ? AppTheme.primaryBlue.withOpacity(0.2) : AppTheme.cardSub,
                      child: Icon(
                        user.isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                        color: user.isAdmin ? AppTheme.cyberCyan : AppTheme.textSecondary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text('@${user.username}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: user.isAdmin ? AppTheme.primaryBlue.withOpacity(0.2) : AppTheme.cardSub,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              user.role.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: user.isAdmin ? AppTheme.cyberCyan : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // NAS Server Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Servidor Conectado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.emeraldGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          conn.isConnected ? 'EN LÍNEA' : 'DESCONECTADO',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildServerRow('Dirección Base', conn.config.baseUrl),
                  const SizedBox(height: 8),
                  _buildServerRow('Protocolo', conn.config.protocol.toUpperCase()),
                  const SizedBox(height: 8),
                  _buildServerRow('Latencia', '${conn.latencyMs ?? "--"} ms'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ConnectionScreen()),
                        );
                      },
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: const Text('Cambiar Servidor NAS'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // About Card
          Card(
            color: AppTheme.cardSub,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('GigaNas OS Mobile Client', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                  SizedBox(height: 6),
                  Text(
                    'Versión 1.0.0-PRO • Motor nativo Flutter\n'
                    'Desarrollado para servidores OpenZFS y almacenamiento privado.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Logout Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.cardSub,
              foregroundColor: AppTheme.roseDanger,
              side: const BorderSide(color: AppTheme.roseDanger, width: 0.8),
            ),
            onPressed: () => _confirmLogout(context, auth),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Cerrar Sesión del NAS'),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildServerRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      ],
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('¿Cerrar Sesión?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: const Text('Tendrás que ingresar tus credenciales nuevamente para acceder a tu GigaNas Drive.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.roseDanger),
              onPressed: () async {
                Navigator.pop(ctx);
                await auth.logout();
              },
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }
}
