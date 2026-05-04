import 'package:flutter/material.dart';

import 'transaction_models.dart';

class TransactionHeaderPanel extends StatelessWidget {
  const TransactionHeaderPanel({
    super.key,
    required this.kind,
    required this.status,
    required this.numberController,
    required this.dateController,
    this.dueDateController,
    this.termsController,
    this.referenceController,
    this.onStatusPressed,
  });

  final TransactionScreenKind kind;
  final TransactionDocumentStatus status;
  final TextEditingController numberController;
  final TextEditingController dateController;
  final TextEditingController? dueDateController;
  final TextEditingController? termsController;
  final TextEditingController? referenceController;
  final VoidCallback? onStatusPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  child: Icon(Icons.description_outlined, color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(kind.label, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text('Full accounting transaction screen', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                ActionChip(
                  avatar: Icon(status.icon, size: 18),
                  label: Text(status.label),
                  onPressed: onStatusPressed,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                final fields = <Widget>[
                  _HeaderField(label: 'Number', controller: numberController, icon: Icons.tag_outlined),
                  _HeaderField(label: 'Date', controller: dateController, icon: Icons.calendar_today_outlined),
                  if (dueDateController != null) _HeaderField(label: 'Due Date', controller: dueDateController!, icon: Icons.event_available_outlined),
                  if (termsController != null) _HeaderField(label: 'Terms', controller: termsController!, icon: Icons.rule_outlined),
                  if (referenceController != null) _HeaderField(label: 'Reference', controller: referenceController!, icon: Icons.numbers_outlined),
                ];

                if (!wide) {
                  return Column(
                    children: fields.map((field) => Padding(padding: const EdgeInsets.only(bottom: 10), child: field)).toList(),
                  );
                }

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: fields.map((field) => SizedBox(width: 190, child: field)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderField extends StatelessWidget {
  const _HeaderField({required this.label, required this.controller, required this.icon});

  final String label;
  final TextEditingController controller;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}
