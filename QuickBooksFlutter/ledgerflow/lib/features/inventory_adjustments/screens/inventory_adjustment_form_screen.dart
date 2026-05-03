// inventory_adjustment_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../core/constants/api_enums.dart' show AccountType;
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../accounts/data/models/account_model.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../items/data/models/item_model.dart';
import '../../items/providers/items_provider.dart';
import '../data/models/inventory_adjustment_model.dart';
import '../providers/inventory_adjustments_provider.dart';

class InventoryAdjustmentFormState {
  String? itemId;
  String? adjustmentAccountId;
  DateTime adjustmentDate = DateTime.now();
  double quantityChange = 0;
  double unitCost = 0;
  String reason = '';

  double get total => quantityChange.abs() * unitCost;
}

final inventoryAdjustmentFormProvider = StateProvider.autoDispose<InventoryAdjustmentFormState>(
  (ref) => InventoryAdjustmentFormState(),
);

final inventoryAdjustmentSavingProvider = StateProvider.autoDispose<bool>((ref) => false);

class InventoryAdjustmentFormScreen extends ConsumerWidget {
  const InventoryAdjustmentFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final form = ref.watch(inventoryAdjustmentFormProvider);
    final saving = ref.watch(inventoryAdjustmentSavingProvider);
    final itemsAsync = ref.watch(itemsProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.newInventoryAdjustment),
        actions: [
          AppButton(
            label: l10n.cancel,
            variant: AppButtonVariant.secondary,
            onPressed: saving ? null : () => context.canPop() ? context.pop() : context.go('/master/items'),
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
          _AdjustmentCard(
            form: form,
            itemsAsync: itemsAsync,
            accountsAsync: accountsAsync,
          ),
          const SizedBox(height: 24),
          Align(alignment: AlignmentDirectional.centerEnd, child: _TotalCard(total: form.total)),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final form = ref.read(inventoryAdjustmentFormProvider);

    if (form.itemId == null || form.itemId!.isEmpty) {
      _error(context, l10n.selectItemFirst);
      return;
    }
    if (form.adjustmentAccountId == null || form.adjustmentAccountId!.isEmpty) {
      _error(context, l10n.selectPaymentAccountFirst);
      return;
    }
    if (form.quantityChange == 0) {
      _error(context, l10n.enterValidQuantity);
      return;
    }
    if (form.unitCost <= 0) {
      _error(context, l10n.enterPositiveAmount);
      return;
    }

    final dto = CreateInventoryAdjustmentDto(
      itemId: form.itemId!,
      adjustmentAccountId: form.adjustmentAccountId!,
      adjustmentDate: form.adjustmentDate,
      quantityChange: form.quantityChange,
      unitCost: form.unitCost,
      reason: form.reason,
    );

    ref.read(inventoryAdjustmentSavingProvider.notifier).state = true;
    final result = await ref.read(inventoryAdjustmentsProvider.notifier).create(dto);
    ref.read(inventoryAdjustmentSavingProvider.notifier).state = false;

    if (!context.mounted) return;

    result.when(
      success: (_) {
        ref.read(itemsProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.inventoryAdjustmentSavedSuccess)));
        context.go('/master/items');
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

class _AdjustmentCard extends ConsumerWidget {
  const _AdjustmentCard({required this.form, required this.itemsAsync, required this.accountsAsync});

  final InventoryAdjustmentFormState form;
  final AsyncValue<List<ItemModel>> itemsAsync;
  final AsyncValue<List<AccountModel>> accountsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final inventoryItems = itemsAsync.maybeWhen(
      data: (items) => items.where((item) => item.isActive && item.isInventory).toList(),
      orElse: () => <ItemModel>[],
    );
    final adjustmentAccounts = accountsAsync.maybeWhen(
      data: (accounts) => accounts
          .where(
            (account) =>
                account.isActive &&
                (account.accountType == AccountType.expense ||
                    account.accountType == AccountType.costOfGoodsSold ||
                    account.accountType == AccountType.otherExpense ||
                    account.accountType == AccountType.income ||
                    account.accountType == AccountType.otherIncome),
          )
          .toList(),
      orElse: () => <AccountModel>[],
    );

    final selectedItem = inventoryItems.where((item) => item.id == form.itemId).firstOrNull;
    final safeItemId = selectedItem?.id;
    final safeAccountId = adjustmentAccounts.any((account) => account.id == form.adjustmentAccountId)
        ? form.adjustmentAccountId
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: safeItemId,
              decoration: InputDecoration(
                labelText: '${l10n.items} *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.inventory_2_outlined),
              ),
              items: inventoryItems
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text('${item.name} • ${l10n.stock}: ${item.quantityOnHand.toStringAsFixed(2)}'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                final item = inventoryItems.where((i) => i.id == value).firstOrNull;
                _update(
                  ref,
                  form
                    ..itemId = value
                    ..unitCost = item?.purchasePrice ?? form.unitCost,
                );
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: safeAccountId,
              decoration: InputDecoration(
                labelText: '${l10n.paymentAccount} *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.account_balance_outlined),
              ),
              items: adjustmentAccounts
                  .map((account) => DropdownMenuItem(value: account.id, child: Text('${account.code} - ${account.name}')))
                  .toList(),
              onChanged: (value) => _update(ref, form..adjustmentAccountId = value),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: l10n.paymentDate,
                    readOnly: true,
                    initialValue: InventoryAdjustmentFormScreen._dateOnly(form.adjustmentDate),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    key: ValueKey('qty-${form.itemId}-${form.quantityChange}'),
                    label: '${l10n.qty} *',
                    initialValue: form.quantityChange == 0 ? '' : form.quantityChange.toString(),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    onChanged: (value) {
                      form.quantityChange = double.tryParse(value) ?? 0;
                      _update(ref, form);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    key: ValueKey('unitCost-${form.itemId}-${form.unitCost}'),
                    label: '${l10n.unitCost} *',
                    initialValue: form.unitCost == 0 ? '' : form.unitCost.toStringAsFixed(2),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      form.unitCost = double.tryParse(value) ?? 0;
                      _update(ref, form);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: l10n.reason,
                    initialValue: form.reason,
                    onChanged: (value) {
                      form.reason = value;
                      _update(ref, form);
                    },
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

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total});
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

void _update(WidgetRef ref, InventoryAdjustmentFormState old) {
  ref.read(inventoryAdjustmentFormProvider.notifier).state = InventoryAdjustmentFormState()
    ..itemId = old.itemId
    ..adjustmentAccountId = old.adjustmentAccountId
    ..adjustmentDate = old.adjustmentDate
    ..quantityChange = old.quantityChange
    ..unitCost = old.unitCost
    ..reason = old.reason;
}
