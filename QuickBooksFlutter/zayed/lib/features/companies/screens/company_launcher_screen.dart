import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/locale_provider.dart';
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
                message: _companyTexts(context).loadingFailed,
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
        const Align(
          alignment: AlignmentDirectional.centerEnd,
          child: _CompanyLanguageToggleButton(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.account_balance_outlined, size: 42, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _companyTexts(context).noCompanyOpen,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _companyTexts(context).pickCompany,
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
              _companyTexts(context).defaultLocation,
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

class _CompanyLanguageToggleButton extends ConsumerWidget {
  const _CompanyLanguageToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isArabic = locale.languageCode == 'ar';
    final cs = Theme.of(context).colorScheme;

    return Tooltip(
      message: isArabic ? 'Switch to English' : 'التحويل إلى العربية',
      child: OutlinedButton.icon(
        onPressed: () => ref.read(localeProvider.notifier).toggleLocale(),
        icon: const Icon(Icons.language_outlined, size: 18),
        label: Text(
          isArabic ? 'EN' : 'ع',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side: BorderSide(color: cs.outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          minimumSize: const Size(62, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
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
        _errorMessage = _companyTexts(context).couldNotCreate;
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
    final draft = await _askCompanyDetails();
    if (!mounted || draft == null) return;

    final databasePath = await FilePicker.platform.saveFile(
      dialogTitle: _companyTexts(context).createCompanyFile,
      fileName:
          '${_safeFileName(draft.name)}${AppConstants.companyFileExtension}',
      type: FileType.custom,
      allowedExtensions: ['zayed'],
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
            name: draft.name,
            databasePath: _ensureCompanyExtension(databasePath),
            businessType: draft.businessType,
            displayPath: _ensureCompanyExtension(databasePath),
            makeActive: true,
          );
      await _routeAfterCompanyOpened(router, ref);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _errorMessage = _companyTexts(context).couldNotCreate;
      });
    }
  }

  Future<void> _openExistingCompany() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: _companyTexts(context).openCompanyFile,
      type: FileType.custom,
      allowedExtensions: ['zayed', 'db'],
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (!mounted || path == null || path.trim().isEmpty) return;
    final businessType = await _askBusinessType();
    if (!mounted || businessType == null) return;

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
            businessType: businessType,
            displayPath: path,
            makeActive: true,
          );
      await _routeAfterCompanyOpened(router, ref);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _openingExisting = false;
        _errorMessage = _companyTexts(context).couldNotOpen;
      });
    }
  }

  Future<_CreateCompanyDraft?> _askCompanyDetails() async {
    final controller = TextEditingController(text: 'Zayed Company');
    var selectedType = CompanyBusinessType.retail;
    final result = await showDialog<_CreateCompanyDraft>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(_companyTexts(context).companyName),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: _companyTexts(context).companyName,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) {
                    final name = controller.text.trim();
                    Navigator.of(context).pop(
                      name.isEmpty
                          ? null
                          : _CreateCompanyDraft(name, selectedType),
                    );
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<CompanyBusinessType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Business Type / نوع النشاط',
                    border: OutlineInputBorder(),
                  ),
                  items: CompanyBusinessType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text('${type.labelEn} / ${type.labelAr}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => selectedType = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_companyTexts(context).cancel),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                Navigator.of(context).pop(
                  name.isEmpty ? null : _CreateCompanyDraft(name, selectedType),
                );
              },
              child: Text(_companyTexts(context).continueText),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result;
  }

  Future<CompanyBusinessType?> _askBusinessType() async {
    var selectedType = CompanyBusinessType.hotelTourism;
    return showDialog<CompanyBusinessType>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Business Type / نوع النشاط'),
          content: SizedBox(
            width: 420,
            child: DropdownButtonFormField<CompanyBusinessType>(
              initialValue: selectedType,
              decoration: const InputDecoration(
                labelText: 'Business Type / نوع النشاط',
                border: OutlineInputBorder(),
              ),
              items: CompanyBusinessType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text('${type.labelEn} / ${type.labelAr}'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setDialogState(() => selectedType = value);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_companyTexts(context).cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(selectedType),
              child: Text(_companyTexts(context).continueText),
            ),
          ],
        ),
      ),
    );
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
    return safe.isEmpty ? 'Zayed_Company' : safe;
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
        ? 'Zayed Company'
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
                    ? _companyTexts(context).createNewCompany
                    : _companyTexts(context).createFirstCompany,
              ),
            ),
            OutlinedButton.icon(
              onPressed: _creating || _openingExisting
                  ? null
                  : _openExistingCompany,
              icon: const Icon(Icons.folder_open_outlined),
              label: Text(_companyTexts(context).openExisting),
            ),
            OutlinedButton.icon(
              onPressed: _creating || _openingExisting
                  ? null
                  : _openExistingCompany,
              icon: const Icon(Icons.search_outlined),
              label: Text(_companyTexts(context).findCompany),
            ),
          ],
        ),
      ],
    );
  }
}

class _CreateCompanyDraft {
  const _CreateCompanyDraft(this.name, this.businessType);

  final String name;
  final CompanyBusinessType businessType;
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
                    _companyTexts(context).recentCompanies,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: companies.isEmpty ? null : () {},
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(_companyTexts(context).editList),
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
                  _companyTexts(context).noCompanies,
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
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(_companyTexts(context).companyName),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(_companyTexts(context).lastOpened),
                        ),
                        Expanded(child: Text(_companyTexts(context).fileSize)),
                        SizedBox(
                          width: 150,
                          child: Text(_companyTexts(context).action),
                        ),
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
        _errorMessage = _companyTexts(context).couldNotOpen;
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
                        width: 92,
                        height: 40,
                        child: FilledButton(
                          onPressed: _openCompany,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _companyTexts(context).open,
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: _companyTexts(context).removeFromList,
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
            Text('Loading companies...'),
          ],
        ),
      ),
    );
  }
}

_CompanyTexts _companyTexts(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'ar'
    ? _CompanyTexts.ar
    : _CompanyTexts.en;

class _CompanyTexts {
  const _CompanyTexts({
    required this.noCompanyOpen,
    required this.pickCompany,
    required this.defaultLocation,
    required this.loadingFailed,
    required this.couldNotCreate,
    required this.couldNotOpen,
    required this.createCompanyFile,
    required this.openCompanyFile,
    required this.companyName,
    required this.cancel,
    required this.continueText,
    required this.createNewCompany,
    required this.createFirstCompany,
    required this.openExisting,
    required this.findCompany,
    required this.recentCompanies,
    required this.editList,
    required this.noCompanies,
    required this.lastOpened,
    required this.fileSize,
    required this.action,
    required this.open,
    required this.removeFromList,
  });

  final String noCompanyOpen;
  final String pickCompany;
  final String defaultLocation;
  final String loadingFailed;
  final String couldNotCreate;
  final String couldNotOpen;
  final String createCompanyFile;
  final String openCompanyFile;
  final String companyName;
  final String cancel;
  final String continueText;
  final String createNewCompany;
  final String createFirstCompany;
  final String openExisting;
  final String findCompany;
  final String recentCompanies;
  final String editList;
  final String noCompanies;
  final String lastOpened;
  final String fileSize;
  final String action;
  final String open;
  final String removeFromList;

  static const en = _CompanyTexts(
    noCompanyOpen: 'Open a company',
    pickCompany:
        'Select a recent company, restore an existing file, or create a new company workspace.',
    defaultLocation: 'Default location: Documents / Zayed / Companies',
    loadingFailed: 'Companies could not be loaded. Try again.',
    couldNotCreate:
        'The company could not be created. Check the selected location and try again.',
    couldNotOpen:
        'The company could not be opened. Check the file and try again.',
    createCompanyFile: 'Create Zayed company file',
    openCompanyFile: 'Open Zayed company file',
    companyName: 'Company name',
    cancel: 'Cancel',
    continueText: 'Continue',
    createNewCompany: 'Create new company',
    createFirstCompany: 'Create first company',
    openExisting: 'Open or restore',
    findCompany: 'Find company file',
    recentCompanies: 'Recent companies',
    editList: 'Edit list',
    noCompanies: 'No companies yet. Create a company to continue.',
    lastOpened: 'Last opened',
    fileSize: 'File size',
    action: 'Action',
    open: 'Open',
    removeFromList: 'Remove from list',
  );

  static const ar = _CompanyTexts(
    noCompanyOpen: 'فتح شركة',
    pickCompany:
        'اختر شركة حديثة، أو افتح ملفاً موجوداً، أو أنشئ مساحة عمل جديدة.',
    defaultLocation: 'الموقع الافتراضي: Documents / Zayed / Companies',
    loadingFailed: 'تعذر تحميل الشركات. حاول مرة أخرى.',
    couldNotCreate: 'تعذر إنشاء الشركة. راجع مكان الحفظ وحاول مرة أخرى.',
    couldNotOpen: 'تعذر فتح الشركة. راجع الملف وحاول مرة أخرى.',
    createCompanyFile: 'إنشاء ملف شركة Zayed',
    openCompanyFile: 'فتح ملف شركة Zayed',
    companyName: 'اسم الشركة',
    cancel: 'إلغاء',
    continueText: 'متابعة',
    createNewCompany: 'إنشاء شركة جديدة',
    createFirstCompany: 'إنشاء أول شركة',
    openExisting: 'فتح أو استعادة',
    findCompany: 'اختيار ملف شركة',
    recentCompanies: 'الشركات الحديثة',
    editList: 'تعديل القائمة',
    noCompanies: 'لا توجد شركات بعد. أنشئ شركة للمتابعة.',
    lastOpened: 'آخر فتح',
    fileSize: 'حجم الملف',
    action: 'الإجراء',
    open: 'فتح',
    removeFromList: 'إزالة من القائمة',
  );
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
