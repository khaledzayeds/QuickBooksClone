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
    this.onPost,
    this.onClear,
    this.onVoid,
    this.onPrintAction,
  });

  final TransactionDocumentStatus status;
  final bool loading;
  final VoidCallback? onSaveDraft;
  final VoidCallback? onSave;
  final VoidCallback? onPost;
  final VoidCallback? onClear;
  final VoidCallback? onVoid;
  final ValueChanged<TransactionPrintAction>? onPrintAction;

  @override
  Widget build(BuildContext context) {
    final isPosted = status == TransactionDocumentStatus.posted;
    final isVoided = status == TransactionDocumentStatus.voided;

    return Material(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (loading) ...[
              const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 12),
            ],
            OutlinedButton.icon(onPressed: loading || isPosted || isVoided ? null : onSaveDraft, icon: const Icon(Icons.edit_note_outlined), label: const Text('Save Draft')),
            const SizedBox(width: 8),
            OutlinedButton.icon(onPressed: loading || isPosted || isVoided ? null : onSave, icon: const Icon(Icons.save_outlined), label: const Text('Save')),
            const SizedBox(width: 8),
            FilledButton.icon(onPressed: loading || isPosted || isVoided ? null : onPost, icon: const Icon(Icons.verified_outlined), label: const Text('Post')),
            const SizedBox(width: 8),
            TransactionPrintMenu(onSelected: onPrintAction),
            const Spacer(),
            TextButton.icon(onPressed: loading || isPosted || isVoided ? null : onClear, icon: const Icon(Icons.cleaning_services_outlined), label: const Text('Clear')),
            const SizedBox(width: 8),
            OutlinedButton.icon(onPressed: loading || !isPosted ? null : onVoid, icon: const Icon(Icons.block_outlined), label: const Text('Void')),
          ],
        ),
      ),
    );
  }
}
