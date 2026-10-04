import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/auth_provider.dart';
import '../providers/connection_provider.dart';
import '../providers/drive_provider.dart';
import '../utils/app_theme.dart';
import 'drive/drive_browser_view.dart';
import 'drive/photo_gallery_view.dart';
import 'drive/user_quota_view.dart';
import 'drive/quota_badge_widget.dart';
import 'admin/admin_dashboard_view.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final conn = context.watch<ConnectionProvider>();
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Sesión cerrada')),
      );
    }

    final isAdmin = user.isAdmin;

    // Define tabs based on role
    final List<Widget> pages = isAdmin
        ? [
            const DriveBrowserView(),
            const PhotoGalleryView(),
            const AdminDashboardView(),
            const SettingsScreen(),
          ]
        : [
            const DriveBrowserView(),
            const PhotoGalleryView(),
            const UserQuotaView(),
            const SettingsScreen(),
          ];

    final List<BottomNavigationBarItem> navItems = isAdmin
        ? const [
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_shared_rounded),
              label: 'OneDrive',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.photo_library_rounded),
              label: 'Fotos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_rounded),
              label: 'Admin NAS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Ajustes',
            ),
          ]
        : const [
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_shared_rounded),
              label: 'OneDrive',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.photo_library_rounded),
              label: 'Fotos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_rounded),
              label: 'Mi Espacio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Ajustes',
            ),
          ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cloud_rounded, color: AppTheme.cyberCyan, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getPageTitle(_currentIndex, isAdmin),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  user.fullName,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (user.quota != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: QuotaBadgeWidget(quota: user.quota!, compact: true),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () {
              setState(() => _currentIndex = navItems.length - 1);
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, auth, conn),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: navItems,
      ),
    );
  }

  String _getPageTitle(int index, bool isAdmin) {
    if (isAdmin) {
      switch (index) {
        case 0:
          return 'GigaNas Drive';
        case 1:
          return 'Fotos Cloud';
        case 2:
          return 'Panel Admin NAS';
        case 3:
          return 'Ajustes';
        default:
          return 'GigaNas';
      }
    } else {
      switch (index) {
        case 0:
          return 'Mi OneDrive';
        case 1:
          return 'Mis Fotos';
        case 2:
          return 'Mi Espacio';
        case 3:
          return 'Ajustes';
        default:
          return 'GigaNas';
      }
    }
  }

  Widget _buildDrawer(BuildContext context, AuthProvider auth, ConnectionProvider conn) {
    final user = auth.user;
    if (user == null) return const Drawer();

    return Drawer(
      backgroundColor: AppTheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // User Header
            Container(
              padding: const EdgeInsets.all(20),
              color: AppTheme.cardSub,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: user.isAdmin ? AppTheme.primaryBlue.withOpacity(0.2) : AppTheme.surface,
                        child: Icon(
                          user.isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                          color: user.isAdmin ? AppTheme.cyberCyan : AppTheme.textSecondary,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '@${user.username}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: user.isAdmin ? AppTheme.primaryBlue.withOpacity(0.2) : AppTheme.surface,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                user.role.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
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
                  if (user.quota != null) ...[
                    const SizedBox(height: 16),
                    QuotaBadgeWidget(quota: user.quota!),
                  ],
                ],
              ),
            ),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  ListTile(
                    leading: const Icon(Icons.folder_shared_rounded, color: AppTheme.cyberCyan),
                    title: const Text('OneDrive / Archivos'),
                    selected: _currentIndex == 0,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = 0);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library_rounded, color: AppTheme.emeraldGreen),
                    title: const Text('Galería de Fotos'),
                    selected: _currentIndex == 1,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = 1);
                    },
                  ),
                  if (user.isAdmin)
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.primaryBlue),
                      title: const Text('Administrar NAS'),
                      selected: _currentIndex == 2,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _currentIndex = 2);
                      },
                    )
                  else
                    ListTile(
                      leading: const Icon(Icons.pie_chart_rounded, color: AppTheme.amberWarning),
                      title: const Text('Mi Espacio Asignado'),
                      selected: _currentIndex == 2,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _currentIndex = 2);
                      },
                    ),
                  const Divider(color: AppTheme.border),
                  ListTile(
                    leading: const Icon(Icons.add_photo_alternate_rounded, color: AppTheme.textSecondary),
                    title: const Text('Subir Fotos Rápidamente'),
                    onTap: () {
                      Navigator.pop(context);
                      context.read<DriveProvider>().pickAndUploadFiles(
                            config: conn.config,
                            username: user.username,
                            fileType: FileType.image,
                          );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.upload_file_rounded, color: AppTheme.textSecondary),
                    title: const Text('Subir Documentos'),
                    onTap: () {
                      Navigator.pop(context);
                      context.read<DriveProvider>().pickAndUploadFiles(
                            config: conn.config,
                            username: user.username,
                            fileType: FileType.any,
                          );
                    },
                  ),
                ],
              ),
            ),

            // Drawer Footer
            Container(
              padding: const EdgeInsets.all(16),
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppTheme.roseDanger),
                title: const Text('Cerrar Sesión', style: TextStyle(color: AppTheme.roseDanger)),
                onTap: () {
                  Navigator.pop(context);
                  auth.logout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
