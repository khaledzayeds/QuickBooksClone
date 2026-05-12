import 'package:flutter/material.dart';

class NotesEditDialog extends StatefulWidget {
  const NotesEditDialog({
    super.key,
    required this.initialNotes,
    required this.onSave,
  });

  final String initialNotes;
  final Future<void> Function(String notes) onSave;

  @override
  State<NotesEditDialog> createState() => _NotesEditDialogState();
}

class _NotesEditDialogState extends State<NotesEditDialog> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNotes);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(_controller.text.trim());
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Notes'),
      content: SizedBox(
        width: 460,
        child: TextField(
          controller: _controller,
          maxLines: 5,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Write internal notes for this sales receipt...',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('Save'),
        ),
      ],
    );
  }
}
