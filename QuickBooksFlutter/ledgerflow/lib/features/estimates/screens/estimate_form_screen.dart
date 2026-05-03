// estimate_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../customers/providers/customers_provider.dart';
import '../../items/providers/items_provider.dart';
import '../data/models/estimate_model.dart';
import '../providers/estimates_provider.dart';

class EstimateLineState {
  String? itemId;
  String description = '';
  double quantity = 1;
  double unitPrice = 0;

  double get total => quantity * unitPrice;
}

class EstimateFormState {
  String? customerId;
  DateTime estimateDate = DateTime.now();
  DateTime expirationDate = DateTime.now().add(const Duration(days: 30));
  List<EstimateLineState> lines = [EstimateLineState()];

  double get subtotal => lines.fold(0, (sum, line) => sum + line.total);
}

final estimateFormProvider = StateProvider.autoDispose<EstimateFormState>((ref) => EstimateFormState());
final estimateSavingProvider = StateProvider.autoDispose<bool>((ref) => false);

class EstimateFormScreen extends ConsumerWidget {
  const EstimateFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final form = ref.watch(estimateFormProvider);
    final saving = ref.watch(estimateSavingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.newText} ${l10n.estimates}'),
        actions: [
          AppButton(
            label: l10n.cancel,
            variant: AppButtonVariant.secondary,
            onPressed: saving ? null : () => context.canPop() ? context.pop() : context.go('/sales/estimates'),
          ),
          const SizedBox(width: 12),
          AppButton(
            label: l10n.save,
            loading: saving,
            onPressed: saving ? null : () => _save(context, ref),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _HeaderCard(form: form),
          const SizedBox(height: 24),
          _LinesCard(form: form),
          const SizedBox(height: 24),
          Align(alignment: AlignmentDirectional.centerEnd, child: _TotalsCard(total: form.subtotal)),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final form = ref.read(estimateFormProvider);

    if (form.customerId == null || form.customerId!.isEmpty) {
      _error(context, l10n.selectCustomerFirst);
      return;
    }

    final validLines = form.lines.where((line) => line.itemId != null && line.itemId!.isNotEmpty && line.quantity > 0).toList();
    if (validLines.isEmpty) {
      _error(context, l10n.selectAtLeastOneLine);
      return;
    }

    final dto = CreateEstimateDto(
      customerId: form.customerId!,
      estimateDate: form.estimateDate,
      expirationDate: form.expirationDate,
      saveMode: 1,
      lines: validLines
          .map(
            (line) => CreateEstimateLineDto(
              itemId: line.itemId!,
              description: line.description,
              quantity: line.quantity,
              unitPrice: line.unitPrice,
            ),
          )
          .toList(),
    );

    ref.read(estimateSavingProvider.notifier).state = true;
    final result = await ref.read(estimatesProvider.notifier).create(dto);
    ref.read(estimateSavingProvider.notifier).state = false;

    if (!context.mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.poCreatedSuccess)));
        context.go('/sales/estimates');
      },
      failure: (error) => _error(context, error.message),
    );
  }

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static void _error(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }
}

class _HeaderCard extends ConsumerWidget {
  const _HeaderCard({required this.form});

  final EstimateFormState form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final customersAsync = ref.watch(customersProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: form.customerId,
              decoration: InputDecoration(
                labelText: '${l10n.customer} *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              items: customersAsync.maybeWhen(
                data: (customers) => customers
                    .map<DropdownMenuItem<String>>((customer) => DropdownMenuItem(value: customer.id, child: Text(customer.displayName)))
                    .toList(),
                orElse: () => const <DropdownMenuItem<String>>[],
              ),
              onChanged: (value) => _update(ref, form..customerId = value),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: l10n.billDate,
                    readOnly: true,
                    initialValue: EstimateFormScreen._dateOnly(form.estimateDate),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: l10n.dueDate,
                    readOnly: true,
                    initialValue: EstimateFormScreen._dateOnly(form.expirationDate),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LinesCard extends ConsumerWidget {
  const _LinesCard({required this.form});

  final EstimateFormState form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(flex: 3, child: Text(l10n.itemService)),
                Expanded(child: Text(l10n.qty)),
                Expanded(child: Text(l10n.rate)),
                Expanded(child: Text(l10n.amount)),
                const SizedBox(width: 40),
              ],
            ),
            const Divider(),
            ...form.lines.asMap().entries.map((entry) => _EstimateLineRow(index: entry.key, line: entry.value, form: form)),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () {
                  form.lines.add(EstimateLineState());
                  _update(ref, form);
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.addLine),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstimateLineRow extends ConsumerWidget {
  const _EstimateLineRow({required this.index, required this.line, required this.form});

  final int index;
  final EstimateLineState line;
  final EstimateFormState form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: DropdownButtonFormField<String>(
                initialValue: line.itemId,
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                items: itemsAsync.maybeWhen(
                  data: (items) => items
                      .where((item) => item.isActive)
                      .map((item) => DropdownMenuItem(value: item.id, child: Text(item.name)))
                      .toList(),
                  orElse: () => const <DropdownMenuItem<String>>[],
                ),
                onChanged: (value) {
                  final item = (itemsAsync.value ?? []).where((item) => item.id == value).firstOrNull;
                  line.itemId = value;
                  line.description = item?.name ?? '';
                  line.unitPrice = item?.salesPrice ?? line.unitPrice;
                  _update(ref, form);
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: AppTextField(
                key: ValueKey('qty-$index-${line.quantity}'),
                label: '',
                initialValue: line.quantity.toString(),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  line.quantity = double.tryParse(value) ?? 0;
                  _update(ref, form);
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: AppTextField(
                key: ValueKey('price-$index-${line.unitPrice}'),
                label: '',
                initialValue: line.unitPrice == 0 ? '' : line.unitPrice.toStringAsFixed(2),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  line.unitPrice = double.tryParse(value) ?? 0;
                  _update(ref, form);
                },
              ),
            ),
          ),
          Expanded(child: Text(line.total.toStringAsFixed(2), textAlign: TextAlign.end)),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: form.lines.length <= 1
                  ? null
                  : () {
                      form.lines.removeAt(index);
                      _update(ref, form);
                    },
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: SizedBox(
        width: 320,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.total, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '${total.toStringAsFixed(2)} ${l10n.egp}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _update(WidgetRef ref, EstimateFormState old) {
  ref.read(estimateFormProvider.notifier).state = EstimateFormState()
    ..customerId = old.customerId
    ..estimateDate = old.estimateDate
    ..expirationDate = old.expirationDate
    ..lines = List.from(old.lines);
}
