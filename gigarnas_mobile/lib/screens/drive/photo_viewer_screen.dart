import 'package:flutter/material.dart';
import '../../models/drive_file.dart';
import '../../models/server_config.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class PhotoViewerScreen extends StatelessWidget {
  final PhotoItem photo;
  final ServerConfig config;
  final String username;

  const PhotoViewerScreen({
    super.key,
    required this.photo,
    required this.config,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    final downloadUrl = ApiService.getDownloadUrl(config, username, photo.path);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.8),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              photo.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${photo.dateHuman} • ${photo.sizeHuman}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            downloadUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              final percent = progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null;
              return Center(
                child: CircularProgressIndicator(
                  value: percent,
                  color: AppTheme.cyberCyan,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.broken_image_rounded, size: 64, color: AppTheme.textMuted),
                  SizedBox(height: 12),
                  Text('No se pudo cargar la imagen', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
