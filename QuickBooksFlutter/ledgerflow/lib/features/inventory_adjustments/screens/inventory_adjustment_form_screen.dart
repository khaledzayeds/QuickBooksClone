// inventory_adjustment_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../../app/router.dart';
import '../../../core/constants/api_enums.dart' show AccountType;
import '../../../core/widgets/app_text_field.dart';
import '../../accounts/data/models/account_model.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../items/data/models/item_model.dart';
import '../../items/providers/items_provider.dart';
import '../../transactions/widgets/transaction_workspace_shell.dart';
import '../data/models/inventory_adjustment_model.dart';
import '../providers/inventory_adjustments_provider.dart';

class InventoryAdjustmentLineState {
  String? itemId;
  double quantityOnHand = 0;
  double newQuantity = 0;
  double quantityDifference = 0;
  double unitCost = 0;
  String description = '';

  double get total => quantityDifference.abs() * unitCost;
  bool get hasWork =>
      itemId != null ||
      quantityDifference != 0 ||
      newQuantity != 0 ||
      description.trim().isNotEmpty;
  bool get isValid =>
      itemId != null && itemId!.isNotEmpty && quantityDifference != 0;

  InventoryAdjustmentLineState copy() => InventoryAdjustmentLineState()
    ..itemId = itemId
    ..quantityOnHand = quantityOnHand
    ..newQuantity = newQuantity
    ..quantityDifference = quantityDifference
    ..unitCost = unitCost
    ..description = description;
}

class InventoryAdjustmentFormState {
  String adjustmentType = 'Quantity';
  String? adjustmentAccountId;
  DateTime adjustmentDate = DateTime.now();
  String referenceNo = 'AUTO';
  String memo = '';
  List<InventoryAdjustmentLineState> lines = List.generate(
    8,
    (_) => InventoryAdjustmentLineState(),
  );

  double get total => lines.fold(0, (sum, line) => sum + line.total);
  int get adjustedItems => lines.where((line) => line.isValid).length;
}

final inventoryAdjustmentFormProvider =
    StateProvider.autoDispose<InventoryAdjustmentFormState>(
      (ref) => InventoryAdjustmentFormState(),
    );

final inventoryAdjustmentSavingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

class InventoryAdjustmentFormScreen extends ConsumerWidget {
  const InventoryAdjustmentFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(inventoryAdjustmentFormProvider);
    final saving = ref.watch(inventoryAdjustmentSavingProvider);
    final itemsAsync = ref.watch(itemsProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return TransactionWorkspaceShell(
      workspaceName: 'Inventory adjustment workspace',
      saving: saving,
      posting: false,
      isEdit: false,
      readOnly: false,
      showPagination: true,
      showSaveDraft: false,
      showSaveAndPrint: false,
      showPrint: true,
      showEmail: false,
      showEditNotes: false,
      showVoid: false,
      onFind: () => context.go(AppRoutes.inventoryAdjustments),
      onPrevious: null,
      onNext: null,
      onNew: () => _reset(ref),
      onSave: saving ? null : () => _save(context, ref, resetAfterSave: false),
      onSaveAndNew: saving
          ? null
          : () => _save(context, ref, resetAfterSave: true),
      onClear: () => _reset(ref),
      onClose: () => context.canPop()
          ? context.pop()
          : context.go(AppRoutes.inventoryAdjustments),
      formContent: _InventoryAdjustmentWorkspace(
        form: form,
        itemsAsync: itemsAsync,
        accountsAsync: accountsAsync,
        saving: saving,
        onSaveAndClose: saving
            ? null
            : () => _save(context, ref, resetAfterSave: false),
        onSaveAndNew: saving
            ? null
            : () => _save(context, ref, resetAfterSave: true),
        onClear: () => _reset(ref),
      ),
      contextPanel: _InventoryAdjustmentSidePanel(form: form),
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref, {
    required bool resetAfterSave,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final form = ref.read(inventoryAdjustmentFormProvider);
    final lines = form.lines.where((line) => line.isValid).toList();

    if (form.adjustmentAccountId == null || form.adjustmentAccountId!.isEmpty) {
      _error(context, l10n.selectPaymentAccountFirst);
      return;
    }
    if (lines.isEmpty) {
      _error(context, l10n.selectItemFirst);
      return;
    }

    ref.read(inventoryAdjustmentSavingProvider.notifier).state = true;
    String? failure;
    for (final line in lines) {
      final dto = CreateInventoryAdjustmentDto(
        itemId: line.itemId!,
        adjustmentAccountId: form.adjustmentAccountId!,
        adjustmentDate: form.adjustmentDate,
        quantityChange: line.quantityDifference,
        unitCost: line.unitCost > 0 ? line.unitCost : null,
        reason: [
          line.description,
          form.memo,
        ].where((part) => part.trim().isNotEmpty).join(' - '),
      );
      final result = await ref
          .read(inventoryAdjustmentsProvider.notifier)
          .create(dto);
      if (!context.mounted) return;
      result.when(
        success: (_) {},
        failure: (error) => failure ??= error.message,
      );
      if (failure != null) break;
    }
    ref.read(inventoryAdjustmentSavingProvider.notifier).state = false;

    if (!context.mounted) return;
    if (failure != null) {
      _error(context, failure!);
      return;
    }

    ref.read(itemsProvider.notifier).refresh();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.inventoryAdjustmentSavedSuccess)),
    );
    if (resetAfterSave) {
      _reset(ref);
    } else {
      context.go(AppRoutes.inventoryAdjustments);
    }
  }

  static void _error(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

void _reset(WidgetRef ref) {
  ref.read(inventoryAdjustmentFormProvider.notifier).state =
      InventoryAdjustmentFormState();
}

class _InventoryAdjustmentWorkspace extends ConsumerWidget {
  const _InventoryAdjustmentWorkspace({
    required this.form,
    required this.itemsAsync,
    required this.accountsAsync,
    required this.saving,
    required this.onClear,
    this.onSaveAndClose,
    this.onSaveAndNew,
  });

  final InventoryAdjustmentFormState form;
  final AsyncValue<List<ItemModel>> itemsAsync;
  final AsyncValue<List<AccountModel>> accountsAsync;
  final bool saving;
  final VoidCallback onClear;
  final VoidCallback? onSaveAndClose;
  final VoidCallback? onSaveAndNew;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryItems = itemsAsync.maybeWhen(
      data: (items) =>
          items.where((item) => item.isActive && item.isInventory).toList(),
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
    final safeAccountId =
        adjustmentAccounts.any(
          (account) => account.id == form.adjustmentAccountId,
        )
        ? form.adjustmentAccountId
        : null;

    return Column(
      children: [
        _AdjustmentHeader(
          form: form,
          accounts: adjustmentAccounts,
          safeAccountId: safeAccountId,
        ),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFF7F9FA),
            border: Border(
              top: BorderSide(color: Color(0xFFB7C3CB)),
              bottom: BorderSide(color: Color(0xFFB7C3CB)),
            ),
          ),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _ensureBlankLine(ref, form),
                icon: const Icon(Icons.search, size: 16),
                label: const Text('Find & Select Items...'),
                style: _smallButton(),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: form.lines.any((line) => line.isValid)
                    ? () => _setQtyToZero(ref, form)
                    : null,
                style: _smallButton(),
                child: const Text('Set Qty to Zero'),
              ),
              const Spacer(),
              Text(
                'Tab moves across cells - negative difference reduces stock',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF596B74),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: _AdjustmentLinesGrid(form: form, items: inventoryItems),
          ),
        ),
        _AdjustmentFooter(
          form: form,
          saving: saving,
          onClear: onClear,
          onSaveAndClose: onSaveAndClose,
          onSaveAndNew: onSaveAndNew,
        ),
      ],
    );
  }

  ButtonStyle _smallButton() => OutlinedButton.styleFrom(
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
    side: const BorderSide(color: Color(0xFF8FA1AB)),
  );
}

class _AdjustmentHeader extends ConsumerWidget {
  const _AdjustmentHeader({
    required this.form,
    required this.accounts,
    required this.safeAccountId,
  });

  final InventoryAdjustmentFormState form;
  final List<AccountModel> accounts;
  final String? safeAccountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF264D5B),
              border: Border(bottom: BorderSide(color: Color(0xFF183642))),
            ),
            child: Row(
              children: [
                const _StripLabel('ADJUSTMENT ACCOUNT'),
                const SizedBox(width: 8),
                Expanded(
                  child: _AccountDropdown(
                    value: safeAccountId,
                    accounts: accounts,
                    onChanged: (value) =>
                        _update(ref, form..adjustmentAccountId = value),
                  ),
                ),
                const SizedBox(width: 16),
                const _StripLabel('ADJUSTMENT TYPE'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 190,
                  height: 30,
                  child: DropdownButtonFormField<String>(
                    initialValue: form.adjustmentType,
                    decoration: const InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Quantity',
                        child: Text('Quantity'),
                      ),
                      DropdownMenuItem(value: 'Value', child: Text('Value')),
                    ],
                    onChanged: (value) => _update(
                      ref,
                      form..adjustmentType = value ?? 'Quantity',
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 150,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 320,
                    child: Text(
                      'Inventory Adjustment',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w300,
                            color: const Color(0xFF243E4A),
                          ),
                    ),
                  ),
                  SizedBox(
                    width: 300,
                    child: Column(
                      children: [
                        _HorizontalField(
                          label: 'DATE',
                          child: _StaticBox(
                            text: dateFmt.format(form.adjustmentDate),
                            icon: Icons.calendar_today_outlined,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _HorizontalField(
                          label: 'REFERENCE NO.',
                          child: _StaticBox(text: form.referenceNo),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _StackedField(
                      label: 'MEMO',
                      child: AppTextField(
                        label: '',
                        initialValue: form.memo,
                        onChanged: (value) => _update(ref, form..memo = value),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdjustmentLinesGrid extends ConsumerWidget {
  const _AdjustmentLinesGrid({required this.form, required this.items});

  final InventoryAdjustmentFormState form;
  final List<ItemModel> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF9EADB6)),
      ),
      child: Column(
        children: [
          Container(
            height: 30,
            color: const Color(0xFFDDE8ED),
            child: const Row(
              children: [
                _HeaderCell('ITEM', flex: 4),
                _HeaderCell('DESCRIPTION', flex: 5),
                _HeaderCell('QTY ON HAND', flex: 2, right: true),
                _HeaderCell('NEW QUANTITY', flex: 2, right: true),
                _HeaderCell('QTY DIFFERENCE', flex: 2, right: true),
                _HeaderCell('UNIT COST', flex: 2, right: true),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: form.lines.length,
              itemBuilder: (context, index) {
                final line = form.lines[index];
                final selectedItem = items
                    .where((item) => item.id == line.itemId)
                    .firstOrNull;
                return _AdjustmentLineRow(
                  shaded: index.isEven,
                  line: line,
                  selectedItem: selectedItem,
                  items: items,
                  onChanged: () => _update(ref, form),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdjustmentLineRow extends StatelessWidget {
  const _AdjustmentLineRow({
    required this.shaded,
    required this.line,
    required this.selectedItem,
    required this.items,
    required this.onChanged,
  });

  final bool shaded;
  final InventoryAdjustmentLineState line;
  final ItemModel? selectedItem;
  final List<ItemModel> items;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: shaded ? const Color(0xFFDDEFF4) : Colors.white,
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              child: DropdownButtonFormField<String>(
                initialValue: selectedItem?.id,
                isExpanded: true,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 7,
                  ),
                ),
                hint: const Text('Select item'),
                items: items
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  final item = items.where((i) => i.id == value).firstOrNull;
                  line
                    ..itemId = value
                    ..quantityOnHand = item?.quantityOnHand ?? 0
                    ..newQuantity = item?.quantityOnHand ?? 0
                    ..quantityDifference = 0
                    ..unitCost = item?.purchasePrice ?? 0
                    ..description = item?.name ?? '';
                  onChanged();
                },
              ),
            ),
          ),
          _TextCell(line.description, flex: 5),
          _TextCell(
            line.quantityOnHand.toStringAsFixed(2),
            flex: 2,
            right: true,
          ),
          _NumberCell(
            value: line.itemId == null
                ? ''
                : line.newQuantity.toStringAsFixed(2),
            flex: 2,
            onChanged: (value) {
              final parsed = double.tryParse(value);
              if (parsed == null) return;
              line
                ..newQuantity = parsed
                ..quantityDifference = parsed - line.quantityOnHand;
              onChanged();
            },
          ),
          _NumberCell(
            value: line.quantityDifference == 0
                ? ''
                : line.quantityDifference.toStringAsFixed(2),
            flex: 2,
            signed: true,
            onChanged: (value) {
              final parsed = double.tryParse(value);
              if (parsed == null) return;
              line
                ..quantityDifference = parsed
                ..newQuantity = line.quantityOnHand + parsed;
              onChanged();
            },
          ),
          _NumberCell(
            value: line.unitCost == 0 ? '' : line.unitCost.toStringAsFixed(2),
            flex: 2,
            onChanged: (value) {
              line.unitCost = double.tryParse(value) ?? 0;
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}

class _AdjustmentFooter extends StatelessWidget {
  const _AdjustmentFooter({
    required this.form,
    required this.saving,
    required this.onClear,
    this.onSaveAndClose,
    this.onSaveAndNew,
  });

  final InventoryAdjustmentFormState form;
  final bool saving;
  final VoidCallback onClear;
  final VoidCallback? onSaveAndClose;
  final VoidCallback? onSaveAndNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F8F9),
        border: Border(top: BorderSide(color: Color(0xFFB7C3CB))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 280,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFB8C6CE)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ITEM INFO AFTER ADJUSTMENT',
                    style: TextStyle(
                      color: Color(0xFF2D4854),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text('Quantity on Hand'),
                  Text('Avg Cost per Item'),
                  Text('Value'),
                ],
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 320,
            child: Column(
              children: [
                _TotalLine(
                  label: 'Total Value of Adjustment',
                  value: form.total.toStringAsFixed(2),
                ),
                const SizedBox(height: 6),
                _TotalLine(
                  label: 'Number of Item Adjustments',
                  value: form.adjustedItems.toString(),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: saving ? null : onSaveAndClose,
                      style: _smallButton(),
                      child: Text(saving ? 'Saving...' : 'Save & Close'),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: saving ? null : onSaveAndNew,
                      style: _smallButton(),
                      child: const Text('Save & New'),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: onClear,
                      style: _smallButton(),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _smallButton() => OutlinedButton.styleFrom(
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
    side: const BorderSide(color: Color(0xFF8FA1AB)),
  );
}

class _InventoryAdjustmentSidePanel extends StatelessWidget {
  const _InventoryAdjustmentSidePanel({required this.form});

  final InventoryAdjustmentFormState form;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
          decoration: const BoxDecoration(
            color: Color(0xFF264D5B),
            border: Border(bottom: BorderSide(color: Color(0xFF183642))),
          ),
          child: const Text(
            'Inventory Adjustment',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
          color: form.adjustedItems == 0
              ? const Color(0xFFFFE7C4)
              : const Color(0xFFDFF0E4),
          child: Text(
            form.adjustedItems == 0
                ? 'Select items and enter quantity differences.'
                : '${form.adjustedItems} item adjustment(s) ready.',
            style: TextStyle(
              color: form.adjustedItems == 0
                  ? const Color(0xFF714600)
                  : const Color(0xFF1B7D2B),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
        _SideSection(
          title: 'Summary',
          child: Column(
            children: [
              _InfoRow(label: 'Type', value: form.adjustmentType),
              _InfoRow(label: 'Items', value: form.adjustedItems.toString()),
              _InfoRow(
                label: 'Value',
                value: form.total.toStringAsFixed(2),
                strong: true,
              ),
            ],
          ),
        ),
        Expanded(
          child: _SideSection(
            title: 'Memo',
            expanded: true,
            child: Text(
              form.memo.trim().isEmpty ? 'No memo added.' : form.memo.trim(),
              style: const TextStyle(color: Color(0xFF4E616A)),
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountDropdown extends StatelessWidget {
  const _AccountDropdown({
    required this.value,
    required this.accounts,
    required this.onChanged,
  });

  final String? value;
  final List<AccountModel> accounts;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: const InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          border: OutlineInputBorder(),
        ),
        hint: const Text('Select account'),
        items: accounts
            .map(
              (account) => DropdownMenuItem(
                value: account.id,
                child: Text('${account.code}  ${account.name}'),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {required this.flex, this.right = false});
  final String text;
  final int flex;
  final bool right;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        textAlign: right ? TextAlign.end : TextAlign.start,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF53656E),
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _TextCell extends StatelessWidget {
  const _TextCell(this.text, {required this.flex, this.right = false});
  final String text;
  final int flex;
  final bool right;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Container(
      height: double.infinity,
      alignment: right ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFFB8C6CE))),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xFF273F4B),
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _NumberCell extends StatelessWidget {
  const _NumberCell({
    required this.value,
    required this.flex,
    required this.onChanged,
    this.signed = false,
  });

  final String value;
  final int flex;
  final bool signed;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: TextFormField(
        initialValue: value,
        textAlign: TextAlign.end,
        keyboardType: TextInputType.numberWithOptions(
          decimal: true,
          signed: signed,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            RegExp(signed ? r'[-0-9.]' : r'[0-9.]'),
          ),
        ],
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        ),
        onChanged: onChanged,
      ),
    ),
  );
}

class _StripLabel extends StatelessWidget {
  const _StripLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _StackedField extends StatelessWidget {
  const _StackedField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF53656E),
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 4),
      SizedBox(height: 34, child: child),
    ],
  );
}

class _StaticBox extends StatelessWidget {
  const _StaticBox({required this.text, this.icon});
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    height: 34,
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFB7C3CB)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
        if (icon != null) Icon(icon, size: 15),
      ],
    ),
  );
}

class _HorizontalField extends StatelessWidget {
  const _HorizontalField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 100,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFF53656E),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      Expanded(child: child),
    ],
  );
}

class _TotalLine extends StatelessWidget {
  const _TotalLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF263C46),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      Text(
        value,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xFF263C46),
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class _SideSection extends StatelessWidget {
  const _SideSection({
    required this.title,
    required this.child,
    this.expanded = false,
  });

  final String title;
  final Widget child;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFB8C6CE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 30,
            padding: const EdgeInsetsDirectional.only(start: 8, end: 4),
            decoration: const BoxDecoration(
              color: Color(0xFFE7EEF1),
              border: Border(bottom: BorderSide(color: Color(0xFFB8C6CE))),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF2D4854),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          if (expanded)
            Expanded(
              child: Padding(padding: const EdgeInsets.all(8), child: child),
            )
          else
            Padding(padding: const EdgeInsets.all(8), child: child),
        ],
      ),
    );

    return expanded ? Expanded(child: content) : content;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.strong = false,
  });
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: const Color(0xFF334A55),
      fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

void _ensureBlankLine(WidgetRef ref, InventoryAdjustmentFormState form) {
  if (form.lines.any((line) => !line.hasWork)) return;
  form.lines.add(InventoryAdjustmentLineState());
  _update(ref, form);
}

void _setQtyToZero(WidgetRef ref, InventoryAdjustmentFormState form) {
  for (final line in form.lines.where((line) => line.itemId != null)) {
    line
      ..newQuantity = 0
      ..quantityDifference = -line.quantityOnHand;
  }
  _update(ref, form);
}

void _update(WidgetRef ref, InventoryAdjustmentFormState old) {
  ref
      .read(inventoryAdjustmentFormProvider.notifier)
      .state = InventoryAdjustmentFormState()
    ..adjustmentType = old.adjustmentType
    ..adjustmentAccountId = old.adjustmentAccountId
    ..adjustmentDate = old.adjustmentDate
    ..referenceNo = old.referenceNo
    ..memo = old.memo
    ..lines = old.lines.map((line) => line.copy()).toList();
}
