import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/connection_provider.dart';
import '../../utils/app_theme.dart';

class AdminUsersView extends StatelessWidget {
  const AdminUsersView({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final conn = context.watch<ConnectionProvider>();
    final users = admin.users;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Gestión de Usuarios & Cuotas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: AppTheme.cyberCyan),
            onPressed: () => _showCreateUserModal(context, admin, conn),
          ),
        ],
      ),
      body: users.isEmpty
          ? const Center(child: Text('No hay usuarios cargados'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final u = users[index] as Map<String, dynamic>;
                final username = u['username'] ?? '';
                final fullName = u['full_name'] ?? username;
                final role = u['role'] ?? 'Usuario Estándar';
                final status = u['status'] ?? 'Activo';
                final quotaGb = u['quota_gb'] ?? 0;
                final isRoot = username == 'root';
                final isActive = status == 'Activo';

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isRoot ? AppTheme.primaryBlue.withOpacity(0.2) : AppTheme.cardSub,
                              child: Icon(
                                isRoot ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                                color: isRoot ? AppTheme.cyberCyan : AppTheme.textSecondary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        username,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isRoot ? AppTheme.primaryBlue.withOpacity(0.2) : AppTheme.cardSub,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          role,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isRoot ? AppTheme.cyberCyan : AppTheme.textMuted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    fullName,
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppTheme.emeraldGreen.withOpacity(0.15)
                                    : AppTheme.roseDanger.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? AppTheme.emeraldGreen : AppTheme.roseDanger,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: AppTheme.border, height: 1),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.pie_chart_outline_rounded, size: 14, color: AppTheme.textMuted),
                                const SizedBox(width: 6),
                                Text(
                                  quotaGb == 0 ? 'Cuota: Ilimitada' : 'Cuota: $quotaGb GB Asignados',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                            if (!isRoot)
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () async {
                                  await admin.toggleUserStatus(conn.config, username);
                                },
                                child: Text(
                                  isActive ? 'Suspender' : 'Activar',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isActive ? AppTheme.roseDanger : AppTheme.emeraldGreen,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showCreateUserModal(BuildContext context, AdminProvider admin, ConnectionProvider conn) {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final quotaCtrl = TextEditingController(text: '100');
    String selectedRole = 'Usuario Estándar';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Crear Usuario para el NAS',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: userCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre de usuario (ej: maria)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre completo (ej: María Pérez)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Contraseña del usuario'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: 'Rol en el sistema'),
                      dropdownColor: AppTheme.cardSub,
                      items: const [
                        DropdownMenuItem(value: 'Usuario Estándar', child: Text('Usuario Estándar (OneDrive Propio)')),
                        DropdownMenuItem(value: 'Solo Lectura', child: Text('Solo Lectura (Visualizador)')),
                        DropdownMenuItem(value: 'Administrador', child: Text('Administrador (Acceso Total)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: quotaCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Cuota de Almacenamiento en GB (0 = Sin límite)'),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final username = userCtrl.text.trim();
                          if (username.isEmpty) return;

                          final success = await admin.createNasUser(conn.config, {
                            'username': username,
                            'full_name': nameCtrl.text.trim().isEmpty ? username : nameCtrl.text.trim(),
                            'password': passCtrl.text.trim().isEmpty ? '${username}123' : passCtrl.text.trim(),
                            'role': selectedRole,
                            'quota_gb': int.tryParse(quotaCtrl.text) ?? 100,
                          });

                          if (success && modalCtx.mounted) {
                            Navigator.pop(modalCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Usuario $username creado en GigaNas')),
                            );
                          }
                        },
                        child: const Text('Crear Usuario & Partición'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
