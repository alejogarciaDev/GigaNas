class DriveItem {
  final String name;
  final String path;
  final bool isDir;
  final int size;
  final String sizeHuman;
  final int modifiedTimestamp;
  final String modifiedHuman;
  final String mimeType;
  final String extension;
  final bool isPhoto;
  final bool isVideo;
  final bool isDocument;

  DriveItem({
    required this.name,
    required this.path,
    required this.isDir,
    required this.size,
    required this.sizeHuman,
    required this.modifiedTimestamp,
    required this.modifiedHuman,
    required this.mimeType,
    required this.extension,
    required this.isPhoto,
    required this.isVideo,
    required this.isDocument,
  });

  factory DriveItem.fromJson(Map<String, dynamic> json) {
    return DriveItem(
      name: json['name'] ?? '',
      path: json['path'] ?? '',
      isDir: json['is_dir'] ?? false,
      size: json['size'] ?? 0,
      sizeHuman: json['size_human'] ?? '--',
      modifiedTimestamp: json['modified_timestamp'] ?? 0,
      modifiedHuman: json['modified_human'] ?? '--',
      mimeType: json['mime_type'] ?? '',
      extension: json['extension'] ?? '',
      isPhoto: json['is_photo'] ?? false,
      isVideo: json['is_video'] ?? false,
      isDocument: json['is_document'] ?? false,
    );
  }
}

class PhotoItem {
  final String name;
  final String path;
  final int size;
  final String sizeHuman;
  final int modifiedTimestamp;
  final String dateIso;
  final String dateHuman;
  final bool isVideo;
  final bool isPhoto;
  final String extension;

  PhotoItem({
    required this.name,
    required this.path,
    required this.size,
    required this.sizeHuman,
    required this.modifiedTimestamp,
    required this.dateIso,
    required this.dateHuman,
    required this.isVideo,
    required this.isPhoto,
    required this.extension,
  });

  factory PhotoItem.fromJson(Map<String, dynamic> json) {
    return PhotoItem(
      name: json['name'] ?? '',
      path: json['path'] ?? '',
      size: json['size'] ?? 0,
      sizeHuman: json['size_human'] ?? '',
      modifiedTimestamp: json['modified_timestamp'] ?? 0,
      dateIso: json['date_iso'] ?? '',
      dateHuman: json['date_human'] ?? '',
      isVideo: json['is_video'] ?? false,
      isPhoto: json['is_photo'] ?? true,
      extension: json['extension'] ?? '',
    );
  }
}
