import 'package:flutter/material.dart';

import '../../transactions/widgets/transaction_form_shell.dart';

List<TransactionFormAction> buildSalesReceiptFormActions({
  required bool saving,
  required VoidCallback onPrint,
  required VoidCallback onClear,
  required VoidCallback onSaveAndNew,
  required VoidCallback onSaveAndClose,
}) {
  return [
    TransactionFormAction(
      label: 'Print',
      icon: Icons.print_outlined,
      style: TransactionFormActionStyle.icon,
      tooltip: 'Print (Ctrl+P)',
      enabled: !saving,
      onPressed: onPrint,
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
      enabled: !saving,
      onPressed: onSaveAndNew,
    ),
    TransactionFormAction(
      label: 'Save & Close  F4',
      icon: Icons.save_outlined,
      style: TransactionFormActionStyle.filled,
      busy: saving,
      enabled: !saving,
      onPressed: onSaveAndClose,
    ),
  ];
}
