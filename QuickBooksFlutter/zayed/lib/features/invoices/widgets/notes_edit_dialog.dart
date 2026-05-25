import 'package:flutter/material.dart';

/// Dialog لكتابة وحفظ النوتس — يفتح فوراً بدون الحاجة لـ save أول.
/// [onSave] بترجع Future — لو حابب تحفظ في الـ backend مرريها هناك،
///          لو مش محتاج backend (local) خليها void function عادية.
class NotesEditDialog extends StatefulWidget {
  const NotesEditDialog({
    super.key,
    required this.initialNotes,
    required this.onSave,
    this.title = 'Notes',
    this.hint = 'Write internal notes...',
  });

  final String initialNotes;
  final Future<void> Function(String notes) onSave;
  final String title;
  final String hint;

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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save notes: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 480,
        child: TextField(
          controller: _controller,
          maxLines: 6,
          autofocus: true,
          decoration: InputDecoration(
            hintText: widget.hint,
            border: const OutlineInputBorder(),
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
              : const Icon(Icons.save_outlined, size: 16),
          label: const Text('Save'),
        ),
      ],
    );
  }
}
