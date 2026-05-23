import 'package:flutter/material.dart';
// BEGIN: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
// END: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]

import '../../data/models/print_template_model.dart';
import '../../logic/print_template_controller.dart';

class ToolboxPanel extends StatelessWidget {
  const ToolboxPanel({super.key, required this.controller});

  final PrintTemplateController controller;

  @override
  Widget build(BuildContext context) {
    // BEGIN: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]
    final theme = Theme.of(context);
    return Container(
      width: 292,
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(14),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Toolbox',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Add elements to the canvas',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            _toolButton('Text', Icons.text_fields, controller.addText),
            _toolButton('Field', Icons.data_object, controller.addField),
            _toolButton('Rectangle', Icons.crop_square, controller.addRectangle),
            _toolButton('Line', Icons.horizontal_rule, controller.addLine),
            _toolButton('Table', Icons.table_chart_outlined, controller.addTable),
            _toolButton('QR', Icons.qr_code_2, controller.addQr),
            _toolButton(
              'Barcode',
              Icons.view_week_outlined,
              controller.addBarcode,
            ),
            const Divider(height: 24),
            if (controller.lastMessage != null) ...[
              Text(
                controller.lastMessage!,
                style: TextStyle(fontSize: 11, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 10),
            ],
            OutlinedButton.icon(
              onPressed: () => _showJson(context),
              icon: const Icon(Icons.code),
              label: const Text('Show JSON'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
    // END: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]
  }

  Widget _toolButton(String title, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Align(alignment: Alignment.centerLeft, child: Text(title)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  // BEGIN: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]
  void _showJson(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => JsonEditorDialog(
        initialJson: controller.exportJson(),
        onSave: (template) {
          controller.loadTemplate(template);
        },
      ),
    );
  }
}

class JsonEditorDialog extends StatefulWidget {
  const JsonEditorDialog({
    super.key,
    required this.initialJson,
    required this.onSave,
  });

  final String initialJson;
  final ValueChanged<PrintTemplateModel> onSave;

  @override
  State<JsonEditorDialog> createState() => _JsonEditorDialogState();
}

class _JsonEditorDialogState extends State<JsonEditorDialog> {
  late TextEditingController _textController;
  late ScrollController _scrollController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialJson);
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null) {
        String? content;
        if (result.files.single.bytes != null) {
          content = utf8.decode(result.files.single.bytes!);
        } else if (result.files.single.path != null) {
          final file = File(result.files.single.path!);
          content = await file.readAsString();
        }
        if (content != null) {
          setState(() {
            _textController.text = content!;
            _errorMessage = null;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading file: $e';
      });
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _textController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void _apply() {
    try {
      final model = PrintTemplateModel.fromJsonString(_textController.text);
      widget.onSave(model);
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid JSON: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('JSON Template Editor'),
          Row(
            children: [
              IconButton(
                tooltip: 'Load from File',
                icon: const Icon(Icons.file_open_outlined),
                onPressed: _loadFromFile,
              ),
              IconButton(
                tooltip: 'Copy to Clipboard',
                icon: const Icon(Icons.copy_all_outlined),
                onPressed: _copyToClipboard,
              ),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: 720,
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                ),
              ),
            ],
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: TextField(
                    controller: _textController,
                    scrollController: _scrollController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 13,
                      height: 1.5,
                      color: Color(0xFFF8FAFC), // Slate 50 – white text
                    ),
                    cursorColor: const Color(0xFF4ADE80), // green cursor
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: true,
                      fillColor: Color(0xFF0F172A), // Slate 900 – dark bg
                      contentPadding: EdgeInsets.all(14),
                      isDense: true,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _apply,
          child: const Text('Apply & Save'),
        ),
      ],
    );
  }
}
// END: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]
