import 'user_quota.dart';

class AuthUser {
  final String username;
  final String fullName;
  final String email;
  final String role; // 'Administrador', 'Usuario Estándar', 'Solo Lectura'
  final String status;
  final int quotaGb;
  final List<String> appsAuthorized;
  final bool smbAccess;
  final bool isAdmin;
  final String token;
  final UserQuota? quota;

  AuthUser({
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
    required this.quotaGb,
    required this.appsAuthorized,
    required this.smbAccess,
    required this.isAdmin,
    required this.token,
    this.quota,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json, String token, bool isAdmin, [Map<String, dynamic>? quotaJson]) {
    final userMap = json['user'] is Map<String, dynamic> ? json['user'] : json;
    return AuthUser(
      username: userMap['username'] ?? '',
      fullName: userMap['full_name'] ?? userMap['username'] ?? '',
      email: userMap['email'] ?? '',
      role: userMap['role'] ?? 'Usuario Estándar',
      status: userMap['status'] ?? 'Activo',
      quotaGb: userMap['quota_gb'] ?? 0,
      appsAuthorized: (userMap['apps_authorized'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      smbAccess: userMap['smb_access'] ?? false,
      isAdmin: isAdmin,
      token: token,
      quota: quotaJson != null ? UserQuota.fromJson(quotaJson) : null,
    );
  }

  bool get hasDriveAccess => isAdmin || quotaGb > 0 || role == 'Usuario Estándar';

  AuthUser copyWith({
    UserQuota? quota,
  }) {
    return AuthUser(
      username: username,
      fullName: fullName,
      email: email,
      role: role,
      status: status,
      quotaGb: quotaGb,
      appsAuthorized: appsAuthorized,
      smbAccess: smbAccess,
      isAdmin: isAdmin,
      token: token,
      quota: quota ?? this.quota,
    );
  }
}
