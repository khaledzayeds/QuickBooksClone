import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/coming_soon_screen.dart';
import '../../print_templates/presentation/pages/print_template_designer_page.dart';
import '../providers/settings_provider.dart';

class SettingsHomeScreen extends ConsumerWidget {
  const SettingsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(companySettingsProvider);
    final runtimeAsync = ref.watch(runtimeSettingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(companySettingsProvider);
              ref.invalidate(runtimeSettingsProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'System Settings',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage company, database, backup, printing, users, license, and setup configuration.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          companyAsync.when(
            loading: () => const _LoadingCard(title: 'Company'),
            error: (error, _) => _ErrorCard(
              title: 'Company Settings',
              message: error.toString(),
              onRetry: () => ref.invalidate(companySettingsProvider),
            ),
            data: (company) => _CompanySummaryCard(company: company),
          ),
          const SizedBox(height: 16),
          runtimeAsync.when(
            loading: () => const _LoadingCard(title: 'Runtime'),
            error: (error, _) => _ErrorCard(
              title: 'Runtime Settings',
              message: error.toString(),
              onRetry: () => ref.invalidate(runtimeSettingsProvider),
            ),
            data: (runtime) => _RuntimeSummaryCard(
              environmentName: runtime.environmentName,
              databaseProvider: runtime.databaseProvider,
              supportsBackupRestore: runtime.supportsBackupRestore,
              liveDatabasePath: runtime.liveDatabasePath,
              backupDirectory: runtime.backupDirectory,
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final cards = [
                _SettingsTile(
                  icon: Icons.business_outlined,
                  title: 'Company Profile',
                  subtitle: 'Legal name, contacts, address, fiscal year, and language.',
                  onTap: () => context.go(AppRoutes.companySettings),
                ),
                _SettingsTile(
                  icon: Icons.language_outlined,
                  title: 'Connection',
                  subtitle: 'Local/LAN/hosted API endpoint and connection test.',
                  onTap: () => context.go(AppRoutes.connectionSettings),
                ),
                _SettingsTile(
                  icon: Icons.calculate_outlined,
                  title: 'Tax Settings',
                  subtitle: 'Sales tax, purchase tax, rounding, and default tax accounts.',
                  onTap: () => context.go(AppRoutes.taxSettings),
                ),
                _SettingsTile(
                  icon: Icons.storage_outlined,
                  title: 'Database & Backup',
                  subtitle: 'Database provider, backup folder, restore, and maintenance.',
                  onTap: () => context.go(AppRoutes.backupSettings),
                ),
                _SettingsTile(
                  icon: Icons.print_outlined,
                  title: 'Printing',
                  subtitle: 'A4 invoices, thermal receipts, logos, and document templates.',
                  onTap: () => context.go(AppRoutes.printingSettings),
                ),
                _SettingsTile(
                  icon: Icons.dashboard_customize_outlined,
                  title: 'Print Template Designer',
                  subtitle: 'Design invoice, receipt, QR, barcode, and A4/thermal templates.',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const PrintTemplateDesignerPage()),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Users & Permissions',
                  subtitle: 'Users, roles, permissions, passwords, and audit access.',
                  onTap: () => context.go(AppRoutes.usersPermissions),
                ),
                _SettingsTile(
                  icon: Icons.flag_outlined,
                  title: 'Setup Wizard',
                  subtitle: 'First-run company setup, restore, connection, and demo options.',
                  onTap: () => context.go(AppRoutes.setupWizard),
                ),
                _SettingsTile(
                  icon: Icons.verified_user_outlined,
                  title: 'License',
                  subtitle: 'Trial, activation key, edition, limits, and device activation.',
                  onTap: () => context.go(AppRoutes.licenseSettings),
                ),
              ];

              if (!wide) {
                return Column(children: cards.map((card) => Padding(padding: const EdgeInsets.only(bottom: 12), child: card)).toList());
              }

              return GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 3.9,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: cards,
              );
            },
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  static void _openComingSoon(BuildContext context, String title) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ComingSoonScreen(title: title)),
    );
  }
}

class _CompanySummaryCard extends StatelessWidget {
  const _CompanySummaryCard({required this.company});

  final dynamic company;

  @override
  Widget build(BuildContext context) {
    if (company == null) {
      return _SummaryCard(
        icon: Icons.business_outlined,
        title: 'Company Settings',
        subtitle: 'No company profile found yet. This will be created by the Setup Wizard.',
        rows: const [
          ('Status', 'Not configured'),
        ],
      );
    }

    return _SummaryCard(
      icon: Icons.business_outlined,
      title: company.companyName.isEmpty ? 'Company Settings' : company.companyName,
      subtitle: company.legalName ?? 'Company profile is available.',
      rows: [
        ('Currency', company.currency),
        ('Country', company.country),
        ('Language', company.defaultLanguage),
        ('Taxes', company.taxesEnabled ? 'Enabled' : 'Disabled'),
        ('Address', company.displayAddress),
      ],
    );
  }
}

class _RuntimeSummaryCard extends StatelessWidget {
  const _RuntimeSummaryCard({
    required this.environmentName,
    required this.databaseProvider,
    required this.supportsBackupRestore,
    this.liveDatabasePath,
    this.backupDirectory,
  });

  final String environmentName;
  final String databaseProvider;
  final bool supportsBackupRestore;
  final String? liveDatabasePath;
  final String? backupDirectory;

  @override
  Widget build(BuildContext context) {
    return _SummaryCard(
      icon: Icons.dns_outlined,
      title: 'Runtime & Database',
      subtitle: 'Current API runtime and database status.',
      rows: [
        ('Environment', environmentName),
        ('Provider', databaseProvider),
        ('Backup/Restore', supportsBackupRestore ? 'Supported' : 'Not supported'),
        ('Database', liveDatabasePath?.isNotEmpty == true ? liveDatabasePath! : '-'),
        ('Backup folder', backupDirectory?.isNotEmpty == true ? backupDirectory! : '-'),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.rows,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<(String, String)> rows;

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...rows.map((row) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(row.$1, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      ),
                      Expanded(child: Text(row.$2.isEmpty ? '-' : row.$2)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: cs.secondaryContainer,
                child: Icon(icon, color: cs.onSecondaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 16),
            Text('Loading $title...'),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.title, required this.message, required this.onRetry});
  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: cs.error),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(message, maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
