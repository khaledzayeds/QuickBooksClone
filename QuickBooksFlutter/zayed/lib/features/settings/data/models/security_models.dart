class SecurityPermissionModel {
  const SecurityPermissionModel({required this.key, required this.area, required this.name, this.description});

  final String key;
  final String area;
  final String name;
  final String? description;

  factory SecurityPermissionModel.fromJson(Map<String, dynamic> json) => SecurityPermissionModel(
        key: json['key']?.toString() ?? '',
        area: json['area']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString(),
      );
}

class SecurityRoleModel {
  const SecurityRoleModel({
    required this.id,
    required this.roleKey,
    required this.name,
    this.description,
    required this.isSystem,
    required this.isActive,
    required this.permissions,
  });

  final String id;
  final String roleKey;
  final String name;
  final String? description;
  final bool isSystem;
  final bool isActive;
  final List<String> permissions;

  factory SecurityRoleModel.fromJson(Map<String, dynamic> json) => SecurityRoleModel(
        id: json['id']?.toString() ?? '',
        roleKey: json['roleKey']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString(),
        isSystem: json['isSystem'] == true,
        isActive: json['isActive'] != false,
        permissions: (json['permissions'] as List? ?? const []).map((item) => item.toString()).toList(),
      );
}

class SecurityUserRoleModel {
  const SecurityUserRoleModel({required this.roleId, required this.roleKey, required this.name});

  final String roleId;
  final String roleKey;
  final String name;

  factory SecurityUserRoleModel.fromJson(Map<String, dynamic> json) => SecurityUserRoleModel(
        roleId: json['roleId']?.toString() ?? json['id']?.toString() ?? '',
        roleKey: json['roleKey']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
      );
}

class SecurityUserModel {
  const SecurityUserModel({
    required this.id,
    required this.userName,
    required this.displayName,
    this.email,
    required this.isActive,
    this.lastLoginAtIso,
    required this.roles,
    required this.effectivePermissions,
  });

  final String id;
  final String userName;
  final String displayName;
  final String? email;
  final bool isActive;
  final String? lastLoginAtIso;
  final List<SecurityUserRoleModel> roles;
  final List<String> effectivePermissions;

  factory SecurityUserModel.fromJson(Map<String, dynamic> json) => SecurityUserModel(
        id: json['id']?.toString() ?? '',
        userName: json['userName']?.toString() ?? '',
        displayName: json['displayName']?.toString() ?? '',
        email: json['email']?.toString(),
        isActive: json['isActive'] != false,
        lastLoginAtIso: json['lastLoginAt']?.toString(),
        roles: (json['roles'] as List? ?? const []).whereType<Map<String, dynamic>>().map(SecurityUserRoleModel.fromJson).toList(),
        effectivePermissions: (json['effectivePermissions'] as List? ?? const []).map((item) => item.toString()).toList(),
      );
}

class SecurityRoleListResult {
  const SecurityRoleListResult({required this.items, required this.totalCount, required this.page, required this.pageSize});

  final List<SecurityRoleModel> items;
  final int totalCount;
  final int page;
  final int pageSize;

  factory SecurityRoleListResult.fromJson(Map<String, dynamic> json) => SecurityRoleListResult(
        items: (json['items'] as List? ?? const []).whereType<Map<String, dynamic>>().map(SecurityRoleModel.fromJson).toList(),
        totalCount: _int(json['totalCount']),
        page: _int(json['page'], fallback: 1),
        pageSize: _int(json['pageSize'], fallback: 25),
      );
}

class SecurityUserListResult {
  const SecurityUserListResult({required this.items, required this.totalCount, required this.page, required this.pageSize});

  final List<SecurityUserModel> items;
  final int totalCount;
  final int page;
  final int pageSize;

  factory SecurityUserListResult.fromJson(Map<String, dynamic> json) => SecurityUserListResult(
        items: (json['items'] as List? ?? const []).whereType<Map<String, dynamic>>().map(SecurityUserModel.fromJson).toList(),
        totalCount: _int(json['totalCount']),
        page: _int(json['page'], fallback: 1),
        pageSize: _int(json['pageSize'], fallback: 25),
      );
}

int _int(dynamic value, {int fallback = 0}) => value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? fallback;
