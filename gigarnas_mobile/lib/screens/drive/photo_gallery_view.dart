import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/drive_provider.dart';
import '../../providers/connection_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/drive_file.dart';
import '../../utils/app_theme.dart';
import 'photo_viewer_screen.dart';

class PhotoGalleryView extends StatefulWidget {
  const PhotoGalleryView({super.key});

  @override
  State<PhotoGalleryView> createState() => _PhotoGalleryViewState();
}

class _PhotoGalleryViewState extends State<PhotoGalleryView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPhotos();
    });
  }

  void _loadPhotos() {
    final conn = context.read<ConnectionProvider>();
    final auth = context.read<AuthProvider>();
    if (auth.user != null) {
      context.read<DriveProvider>().loadPhotos(conn.config, auth.user!.username);
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

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: () async => _loadPhotos(),
        color: AppTheme.cyberCyan,
        child: drive.isLoading && drive.photos.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppTheme.cyberCyan))
            : drive.photos.isEmpty
                ? _buildEmptyState(context, conn, user.username)
                : _buildPhotoGrid(context, drive.photos, conn, user.username),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: drive.isUploading
            ? null
            : () async {
                final success = await context.read<DriveProvider>().pickAndUploadFiles(
                      config: conn.config,
                      username: user.username,
                      fileType: FileType.image,
                    );
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fotos subidas a GigaNas Drive')),
                  );
                }
              },
        backgroundColor: AppTheme.primaryBlue,
        icon: drive.isUploading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
        label: Text(
          drive.isUploading ? 'Subiendo...' : 'Subir Fotos',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ConnectionProvider conn, String username) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.cyberCyan.withOpacity(0.3), width: 2),
                ),
                child: const Icon(Icons.photo_library_outlined, size: 48, color: AppTheme.cyberCyan),
              ),
              const SizedBox(height: 20),
              const Text(
                'No hay fotos en tu nube aún',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Sube tus recuerdos desde tu dispositivo móvil para guardarlos con redundancia ZFS en tu NAS personal.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.read<DriveProvider>().pickAndUploadFiles(
                      config: conn.config,
                      username: username,
                      fileType: FileType.image,
                    ),
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Subir Primera Foto'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoGrid(
    BuildContext context,
    List<PhotoItem> photos,
    ConnectionProvider conn,
    String username,
  ) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${photos.length} Fotos Sincronizadas',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                ),
                Row(
                  children: const [
                    Icon(Icons.cloud_done_rounded, size: 16, color: AppTheme.emeraldGreen),
                    SizedBox(width: 4),
                    Text('Almacenamiento Seguro', style: TextStyle(fontSize: 11, color: AppTheme.emeraldGreen)),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final photo = photos[index];
                final thumbUrl = ApiService.getThumbnailUrl(conn.config, username, photo.path);

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PhotoViewerScreen(
                          photo: photo,
                          config: conn.config,
                          username: username,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(color: AppTheme.cardSub),
                        Image.network(
                          thumbUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image, color: AppTheme.textMuted, size: 24),
                          ),
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: AppTheme.cardSub,
                              child: const Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyberCyan),
                                ),
                              ),
                            );
                          },
                        ),
                        if (photo.isVideo)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
              childCount: photos.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}
