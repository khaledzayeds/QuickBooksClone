import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../app/router.dart';
import '../../print_templates/data/models/print_template_model.dart';
import '../../print_templates/data/print_template_repository.dart';
import '../../print_templates/data/sample_templates.dart';
import '../data/models/printing_settings_model.dart';
import '../providers/printing_settings_provider.dart';
import '../widgets/printing_test_preview_card.dart';

class PrintingSettingsScreen extends ConsumerStatefulWidget {
  const PrintingSettingsScreen({super.key});

  @override
  ConsumerState<PrintingSettingsScreen> createState() =>
      _PrintingSettingsScreenState();
}

class _PrintingSettingsScreenState
    extends ConsumerState<PrintingSettingsScreen> {
  late Future<_TemplateCatalog> _catalogFuture;
  List<Printer> _printers = const [];
  bool _loadingPrinters = false;

  @override
  void initState() {
    super.initState();
    _catalogFuture = _loadTemplates();
  }

  Future<_TemplateCatalog> _loadTemplates() async {
    final saved = await const PrintTemplateRepository().list();
    return _TemplateCatalog(saved);
  }

  void _reloadTemplates() {
    final next = _loadTemplates();
    setState(() {
      _catalogFuture = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(printingSettingsProvider);
    final notifier = ref.read(printingSettingsProvider.notifier);
    final theme = Theme.of(context);

    ref.listen(printingSettingsProvider, (previous, next) {
      if (next.saved && previous?.saved != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Printing settings saved.')),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F7),
      appBar: AppBar(
        title: const Text('Printing Settings'),
        actions: [
          TextButton.icon(
            onPressed: _reloadTemplates,
            icon: const Icon(Icons.refresh_outlined),
            label: const Text('Refresh Templates'),
          ),
          TextButton.icon(
            onPressed: state.saving ? null : notifier.reset,
            icon: const Icon(Icons.restore_outlined),
            label: const Text('Reset'),
          ),
          FilledButton.icon(
            onPressed: state.saving ? null : notifier.save,
            icon: state.saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<_TemplateCatalog>(
              future: _catalogFuture,
              builder: (context, snapshot) {
                final catalog = snapshot.data ?? _TemplateCatalog.empty();
                return ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    _Header(
                      title: 'Printing Settings',
                      subtitle:
                          'Set the default printers, receipt width, preview behavior, and branding used by LedgerFlow printing.',
                      loadingTemplates:
                          snapshot.connectionState == ConnectionState.waiting,
                    ),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      _ErrorBanner(message: state.errorMessage!),
                    ],
                    const SizedBox(height: 14),
                    _DocumentProfilesLauncherCard(
                      settings: state.settings,
                      catalog: catalog,
                      loadingTemplates:
                          snapshot.connectionState == ConnectionState.waiting,
                      onChanged: (profile) {
                        notifier.update(
                          (current) => current.updateProfile(profile),
                        );
                      },
                      onOpenDesigner: _openDesigner,
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 980;
                        final left = Column(
                          children: [
                            _PrinterCard(
                              settings: state.settings,
                              printers: _printers,
                              loadingPrinters: _loadingPrinters,
                              onScan: _scanPrinters,
                              onChanged: (change) => notifier.update(change),
                            ),
                            const SizedBox(height: 14),
                            _BrandingCard(
                              settings: state.settings,
                              onChanged: (change) => notifier.update(change),
                            ),
                          ],
                        );
                        final right = Column(
                          children: [
                            _OptionsCard(
                              settings: state.settings,
                              onChanged: (change) => notifier.update(change),
                            ),
                            const SizedBox(height: 14),
                            PrintingTestPreviewCard(settings: state.settings),
                          ],
                        );
                        if (!wide) {
                          return Column(
                            children: [left, const SizedBox(height: 14), right],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: left),
                            const SizedBox(width: 14),
                            Expanded(child: right),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Built-in print layouts are used automatically. Templates and the designer are optional customizations.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Future<void> _scanPrinters() async {
    setState(() => _loadingPrinters = true);
    try {
      final printers = await Printing.listPrinters();
      if (!mounted) return;
      setState(() => _printers = printers);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Printer scan failed: $error')));
    } finally {
      if (mounted) setState(() => _loadingPrinters = false);
    }
  }

  Future<void> _openDesigner({
    required String documentType,
    required String paperKind,
    String? templateId,
  }) async {
    final normalizedDocumentType = normalizePrintDocumentType(documentType);
    final query = <String, String>{
      'documentType': normalizedDocumentType,
      'paperKind': paperKind,
      if ((templateId ?? '').isNotEmpty) 'templateId': templateId!,
    };
    await context.push(
      Uri(
        path: AppRoutes.printTemplateDesigner,
        queryParameters: query,
      ).toString(),
    );
    _reloadTemplates();
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.loadingTemplates,
  });

  final String title;
  final String subtitle;
  final bool loadingTemplates;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (loadingTemplates)
          const Padding(
            padding: EdgeInsetsDirectional.only(start: 16, top: 8),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }
}

class _DocumentProfilesLauncherCard extends StatelessWidget {
  const _DocumentProfilesLauncherCard({
    required this.settings,
    required this.catalog,
    required this.loadingTemplates,
    required this.onChanged,
    required this.onOpenDesigner,
  });

  final PrintingSettingsModel settings;
  final _TemplateCatalog catalog;
  final bool loadingTemplates;
  final ValueChanged<DocumentPrintProfile> onChanged;
  final Future<void> Function({
    required String documentType,
    required String paperKind,
    String? templateId,
  })
  onOpenDesigner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.tune_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Document print profiles',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    settings.enableTemplateDesigner
                        ? 'Choose templates per document for custom output.'
                        : 'Disabled. Built-in LedgerFlow layouts print every document.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: loadingTemplates || !settings.enableTemplateDesigner
                  ? null
                  : () => showDialog<void>(
                      context: context,
                      builder: (dialogContext) => Dialog(
                        insetPadding: const EdgeInsets.all(24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 1180,
                            maxHeight: 760,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Document print profiles',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Close',
                                      onPressed: () =>
                                          Navigator.of(dialogContext).pop(),
                                      icon: const Icon(Icons.close),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: _DocumentProfilesTable(
                                      settings: settings,
                                      catalog: catalog,
                                      onChanged: onChanged,
                                      onOpenDesigner: onOpenDesigner,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
              icon: const Icon(Icons.list_alt_outlined),
              label: const Text('Choose templates per document'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentProfilesTable extends StatelessWidget {
  const _DocumentProfilesTable({
    required this.settings,
    required this.catalog,
    required this.onChanged,
    required this.onOpenDesigner,
  });

  final PrintingSettingsModel settings;
  final _TemplateCatalog catalog;
  final ValueChanged<DocumentPrintProfile> onChanged;
  final Future<void> Function({
    required String documentType,
    required String paperKind,
    String? templateId,
  })
  onOpenDesigner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Document Profiles',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...printDocumentTypeOptions.map((option) {
              final profile = settings.profileFor(option.key);
              final effective = settings.effectiveFor(option.key);
              return _DocumentProfileRow(
                option: option,
                profile: profile,
                effective: effective,
                catalog: catalog,
                onChanged: onChanged,
                onOpenDesigner: onOpenDesigner,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _DocumentProfileRow extends StatelessWidget {
  const _DocumentProfileRow({
    required this.option,
    required this.profile,
    required this.effective,
    required this.catalog,
    required this.onChanged,
    required this.onOpenDesigner,
  });

  final PrintDocumentTypeOption option;
  final DocumentPrintProfile profile;
  final PrintingSettingsModel effective;
  final _TemplateCatalog catalog;
  final ValueChanged<DocumentPrintProfile> onChanged;
  final Future<void> Function({
    required String documentType,
    required String paperKind,
    String? templateId,
  })
  onOpenDesigner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a4Choices = catalog.choicesFor(option.key, 'a4');
    final thermalChoices = catalog.choicesFor(option.key, 'thermal');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 930;
          final name = _DocumentName(option: option);
          final mode = DropdownButtonFormField<PrintMode>(
            key: ValueKey('${option.key}-mode-${effective.printMode.name}'),
            initialValue: effective.printMode,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Mode',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: PrintMode.values
                .map(
                  (mode) =>
                      DropdownMenuItem(value: mode, child: Text(mode.label)),
                )
                .toList(),
            selectedItemBuilder: (context) => PrintMode.values
                .map(
                  (mode) => Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      mode.shortLabel,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onChanged(profile.copyWith(printMode: value));
              }
            },
          );
          final a4Selector = _TemplateSelector(
            label: 'A4 Template',
            choices: a4Choices,
            value: profile.a4TemplateBackendId ?? profile.templateBackendId,
            onChanged: (choice) => onChanged(
              profile.copyWith(
                a4TemplateBackendId: choice.id,
                a4TemplateName: choice.label,
                clearA4Template: choice.id.isEmpty,
              ),
            ),
          );
          final thermalSelector = _TemplateSelector(
            label: 'Thermal Template',
            choices: thermalChoices,
            value: profile.thermalTemplateBackendId,
            onChanged: (choice) => onChanged(
              profile.copyWith(
                thermalTemplateBackendId: choice.id,
                thermalTemplateName: choice.label,
                clearThermalTemplate: choice.id.isEmpty,
              ),
            ),
          );
          final actions = Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                onPressed: () => onOpenDesigner(
                  documentType: option.key,
                  paperKind: 'a4',
                  templateId:
                      profile.a4TemplateBackendId ?? profile.templateBackendId,
                ),
                icon: const Icon(Icons.description_outlined, size: 18),
                label: const Text('Design A4'),
              ),
              OutlinedButton.icon(
                onPressed: () => onOpenDesigner(
                  documentType: option.key,
                  paperKind: 'thermal',
                  templateId: profile.thermalTemplateBackendId,
                ),
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('Design Thermal'),
              ),
              TextButton.icon(
                onPressed: () =>
                    onChanged(DocumentPrintProfile(documentType: option.key)),
                icon: const Icon(Icons.restart_alt_outlined, size: 18),
                label: const Text('Reset'),
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                name,
                const SizedBox(height: 8),
                mode,
                const SizedBox(height: 8),
                a4Selector,
                const SizedBox(height: 8),
                thermalSelector,
                const SizedBox(height: 8),
                actions,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: 190, child: name),
              const SizedBox(width: 8),
              SizedBox(width: 150, child: mode),
              const SizedBox(width: 8),
              Expanded(child: a4Selector),
              const SizedBox(width: 8),
              Expanded(child: thermalSelector),
              const SizedBox(width: 8),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _DocumentName extends StatelessWidget {
  const _DocumentName({required this.option});

  final PrintDocumentTypeOption option;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            _iconFor(option.group),
            size: 18,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                option.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                option.group,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _iconFor(String group) {
    return switch (group) {
      'Purchasing' => Icons.local_shipping_outlined,
      'Inventory' => Icons.inventory_2_outlined,
      _ => Icons.sell_outlined,
    };
  }
}

class _TemplateSelector extends StatelessWidget {
  const _TemplateSelector({
    required this.label,
    required this.choices,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final List<_TemplateChoice> choices;
  final String? value;
  final ValueChanged<_TemplateChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeValue = choices.any((choice) => choice.id == value) ? value : '';
    return DropdownButtonFormField<String>(
      key: ValueKey('$label-$safeValue-${choices.length}'),
      initialValue: safeValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      items: choices
          .map(
            (choice) => DropdownMenuItem<String>(
              value: choice.id,
              child: Text(choice.displayLabel, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      selectedItemBuilder: (context) => choices
          .map(
            (choice) => Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                choice.label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          )
          .toList(),
      onChanged: (next) {
        final choice = choices.firstWhere(
          (item) => item.id == next,
          orElse: () => choices.first,
        );
        onChanged(choice);
      },
    );
  }
}

class _PrinterCard extends StatelessWidget {
  const _PrinterCard({
    required this.settings,
    required this.printers,
    required this.loadingPrinters,
    required this.onScan,
    required this.onChanged,
  });

  final PrintingSettingsModel settings;
  final List<Printer> printers;
  final bool loadingPrinters;
  final VoidCallback onScan;
  final ValueChanged<PrintingSettingsModel Function(PrintingSettingsModel)>
  onChanged;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.print_outlined,
      title: 'Printers',
      trailing: OutlinedButton.icon(
        onPressed: loadingPrinters ? null : onScan,
        icon: loadingPrinters
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.search_outlined),
        label: const Text('Scan'),
      ),
      children: [
        if (printers.isEmpty)
          Text(
            'Scan printers to store a stable printer URL. When Preview before print is off, LedgerFlow sends the job directly to the selected printer.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else ...[
          _PrinterDropdown(
            label: 'A4 Printer',
            value: settings.a4PrinterName,
            printers: printers,
            onChanged: (value) =>
                onChanged((current) => current.copyWith(a4PrinterName: value)),
          ),
          const SizedBox(height: 10),
          _PrinterDropdown(
            label: 'Thermal Printer',
            value: settings.thermalPrinterName,
            printers: printers,
            onChanged: (value) => onChanged(
              (current) => current.copyWith(thermalPrinterName: value),
            ),
          ),
          const SizedBox(height: 10),
        ],
        _TextField(
          label: 'A4 printer name / URL',
          value: settings.a4PrinterName ?? '',
          icon: Icons.description_outlined,
          onChanged: (value) =>
              onChanged((current) => current.copyWith(a4PrinterName: value)),
        ),
        const SizedBox(height: 10),
        _TextField(
          label: 'Thermal printer name / URL',
          value: settings.thermalPrinterName ?? '',
          icon: Icons.receipt_long_outlined,
          onChanged: (value) => onChanged(
            (current) => current.copyWith(thermalPrinterName: value),
          ),
        ),
      ],
    );
  }
}

class _PrinterDropdown extends StatelessWidget {
  const _PrinterDropdown({
    required this.label,
    required this.value,
    required this.printers,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<Printer> printers;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final urls = printers.map((printer) => printer.url).toSet();
    final safeValue = urls.contains(value) ? value : null;
    return DropdownButtonFormField<String>(
      key: ValueKey('$label-$safeValue-${printers.length}'),
      initialValue: safeValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: printers
          .map(
            (printer) => DropdownMenuItem(
              value: printer.url,
              child: Text(
                printer.name.isEmpty ? printer.url : printer.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      selectedItemBuilder: (context) => printers
          .map(
            (printer) => Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                printer.name.isEmpty ? printer.url : printer.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _BrandingCard extends StatelessWidget {
  const _BrandingCard({required this.settings, required this.onChanged});

  final PrintingSettingsModel settings;
  final ValueChanged<PrintingSettingsModel Function(PrintingSettingsModel)>
  onChanged;

  Future<void> _pickLogo(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
        allowMultiple: false,
        withData: false,
      );
      final path = result?.files.single.path;
      if (path == null || path.trim().isEmpty) return;
      onChanged((current) => current.copyWith(logoPath: path, showLogo: true));
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logo picker failed: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.image_outlined,
      title: 'Branding',
      children: [
        _TextField(
          label: 'Logo Path',
          value: settings.logoPath ?? '',
          icon: Icons.folder_open_outlined,
          onChanged: (value) =>
              onChanged((current) => current.copyWith(logoPath: value)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _pickLogo(context),
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Choose Logo'),
            ),
            TextButton.icon(
              onPressed: (settings.logoPath ?? '').isEmpty
                  ? null
                  : () => onChanged(
                      (current) =>
                          current.copyWith(logoPath: '', showLogo: false),
                    ),
              icon: const Icon(Icons.clear_outlined),
              label: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _SwitchRow(
          title: 'Show logo',
          subtitle: 'Display company logo when the template has a logo area.',
          value: settings.showLogo,
          onChanged: (value) =>
              onChanged((current) => current.copyWith(showLogo: value)),
        ),
        _SwitchRow(
          title: 'Show company address',
          subtitle: 'Print company address under the header.',
          value: settings.showCompanyAddress,
          onChanged: (value) => onChanged(
            (current) => current.copyWith(showCompanyAddress: value),
          ),
        ),
        _SwitchRow(
          title: 'Use Arabic fonts',
          subtitle: 'Use bundled RTL-friendly fonts for generated PDFs.',
          value: settings.useArabicFonts,
          onChanged: (value) =>
              onChanged((current) => current.copyWith(useArabicFonts: value)),
        ),
      ],
    );
  }
}

class _OptionsCard extends StatelessWidget {
  const _OptionsCard({required this.settings, required this.onChanged});

  final PrintingSettingsModel settings;
  final ValueChanged<PrintingSettingsModel Function(PrintingSettingsModel)>
  onChanged;

  @override
  Widget build(BuildContext context) {
    final hasPrinterUrl =
        (settings.a4PrinterName?.trim().isNotEmpty ?? false) ||
        (settings.thermalPrinterName?.trim().isNotEmpty ?? false);

    return _SectionCard(
      icon: Icons.tune_outlined,
      title: 'Global Print Options',
      children: [
        // Direct-print toggle — highlight it visually when a printer URL is set.
        _DirectPrintTile(
          previewEnabled: settings.printPreviewBeforePrint,
          hasPrinterUrl: hasPrinterUrl,
          onChanged: (value) => onChanged(
            (current) => current.copyWith(printPreviewBeforePrint: value),
          ),
        ),
        const SizedBox(height: 4),
        _SwitchRow(
          title: 'Auto print after save',
          subtitle: 'Send print jobs immediately after saving transactions.',
          value: settings.autoPrintAfterSave,
          onChanged: (value) => onChanged(
            (current) => current.copyWith(autoPrintAfterSave: value),
          ),
        ),
        _SwitchRow(
          title: 'Enable template designer',
          subtitle:
              'Phase two customization. Keep this off for stable built-in printing.',
          value: settings.enableTemplateDesigner,
          onChanged: (value) => onChanged(
            (current) => current.copyWith(enableTemplateDesigner: value),
          ),
        ),
        const SizedBox(height: 4),
        _SwitchRow(
          title: 'Show QR code',
          subtitle: 'Reserve QR areas for invoices and receipts.',
          value: settings.showQrCode,
          onChanged: (value) =>
              onChanged((current) => current.copyWith(showQrCode: value)),
        ),
        _SwitchRow(
          title: 'Show tax summary',
          subtitle: 'Print tax breakdown when taxes are enabled.',
          value: settings.showTaxSummary,
          onChanged: (value) =>
              onChanged((current) => current.copyWith(showTaxSummary: value)),
        ),
        _SwitchRow(
          title: 'Show customer balance',
          subtitle: 'Only customer documents display balance and credit lines.',
          value: settings.showCustomerBalance,
          onChanged: (value) => onChanged(
            (current) => current.copyWith(showCustomerBalance: value),
          ),
        ),
        _SwitchRow(
          title: 'Show item SKU',
          subtitle: 'Optional item code visibility in print lines.',
          value: settings.showItemSku,
          onChanged: (value) =>
              onChanged((current) => current.copyWith(showItemSku: value)),
        ),
      ],
    );
  }
}

/// A prominent tile that controls preview-vs-direct-print behaviour.
/// When [hasPrinterUrl] is true and preview is disabled it glows green to
/// signal cashier / kiosk mode is active.
class _DirectPrintTile extends StatelessWidget {
  const _DirectPrintTile({
    required this.previewEnabled,
    required this.hasPrinterUrl,
    required this.onChanged,
  });

  final bool previewEnabled;
  final bool hasPrinterUrl;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    // Direct-print mode is active when preview is OFF and a URL is configured.
    final directActive = !previewEnabled && hasPrinterUrl;

    final tileColor = directActive
        ? Colors.green.shade50
        : previewEnabled
        ? cs.surfaceContainerLow
        : cs.errorContainer.withValues(alpha: .35);

    final borderColor = directActive
        ? Colors.green.shade300
        : previewEnabled
        ? cs.outlineVariant
        : cs.error.withValues(alpha: .4);

    final statusIcon = directActive
        ? Icons.bolt_outlined
        : previewEnabled
        ? Icons.visibility_outlined
        : Icons.warning_amber_rounded;

    final statusColor = directActive
        ? Colors.green.shade700
        : previewEnabled
        ? cs.primary
        : cs.error;

    final title = previewEnabled
        ? 'Preview before print'
        : 'Direct print (no dialog)';
    final subtitle = directActive
        ? 'Cashier / kiosk mode — prints instantly to your configured printer.'
        : previewEnabled
        ? 'A preview dialog appears before every print job.'
        : 'No preview dialog — but no printer URL is set yet. Go to Printers above.';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: previewEnabled,
            activeThumbColor: cs.primary,
            onChanged: onChanged,
          ),
        ],
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
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(icon, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _TextField extends StatefulWidget {
  const _TextField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onChanged,
  });

  final String label;
  final String value;
  final IconData icon;
  final ValueChanged<String> onChanged;

  @override
  State<_TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<_TextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _TextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(widget.icon),
      ),
      onChanged: widget.onChanged,
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
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
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCatalog {
  const _TemplateCatalog(this.savedTemplates);

  factory _TemplateCatalog.empty() => const _TemplateCatalog([]);

  final List<PrintTemplateModel> savedTemplates;

  List<_TemplateChoice> choicesFor(String documentType, String paperKind) {
    final normalizedDocumentType = normalizePrintDocumentType(documentType);
    final choices = <_TemplateChoice>[
      const _TemplateChoice(
        id: '',
        label: 'Automatic default',
        source: 'System',
      ),
    ];
    choices.addAll(
      SamplePrintTemplates.defaults()
          .where(
            (template) =>
                normalizePrintDocumentType(template.documentType) ==
                    normalizedDocumentType &&
                _matchesPaper(template, paperKind),
          )
          .map(_TemplateChoice.builtIn),
    );
    choices.addAll(
      savedTemplates
          .where(
            (template) =>
                normalizePrintDocumentType(template.documentType) ==
                    normalizedDocumentType &&
                _matchesPaper(template, paperKind),
          )
          .map(_TemplateChoice.saved),
    );
    return choices;
  }

  static bool _matchesPaper(PrintTemplateModel template, String paperKind) {
    final thermal = _isThermal(template);
    return paperKind.toLowerCase() == 'thermal' ? thermal : !thermal;
  }

  static bool _isThermal(PrintTemplateModel template) {
    final size = template.pageSize.toLowerCase();
    return size.contains('receipt') ||
        size.contains('thermal') ||
        template.page.widthMm <= 90;
  }
}

class _TemplateChoice {
  const _TemplateChoice({
    required this.id,
    required this.label,
    required this.source,
  });

  factory _TemplateChoice.builtIn(PrintTemplateModel template) {
    return _TemplateChoice(
      id: 'builtin:${template.id}',
      label: template.name,
      source: 'Built-in',
    );
  }

  factory _TemplateChoice.saved(PrintTemplateModel template) {
    return _TemplateChoice(
      id: template.backendId ?? template.id,
      label: template.name,
      source: 'Saved',
    );
  }

  final String id;
  final String label;
  final String source;

  String get displayLabel => '$label - $source';
}
