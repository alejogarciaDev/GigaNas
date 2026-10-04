import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/server_config.dart';
import '../models/auth_user.dart';
import '../models/drive_file.dart';
import '../models/user_quota.dart';
import '../models/nas_status.dart';

class ApiService {
  static const Duration defaultTimeout = Duration(seconds: 10);

  /// Tests connection to NAS server and returns latency in milliseconds
  static Future<Map<String, dynamic>> testConnection(ServerConfig config) async {
    final stopwatch = Stopwatch()..start();
    final url = Uri.parse('${config.baseUrl}/api/health');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'latency_ms': stopwatch.elapsedMilliseconds,
          'data': data,
          'message': 'Conexión exitosa al NAS (${stopwatch.elapsedMilliseconds}ms)'
        };
      } else {
        return {
          'success': false,
          'message': 'El servidor respondió con código HTTP ${response.statusCode}'
        };
      }
    } on TimeoutException {
      return {'success': false, 'message': 'Tiempo de espera agotado. Revisa la IP y el puerto.'};
    } catch (e) {
      return {'success': false, 'message': 'No se pudo conectar al NAS: ${e.toString()}'};
    }
  }

  /// Authenticates NAS user credentials
  static Future<AuthUser> login(ServerConfig config, String username, String password) async {
    final url = Uri.parse('${config.baseUrl}/api/auth/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    ).timeout(defaultTimeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'] ?? '';
      final isAdmin = data['is_admin'] ?? false;
      final quota = data['quota'] as Map<String, dynamic>?;
      return AuthUser.fromJson(data, token, isAdmin, quota);
    } else {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(data['detail'] ?? data['error'] ?? 'Error de autenticación');
    }
  }

  /// Lists files and directories in user's partition
  static Future<Map<String, dynamic>> getDriveFiles(ServerConfig config, String username, [String path = '']) async {
    final url = Uri.parse('${config.baseUrl}/api/drive/files').replace(queryParameters: {
      'username': username,
      'path': path,
    });

    final response = await http.get(url).timeout(defaultTimeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final items = (data['items'] as List<dynamic>?)
              ?.map((item) => DriveItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];
      return {
        'items': items,
        'current_path': data['current_path'] ?? '',
        'parent_path': data['parent_path'] ?? '',
      };
    } else {
      throw Exception('Error al cargar archivos de GigaNas Drive');
    }
  }

  /// Lists all photos in user's partition
  static Future<List<PhotoItem>> getDrivePhotos(ServerConfig config, String username) async {
    final url = Uri.parse('${config.baseUrl}/api/drive/photos').replace(queryParameters: {
      'username': username,
    });

    final response = await http.get(url).timeout(defaultTimeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      return data.map((item) => PhotoItem.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Error al cargar fotos de la galería');
    }
  }

  /// Uploads a file or photo to user's partition
  static Future<Map<String, dynamic>> uploadFile({
    required ServerConfig config,
    required String username,
    required String relDir,
    required String filename,
    required List<int> bytes,
  }) async {
    final url = Uri.parse('${config.baseUrl}/api/drive/upload');
    final request = http.MultipartRequest('POST', url);

    request.fields['username'] = username;
    request.fields['path'] = relDir;
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ),
    );

    final streamedResponse = await request.send().timeout(const Duration(minutes: 5));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(data['detail'] ?? data['error'] ?? 'Error al subir archivo');
    }
  }

  /// Creates a new directory in user partition
  static Future<void> createFolder(ServerConfig config, String username, String relDir, String name) async {
    final url = Uri.parse('${config.baseUrl}/api/drive/folder');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'path': relDir, 'name': name}),
    ).timeout(defaultTimeout);

    if (response.statusCode != 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(data['detail'] ?? data['error'] ?? 'Error al crear carpeta');
    }
  }

  /// Deletes a file or directory
  static Future<void> deleteItem(ServerConfig config, String username, String relPath) async {
    final url = Uri.parse('${config.baseUrl}/api/drive/delete').replace(queryParameters: {
      'username': username,
      'path': relPath,
    });

    final response = await http.delete(url).timeout(defaultTimeout);
    if (response.statusCode != 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(data['detail'] ?? data['error'] ?? 'Error al eliminar');
    }
  }

  /// Renames a file or directory
  static Future<void> renameItem(ServerConfig config, String username, String relPath, String newName) async {
    final url = Uri.parse('${config.baseUrl}/api/drive/rename');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'path': relPath, 'new_name': newName}),
    ).timeout(defaultTimeout);

    if (response.statusCode != 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(data['detail'] ?? data['error'] ?? 'Error al renombrar');
    }
  }

  /// Fetches real-time quota information
  static Future<UserQuota> getQuota(ServerConfig config, String username) async {
    final url = Uri.parse('${config.baseUrl}/api/drive/quota').replace(queryParameters: {
      'username': username,
    });

    final response = await http.get(url).timeout(defaultTimeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return UserQuota.fromJson(data);
    } else {
      throw Exception('Error al obtener cuota de almacenamiento');
    }
  }

  /// Returns URL for photo thumbnail
  static String getThumbnailUrl(ServerConfig config, String username, String relPath) {
    return '${config.baseUrl}/api/drive/thumbnail?username=${Uri.encodeComponent(username)}&path=${Uri.encodeComponent(relPath)}';
  }

  /// Returns URL for file download
  static String getDownloadUrl(ServerConfig config, String username, String relPath) {
    return '${config.baseUrl}/api/drive/download?username=${Uri.encodeComponent(username)}&path=${Uri.encodeComponent(relPath)}';
  }

  // ==========================================
  // Admin Endpoints
  // ==========================================

  /// Gets real-time NAS status (CPU, RAM, ARC hit rate, Uptime)
  static Future<NasSystemStatus> getSystemStatus(ServerConfig config) async {
    final url = Uri.parse('${config.baseUrl}/api/system/status');
    final response = await http.get(url).timeout(defaultTimeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return NasSystemStatus.fromJson(data);
    } else {
      throw Exception('Error al obtener estado del sistema');
    }
  }

  /// Gets physical disks with SMART and temperature
  static Future<List<dynamic>> getDisks(ServerConfig config) async {
    final url = Uri.parse('${config.baseUrl}/api/storage/disks');
    final response = await http.get(url).timeout(defaultTimeout);
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    }
    return [];
  }

  /// Gets ZFS pools
  static Future<List<dynamic>> getPools(ServerConfig config) async {
    final url = Uri.parse('${config.baseUrl}/api/storage/pools');
    final response = await http.get(url).timeout(defaultTimeout);
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    }
    return [];
  }

  /// Gets all system accounts (Admin only)
  static Future<List<dynamic>> getUsers(ServerConfig config) async {
    final url = Uri.parse('${config.baseUrl}/api/accounts/users');
    final response = await http.get(url).timeout(defaultTimeout);
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    }
    return [];
  }

  /// Toggles user status (Activo / Suspendido)
  static Future<void> toggleUser(ServerConfig config, String username) async {
    final url = Uri.parse('${config.baseUrl}/api/accounts/users/$username/toggle');
    final response = await http.post(url).timeout(defaultTimeout);
    if (response.statusCode != 200) {
      throw Exception('Error al cambiar estado del usuario');
    }
  }

  /// Creates a new user in the NAS
  static Future<void> createUser(ServerConfig config, Map<String, dynamic> userData) async {
    final url = Uri.parse('${config.baseUrl}/api/accounts/users');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    ).timeout(defaultTimeout);

    if (response.statusCode != 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(data['error'] ?? 'Error al crear usuario');
    }
  }

  /// Runs GigaNas kernel & storage optimization
  static Future<String> applyOptimization(ServerConfig config) async {
    final url = Uri.parse('${config.baseUrl}/api/optimizer/apply');
    final response = await http.post(url).timeout(defaultTimeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['message'] ?? 'Optimización completada con éxito';
    }
    throw Exception('Error al aplicar optimización');
  }

  /// Sends reboot command to NAS
  static Future<void> rebootSystem(ServerConfig config) async {
    final url = Uri.parse('${config.baseUrl}/api/system/reboot');
    await http.post(url).timeout(defaultTimeout);
  }

  /// Sends shutdown command to NAS
  static Future<void> shutdownSystem(ServerConfig config) async {
    final url = Uri.parse('${config.baseUrl}/api/system/shutdown');
    await http.post(url).timeout(defaultTimeout);
  }
}
