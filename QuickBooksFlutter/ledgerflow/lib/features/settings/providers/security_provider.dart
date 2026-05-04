import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/security_models.dart';
import '../data/security_repository.dart';

final securityRepositoryProvider = Provider<SecurityRepository>((ref) => SecurityRepository());

class SecurityState {
  const SecurityState({
    this.loading = false,
    this.working = false,
    this.users = const [],
    this.roles = const [],
    this.permissions = const [],
    this.errorMessage,
    this.successMessage,
  });

  final bool loading;
  final bool working;
  final List<SecurityUserModel> users;
  final List<SecurityRoleModel> roles;
  final List<SecurityPermissionModel> permissions;
  final String? errorMessage;
  final String? successMessage;

  SecurityState copyWith({
    bool? loading,
    bool? working,
    List<SecurityUserModel>? users,
    List<SecurityRoleModel>? roles,
    List<SecurityPermissionModel>? permissions,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return SecurityState(
      loading: loading ?? this.loading,
      working: working ?? this.working,
      users: users ?? this.users,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage: clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }
}

class SecurityNotifier extends Notifier<SecurityState> {
  late final SecurityRepository _repository;

  @override
  SecurityState build() {
    _repository = ref.watch(securityRepositoryProvider);
    Future.microtask(load);
    return const SecurityState(loading: true);
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true, clearSuccess: true);
    try {
      final results = await Future.wait([
        _repository.listUsers(),
        _repository.listRoles(),
        _repository.listPermissions(),
      ]);

      state = state.copyWith(
        loading: false,
        users: (results[0] as SecurityUserListResult).items,
        roles: (results[1] as SecurityRoleListResult).items,
        permissions: results[2] as List<SecurityPermissionModel>,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(loading: false, errorMessage: error.toString());
    }
  }

  Future<void> createUser({required String userName, required String displayName, String? email, required List<String> roleIds}) async {
    state = state.copyWith(working: true, clearError: true, clearSuccess: true);
    try {
      final user = await _repository.createUser(userName: userName, displayName: displayName, email: email, roleIds: roleIds);
      state = state.copyWith(
        working: false,
        users: [user, ...state.users],
        successMessage: 'User created: ${user.userName}',
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(working: false, errorMessage: error.toString());
    }
  }

  Future<void> setUserActive(SecurityUserModel user, bool isActive) async {
    state = state.copyWith(working: true, clearError: true, clearSuccess: true);
    try {
      await _repository.setUserActive(user.id, isActive);
      final users = state.users.map((item) {
        if (item.id != user.id) return item;
        return SecurityUserModel(
          id: item.id,
          userName: item.userName,
          displayName: item.displayName,
          email: item.email,
          isActive: isActive,
          lastLoginAtIso: item.lastLoginAtIso,
          roles: item.roles,
          effectivePermissions: item.effectivePermissions,
        );
      }).toList();
      state = state.copyWith(working: false, users: users, successMessage: 'User status updated.', clearError: true);
    } catch (error) {
      state = state.copyWith(working: false, errorMessage: error.toString());
    }
  }

  Future<void> replaceUserRoles(SecurityUserModel user, List<String> roleIds) async {
    state = state.copyWith(working: true, clearError: true, clearSuccess: true);
    try {
      final updated = await _repository.replaceUserRoles(user.id, roleIds);
      final users = state.users.map((item) => item.id == updated.id ? updated : item).toList();
      state = state.copyWith(working: false, users: users, successMessage: 'User roles updated.', clearError: true);
    } catch (error) {
      state = state.copyWith(working: false, errorMessage: error.toString());
    }
  }

  Future<void> createRole({required String roleKey, required String name, String? description, required List<String> permissions}) async {
    state = state.copyWith(working: true, clearError: true, clearSuccess: true);
    try {
      final role = await _repository.createRole(roleKey: roleKey, name: name, description: description, permissions: permissions);
      state = state.copyWith(
        working: false,
        roles: [role, ...state.roles],
        successMessage: 'Role created: ${role.name}',
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(working: false, errorMessage: error.toString());
    }
  }

  Future<void> replaceRolePermissions(SecurityRoleModel role, List<String> permissions) async {
    state = state.copyWith(working: true, clearError: true, clearSuccess: true);
    try {
      final updated = await _repository.replaceRolePermissions(role.id, permissions);
      final roles = state.roles.map((item) => item.id == updated.id ? updated : item).toList();
      state = state.copyWith(working: false, roles: roles, successMessage: 'Role permissions updated.', clearError: true);
    } catch (error) {
      state = state.copyWith(working: false, errorMessage: error.toString());
    }
  }
}

final securityProvider = NotifierProvider<SecurityNotifier, SecurityState>(SecurityNotifier.new);
