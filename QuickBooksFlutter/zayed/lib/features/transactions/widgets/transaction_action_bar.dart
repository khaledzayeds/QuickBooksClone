import 'package:flutter/material.dart';

import 'transaction_models.dart';
import 'transaction_print_menu.dart';

class TransactionActionBar extends StatelessWidget {
  const TransactionActionBar({
    super.key,
    required this.status,
    this.loading = false,
    this.onSaveDraft,
    this.onSave,
    this.onSaveAndClose,
    this.onSaveAndNew,
    this.onPost,
    this.onClear,
    this.onVoid,
    this.onPrintAction,
  });

  final TransactionDocumentStatus status;
  final bool loading;
  final VoidCallback? onSaveDraft;
  final VoidCallback? onSave;
  final VoidCallback? onSaveAndClose;
  final VoidCallback? onSaveAndNew;
  final VoidCallback? onPost;
  final VoidCallback? onClear;
  final VoidCallback? onVoid;
  final ValueChanged<TransactionPrintAction>? onPrintAction;

  @override
  Widget build(BuildContext context) {
    final isPosted = status == TransactionDocumentStatus.posted;
    final isVoided = status == TransactionDocumentStatus.voided;
    final canEdit = !loading && !isPosted && !isVoided;
    final saveAndClose = onSaveAndClose ?? onSave ?? onPost ?? onSaveDraft;
    final saveAndNew = onSaveAndNew ?? onPost ?? onSave ?? onSaveDraft;

    return Material(
      elevation: 1,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            if (loading) ...[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
            ],
            FilledButton.icon(
              onPressed: canEdit ? saveAndClose : null,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Save & Close'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: canEdit ? saveAndNew : null,
              icon: const Icon(Icons.add_box_outlined, size: 18),
              label: const Text('Save & New'),
            ),
            const SizedBox(width: 8),
            TransactionPrintMenu(onSelected: onPrintAction),
            const Spacer(),
            TextButton.icon(
              onPressed: canEdit ? onClear : null,
              icon: const Icon(Icons.cleaning_services_outlined, size: 18),
              label: const Text('Clear'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: loading || !isPosted ? null : onVoid,
              icon: const Icon(Icons.block_outlined, size: 18),
              label: const Text('Void'),
            ),
          ],
        ),
      ),
    );
  }
}
