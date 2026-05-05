// document_print_preview_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../settings/data/models/printing_settings_model.dart';
import '../../settings/providers/printing_settings_provider.dart';
import '../data/models/print_data_contracts.dart';
import '../providers/printing_provider.dart';
import '../services/a4_document_pdf_service.dart';
import '../services/thermal_document_pdf_service.dart';

Future<void> showDocumentPrintPreviewDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String documentType,
  required String documentId,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => DocumentPrintPreviewDialog(
      documentType: documentType,
      documentId: documentId,
    ),
  );
}

class DocumentPrintPreviewDialog extends ConsumerWidget {
  const DocumentPrintPreviewDialog({
    super.key,
    required this.documentType,
    required this.documentId,
  });

  final String documentType;
  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = DocumentPrintDataRequest(
      documentType: documentType,
      documentId: documentId,
    );
    final dataAsync = ref.watch(documentPrintDataProvider(request));
    final settingsState = ref.watch(printingSettingsProvider);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980, maxHeight: 760),
        child: dataAsync.when(
          loading: () => const _LoadingPrintPreview(),
          error: (error, stackTrace) =>
              _PrintPreviewError(message: error.toString()),
          data: (data) => _PrintPreviewContent(
            data: data,
            settings: settingsState.settings,
          ),
        ),
      ),
    );
  }
}

class _LoadingPrintPreview extends StatelessWidget {
  const _LoadingPrintPreview();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading print preview...'),
        ],
      ),
    );
  }
}

class _PrintPreviewError extends StatelessWidget {
  const _PrintPreviewError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: cs.error),
              const SizedBox(width: 8),
              Text(
                'Print preview failed',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 20),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrintPreviewContent extends StatelessWidget {
  const _PrintPreviewContent({required this.data, required this.settings});

  final DocumentPrintDataModel data;
  final PrintingSettingsModel settings;

  bool get _a4Enabled =>
      settings.printMode == PrintMode.a4 ||
      settings.printMode == PrintMode.both;
  bool get _thermalEnabled =>
      settings.printMode == PrintMode.thermal ||
      settings.printMode == PrintMode.both;

  Future<void> _printA4(BuildContext context) async {
    try {
      final service = const A4DocumentPdfService();
      await Printing.layoutPdf(
        name: '${data.documentType}-${data.documentNumber}-A4.pdf',
        onLayout: (_) => service.build(data, settings),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('A4 PDF failed: $error')));
      }
    }
  }

  Future<void> _printThermal(BuildContext context) async {
    try {
      final service = const ThermalDocumentPdfService();
      await Printing.layoutPdf(
        name: '${data.documentType}-${data.documentNumber}-thermal.pdf',
        onLayout: (_) => service.build(data, settings),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Thermal print failed: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            border: Border(bottom: BorderSide(color: cs.outlineVariant)),
          ),
          child: Row(
            children: [
              Icon(Icons.print_outlined, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data.documentType} ${data.documentNumber}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${data.customer.displayName} • ${_formatDate(data.documentDate)} • ${settings.printMode.label}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (_a4Enabled)
                OutlinedButton.icon(
                  onPressed: () => _printA4(context),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('A4 PDF'),
                ),
              if (_a4Enabled && _thermalEnabled) const SizedBox(width: 8),
              if (_thermalEnabled)
                OutlinedButton.icon(
                  onPressed: () => _printThermal(context),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: Text('Thermal ${settings.thermalWidth.label}'),
                ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Container(
                width: 760,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .06),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(data: data, settings: settings),
                    const SizedBox(height: 24),
                    _PartyAndMeta(data: data, settings: settings),
                    const SizedBox(height: 24),
                    _LinesTable(data: data, settings: settings),
                    const SizedBox(height: 18),
                    _Summary(data: data, settings: settings),
                    if ((data.terms ?? '').isNotEmpty ||
                        (data.notes ?? '').isNotEmpty ||
                        (settings.invoiceFooterMessage ?? '').isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _Notes(data: data, settings: settings),
                    ],
                    const SizedBox(height: 18),
                    Text(
                      'Generated: ${_formatDateTime(data.generatedAt)}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.data, required this.settings});

  final DocumentPrintDataModel data;
  final PrintingSettingsModel settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (settings.showLogo) ...[
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'LOGO',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.company.companyName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              if ((data.company.legalName ?? '').isNotEmpty)
                Text(data.company.legalName!),
              if (settings.showCompanyAddress)
                Text('${data.company.country} • ${data.company.currency}'),
              if ((data.company.phone ?? '').isNotEmpty)
                Text('Phone: ${data.company.phone}'),
              if ((data.company.email ?? '').isNotEmpty)
                Text('Email: ${data.company.email}'),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              data.documentType.toUpperCase(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            Text('#${data.documentNumber}', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Chip(label: Text(data.status)),
          ],
        ),
      ],
    );
  }
}

class _PartyAndMeta extends StatelessWidget {
  const _PartyAndMeta({required this.data, required this.settings});

  final DocumentPrintDataModel data;
  final PrintingSettingsModel settings;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _InfoBox(
            title: 'Bill To',
            children: [
              Text(
                data.customer.displayName,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              if ((data.customer.phone ?? '').isNotEmpty)
                Text('Phone: ${data.customer.phone}'),
              if ((data.customer.email ?? '').isNotEmpty)
                Text('Email: ${data.customer.email}'),
              if (settings.showCustomerBalance) ...[
                Text(
                  'Balance: ${_money(data.customer.openBalance, data.customer.currency)}',
                ),
                Text(
                  'Credits: ${_money(data.customer.creditBalance, data.customer.currency)}',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _InfoBox(
            title: 'Document',
            children: [
              _KeyValue(label: 'Date', value: _formatDate(data.documentDate)),
              _KeyValue(label: 'Due date', value: _formatDate(data.dueDate)),
              if ((data.payment?.paymentMethod ?? '').isNotEmpty)
                _KeyValue(
                  label: 'Payment',
                  value: data.payment!.paymentMethod!,
                ),
              if ((data.payment?.depositAccountName ?? '').isNotEmpty)
                _KeyValue(
                  label: 'Deposit',
                  value: data.payment!.depositAccountName!,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LinesTable extends StatelessWidget {
  const _LinesTable({required this.data, required this.settings});

  final DocumentPrintDataModel data;
  final PrintingSettingsModel settings;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(44),
        1: FlexColumnWidth(3),
        2: FixedColumnWidth(80),
        3: FixedColumnWidth(90),
        4: FixedColumnWidth(100),
      },
      border: TableBorder.all(color: cs.outlineVariant),
      children: [
        _tableRow([
          '#',
          settings.showItemSku ? 'Item / SKU' : 'Item',
          'Qty',
          'Price',
          if (settings.showTaxSummary) 'Tax',
          'Total',
        ], header: true),
        ...data.lines.map(
          (line) => _tableRow([
            line.lineNumber.toString(),
            line.description.isNotEmpty ? line.description : line.itemName,
            line.quantity.toStringAsFixed(2),
            _money(line.unitPrice, data.company.currency),
            if (settings.showTaxSummary)
              _money(line.taxAmount, data.company.currency),
            _money(line.lineTotal, data.company.currency),
          ]),
        ),
      ],
    );
  }

  TableRow _tableRow(List<String> cells, {bool header = false}) {
    return TableRow(
      children: cells
          .map(
            (cell) => Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                cell,
                style: TextStyle(
                  fontWeight: header ? FontWeight.w900 : FontWeight.w400,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.data, required this.settings});

  final DocumentPrintDataModel data;
  final PrintingSettingsModel settings;

  @override
  Widget build(BuildContext context) {
    final rows = settings.showTaxSummary
        ? data.summaryRows
        : data.summaryRows
              .where((row) => row.label.toLowerCase() != 'tax')
              .toList();
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: SizedBox(
        width: 320,
        child: Column(
          children: rows
              .map(
                (row) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          row.label,
                          style: TextStyle(
                            fontWeight: row.isStrong
                                ? FontWeight.w900
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        _money(row.amount, data.company.currency),
                        style: TextStyle(
                          fontWeight: row.isStrong
                              ? FontWeight.w900
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _Notes extends StatelessWidget {
  const _Notes({required this.data, required this.settings});

  final DocumentPrintDataModel data;
  final PrintingSettingsModel settings;

  @override
  Widget build(BuildContext context) {
    return _InfoBox(
      title: 'Notes / Terms',
      children: [
        if ((data.terms ?? '').isNotEmpty) Text('Terms: ${data.terms}'),
        if ((data.notes ?? '').isNotEmpty) Text(data.notes!),
        if ((settings.invoiceFooterMessage ?? '').isNotEmpty)
          Text(settings.invoiceFooterMessage!),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

String _money(double value, String currency) =>
    '${value.toStringAsFixed(2)} $currency';
String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
String _formatDateTime(DateTime date) =>
    '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
