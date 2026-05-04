import 'package:flutter/material.dart';

class UsersPermissionsScreen extends StatelessWidget {
  const UsersPermissionsScreen({super.key});

  static const _roles = [
    ('Owner / Admin', 'Full access to company, settings, users, posting, reports, backup, and license.'),
    ('Manager', 'Access to sales, purchases, inventory, reports, and limited settings.'),
    ('Cashier', 'Access to invoices, sales receipts, payments, and customer lookup.'),
    ('Accountant', 'Access to chart of accounts, journal entries, reports, and transaction review.'),
    ('Warehouse', 'Access to items, receive inventory, adjustments, and stock movement.'),
  ];

  static const _permissions = [
    ('Sales', 'Estimates, sales orders, invoices, receipts, payments, returns, customer credits'),
    ('Purchases', 'Purchase orders, receive inventory, bills, vendor payments, purchase returns, vendor credits'),
    ('Inventory', 'Items, stock, adjustments, transfers, assemblies, valuation'),
    ('Accounting', 'Chart of accounts, journal entries, posting, void/reversal, fiscal periods'),
    ('Reports', 'Sales, purchasing, inventory, accounting, profit/loss, balance sheet, statements'),
    ('Settings', 'Company, connection, taxes, backup, printing, users, license'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users & Permissions'),
        actions: const [
          Padding(
            padding: EdgeInsetsDirectional.only(end: 12),
            child: FilledButton.icon(
              onPressed: null,
              icon: Icon(Icons.person_add_outlined),
              label: Text('Add User'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Security & Access Control', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            'Prepare role-based access for commercial editions. Backend users, roles, permissions, device limits, and audit endpoints will be wired in the next security step.',
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          _StatusBanner(),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              final left = Column(
                children: const [
                  _AdminBootstrapCard(),
                  SizedBox(height: 16),
                  _UsersPlaceholderCard(),
                ],
              );
              final right = Column(
                children: const [
                  _RolesCard(),
                  SizedBox(height: 16),
                  _PermissionsCard(),
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
}

class _StatusBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.timelapse_outlined, color: cs.onSecondaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Status: UI skeleton ready. Backend users/roles/permissions endpoints are still required before enabling real user management.',
              style: TextStyle(color: cs.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminBootstrapCard extends StatelessWidget {
  const _AdminBootstrapCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.admin_panel_settings_outlined,
      title: 'First Admin User',
      children: const [
        TextField(
          enabled: false,
          decoration: InputDecoration(
            labelText: 'Admin Name',
            hintText: 'Company owner / first admin',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        SizedBox(height: 12),
        TextField(
          enabled: false,
          decoration: InputDecoration(
            labelText: 'Admin Email / Username',
            hintText: 'admin@example.com',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.alternate_email_outlined),
          ),
        ),
        SizedBox(height: 12),
        TextField(
          enabled: false,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Temporary Password',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.password_outlined),
          ),
        ),
        SizedBox(height: 16),
        FilledButton.icon(
          onPressed: null,
          icon: Icon(Icons.verified_user_outlined),
          label: Text('Create First Admin'),
        ),
      ],
    );
  }
}

class _UsersPlaceholderCard extends StatelessWidget {
  const _UsersPlaceholderCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.people_alt_outlined,
      title: 'Users',
      children: const [
        _PlaceholderListTile(
          icon: Icons.person_outline,
          title: 'No connected user list yet',
          subtitle: 'Will display active users, roles, status, last login, and allowed devices.',
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: null,
                icon: Icon(Icons.person_add_outlined),
                label: Text('Add User'),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: null,
                icon: Icon(Icons.devices_outlined),
                label: Text('Devices'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RolesCard extends StatelessWidget {
  const _RolesCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.assignment_ind_outlined,
      title: 'Default Roles',
      children: UsersPermissionsScreen._roles
          .map((role) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PlaceholderListTile(icon: Icons.badge_outlined, title: role.$1, subtitle: role.$2),
              ))
          .toList(),
    );
  }
}

class _PermissionsCard extends StatelessWidget {
  const _PermissionsCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.rule_outlined,
      title: 'Permission Groups',
      children: UsersPermissionsScreen._permissions
          .map((permission) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PlaceholderListTile(icon: Icons.lock_open_outlined, title: permission.$1, subtitle: permission.$2),
              ))
          .toList(),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: cs.tertiaryContainer, child: Icon(Icons.api_outlined, color: cs.onTertiaryContainer)),
                const SizedBox(width: 12),
                Text('Required Backend Work', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 14),
            const Text('Needed endpoints: users CRUD, roles CRUD, permissions matrix, password reset, device activation, audit log, and license limits integration.'),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.icon, required this.title, required this.children});
  final IconData icon;
  final String title;
  final List<Widget> children;

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

class _PlaceholderListTile extends StatelessWidget {
  const _PlaceholderListTile({required this.icon, required this.title, required this.subtitle});
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
