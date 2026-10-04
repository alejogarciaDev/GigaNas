import 'package:flutter/foundation.dart';
import '../models/auth_user.dart';
import '../models/server_config.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

enum AuthStatus { unauthenticated, authenticating, authenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthUser? _user;
  AuthStatus _status = AuthStatus.unauthenticated;
  String? _errorMessage;

  AuthUser? get user => _user;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _status == AuthStatus.authenticated && _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get hasDriveAccess => _user?.hasDriveAccess ?? false;

  Future<bool> login(ServerConfig config, String username, String password, [bool remember = true]) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await ApiService.login(config, username, password);
      _user = user;
      _status = AuthStatus.authenticated;

      if (remember) {
        await StorageService.saveLastUsername(username);
        await StorageService.saveToken(user.token);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshQuota(ServerConfig config) async {
    if (_user == null) return;
    try {
      final quota = await ApiService.getQuota(config, _user!.username);
      _user = _user!.copyWith(quota: quota);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> logout() async {
    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    await StorageService.clearAuth();
    notifyListeners();
  }
}
