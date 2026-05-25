import 'package:flutter/material.dart';

import '../../transactions/widgets/transaction_form_shell.dart';

List<TransactionFormAction> buildInvoiceFormActions({
  required bool saving,
  required bool posting,
  required bool isEdit,
  required VoidCallback onSaveDraft,
  required VoidCallback onSave,
  required VoidCallback onPost,
  required VoidCallback onPrint,
  required VoidCallback? onVoid,
}) {
  final busy = saving || posting;

  return [
    TransactionFormAction(
      label: 'Print',
      icon: Icons.print_outlined,
      style: TransactionFormActionStyle.icon,
      tooltip: 'Print (Ctrl+P)',
      enabled: !busy,
      onPressed: onPrint,
    ),
    if (isEdit)
      TransactionFormAction(
        label: 'Void',
        icon: Icons.block_outlined,
        style: TransactionFormActionStyle.text,
        enabled: !busy,
        onPressed: onVoid,
      ),
    TransactionFormAction(
      label: 'Save Draft',
      icon: Icons.drafts_outlined,
      style: TransactionFormActionStyle.outlined,
      busy: saving,
      enabled: !busy,
      onPressed: onSaveDraft,
    ),
    TransactionFormAction(
      label: 'Save',
      icon: Icons.save_outlined,
      style: TransactionFormActionStyle.outlined,
      busy: saving,
      enabled: !busy,
      onPressed: onSave,
    ),
    TransactionFormAction(
      label: 'Post',
      icon: Icons.task_alt_outlined,
      style: TransactionFormActionStyle.filled,
      busy: posting,
      enabled: !busy,
      onPressed: onPost,
    ),
  ];
}
