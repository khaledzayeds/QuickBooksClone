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

    ref.listen(securityProvider, (previous, next) {
      if (next.successMessage != null && previous?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.successMessage!)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users & Permissions'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: notifier.load,
            icon: const Icon(Icons.refresh),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: FilledButton.icon(
              onPressed: state.working ? null : () => _showCreateUserDialog(context, notifier, state.roles),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Add User'),
            ),
          ),
        ],
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('Security & Access Control', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(
                  'Manage backend users, roles, and permission groups. These calls use the existing SecurityController APIs.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _ErrorBanner(message: state.errorMessage!),
                ],
                const SizedBox(height: 24),
                _StatusBanner(users: state.users.length, roles: state.roles.length, permissions: state.permissions.length),
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
                          onEditRoles: (user) => _showEditUserRolesDialog(context, notifier, user, state.roles),
                        ),
                      ],
                    );
                    final right = Column(
                      children: [
                        _RolesCard(
                          roles: state.roles,
                          permissions: state.permissions,
                          working: state.working,
                          onCreateRole: () => _showCreateRoleDialog(context, notifier, state.permissions),
                          onEditPermissions: (role) => _showEditRolePermissionsDialog(context, notifier, role, state.permissions),
                        ),
                        const SizedBox(height: 16),
                        _PermissionsCard(permissions: state.permissions),
                      ],
                    );

                    if (!wide) {
                      return Column(children: [left, const SizedBox(height: 16), right]);
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
                _FutureBackendCard(),
              ],
            ),
    );
  }

  static Future<void> _showCreateUserDialog(BuildContext context, SecurityNotifier notifier, List<SecurityRoleModel> roles) async {
    final userName = TextEditingController();
    final displayName = TextEditingController();
    final email = TextEditingController();
    final selectedRoleIds = <String>{};

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add User'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: userName, decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: displayName, decoration: const InputDecoration(labelText: 'Display Name', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: email, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  Align(alignment: AlignmentDirectional.centerStart, child: Text('Roles', style: Theme.of(context).textTheme.titleSmall)),
                  ...roles.map((role) => CheckboxListTile(
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
                      )),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
          ],
        ),
      ),
    );

    if (ok == true) {
      await notifier.createUser(
        userName: userName.text,
        displayName: displayName.text,
        email: email.text.isEmpty ? null : email.text,
        roleIds: selectedRoleIds.toList(),
      );
    }
  }

  static Future<void> _showEditUserRolesDialog(BuildContext context, SecurityNotifier notifier, SecurityUserModel user, List<SecurityRoleModel> roles) async {
    final selectedRoleIds = user.roles.map((role) => role.roleId).toSet();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Roles: ${user.userName}'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: roles.map((role) => CheckboxListTile(
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
                    )).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (ok == true) {
      await notifier.replaceUserRoles(user, selectedRoleIds.toList());
    }
  }

  static Future<void> _showCreateRoleDialog(BuildContext context, SecurityNotifier notifier, List<SecurityPermissionModel> permissions) async {
    final roleKey = TextEditingController();
    final name = TextEditingController();
    final description = TextEditingController();
    final selected = <String>{};
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Role'),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: roleKey, decoration: const InputDecoration(labelText: 'Role Key', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: description, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  Align(alignment: AlignmentDirectional.centerStart, child: Text('Permissions', style: Theme.of(context).textTheme.titleSmall)),
                  ...permissions.map((permission) => CheckboxListTile(
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
                      )),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
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

  static Future<void> _showEditRolePermissionsDialog(BuildContext context, SecurityNotifier notifier, SecurityRoleModel role, List<SecurityPermissionModel> permissions) async {
    final selected = role.permissions.toSet();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Permissions: ${role.name}'),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: permissions.map((permission) => CheckboxListTile(
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
                      subtitle: Text('${permission.area} • ${permission.key}'),
                    )).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: role.isSystem ? null : () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (ok == true) {
      await notifier.replaceRolePermissions(role, selected.toList());
    }
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.users, required this.roles, required this.permissions});
  final int users;
  final int roles;
  final int permissions;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.verified_user_outlined, color: cs.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Loaded $users users, $roles roles, and $permissions permissions from the backend security API.',
              style: TextStyle(color: cs.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersCard extends StatelessWidget {
  const _UsersCard({required this.users, required this.roles, required this.working, required this.onToggleActive, required this.onEditRoles});

  final List<SecurityUserModel> users;
  final List<SecurityRoleModel> roles;
  final bool working;
  final Future<void> Function(SecurityUserModel user, bool isActive) onToggleActive;
  final ValueChanged<SecurityUserModel> onEditRoles;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.people_alt_outlined,
      title: 'Users',
      trailing: Text('${users.length}'),
      children: [
        if (users.isEmpty)
          const _EmptyTile(icon: Icons.person_outline, title: 'No users found', subtitle: 'Create the first admin from Setup Wizard, then add more users here.')
        else
          ...users.map((user) => _UserTile(user: user, working: working, onToggleActive: onToggleActive, onEditRoles: onEditRoles)),
      ],
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.working, required this.onToggleActive, required this.onEditRoles});
  final SecurityUserModel user;
  final bool working;
  final Future<void> Function(SecurityUserModel user, bool isActive) onToggleActive;
  final ValueChanged<SecurityUserModel> onEditRoles;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(user.isActive ? Icons.person_outline : Icons.person_off_outlined, color: user.isActive ? cs.primary : cs.error),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName.isEmpty ? user.userName : user.displayName, style: const TextStyle(fontWeight: FontWeight.w900)),
                    Text('${user.userName}${user.email == null ? '' : ' • ${user.email}'}', style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Switch(value: user.isActive, onChanged: working ? null : (value) => onToggleActive(user, value)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: user.roles.isEmpty
                ? [const Chip(label: Text('No roles'))]
                : user.roles.map((role) => Chip(label: Text(role.roleKey))).toList(),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: working ? null : () => onEditRoles(user),
            icon: const Icon(Icons.assignment_ind_outlined),
            label: const Text('Edit Roles'),
          ),
        ],
      ),
    );
  }
}

class _RolesCard extends StatelessWidget {
  const _RolesCard({required this.roles, required this.permissions, required this.working, required this.onCreateRole, required this.onEditPermissions});

  final List<SecurityRoleModel> roles;
  final List<SecurityPermissionModel> permissions;
  final bool working;
  final VoidCallback onCreateRole;
  final ValueChanged<SecurityRoleModel> onEditPermissions;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.assignment_ind_outlined,
      title: 'Roles',
      trailing: FilledButton.icon(
        onPressed: working ? null : onCreateRole,
        icon: const Icon(Icons.add),
        label: const Text('Role'),
      ),
      children: [
        if (roles.isEmpty)
          const _EmptyTile(icon: Icons.badge_outlined, title: 'No roles found', subtitle: 'Create roles and assign permissions.')
        else
          ...roles.map((role) => _RoleTile(role: role, onEditPermissions: onEditPermissions, working: working)),
      ],
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({required this.role, required this.onEditPermissions, required this.working});
  final SecurityRoleModel role;
  final ValueChanged<SecurityRoleModel> onEditPermissions;
  final bool working;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(role.isSystem ? Icons.shield_outlined : Icons.badge_outlined, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(child: Text('${role.name} (${role.roleKey})', style: const TextStyle(fontWeight: FontWeight.w900))),
              Chip(label: Text(role.isActive ? 'Active' : 'Inactive')),
            ],
          ),
          if (role.description?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(role.description!, style: TextStyle(color: cs.onSurfaceVariant)),
          ],
          const SizedBox(height: 8),
          Text('${role.permissions.length} permissions'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: working ? null : () => onEditPermissions(role),
            icon: const Icon(Icons.rule_outlined),
            label: Text(role.isSystem ? 'View Permissions' : 'Edit Permissions'),
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
      title: 'Permission Catalog',
      trailing: Text('${permissions.length}'),
      children: [
        if (permissions.isEmpty)
          const _EmptyTile(icon: Icons.lock_open_outlined, title: 'No permissions loaded', subtitle: 'Permission catalog endpoint returned no entries.')
        else
          ...grouped.entries.map((entry) => ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${entry.value.length} permissions'),
                children: entry.value
                    .map((permission) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(permission.name),
                          subtitle: Text('${permission.key}${permission.description == null ? '' : ' • ${permission.description}'}'),
                        ))
                    .toList(),
              )),
      ],
    );
  }
}

class _FutureBackendCard extends StatelessWidget {
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
            CircleAvatar(backgroundColor: cs.tertiaryContainer, child: Icon(Icons.info_outline, color: cs.onTertiaryContainer)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Remaining security polish', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text('Next security polish: password reset/change UI, device activation limits, audit log display, and license user limit enforcement.'),
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
  const _SectionCard({required this.icon, required this.title, required this.children, this.trailing});
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
                CircleAvatar(backgroundColor: cs.primaryContainer, child: Icon(icon, color: cs.onPrimaryContainer)),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
                if (trailing != null) trailing!,
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
  const _EmptyTile({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
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
      decoration: BoxDecoration(color: cs.errorContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: TextStyle(color: cs.onErrorContainer))),
        ],
      ),
    );
  }
}
