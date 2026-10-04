import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../models/server_config.dart';
import '../models/drive_file.dart';
import '../services/api_service.dart';

class DriveProvider extends ChangeNotifier {
  String _currentPath = '';
  String _parentPath = '';
  List<DriveItem> _items = [];
  List<PhotoItem> _photos = [];
  bool _isLoading = false;
  bool _isUploading = false;
  String? _errorMessage;
  String? _uploadStatusText;

  String get currentPath => _currentPath;
  String get parentPath => _parentPath;
  List<DriveItem> get items => _items;
  List<PhotoItem> get photos => _photos;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;
  String? get uploadStatusText => _uploadStatusText;

  /// Loads files in specified directory
  Future<void> loadFiles(ServerConfig config, String username, [String path = '']) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.getDriveFiles(config, username, path);
      _items = res['items'] as List<DriveItem>;
      _currentPath = res['current_path'] as String;
      _parentPath = res['parent_path'] as String;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  /// Refreshes current directory files
  Future<void> refreshCurrentDir(ServerConfig config, String username) async {
    await loadFiles(config, username, _currentPath);
  }

  /// Navigates up one folder level
  Future<void> navigateUp(ServerConfig config, String username) async {
    if (_currentPath.isEmpty) return;
    await loadFiles(config, username, _parentPath);
  }

  /// Loads all photos for the Photos tab
  Future<void> loadPhotos(ServerConfig config, String username) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _photos = await ApiService.getDrivePhotos(config, username);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  /// Picks files from device and uploads to current directory
  Future<bool> pickAndUploadFiles({
    required ServerConfig config,
    required String username,
    FileType fileType = FileType.any,
  }) async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        withData: true,
        type: fileType,
      );

      if (result == null || result.files.isEmpty) {
        return false;
      }

      _isUploading = true;
      notifyListeners();

      int uploadedCount = 0;
      final targetFolder = (fileType == FileType.image && _currentPath.isEmpty) ? 'Fotos' : _currentPath;

      for (var f in result.files) {
        final bytes = f.bytes;
        final name = f.name;

        if (bytes != null) {
          _uploadStatusText = 'Subiendo $name (${uploadedCount + 1}/${result.files.length})...';
          notifyListeners();

          await ApiService.uploadFile(
            config: config,
            username: username,
            relDir: targetFolder,
            filename: name,
            bytes: bytes,
          );
          uploadedCount++;
        }
      }

      _isUploading = false;
      _uploadStatusText = null;

      // Refresh both views
      await refreshCurrentDir(config, username);
      await loadPhotos(config, username);
      return true;
    } catch (e) {
      _isUploading = false;
      _uploadStatusText = null;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Creates a new folder in current directory
  Future<bool> createFolder(ServerConfig config, String username, String folderName) async {
    try {
      await ApiService.createFolder(config, username, _currentPath, folderName);
      await refreshCurrentDir(config, username);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Deletes a file or directory
  Future<bool> deleteItem(ServerConfig config, String username, String relPath) async {
    try {
      await ApiService.deleteItem(config, username, relPath);
      await refreshCurrentDir(config, username);
      await loadPhotos(config, username);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Renames an item
  Future<bool> renameItem(ServerConfig config, String username, String relPath, String newName) async {
    try {
      await ApiService.renameItem(config, username, relPath, newName);
      await refreshCurrentDir(config, username);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
