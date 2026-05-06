import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/printing_settings_model.dart';
import '../providers/printing_settings_provider.dart';
import '../widgets/printing_test_preview_card.dart';

class PrintingSettingsScreen extends ConsumerWidget {
  const PrintingSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(printingSettingsProvider);
    final notifier = ref.read(printingSettingsProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    ref.listen(printingSettingsProvider, (previous, next) {
      if (next.saved && previous?.saved != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Printing settings saved.')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Printing Settings'),
        actions: [
          TextButton.icon(
            onPressed: state.saving ? null : notifier.reset,
            icon: const Icon(Icons.restore_outlined),
            label: const Text('Reset'),
          ),
          TextButton.icon(
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
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Document Printing',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Configure professional A4 invoices and thermal receipts. These settings will be consumed by the PDF/printing services when document templates are wired.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _ErrorBanner(message: state.errorMessage!),
                ],
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 980;
                    final left = Column(
                      children: [
                        _ModeCard(state: state, notifier: notifier),
                        const SizedBox(height: 16),
                        _A4Card(state: state, notifier: notifier),
                        const SizedBox(height: 16),
                        _ThermalCard(state: state, notifier: notifier),
                      ],
                    );
                    final right = Column(
                      children: [
                        _BrandingCard(state: state, notifier: notifier),
                        const SizedBox(height: 16),
                        _OptionsCard(state: state, notifier: notifier),
                        const SizedBox(height: 16),
                        _PreviewCard(settings: state.settings),
                        const SizedBox(height: 16),
                        PrintingTestPreviewCard(settings: state.settings),
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
                const SizedBox(height: 24),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: FilledButton.icon(
                    onPressed: state.saving ? null : notifier.save,
                    icon: state.saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Save Printing Settings'),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.state, required this.notifier});
  final PrintingSettingsState state;
  final PrintingSettingsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.print_outlined,
      title: 'Print Mode',
      children: [
        DropdownButtonFormField<PrintMode>(
          initialValue: state.settings.printMode,
          decoration: const InputDecoration(
            labelText: 'Enabled Print Formats',
            border: OutlineInputBorder(),
          ),
          items: PrintMode.values
              .map(
                (mode) => DropdownMenuItem<PrintMode>(
                  value: mode,
                  child: Text(mode.label),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null)
              notifier.update((current) => current.copyWith(printMode: value));
          },
        ),
        const SizedBox(height: 12),
        _TextField(
          label: 'A4 Printer Name',
          value: state.settings.a4PrinterName ?? '',
          icon: Icons.description_outlined,
          onChanged: (value) => notifier.update(
            (current) => current.copyWith(a4PrinterName: value),
          ),
        ),
        const SizedBox(height: 12),
        _TextField(
          label: 'Thermal Printer Name',
          value: state.settings.thermalPrinterName ?? '',
          icon: Icons.receipt_long_outlined,
          onChanged: (value) => notifier.update(
            (current) => current.copyWith(thermalPrinterName: value),
          ),
        ),
      ],
    );
  }
}

class _A4Card extends StatelessWidget {
  const _A4Card({required this.state, required this.notifier});
  final PrintingSettingsState state;
  final PrintingSettingsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.description_outlined,
      title: 'A4 Invoice Template',
      children: [
        DropdownButtonFormField<A4TemplateStyle>(
          initialValue: state.settings.a4TemplateStyle,
          decoration: const InputDecoration(
            labelText: 'A4 Template Style',
            border: OutlineInputBorder(),
          ),
          items: A4TemplateStyle.values
              .map(
                (style) => DropdownMenuItem<A4TemplateStyle>(
                  value: style,
                  child: Text(style.label),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null)
              notifier.update(
                (current) => current.copyWith(a4TemplateStyle: value),
              );
          },
        ),
        const SizedBox(height: 12),
        _TextField(
          label: 'Invoice Footer Message',
          value: state.settings.invoiceFooterMessage ?? '',
          icon: Icons.notes_outlined,
          maxLines: 2,
          onChanged: (value) => notifier.update(
            (current) => current.copyWith(invoiceFooterMessage: value),
          ),
        ),
      ],
    );
  }
}

class _ThermalCard extends StatelessWidget {
  const _ThermalCard({required this.state, required this.notifier});
  final PrintingSettingsState state;
  final PrintingSettingsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.receipt_outlined,
      title: 'Thermal Receipt Template',
      children: [
        DropdownButtonFormField<ThermalWidth>(
          initialValue: state.settings.thermalWidth,
          decoration: const InputDecoration(
            labelText: 'Thermal Paper Width',
            border: OutlineInputBorder(),
          ),
          items: ThermalWidth.values
              .map(
                (width) => DropdownMenuItem<ThermalWidth>(
                  value: width,
                  child: Text(width.label),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null)
              notifier.update(
                (current) => current.copyWith(thermalWidth: value),
              );
          },
        ),
        const SizedBox(height: 12),
        _TextField(
          label: 'Receipt Footer Message',
          value: state.settings.receiptFooterMessage ?? '',
          icon: Icons.notes_outlined,
          maxLines: 2,
          onChanged: (value) => notifier.update(
            (current) => current.copyWith(receiptFooterMessage: value),
          ),
        ),
      ],
    );
  }
}

class _BrandingCard extends StatelessWidget {
  const _BrandingCard({required this.state, required this.notifier});
  final PrintingSettingsState state;
  final PrintingSettingsNotifier notifier;

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
      notifier.update(
        (current) => current.copyWith(logoPath: path, showLogo: true),
      );
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
          value: state.settings.logoPath ?? '',
          icon: Icons.folder_open_outlined,
          onChanged: (value) =>
              notifier.update((current) => current.copyWith(logoPath: value)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _pickLogo(context),
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Choose Logo'),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: (state.settings.logoPath ?? '').isEmpty
                  ? null
                  : () => notifier.update(
                      (current) =>
                          current.copyWith(logoPath: '', showLogo: false),
                    ),
              icon: const Icon(Icons.clear_outlined),
              label: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SwitchRow(
          title: 'Show Logo',
          subtitle:
              'Display company logo on A4 invoices and thermal receipts when possible.',
          value: state.settings.showLogo,
          onChanged: (value) =>
              notifier.update((current) => current.copyWith(showLogo: value)),
        ),
        _SwitchRow(
          title: 'Show Company Address',
          subtitle: 'Print company address under the header.',
          value: state.settings.showCompanyAddress,
          onChanged: (value) => notifier.update(
            (current) => current.copyWith(showCompanyAddress: value),
          ),
        ),
        _SwitchRow(
          title: 'Use Arabic Fonts',
          subtitle: 'Use Arabic-friendly fonts for RTL text in generated PDFs.',
          value: state.settings.useArabicFonts,
          onChanged: (value) => notifier.update(
            (current) => current.copyWith(useArabicFonts: value),
          ),
        ),
      ],
    );
  }
}

class _OptionsCard extends StatelessWidget {
  const _OptionsCard({required this.state, required this.notifier});
  final PrintingSettingsState state;
  final PrintingSettingsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.tune_outlined,
      title: 'Document Options',
      children: [
        _SwitchRow(
          title: 'Show QR Code',
          subtitle: 'Reserve QR area for invoices/receipts.',
          value: state.settings.showQrCode,
          onChanged: (value) =>
              notifier.update((current) => current.copyWith(showQrCode: value)),
        ),
        _SwitchRow(
          title: 'Show Tax Summary',
          subtitle: 'Print tax breakdown when taxes are enabled.',
          value: state.settings.showTaxSummary,
          onChanged: (value) => notifier.update(
            (current) => current.copyWith(showTaxSummary: value),
          ),
        ),
        _SwitchRow(
          title: 'Show Customer Balance',
          subtitle: 'Show previous/current balance on customer documents.',
          value: state.settings.showCustomerBalance,
          onChanged: (value) => notifier.update(
            (current) => current.copyWith(showCustomerBalance: value),
          ),
        ),
        _SwitchRow(
          title: 'Show Item SKU',
          subtitle: 'Print SKU/code beside item names.',
          value: state.settings.showItemSku,
          onChanged: (value) => notifier.update(
            (current) => current.copyWith(showItemSku: value),
          ),
        ),
        _SwitchRow(
          title: 'Preview Before Print',
          subtitle: 'Open preview before sending to the printer.',
          value: state.settings.printPreviewBeforePrint,
          onChanged: (value) => notifier.update(
            (current) => current.copyWith(printPreviewBeforePrint: value),
          ),
        ),
        _SwitchRow(
          title: 'Auto Print After Save',
          subtitle: 'Send print job immediately after saving a transaction.',
          value: state.settings.autoPrintAfterSave,
          onChanged: (value) => notifier.update(
            (current) => current.copyWith(autoPrintAfterSave: value),
          ),
        ),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.settings});
  final PrintingSettingsModel settings;

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
                  child: Icon(
                    Icons.preview_outlined,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Preview Summary',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _PreviewLine(label: 'Formats', value: settings.printMode.label),
            _PreviewLine(
              label: 'A4 style',
              value: settings.a4TemplateStyle.label,
            ),
            _PreviewLine(
              label: 'Thermal width',
              value: settings.thermalWidth.label,
            ),
            _PreviewLine(
              label: 'Logo',
              value: settings.showLogo ? 'Visible' : 'Hidden',
            ),
            if ((settings.logoPath ?? '').isNotEmpty)
              _PreviewLine(label: 'Logo path', value: settings.logoPath!),
            _PreviewLine(
              label: 'QR',
              value: settings.showQrCode ? 'Visible' : 'Hidden',
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Template wiring note',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Print preview and PDF renderers now read these settings, including print mode, logo, fonts, thermal width, footer, tax, and balance options.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
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
  });
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
                CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  child: Icon(icon, color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
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

class _TextField extends StatelessWidget {
  const _TextField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onChanged,
    this.maxLines = 1,
  });
  final String label;
  final String value;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      onChanged: onChanged,
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
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
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
