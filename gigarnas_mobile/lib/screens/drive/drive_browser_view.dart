import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/drive_provider.dart';
import '../../providers/connection_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/drive_file.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import 'photo_viewer_screen.dart';

class DriveBrowserView extends StatefulWidget {
  const DriveBrowserView({super.key});

  @override
  State<DriveBrowserView> createState() => _DriveBrowserViewState();
}

class _DriveBrowserViewState extends State<DriveBrowserView> {
  bool _isGridView = false;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFiles();
    });
  }

  void _loadFiles() {
    final conn = context.read<ConnectionProvider>();
    final auth = context.read<AuthProvider>();
    if (auth.user != null) {
      context.read<DriveProvider>().loadFiles(conn.config, auth.user!.username);
    }
  }

  @override
  Widget build(BuildContext context) {
    final drive = context.watch<DriveProvider>();
    final conn = context.watch<ConnectionProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return const Center(child: Text('Sesión no iniciada'));
    }

    final filteredItems = drive.items.where((i) {
      if (_searchQuery.isEmpty) return true;
      return i.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Header / Breadcrumb Bar
          _buildNavigationHeader(context, drive, conn, user.username),

          // Uploading Progress banner
          if (drive.isUploading && drive.uploadStatusText != null)
            Container(
              color: AppTheme.primaryBlue.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyberCyan),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      drive.uploadStatusText!,
                      style: const TextStyle(fontSize: 12, color: AppTheme.cyberCyan),
                    ),
                  ),
                ],
              ),
            ),

          // Search & View toggler
          _buildToolbar(),

          // Files Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => drive.refreshCurrentDir(conn.config, user.username),
              color: AppTheme.cyberCyan,
              child: drive.isLoading && drive.items.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.cyberCyan))
                  : filteredItems.isEmpty
                      ? _buildEmptyFolder(context, conn, user.username)
                      : _isGridView
                          ? _buildGridView(context, filteredItems, conn, user.username)
                          : _buildListView(context, filteredItems, conn, user.username),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddActionSheet(context, conn, user.username),
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
      ),
    );
  }

  Widget _buildNavigationHeader(
    BuildContext context,
    DriveProvider drive,
    ConnectionProvider conn,
    String username,
  ) {
    final isRoot = drive.currentPath.isEmpty;

    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          if (!isRoot)
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, size: 20, color: AppTheme.cyberCyan),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => drive.navigateUp(conn.config, username),
            ),
          if (!isRoot) const SizedBox(width: 10),
          const Icon(Icons.folder_open_rounded, size: 18, color: AppTheme.cyberCyan),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isRoot ? 'GigaNas Drive (Raíz)' : '/${drive.currentPath}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20, color: AppTheme.textSecondary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => drive.refreshCurrentDir(conn.config, username),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.background,
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Buscar en esta carpeta...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.textMuted),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded, size: 20),
            color: AppTheme.textSecondary,
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(
    BuildContext context,
    List<DriveItem> items,
    ConnectionProvider conn,
    String username,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(color: AppTheme.border, height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          leading: _buildItemIcon(item, conn, username),
          title: Text(
            item.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: item.isDir ? FontWeight.bold : FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            item.isDir ? 'Carpeta • ${item.modifiedHuman}' : '${item.sizeHuman} • ${item.modifiedHuman}',
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppTheme.textMuted),
            onPressed: () => _showItemOptions(context, item, conn, username),
          ),
          onTap: () {
            if (item.isDir) {
              context.read<DriveProvider>().loadFiles(conn.config, username, item.path);
            } else if (item.isPhoto) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PhotoViewerScreen(
                    photo: PhotoItem(
                      name: item.name,
                      path: item.path,
                      size: item.size,
                      sizeHuman: item.sizeHuman,
                      modifiedTimestamp: item.modifiedTimestamp,
                      dateIso: '',
                      dateHuman: item.modifiedHuman,
                      isVideo: false,
                      isPhoto: true,
                      extension: item.extension,
                    ),
                    config: conn.config,
                    username: username,
                  ),
                ),
              );
            } else {
              _showItemOptions(context, item, conn, username);
            }
          },
        );
      },
    );
  }

  Widget _buildGridView(
    BuildContext context,
    List<DriveItem> items,
    ConnectionProvider conn,
    String username,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.25,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () {
            if (item.isDir) {
              context.read<DriveProvider>().loadFiles(conn.config, username, item.path);
            } else if (item.isPhoto) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PhotoViewerScreen(
                    photo: PhotoItem(
                      name: item.name,
                      path: item.path,
                      size: item.size,
                      sizeHuman: item.sizeHuman,
                      modifiedTimestamp: item.modifiedTimestamp,
                      dateIso: '',
                      dateHuman: item.modifiedHuman,
                      isVideo: false,
                      isPhoto: true,
                      extension: item.extension,
                    ),
                    config: conn.config,
                    username: username,
                  ),
                ),
              );
            } else {
              _showItemOptions(context, item, conn, username);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border.withOpacity(0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildItemIcon(item, conn, username, 32),
                    IconButton(
                      icon: const Icon(Icons.more_horiz_rounded, size: 18, color: AppTheme.textMuted),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showItemOptions(context, item, conn, username),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.isDir ? 'Carpeta' : item.sizeHuman,
                      style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemIcon(DriveItem item, ConnectionProvider conn, String username, [double size = 28]) {
    if (item.isDir) {
      return Icon(Icons.folder_rounded, color: AppTheme.cyberCyan, size: size);
    }
    if (item.isPhoto) {
      final thumbUrl = ApiService.getThumbnailUrl(conn.config, username, item.path);
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          thumbUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(Icons.image_rounded, color: AppTheme.emeraldGreen, size: size),
        ),
      );
    }
    if (item.isVideo) {
      return Icon(Icons.video_file_rounded, color: AppTheme.amberWarning, size: size);
    }
    if (item.isDocument) {
      return Icon(Icons.description_rounded, color: AppTheme.primaryBlue, size: size);
    }
    return Icon(Icons.insert_drive_file_rounded, color: AppTheme.textSecondary, size: size);
  }

  Widget _buildEmptyFolder(BuildContext context, ConnectionProvider conn, String username) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_open_rounded, size: 56, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          const Text('Esta carpeta está vacía', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          const Text('Usa el botón + para subir archivos o fotos', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => _showAddActionSheet(context, conn, username),
            icon: const Icon(Icons.cloud_upload_outlined, size: 18),
            label: const Text('Subir Archivo'),
          ),
        ],
      ),
    );
  }

  void _showAddActionSheet(BuildContext context, ConnectionProvider conn, String username) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Agregar a GigaNas Drive',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.upload_file_rounded, color: AppTheme.primaryBlue),
                  ),
                  title: const Text('Subir Archivo(s)'),
                  subtitle: const Text('Documentos, PDF, ZIP, música, etc.'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.read<DriveProvider>().pickAndUploadFiles(
                          config: conn.config,
                          username: username,
                          fileType: FileType.any,
                        );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.emeraldGreen.withOpacity(0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.add_photo_alternate_rounded, color: AppTheme.emeraldGreen),
                  ),
                  title: const Text('Subir Fotos / Vídeos'),
                  subtitle: const Text('Seleccionar imágenes desde la galería'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.read<DriveProvider>().pickAndUploadFiles(
                          config: conn.config,
                          username: username,
                          fileType: FileType.image,
                        );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.cyberCyan.withOpacity(0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.create_new_folder_rounded, color: AppTheme.cyberCyan),
                  ),
                  title: const Text('Nueva Carpeta'),
                  subtitle: const Text('Crear un directorio en esta ubicación'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showCreateFolderDialog(context, conn, username);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateFolderDialog(BuildContext context, ConnectionProvider conn, String username) {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Nueva Carpeta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: textCtrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Nombre de la carpeta'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = textCtrl.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(dialogCtx);
                  await context.read<DriveProvider>().createFolder(conn.config, username, name);
                }
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }

  void _showItemOptions(BuildContext context, DriveItem item, ConnectionProvider conn, String username) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: _buildItemIcon(item, conn, username, 32),
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                  subtitle: Text('${item.isDir ? "Carpeta" : item.sizeHuman} • ${item.modifiedHuman}'),
                ),
                const Divider(color: AppTheme.border),
                if (!item.isDir)
                  ListTile(
                    leading: const Icon(Icons.download_rounded, color: AppTheme.cyberCyan),
                    title: const Text('Descargar archivo'),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Descargando ${item.name}...')),
                      );
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: AppTheme.textSecondary),
                  title: const Text('Renombrar'),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _showRenameDialog(context, item, conn, username);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.roseDanger),
                  title: const Text('Eliminar', style: TextStyle(color: AppTheme.roseDanger)),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _showDeleteConfirmDialog(context, item, conn, username);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context, DriveItem item, ConnectionProvider conn, String username) {
    final textCtrl = TextEditingController(text: item.name);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Renombrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: TextField(controller: textCtrl, autofocus: true),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = textCtrl.text.trim();
                if (newName.isNotEmpty && newName != item.name) {
                  Navigator.pop(ctx);
                  await context.read<DriveProvider>().renameItem(conn.config, username, item.path, newName);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, DriveItem item, ConnectionProvider conn, String username) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('¿Eliminar elemento?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Text('¿Seguro que deseas eliminar "${item.name}" de tu partición GigaNas? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.roseDanger),
              onPressed: () async {
                Navigator.pop(ctx);
                await context.read<DriveProvider>().deleteItem(conn.config, username, item.path);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }
}
