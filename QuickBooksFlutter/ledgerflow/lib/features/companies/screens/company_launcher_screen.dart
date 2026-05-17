import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/constants/app_constants.dart';
import '../../setup/providers/setup_provider.dart';
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
                onRetry: () =>
                    ref.read(companyRegistryProvider.notifier).refresh(),
              ),
              data: (registry) => _LauncherBody(registry: registry),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _openAndRoute(
  GoRouter router,
  WidgetRef ref,
  LocalCompanyInfo company,
) async {
  await ref.read(companyRegistryProvider.notifier).openCompany(company.id);
  await _routeAfterCompanyOpened(router, ref);
}

Future<void> _routeAfterCompanyOpened(GoRouter router, WidgetRef ref) async {
  ref.invalidate(setupProvider);
  final setup = await ref.read(setupProvider.future);
  router.go(setup.isInitialized ? AppRoutes.login : AppRoutes.setup);
}

class _LauncherBody extends ConsumerWidget {
  const _LauncherBody({required this.registry});

  final CompanyRegistry registry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.account_balance_outlined, size: 42, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No Company Open',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select a company that you have previously opened and click Open.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              AppConstants.appDisplayName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _RecentCompaniesCard(companies: registry.companies),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final actions = _ActionsCard(hasCompanies: registry.hasCompanies);
            final location = Text(
              'Location: Documents / LedgerFlow / Companies',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            );
            if (!wide) {
              return Column(
                children: [location, const SizedBox(height: 12), actions],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: location),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: actions),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ActiveCompanyCard extends ConsumerStatefulWidget {
  const _ActiveCompanyCard({required this.company});

  final LocalCompanyInfo company;

  @override
  ConsumerState<_ActiveCompanyCard> createState() => _ActiveCompanyCardState();
}

class _ActiveCompanyCardState extends ConsumerState<_ActiveCompanyCard> {
  bool _opening = false;
  String? _errorMessage;

  Future<void> _continueCompany() async {
    setState(() {
      _opening = true;
      _errorMessage = null;
    });

    final router = GoRouter.of(context);
    try {
      await _openAndRoute(router, ref, widget.company);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _opening = false;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  child: Icon(
                    Icons.check_circle_outline,
                    color: cs.onPrimaryContainer,
                  ),
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
                        widget.company.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.company.displayPath ??
                            widget.company.databasePath,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _opening ? null : _continueCompany,
                  icon: _opening
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow_outlined),
                  label: const Text('Continue'),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: cs.onErrorContainer),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionsCard extends ConsumerStatefulWidget {
  const _ActionsCard({required this.hasCompanies});

  final bool hasCompanies;

  @override
  ConsumerState<_ActionsCard> createState() => _ActionsCardState();
}

class _ActionsCardState extends ConsumerState<_ActionsCard> {
  bool _creating = false;
  bool _openingExisting = false;
  String? _errorMessage;

  Future<void> _createDefaultCompany() async {
    final companyName = await _askCompanyName();
    if (!mounted || companyName == null) return;

    final databasePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Create LedgerFlow company file',
      fileName:
          '${_safeFileName(companyName)}${AppConstants.companyFileExtension}',
      type: FileType.custom,
      allowedExtensions: ['ledgerflow'],
    );
    if (!mounted || databasePath == null) return;

    setState(() {
      _creating = true;
      _errorMessage = null;
    });

    final router = GoRouter.of(context);
    try {
      await ref
          .read(companyRegistryProvider.notifier)
          .registerCompany(
            name: companyName,
            databasePath: _ensureCompanyExtension(databasePath),
            displayPath: _ensureCompanyExtension(databasePath),
            makeActive: true,
          );
      await _routeAfterCompanyOpened(router, ref);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _openExistingCompany() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Open LedgerFlow company file',
      type: FileType.custom,
      allowedExtensions: ['ledgerflow', 'db'],
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (!mounted || path == null || path.trim().isEmpty) return;

    setState(() {
      _openingExisting = true;
      _errorMessage = null;
    });

    final router = GoRouter.of(context);
    final companyName = _companyNameFromPath(path);
    try {
      await ref
          .read(companyRegistryProvider.notifier)
          .registerCompany(
            name: companyName,
            databasePath: path,
            displayPath: path,
            makeActive: true,
          );
      await _routeAfterCompanyOpened(router, ref);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _openingExisting = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<String?> _askCompanyName() async {
    final controller = TextEditingController(text: 'LedgerFlow Company');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Company name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Company name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => Navigator.of(context).pop(controller.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmed = result?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  String _ensureCompanyExtension(String path) {
    return path.toLowerCase().endsWith(AppConstants.companyFileExtension)
        ? path
        : '$path${AppConstants.companyFileExtension}';
  }

  String _safeFileName(String value) {
    final safe = value
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9\u0600-\u06FF]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return safe.isEmpty ? 'LedgerFlow_Company' : safe;
  }

  String _companyNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final fileName = normalized.split('/').last;
    final withoutExtension =
        fileName.endsWith(AppConstants.companyFileExtension)
        ? fileName.substring(
            0,
            fileName.length - AppConstants.companyFileExtension.length,
          )
        : fileName.replaceFirst(RegExp(r'\.[^.]+$'), '');
    return withoutExtension.trim().isEmpty
        ? 'LedgerFlow Company'
        : withoutExtension.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: cs.onErrorContainer),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.end,
          children: [
            FilledButton.icon(
              onPressed: _creating ? null : _createDefaultCompany,
              icon: _creating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_business_outlined),
              label: Text(
                widget.hasCompanies
                    ? 'Create a new company'
                    : 'Create your first company',
              ),
            ),
            OutlinedButton.icon(
              onPressed: _creating || _openingExisting
                  ? null
                  : _openExistingCompany,
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('Open or restore existing'),
            ),
            OutlinedButton.icon(
              onPressed: _creating || _openingExisting
                  ? null
                  : _openExistingCompany,
              icon: const Icon(Icons.search_outlined),
              label: const Text('Find a company file'),
            ),
          ],
        ),
      ],
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
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent Companies',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: companies.isEmpty ? null : () {},
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit List'),
                ),
              ],
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              )
            else
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                    child: Row(
                      children: const [
                        Expanded(flex: 3, child: Text('Company Name')),
                        Expanded(flex: 2, child: Text('Last Opened')),
                        Expanded(child: Text('File Size')),
                        SizedBox(width: 150, child: Text('Action')),
                      ],
                    ),
                  ),
                  ...companies.map(
                    (company) => _CompanyListTile(company: company),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _CompanyListTile extends ConsumerStatefulWidget {
  const _CompanyListTile({required this.company});

  final LocalCompanyInfo company;

  @override
  ConsumerState<_CompanyListTile> createState() => _CompanyListTileState();
}

class _CompanyListTileState extends ConsumerState<_CompanyListTile> {
  bool _opening = false;
  String? _errorMessage;

  Future<void> _openCompany() async {
    setState(() {
      _opening = true;
      _errorMessage = null;
    });

    final router = GoRouter.of(context);
    try {
      await _openAndRoute(router, ref, widget.company);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _opening = false;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _opening ? null : _openCompany,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.company.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.company.displayPath ??
                                widget.company.databasePath,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(_formatDate(widget.company.lastOpenedAt)),
                    ),
                    Expanded(
                      child: _FileSizeText(path: widget.company.databasePath),
                    ),
                    const SizedBox(width: 12),
                    if (_opening)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else ...[
                      SizedBox(
                        width: 68,
                        child: FilledButton(
                          onPressed: _openCompany,
                          child: const Text('Open'),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove from list',
                        onPressed: () => ref
                            .read(companyRegistryProvider.notifier)
                            .removeCompany(widget.company.id),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(_errorMessage!, style: TextStyle(color: cs.error)),
          ],
        ],
      ),
    );
  }
}

class _FileSizeText extends StatelessWidget {
  const _FileSizeText({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: File(
        path,
      ).exists().then((exists) => exists ? File(path).length() : 0),
      builder: (context, snapshot) {
        final bytes = snapshot.data ?? 0;
        return Text(bytes == 0 ? '-' : _formatBytes(bytes));
      },
    );
  }
}

String _formatDate(DateTime value) {
  if (value.millisecondsSinceEpoch == 0) return '-';
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  return '${(kb / 1024).toStringAsFixed(1)} MB';
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
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
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
