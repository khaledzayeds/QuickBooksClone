import '../../../core/api/api_client.dart';
import 'models/security_models.dart';

class SecurityRepository {
  Future<List<SecurityPermissionModel>> listPermissions() async {
    final response = await ApiClient.instance.get<List<dynamic>>('/api/security/permissions');
    final data = response.data ?? const [];
    return data.whereType<Map<String, dynamic>>().map(SecurityPermissionModel.fromJson).toList();
  }

  Future<SecurityRoleListResult> listRoles({String? search, bool includeInactive = false}) async {
    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      '/api/security/roles',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        'includeInactive': includeInactive,
        'page': 1,
        'pageSize': 100,
      },
    );
    return SecurityRoleListResult.fromJson(response.data ?? const {});
  }

  Future<SecurityUserListResult> listUsers({String? search, bool includeInactive = false}) async {
    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      '/api/security/users',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        'includeInactive': includeInactive,
        'page': 1,
        'pageSize': 100,
      },
    );
    return SecurityUserListResult.fromJson(response.data ?? const {});
  }

  Future<SecurityUserModel> createUser({
    required String userName,
    required String displayName,
    String? email,
    required List<String> roleIds,
  }) async {
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      '/api/security/users',
      data: {
        'userName': userName,
        'displayName': displayName,
        'email': email,
        'roleIds': roleIds,
      },
    );
    return SecurityUserModel.fromJson(response.data ?? const {});
  }

  Future<void> setUserActive(String id, bool isActive) async {
    await ApiClient.instance.patch<void>(
      '/api/security/users/$id/active',
      data: {'isActive': isActive},
    );
  }

  Future<SecurityUserModel> replaceUserRoles(String id, List<String> roleIds) async {
    final response = await ApiClient.instance.put<Map<String, dynamic>>(
      '/api/security/users/$id/roles',
      data: {'roleIds': roleIds},
    );
    return SecurityUserModel.fromJson(response.data ?? const {});
  }

  Future<SecurityRoleModel> createRole({
    required String roleKey,
    required String name,
    String? description,
    required List<String> permissions,
  }) async {
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      '/api/security/roles',
      data: {
        'roleKey': roleKey,
        'name': name,
        'description': description,
        'permissions': permissions,
      },
    );
    return SecurityRoleModel.fromJson(response.data ?? const {});
  }

  Future<SecurityRoleModel> replaceRolePermissions(String id, List<String> permissions) async {
    final response = await ApiClient.instance.put<Map<String, dynamic>>(
      '/api/security/roles/$id/permissions',
      data: {'permissions': permissions},
    );
    return SecurityRoleModel.fromJson(response.data ?? const {});
  }
}
