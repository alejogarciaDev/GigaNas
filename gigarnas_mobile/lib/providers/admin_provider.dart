import 'package:flutter/foundation.dart';
import '../models/server_config.dart';
import '../models/nas_status.dart';
import '../services/api_service.dart';

class AdminProvider extends ChangeNotifier {
  NasSystemStatus? _status;
  List<dynamic> _disks = [];
  List<dynamic> _pools = [];
  List<dynamic> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  NasSystemStatus? get status => _status;
  List<dynamic> get disks => _disks;
  List<dynamic> get pools => _pools;
  List<dynamic> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDashboardData(ServerConfig config) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        ApiService.getSystemStatus(config),
        ApiService.getDisks(config),
        ApiService.getPools(config),
        ApiService.getUsers(config),
      ]);

      _status = results[0] as NasSystemStatus;
      _disks = results[1] as List<dynamic>;
      _pools = results[2] as List<dynamic>;
      _users = results[3] as List<dynamic>;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> toggleUserStatus(ServerConfig config, String username) async {
    try {
      await ApiService.toggleUser(config, username);
      _users = await ApiService.getUsers(config);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> createNasUser(ServerConfig config, Map<String, dynamic> userData) async {
    try {
      await ApiService.createUser(config, userData);
      _users = await ApiService.getUsers(config);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<String> applyOptimization(ServerConfig config) async {
    try {
      final msg = await ApiService.applyOptimization(config);
      await fetchDashboardData(config);
      return msg;
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> rebootServer(ServerConfig config) async {
    await ApiService.rebootSystem(config);
  }

  Future<void> shutdownServer(ServerConfig config) async {
    await ApiService.shutdownSystem(config);
  }
}
