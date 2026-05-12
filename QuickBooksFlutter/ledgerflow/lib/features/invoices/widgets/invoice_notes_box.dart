import 'package:flutter/material.dart';

class InvoiceNotesBox extends StatelessWidget {
  const InvoiceNotesBox({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      maxLines: 5,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Notes',
        hintText: 'Write notes here',
        border: OutlineInputBorder(borderSide: BorderSide(color: cs.outlineVariant)),
      ),
    );
  }
}
