import 'package:flutter/material.dart';

Future<bool> showVoidConfirmationDialog({
  required BuildContext context,
  required String documentLabel,
  String? warning,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(Icons.block_outlined, color: Theme.of(context).colorScheme.error),
      title: Text('Void $documentLabel?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This will cancel the document and create reversal activity when required.'),
          const SizedBox(height: 10),
          Text(
            warning ?? 'This action should only be used when the original document must be cancelled.',
            style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep Document'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.block_outlined),
          label: const Text('Void'),
        ),
      ],
    ),
  );
  return result == true;
}
