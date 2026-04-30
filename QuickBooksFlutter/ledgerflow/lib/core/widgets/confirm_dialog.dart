import 'package:flutter/material.dart';

/// Shows a confirmation dialog and returns true if confirmed, false/null otherwise.
Future<bool?> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel  = 'تأكيد',
  String cancelLabel   = 'إلغاء',
  bool   isDangerous   = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => ConfirmDialog(
      title:        title,
      message:      message,
      confirmLabel: confirmLabel,
      cancelLabel:  cancelLabel,
      isDangerous:  isDangerous,
    ),
  );
}

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'تأكيد',
    this.cancelLabel  = 'إلغاء',
    this.isDangerous  = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool   isDangerous;

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final color = isDangerous ? cs.error : cs.primary;

    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      icon: Icon(
        isDangerous ? Icons.warning_amber_rounded : Icons.help_outline,
        color: color,
        size: 36,
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: cs.onSurface.withValues(alpha: 0.7),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: isDangerous ? cs.onError : cs.onPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}