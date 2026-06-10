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
    final text = _ToolboxText.of(context);
    return Container(
      width: 292,
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(14),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              text.toolbox,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              text.addElementsHint,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            _toolButton(text.text, Icons.text_fields, controller.addText),
            _toolButton(text.field, Icons.data_object, controller.addField),
            _toolButton(
              text.rectangle,
              Icons.crop_square,
              controller.addRectangle,
            ),
            _toolButton(text.line, Icons.horizontal_rule, controller.addLine),
            _toolButton(
              text.table,
              Icons.table_chart_outlined,
              controller.addTable,
            ),
            _toolButton(text.qr, Icons.qr_code_2, controller.addQr),
            _toolButton(
              text.barcode,
              Icons.view_week_outlined,
              controller.addBarcode,
            ),
            const Divider(height: 24),
            if (controller.lastMessage != null) ...[
              Text(
                controller.lastMessage!,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
            ],
            OutlinedButton.icon(
              onPressed: () => _showJson(context),
              icon: const Icon(Icons.code),
              label: Text(text.showJson),
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
    final text = _ToolboxText.of(context);
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
        _errorMessage = text.errorLoadingFile(e);
      });
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _textController.text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_ToolboxText.of(context).copied)));
  }

  void _apply() {
    try {
      final model = PrintTemplateModel.fromJsonString(_textController.text);
      widget.onSave(model);
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _errorMessage = _ToolboxText.of(context).invalidJson(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = _ToolboxText.of(context);
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text.jsonTemplateEditor),
          Row(
            children: [
              IconButton(
                tooltip: text.loadFromFile,
                icon: const Icon(Icons.file_open_outlined),
                onPressed: _loadFromFile,
              ),
              IconButton(
                tooltip: text.copyToClipboard,
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
          child: Text(text.cancel),
        ),
        FilledButton(onPressed: _apply, child: Text(text.applySave)),
      ],
    );
  }
}

class _ToolboxText {
  const _ToolboxText(this.ar);

  final bool ar;

  static _ToolboxText of(BuildContext context) =>
      _ToolboxText(Localizations.localeOf(context).languageCode == 'ar');

  String get toolbox => ar ? 'الأدوات' : 'Toolbox';
  String get addElementsHint =>
      ar ? 'أضف عناصر إلى مساحة التصميم' : 'Add elements to the canvas';
  String get text => ar ? 'نص' : 'Text';
  String get field => ar ? 'حقل' : 'Field';
  String get rectangle => ar ? 'مستطيل' : 'Rectangle';
  String get line => ar ? 'خط' : 'Line';
  String get table => ar ? 'جدول' : 'Table';
  String get qr => ar ? 'QR' : 'QR';
  String get barcode => ar ? 'باركود' : 'Barcode';
  String get showJson => ar ? 'عرض JSON' : 'Show JSON';
  String get copied => ar ? 'تم النسخ إلى الحافظة' : 'Copied to clipboard';
  String get jsonTemplateEditor =>
      ar ? 'محرر قالب JSON' : 'JSON Template Editor';
  String get loadFromFile => ar ? 'تحميل من ملف' : 'Load from File';
  String get copyToClipboard => ar ? 'نسخ إلى الحافظة' : 'Copy to Clipboard';
  String get cancel => ar ? 'إلغاء' : 'Cancel';
  String get applySave => ar ? 'تطبيق وحفظ' : 'Apply & Save';

  String errorLoadingFile(Object error) =>
      ar ? 'خطأ أثناء تحميل الملف: $error' : 'Error loading file: $error';
  String invalidJson(Object error) =>
      ar ? 'JSON غير صالح: $error' : 'Invalid JSON: $error';
}

// END: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]
