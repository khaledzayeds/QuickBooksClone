// invoice_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../customers/providers/customers_provider.dart';
import '../../items/providers/items_provider.dart';

// ─── Local State for Form ────────────────────────────────
class InvoiceLineState {
  String? itemId;
  String description = '';
  double quantity = 1;
  double unitPrice = 0;

  double get total => quantity * unitPrice;
}

class InvoiceFormState {
  String? customerId;
  DateTime invoiceDate = DateTime.now();
  DateTime dueDate = DateTime.now().add(const Duration(days: 14));
  List<InvoiceLineState> lines = [InvoiceLineState()];

  double get subtotal => lines.fold(0, (sum, line) => sum + line.total);
}

final invoiceFormProvider = StateProvider.autoDispose<InvoiceFormState>((ref) {
  return InvoiceFormState();
});

// ─── Screen ──────────────────────────────────────────────
class InvoiceFormScreen extends ConsumerWidget {
  const InvoiceFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(invoiceFormProvider);
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Text('${l10n.invoices} (${l10n.newText})'),
        backgroundColor: cs.surface,
        scrolledUnderElevation: 0,
        actions: [
          AppButton(
            label: l10n.cancel,
            variant: AppButtonVariant.secondary,
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 12),
          AppButton(
            label: l10n.save,
            onPressed: () {
              // TODO: Implement saving logic to backend
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Saving invoice... (API integration pending)'),
                ),
              );
            },
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Section (Customer & Dates)
            _HeaderSection(),
            const SizedBox(height: 32),

            // ── Lines Section
            _LinesSection(),
            const SizedBox(height: 32),

            // ── Totals Section
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: _TotalsSection(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header Section ──────────────────────────────────────
class _HeaderSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersProvider);
    final formState = ref.watch(invoiceFormProvider);
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          final customerDropdown = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'العميل',
                style: Theme.of(context).textTheme.labelMedium,
              ), // Localized later
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: customersAsync.when(
                    data: (customers) => DropdownButton<String>(
                      isExpanded: true,
                      value: formState.customerId,
                      hint: const Text('اختر عميل...'),
                      items: customers
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        final state = ref.read(invoiceFormProvider);
                        state.customerId = val;
                        ref.read(invoiceFormProvider.notifier).state =
                            state; // Trigger rebuild
                      },
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading customers: $e'),
                  ),
                ),
              ),
            ],
          );

          final dates = Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تاريخ الفاتورة',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      label: '',
                      readOnly: true,
                      initialValue: '${formState.invoiceDate.toLocal()}'.split(
                        ' ',
                      )[0],
                      suffixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تاريخ الاستحقاق',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      label: '',
                      readOnly: true,
                      initialValue: '${formState.dueDate.toLocal()}'.split(
                        ' ',
                      )[0],
                      suffixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                  ],
                ),
              ),
            ],
          );

          if (isMobile) {
            return Column(
              children: [customerDropdown, const SizedBox(height: 16), dates],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: customerDropdown),
              const SizedBox(width: 32),
              Expanded(flex: 3, child: dates),
            ],
          );
        },
      ),
    );
  }
}

// ─── Lines Section ───────────────────────────────────────
class _LinesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(invoiceFormProvider);
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'الصنف / الوصف',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'الكمية',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'السعر',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'الإجمالي',
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(width: 48), // Action icon space
              ],
            ),
          ),

          // Table Rows
          ...formState.lines.asMap().entries.map((entry) {
            final index = entry.key;
            final line = entry.value;
            return _LineRow(index: index, line: line);
          }),

          // Add Line Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () {
                  final state = ref.read(invoiceFormProvider);
                  state.lines.add(InvoiceLineState());
                  ref
                      .read(invoiceFormProvider.notifier)
                      .state = InvoiceFormState()
                    ..lines = state.lines
                    ..customerId = state.customerId
                    ..invoiceDate = state.invoiceDate
                    ..dueDate = state.dueDate; // Force rebuild
                },
                icon: const Icon(Icons.add),
                label: const Text('إضافة سطر'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineRow extends ConsumerWidget {
  const _LineRow({required this.index, required this.line});
  final int index;
  final InvoiceLineState line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemsProvider);
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          // Item Select
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: itemsAsync.when(
                    data: (items) => DropdownButton<String>(
                      isExpanded: true,
                      value: line.itemId,
                      hint: const Text('اختر صنف...'),
                      items: items
                          .map(
                            (i) => DropdownMenuItem(
                              value: i.id,
                              child: Text(i.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        final selectedItem = items.firstWhere(
                          (i) => i.id == val,
                        );
                        final state = ref.read(invoiceFormProvider);
                        state.lines[index].itemId = val;
                        state.lines[index].unitPrice = selectedItem.salesPrice;
                        state.lines[index].description = selectedItem.name;
                        _forceRebuild(ref, state);
                      },
                    ),
                    loading: () => const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, __) => const Text('Error'),
                  ),
                ),
              ),
            ),
          ),

          // Quantity
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: AppTextField(
                label: '',
                initialValue: line.quantity.toString(),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final state = ref.read(invoiceFormProvider);
                  state.lines[index].quantity = double.tryParse(v) ?? 0;
                  _forceRebuild(ref, state);
                },
              ),
            ),
          ),

          // Unit Price
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: AppTextField(
                label: '',
                initialValue: line.unitPrice.toString(),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final state = ref.read(invoiceFormProvider);
                  state.lines[index].unitPrice = double.tryParse(v) ?? 0;
                  _forceRebuild(ref, state);
                },
              ),
            ),
          ),

          // Total
          Expanded(
            flex: 1,
            child: Text(
              line.total.toStringAsFixed(2),
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // Action
          SizedBox(
            width: 48,
            child: IconButton(
              icon: Icon(Icons.delete_outline, color: cs.error),
              onPressed: () {
                final state = ref.read(invoiceFormProvider);
                if (state.lines.length > 1) {
                  state.lines.removeAt(index);
                  _forceRebuild(ref, state);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _forceRebuild(WidgetRef ref, InvoiceFormState oldState) {
    ref.read(invoiceFormProvider.notifier).state = InvoiceFormState()
      ..customerId = oldState.customerId
      ..invoiceDate = oldState.invoiceDate
      ..dueDate = oldState.dueDate
      ..lines = List.from(oldState.lines);
  }
}

// ─── Totals Section ──────────────────────────────────────
class _TotalsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(invoiceFormProvider);
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المجموع الفرعي (Subtotal)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                formState.subtotal.toStringAsFixed(2),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الضريبة (Tax)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'يتم حسابها بعد الحفظ',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.primary),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الإجمالي (Total)',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                formState.subtotal.toStringAsFixed(2),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
