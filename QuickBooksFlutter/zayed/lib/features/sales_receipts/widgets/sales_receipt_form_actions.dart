import 'package:flutter/material.dart';

import '../../transactions/widgets/transaction_form_shell.dart';

List<TransactionFormAction> buildSalesReceiptFormActions({
  required bool saving,
  required bool readOnly,
  required VoidCallback onFind,
  required VoidCallback onPrint,
  required VoidCallback? onVoid,
  required VoidCallback onClear,
  required VoidCallback? onSaveAndNew,
  required VoidCallback? onSaveAndClose,
}) {
  return [
    TransactionFormAction(
      label: 'Find',
      icon: Icons.search,
      style: TransactionFormActionStyle.icon,
      tooltip: 'Find sales receipts',
      enabled: !saving,
      onPressed: onFind,
    ),
    TransactionFormAction(
      label: 'Print',
      icon: Icons.print_outlined,
      style: TransactionFormActionStyle.icon,
      tooltip: 'Print (Ctrl+P)',
      enabled: !saving,
      onPressed: onPrint,
    ),
    TransactionFormAction(
      label: 'Void',
      icon: Icons.block_outlined,
      style: TransactionFormActionStyle.text,
      enabled: !saving && onVoid != null,
      onPressed: onVoid,
    ),
    TransactionFormAction(
      label: 'Clear',
      icon: Icons.refresh_outlined,
      style: TransactionFormActionStyle.text,
      enabled: !saving,
      onPressed: onClear,
    ),
    TransactionFormAction(
      label: 'Save & New  F2',
      icon: Icons.add_circle_outline,
      style: TransactionFormActionStyle.outlined,
      enabled: !saving && !readOnly && onSaveAndNew != null,
      onPressed: onSaveAndNew,
    ),
    TransactionFormAction(
      label: 'Save & Close  F4',
      icon: Icons.save_outlined,
      style: TransactionFormActionStyle.filled,
      busy: saving,
      enabled: !saving && !readOnly && onSaveAndClose != null,
      onPressed: onSaveAndClose,
    ),
  ];
}
