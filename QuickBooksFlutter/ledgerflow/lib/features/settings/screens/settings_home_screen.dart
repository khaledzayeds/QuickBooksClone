import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/coming_soon_screen.dart';
import '../providers/settings_provider.dart';

class SettingsHomeScreen extends ConsumerWidget {
  const SettingsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(companySettingsProvider);
    final runtimeAsync = ref.watch(runtimeSettingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          _SettingsToolbar(
            onRefresh: () {
              ref.invalidate(companySettingsProvider);
              ref.invalidate(runtimeSettingsProvider);
            },
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              children: [
                Text(
                  'Offline Company Settings',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage this desktop company file, local service, users, payroll, time tracking, backup, and document output.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
                        icon: Icons.folder_open_outlined,
                        title: 'Company Files',
                        subtitle:
                            'Create, open, restore, or switch local company files.',
                        onTap: () => context.go(AppRoutes.companies),
                      ),
                      _SettingsTile(
                        icon: Icons.business_outlined,
                        title: 'Company Profile',
                        subtitle:
                            'Legal name, contacts, address, fiscal year, currency, and language.',
                        onTap: () => context.go(AppRoutes.companySettings),
                      ),
                      _SettingsTile(
                        icon: Icons.dns_outlined,
                        title: 'Offline Service',
                        subtitle:
                            'Local service health, company connection, and desktop runtime status.',
                        onTap: () => context.go(AppRoutes.connectionSettings),
                      ),
                      _SettingsTile(
                        icon: Icons.calculate_outlined,
                        title: 'Tax Settings',
                        subtitle:
                            'Sales tax, purchase tax, rounding, and default tax accounts.',
                        onTap: () => context.go(AppRoutes.taxSettings),
                      ),
                      _SettingsTile(
                        icon: Icons.storage_outlined,
                        title: 'Database & Backup',
                        subtitle:
                            'Company database, backup folder, restore, and maintenance.',
                        onTap: () => context.go(AppRoutes.backupSettings),
                      ),
                      _SettingsTile(
                        icon: Icons.print_outlined,
                        title: 'Printing',
                        subtitle:
                            'A4 invoices, thermal receipts, logos, and document templates.',
                        onTap: () => context.go(AppRoutes.printingSettings),
                      ),
                      _SettingsTile(
                        icon: Icons.dashboard_customize_outlined,
                        title: 'Print Template Designer',
                        subtitle:
                            'Design invoice, receipt, QR, barcode, and A4/thermal templates.',
                        onTap: () =>
                            context.go(AppRoutes.printTemplateDesigner),
                      ),
                      _SettingsTile(
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'Users & Permissions',
                        subtitle:
                            'User list, login passwords, roles, and access permissions.',
                        onTap: () => context.go(AppRoutes.usersPermissions),
                      ),
                      _SettingsTile(
                        icon: Icons.timer_outlined,
                        title: 'Time Tracking',
                        subtitle:
                            'Employee time entries, billable hours, approvals, and exports.',
                        onTap: () => context.go(AppRoutes.timeTracking),
                      ),
                      _SettingsTile(
                        icon: Icons.payments_outlined,
                        title: 'Payroll',
                        subtitle:
                            'Employees, earning types, deductions, posting accounts, and pay runs.',
                        onTap: () => context.go(AppRoutes.payroll),
                      ),
                      _SettingsTile(
                        icon: Icons.flag_outlined,
                        title: 'Company Setup',
                        subtitle:
                            'Review first company setup, defaults, tax, users, backup, and printing.',
                        onTap: () => context.go(AppRoutes.setupWizard),
                      ),
                      _SettingsTile(
                        icon: Icons.verified_user_outlined,
                        title: 'Online License',
                        subtitle:
                            'Only for hosted/online services, remote access, and subscription features.',
                        onTap: () => context.go(AppRoutes.licenseSettings),
                      ),
                    ];

                    if (!wide) {
                      return Column(
                        children: cards
                            .map(
                              (card) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: card,
                              ),
                            )
                            .toList(),
                      );
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
        subtitle:
            'No company profile found yet. This will be created by the Setup Wizard.',
        rows: const [('Status', 'Not configured')],
      );
    }

    return _SummaryCard(
      icon: Icons.business_outlined,
      title: company.companyName.isEmpty
          ? 'Company Settings'
          : company.companyName,
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
      subtitle: 'Current local runtime and company database status.',
      rows: [
        ('Environment', environmentName),
        ('Provider', databaseProvider),
        (
          'Backup/Restore',
          supportsBackupRestore ? 'Supported' : 'Not supported',
        ),
        (
          'Database',
          liveDatabasePath?.isNotEmpty == true ? liveDatabasePath! : '-',
        ),
        (
          'Backup folder',
          backupDirectory?.isNotEmpty == true ? backupDirectory! : '-',
        ),
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
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        row.$1,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(child: Text(row.$2.isEmpty ? '-' : row.$2)),
                  ],
                ),
              ),
            ),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: cs.secondaryContainer,
                child: Icon(icon, color: cs.onSecondaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
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
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text('Loading $title...'),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(message),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsToolbar extends StatelessWidget {
  const _SettingsToolbar({required this.onRefresh});
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          const Icon(Icons.business_outlined, size: 19),
          const SizedBox(width: 8),
          const Text(
            'Company Center',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 10),
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Refresh',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}
