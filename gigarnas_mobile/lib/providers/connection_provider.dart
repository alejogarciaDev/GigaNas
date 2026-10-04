import 'package:flutter/foundation.dart';
import '../models/server_config.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

enum ConnectionStateStatus { idle, testing, connected, failed }

class ConnectionProvider extends ChangeNotifier {
  ServerConfig _config = ServerConfig(host: '127.0.0.1', port: 8080, protocol: 'http');
  ConnectionStateStatus _status = ConnectionStateStatus.idle;
  int? _latencyMs;
  String? _errorMessage;
  String? _serverVersion;
  String? _serverHostname;

  ServerConfig get config => _config;
  ConnectionStateStatus get status => _status;
  int? get latencyMs => _latencyMs;
  String? get errorMessage => _errorMessage;
  String? get serverVersion => _serverVersion;
  String? get serverHostname => _serverHostname;
  bool get isConnected => _status == ConnectionStateStatus.connected;

  ConnectionProvider() {
    _loadSavedConfig();
  }

  Future<void> _loadSavedConfig() async {
    final saved = await StorageService.getServerConfig();
    if (saved != null) {
      _config = saved;
      notifyListeners();
    }
  }

  void updateConfig({String? host, int? port, String? protocol, String? name}) {
    _config = _config.copyWith(
      host: host,
      port: port,
      protocol: protocol,
      name: name,
    );
    _status = ConnectionStateStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> testConnection() async {
    _status = ConnectionStateStatus.testing;
    _errorMessage = null;
    notifyListeners();

    final res = await ApiService.testConnection(_config);
    if (res['success'] == true) {
      _status = ConnectionStateStatus.connected;
      _latencyMs = res['latency_ms'] as int?;
      final data = res['data'] as Map<String, dynamic>?;
      _serverVersion = data?['version'] ?? '1.0.0-PRO';
      _serverHostname = data?['hostname'] ?? 'gigarnas';
      await StorageService.saveServerConfig(_config);
      notifyListeners();
      return true;
    } else {
      _status = ConnectionStateStatus.failed;
      _errorMessage = res['message'] ?? 'Error desconocido al conectar';
      notifyListeners();
      return false;
    }
  }
}
