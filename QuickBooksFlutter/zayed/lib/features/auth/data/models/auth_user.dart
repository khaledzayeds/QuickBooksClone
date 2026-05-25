// auth_user.dart

class AuthUser {
  const AuthUser({
    required this.id,
    required this.userName,
    required this.displayName,
    required this.token,
    required this.expiresAt,
    this.effectivePermissions = const [],
    this.roles = const [],
  });

  final String id;
  final String userName;
  final String displayName;
  final String token;
  final DateTime expiresAt;
  final List<String> effectivePermissions;
  final List<String> roles;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool hasPermission(String perm) => effectivePermissions.contains(perm);

  factory AuthUser.fromLoginResponse(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    final token = json['token']?.toString() ?? '';
    return AuthUser(
      id: user['id']?.toString() ?? '',
      userName: user['userName']?.toString() ?? '',
      displayName:
          user['displayName']?.toString() ?? user['userName']?.toString() ?? '',
      token: token,
      expiresAt:
          DateTime.tryParse(json['expiresAt']?.toString() ?? '') ??
          DateTime.now().add(const Duration(hours: 8)),
      effectivePermissions:
          (user['effectivePermissions'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList(),
      roles: (user['roles'] as List<dynamic>? ?? [])
          .map((e) {
            if (e is Map<String, dynamic>) {
              return e['roleKey']?.toString() ?? e['name']?.toString() ?? '';
            }
            return e.toString();
          })
          .where((e) => e.isNotEmpty)
          .toList(),
    );
  }
}
