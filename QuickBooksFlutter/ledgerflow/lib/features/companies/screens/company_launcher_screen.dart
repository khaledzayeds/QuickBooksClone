import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/constants/app_constants.dart';
import '../data/models/company_registry_models.dart';
import '../providers/company_registry_provider.dart';

class CompanyLauncherScreen extends ConsumerWidget {
  const CompanyLauncherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registryState = ref.watch(companyRegistryProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: registryState.when(
              loading: () => const _LauncherLoadingCard(),
              error: (error, _) => _LauncherErrorCard(
                message: error.toString(),
                onRetry: () => ref.read(companyRegistryProvider.notifier).refresh(),
              ),
              data: (registry) => _LauncherBody(registry: registry),
            ),
          ),
        ),
      ),
    );
  }
}

class _LauncherBody extends ConsumerWidget {
  const _LauncherBody({required this.registry});

  final CompanyRegistry registry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final activeCompany = registry.activeCompany;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.account_balance_outlined, size: 64, color: cs.primary),
        const SizedBox(height: 12),
        Text(
          AppConstants.appDisplayName,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Open a company file or create a new offline company.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 28),
        if (activeCompany != null) ...[
          _ActiveCompanyCard(company: activeCompany),
          const SizedBox(height: 16),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final left = _ActionsCard(hasCompanies: registry.hasCompanies);
            final right = _RecentCompaniesCard(companies: registry.companies);
            if (!wide) {
              return Column(
                children: [left, const SizedBox(height: 16), right],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: left),
                const SizedBox(width: 16),
                Expanded(flex: 6, child: right),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ActiveCompanyCard extends ConsumerWidget {
  const _ActiveCompanyCard({required this.company});

  final LocalCompanyInfo company;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: cs.primaryContainer,
              child: Icon(Icons.check_circle_outline, color: cs.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last opened company',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    company.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    company.displayPath ?? company.databasePath,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () async {
                await ref.read(companyRegistryProvider.notifier).openCompany(company.id);
                if (context.mounted) context.go(AppRoutes.setup);
              },
              icon: const Icon(Icons.play_arrow_outlined),
              label: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({required this.hasCompanies});

  final bool hasCompanies;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Company Files',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Each company will have its own offline LedgerFlow database file.',
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.setup),
              icon: const Icon(Icons.add_business_outlined),
              label: Text(hasCompanies ? 'Create New Company' : 'Create First Company'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('Open Existing Company File'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.restore_outlined),
              label: const Text('Restore Backup'),
            ),
            const SizedBox(height: 12),
            Text(
              'Open/restore will be enabled after the company file picker and runtime database switching are connected.',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentCompaniesCard extends ConsumerWidget {
  const _RecentCompaniesCard({required this.companies});

  final List<LocalCompanyInfo> companies;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Recent Companies',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            if (companies.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'No company files yet. Create your first company to continue.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              )
            else
              ...companies.map((company) => _CompanyListTile(company: company)),
          ],
        ),
      ),
    );
  }
}

class _CompanyListTile extends ConsumerWidget {
  const _CompanyListTile({required this.company});

  final LocalCompanyInfo company;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await ref.read(companyRegistryProvider.notifier).openCompany(company.id);
            if (context.mounted) context.go(AppRoutes.setup);
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: cs.secondaryContainer,
                  child: Icon(Icons.business_outlined, color: cs.onSecondaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.name,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        company.displayPath ?? company.databasePath,
                        maxLines: 1,
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
      ),
    );
  }
}

class _LauncherLoadingCard extends StatelessWidget {
  const _LauncherLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 14),
            Text('Loading company files...'),
          ],
        ),
      ),
    );
  }
}

class _LauncherErrorCard extends StatelessWidget {
  const _LauncherErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 42),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
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
