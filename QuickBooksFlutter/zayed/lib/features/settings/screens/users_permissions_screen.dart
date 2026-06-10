import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/security_models.dart';
import '../providers/security_provider.dart';

class UsersPermissionsScreen extends ConsumerWidget {
  const UsersPermissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(securityProvider);
    final notifier = ref.read(securityProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = _SecurityText.of(context);

    ref.listen(securityProvider, (previous, next) {
      if (next.successMessage != null &&
          previous?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.successMessage!)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(text.title),
        actions: [
          IconButton(
            tooltip: text.refresh,
            onPressed: notifier.load,
            icon: const Icon(Icons.refresh),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: FilledButton.icon(
              onPressed: state.working
                  ? null
                  : () => _showCreateUserDialog(context, notifier, state.roles),
              icon: const Icon(Icons.person_add_outlined),
              label: Text(text.addUser),
            ),
          ),
        ],
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  text.heading,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  text.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _ErrorBanner(message: state.errorMessage!),
                ],
                const SizedBox(height: 24),
                _StatusBanner(
                  users: state.users.length,
                  roles: state.roles.length,
                  permissions: state.permissions.length,
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 980;
                    final left = Column(
                      children: [
                        _UsersCard(
                          users: state.users,
                          roles: state.roles,
                          working: state.working,
                          onToggleActive: notifier.setUserActive,
                          onSetPassword: (user) =>
                              _showSetPasswordDialog(context, notifier, user),
                          onEditRoles: (user) => _showEditUserRolesDialog(
                            context,
                            notifier,
                            user,
                            state.roles,
                          ),
                        ),
                      ],
                    );
                    final right = Column(
                      children: [
                        _RolesCard(
                          roles: state.roles,
                          permissions: state.permissions,
                          working: state.working,
                          onCreateRole: () => _showCreateRoleDialog(
                            context,
                            notifier,
                            state.permissions,
                          ),
                          onEditPermissions: (role) =>
                              _showEditRolePermissionsDialog(
                                context,
                                notifier,
                                role,
                                state.permissions,
                              ),
                        ),
                        const SizedBox(height: 16),
                        _PermissionsCard(permissions: state.permissions),
                      ],
                    );

                    if (!wide) {
                      return Column(
                        children: [left, const SizedBox(height: 16), right],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: left),
                        const SizedBox(width: 16),
                        Expanded(child: right),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                _SecurityNotesCard(),
              ],
            ),
    );
  }

  static Future<void> _showCreateUserDialog(
    BuildContext context,
    SecurityNotifier notifier,
    List<SecurityRoleModel> roles,
  ) async {
    final userName = TextEditingController();
    final displayName = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final selectedRoleIds = <String>{};

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(_SecurityText.of(context).addUser),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: userName,
                    decoration: InputDecoration(
                      labelText: _SecurityText.of(context).username,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: displayName,
                    decoration: InputDecoration(
                      labelText: _SecurityText.of(context).displayName,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: email,
                    decoration: InputDecoration(
                      labelText: _SecurityText.of(context).email,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: _SecurityText.of(context).initialPassword,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      _SecurityText.of(context).roles,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  ...roles.map(
                    (role) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: selectedRoleIds.contains(role.id),
                      onChanged: (value) => setState(() {
                        if (value == true) {
                          selectedRoleIds.add(role.id);
                        } else {
                          selectedRoleIds.remove(role.id);
                        }
                      }),
                      title: Text(role.name),
                      subtitle: Text(role.roleKey),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(_SecurityText.of(context).cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(_SecurityText.of(context).create),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      await notifier.createUser(
        userName: userName.text,
        displayName: displayName.text,
        email: email.text.isEmpty ? null : email.text,
        initialPassword: password.text,
        roleIds: selectedRoleIds.toList(),
      );
    }
    userName.dispose();
    displayName.dispose();
    email.dispose();
    password.dispose();
  }

  static Future<void> _showSetPasswordDialog(
    BuildContext context,
    SecurityNotifier notifier,
    SecurityUserModel user,
  ) async {
    final password = TextEditingController();
    final confirm = TextEditingController();
    String? error;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(_SecurityText.of(context).setPasswordFor(user.userName)),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: _SecurityText.of(context).newPassword,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirm,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: _SecurityText.of(context).confirmPassword,
                    border: OutlineInputBorder(),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(_SecurityText.of(context).cancel),
            ),
            FilledButton(
              onPressed: () {
                final value = password.text.trim();
                if (value.length < 4) {
                  setState(() => error = _SecurityText.of(context).passwordMin);
                  return;
                }
                if (value != confirm.text.trim()) {
                  setState(
                    () => error = _SecurityText.of(context).passwordMismatch,
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              child: Text(_SecurityText.of(context).savePassword),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      await notifier.setUserPassword(user, password.text.trim());
    }
    password.dispose();
    confirm.dispose();
  }

  static Future<void> _showEditUserRolesDialog(
    BuildContext context,
    SecurityNotifier notifier,
    SecurityUserModel user,
    List<SecurityRoleModel> roles,
  ) async {
    final selectedRoleIds = user.roles.map((role) => role.roleId).toSet();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(_SecurityText.of(context).rolesFor(user.userName)),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: roles
                    .map(
                      (role) => CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: selectedRoleIds.contains(role.id),
                        onChanged: (value) => setState(() {
                          if (value == true) {
                            selectedRoleIds.add(role.id);
                          } else {
                            selectedRoleIds.remove(role.id);
                          }
                        }),
                        title: Text(role.name),
                        subtitle: Text(role.roleKey),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(_SecurityText.of(context).cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(_SecurityText.of(context).save),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      await notifier.replaceUserRoles(user, selectedRoleIds.toList());
    }
  }

  static Future<void> _showCreateRoleDialog(
    BuildContext context,
    SecurityNotifier notifier,
    List<SecurityPermissionModel> permissions,
  ) async {
    final roleKey = TextEditingController();
    final name = TextEditingController();
    final description = TextEditingController();
    final selected = <String>{};
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(_SecurityText.of(context).createRole),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: roleKey,
                    decoration: InputDecoration(
                      labelText: _SecurityText.of(context).roleKey,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: name,
                    decoration: InputDecoration(
                      labelText: _SecurityText.of(context).name,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: description,
                    decoration: InputDecoration(
                      labelText: _SecurityText.of(context).roleDescription,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      _SecurityText.of(context).permissions,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  ...permissions.map(
                    (permission) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: selected.contains(permission.key),
                      onChanged: (value) => setState(() {
                        if (value == true) {
                          selected.add(permission.key);
                        } else {
                          selected.remove(permission.key);
                        }
                      }),
                      title: Text(permission.name),
                      subtitle: Text('${permission.area} • ${permission.key}'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(_SecurityText.of(context).cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(_SecurityText.of(context).create),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      await notifier.createRole(
        roleKey: roleKey.text,
        name: name.text,
        description: description.text.isEmpty ? null : description.text,
        permissions: selected.toList(),
      );
    }
  }

  static Future<void> _showEditRolePermissionsDialog(
    BuildContext context,
    SecurityNotifier notifier,
    SecurityRoleModel role,
    List<SecurityPermissionModel> permissions,
  ) async {
    final selected = role.permissions.toSet();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(_SecurityText.of(context).permissionsFor(role.name)),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: permissions
                    .map(
                      (permission) => CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: selected.contains(permission.key),
                        onChanged: role.isSystem
                            ? null
                            : (value) => setState(() {
                                if (value == true) {
                                  selected.add(permission.key);
                                } else {
                                  selected.remove(permission.key);
                                }
                              }),
                        title: Text(permission.name),
                        subtitle: Text(
                          '${permission.area} • ${permission.key}',
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(_SecurityText.of(context).cancel),
            ),
            FilledButton(
              onPressed: role.isSystem
                  ? null
                  : () => Navigator.pop(context, true),
              child: Text(_SecurityText.of(context).save),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      await notifier.replaceRolePermissions(role, selected.toList());
    }
  }
}

class _SecurityText {
  const _SecurityText(this.ar);

  final bool ar;

  static _SecurityText of(BuildContext context) =>
      _SecurityText(Localizations.localeOf(context).languageCode == 'ar');

  String get title => ar ? 'المستخدمون والصلاحيات' : 'Users & Permissions';
  String get refresh => ar ? 'تحديث' : 'Refresh';
  String get addUser => ar ? 'إضافة مستخدم' : 'Add User';
  String get heading =>
      ar ? 'الأمان والتحكم في الوصول' : 'Security & Access Control';
  String get description => ar
      ? 'إدارة مستخدمي الشركة والأدوار ومجموعات الصلاحيات من مكان واحد.'
      : 'Manage company users, roles, and permission groups from one place.';
  String get username => ar ? 'اسم المستخدم' : 'Username';
  String get displayName => ar ? 'الاسم الظاهر' : 'Display Name';
  String get email => ar ? 'البريد الإلكتروني' : 'Email';
  String get initialPassword => ar ? 'كلمة السر الأولية' : 'Initial Password';
  String get roles => ar ? 'الأدوار' : 'Roles';
  String get cancel => ar ? 'إلغاء' : 'Cancel';
  String get create => ar ? 'إنشاء' : 'Create';
  String setPasswordFor(String userName) =>
      ar ? 'تعيين كلمة السر: $userName' : 'Set Password: $userName';
  String get newPassword => ar ? 'كلمة السر الجديدة' : 'New Password';
  String get confirmPassword => ar ? 'تأكيد كلمة السر' : 'Confirm Password';
  String get passwordMin => ar
      ? 'كلمة السر يجب ألا تقل عن 4 أحرف.'
      : 'Password must be at least 4 characters.';
  String get passwordMismatch =>
      ar ? 'كلمتا السر غير متطابقتين.' : 'Passwords do not match.';
  String get savePassword => ar ? 'حفظ كلمة السر' : 'Save Password';
  String rolesFor(String userName) =>
      ar ? 'أدوار: $userName' : 'Roles: $userName';
  String get save => ar ? 'حفظ' : 'Save';
  String get createRole => ar ? 'إنشاء دور' : 'Create Role';
  String get roleKey => ar ? 'مفتاح الدور' : 'Role Key';
  String get name => ar ? 'الاسم' : 'Name';
  String get roleDescription => ar ? 'الوصف' : 'Description';
  String get permissions => ar ? 'الصلاحيات' : 'Permissions';
  String permissionsFor(String roleName) =>
      ar ? 'صلاحيات: $roleName' : 'Permissions: $roleName';
  String loaded(int users, int roles, int permissions) => ar
      ? 'تم تحميل $users مستخدم، و$roles دور، و$permissions صلاحية.'
      : 'Loaded $users users, $roles roles, and $permissions permissions.';
  String get users => ar ? 'المستخدمون' : 'Users';
  String get noUsers => ar ? 'لا يوجد مستخدمون' : 'No users found';
  String get noUsersDescription => ar
      ? 'أنشئ أول مدير من معالج الإعداد، ثم أضف مستخدمين آخرين هنا.'
      : 'Create the first admin from Setup Wizard, then add more users here.';
  String get noRoles => ar ? 'لا توجد أدوار' : 'No roles';
  String get editRoles => ar ? 'تعديل الأدوار' : 'Edit Roles';
  String get setPassword => ar ? 'تعيين كلمة السر' : 'Set Password';
  String get role => ar ? 'دور' : 'Role';
  String get noRolesFound => ar ? 'لا توجد أدوار' : 'No roles found';
  String get noRolesDescription => ar
      ? 'أنشئ أدوارا واربط بها الصلاحيات.'
      : 'Create roles and assign permissions.';
  String get active => ar ? 'نشط' : 'Active';
  String get inactive => ar ? 'غير نشط' : 'Inactive';
  String permissionCount(int count) =>
      ar ? '$count صلاحية' : '$count permissions';
  String get viewPermissions => ar ? 'عرض الصلاحيات' : 'View Permissions';
  String get editPermissions => ar ? 'تعديل الصلاحيات' : 'Edit Permissions';
  String get permissionCatalog =>
      ar ? 'كتالوج الصلاحيات' : 'Permission Catalog';
  String get noPermissionsLoaded =>
      ar ? 'لم يتم تحميل صلاحيات' : 'No permissions loaded';
  String get noPermissionsDescription => ar
      ? 'نقطة كتالوج الصلاحيات لم ترجع أي بيانات.'
      : 'Permission catalog endpoint returned no entries.';
  String get securityCoverage => ar ? 'تغطية الأمان' : 'Security coverage';
  String get securityCoverageDescription => ar
      ? 'المستخدمون والأدوار وحالة التفعيل وصلاحيات الأدوار مربوطة. تغيير كلمات السر يظل تحت تحكم المدير.'
      : 'Users, roles, active status, and role permissions are connected. Password changes remain under administrator control.';
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.users,
    required this.roles,
    required this.permissions,
  });
  final int users;
  final int roles;
  final int permissions;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_outlined, color: cs.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _SecurityText.of(context).loaded(users, roles, permissions),
              style: TextStyle(color: cs.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersCard extends StatelessWidget {
  const _UsersCard({
    required this.users,
    required this.roles,
    required this.working,
    required this.onToggleActive,
    required this.onSetPassword,
    required this.onEditRoles,
  });

  final List<SecurityUserModel> users;
  final List<SecurityRoleModel> roles;
  final bool working;
  final Future<void> Function(SecurityUserModel user, bool isActive)
  onToggleActive;
  final ValueChanged<SecurityUserModel> onSetPassword;
  final ValueChanged<SecurityUserModel> onEditRoles;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.people_alt_outlined,
      title: _SecurityText.of(context).users,
      trailing: Text('${users.length}'),
      children: [
        if (users.isEmpty)
          _EmptyTile(
            icon: Icons.person_outline,
            title: _SecurityText.of(context).noUsers,
            subtitle: _SecurityText.of(context).noUsersDescription,
          )
        else
          ...users.map(
            (user) => _UserTile(
              user: user,
              working: working,
              onToggleActive: onToggleActive,
              onSetPassword: onSetPassword,
              onEditRoles: onEditRoles,
            ),
          ),
      ],
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.working,
    required this.onToggleActive,
    required this.onSetPassword,
    required this.onEditRoles,
  });
  final SecurityUserModel user;
  final bool working;
  final Future<void> Function(SecurityUserModel user, bool isActive)
  onToggleActive;
  final ValueChanged<SecurityUserModel> onSetPassword;
  final ValueChanged<SecurityUserModel> onEditRoles;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                user.isActive
                    ? Icons.person_outline
                    : Icons.person_off_outlined,
                color: user.isActive ? cs.primary : cs.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName.isEmpty
                          ? user.userName
                          : user.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '${user.userName}${user.email == null ? '' : ' • ${user.email}'}',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Switch(
                value: user.isActive,
                onChanged: working
                    ? null
                    : (value) => onToggleActive(user, value),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: user.roles.isEmpty
                ? [Chip(label: Text(_SecurityText.of(context).noRoles))]
                : user.roles
                      .map((role) => Chip(label: Text(role.roleKey)))
                      .toList(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: working ? null : () => onEditRoles(user),
                icon: const Icon(Icons.assignment_ind_outlined),
                label: Text(_SecurityText.of(context).editRoles),
              ),
              OutlinedButton.icon(
                onPressed: working ? null : () => onSetPassword(user),
                icon: const Icon(Icons.password_outlined),
                label: Text(_SecurityText.of(context).setPassword),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RolesCard extends StatelessWidget {
  const _RolesCard({
    required this.roles,
    required this.permissions,
    required this.working,
    required this.onCreateRole,
    required this.onEditPermissions,
  });

  final List<SecurityRoleModel> roles;
  final List<SecurityPermissionModel> permissions;
  final bool working;
  final VoidCallback onCreateRole;
  final ValueChanged<SecurityRoleModel> onEditPermissions;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.assignment_ind_outlined,
      title: _SecurityText.of(context).roles,
      trailing: FilledButton.icon(
        onPressed: working ? null : onCreateRole,
        icon: const Icon(Icons.add),
        label: Text(_SecurityText.of(context).role),
      ),
      children: [
        if (roles.isEmpty)
          _EmptyTile(
            icon: Icons.badge_outlined,
            title: _SecurityText.of(context).noRolesFound,
            subtitle: _SecurityText.of(context).noRolesDescription,
          )
        else
          ...roles.map(
            (role) => _RoleTile(
              role: role,
              onEditPermissions: onEditPermissions,
              working: working,
            ),
          ),
      ],
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.role,
    required this.onEditPermissions,
    required this.working,
  });
  final SecurityRoleModel role;
  final ValueChanged<SecurityRoleModel> onEditPermissions;
  final bool working;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                role.isSystem ? Icons.shield_outlined : Icons.badge_outlined,
                color: cs.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${role.name} (${role.roleKey})',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Chip(
                label: Text(
                  role.isActive
                      ? _SecurityText.of(context).active
                      : _SecurityText.of(context).inactive,
                ),
              ),
            ],
          ),
          if (role.description?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              role.description!,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            _SecurityText.of(context).permissionCount(role.permissions.length),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: working ? null : () => onEditPermissions(role),
            icon: const Icon(Icons.rule_outlined),
            label: Text(
              role.isSystem
                  ? _SecurityText.of(context).viewPermissions
                  : _SecurityText.of(context).editPermissions,
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionsCard extends StatelessWidget {
  const _PermissionsCard({required this.permissions});
  final List<SecurityPermissionModel> permissions;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<SecurityPermissionModel>>{};
    for (final permission in permissions) {
      grouped.putIfAbsent(permission.area, () => []).add(permission);
    }

    return _SectionCard(
      icon: Icons.rule_outlined,
      title: _SecurityText.of(context).permissionCatalog,
      trailing: Text('${permissions.length}'),
      children: [
        if (permissions.isEmpty)
          _EmptyTile(
            icon: Icons.lock_open_outlined,
            title: _SecurityText.of(context).noPermissionsLoaded,
            subtitle: _SecurityText.of(context).noPermissionsDescription,
          )
        else
          ...grouped.entries.map(
            (entry) => ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                _SecurityText.of(context).permissionCount(entry.value.length),
              ),
              children: entry.value
                  .map(
                    (permission) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(permission.name),
                      subtitle: Text(
                        '${permission.key}${permission.description == null ? '' : ' • ${permission.description}'}',
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _SecurityNotesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: cs.tertiaryContainer,
              child: Icon(Icons.info_outline, color: cs.onTertiaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _SecurityText.of(context).securityCoverage,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_SecurityText.of(context).securityCoverageDescription),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  child: Icon(icon, color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _EmptyTile extends StatelessWidget {
  const _EmptyTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: cs.onErrorContainer)),
          ),
        ],
      ),
    );
  }
}
