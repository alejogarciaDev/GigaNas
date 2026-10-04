import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/server_config.dart';

class StorageService {
  static const _keyServerConfig = 'gigarnas_server_config';
  static const _keyLastUsername = 'gigarnas_last_username';
  static const _keySessionToken = 'gigarnas_session_token';

  static Future<void> saveServerConfig(ServerConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerConfig, jsonEncode(config.toJson()));
  }

  static Future<ServerConfig?> getServerConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyServerConfig);
    if (raw == null) return null;
    try {
      return ServerConfig.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveLastUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastUsername, username);
  }

  static Future<String?> getLastUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastUsername);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySessionToken, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySessionToken);
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySessionToken);
  }
}
