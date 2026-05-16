import 'package:flutter/material.dart';

import '../../data/models/print_element_model.dart';
import '../../logic/template_field_registry.dart';

class TemplateElementWidget extends StatelessWidget {
  const TemplateElementWidget({
    super.key,
    required this.element,
    required this.selected,
    required this.onTap,
  });

  final PrintElementModel element;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: _background,
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : const Color(0xFFD1D5DB),
            width: selected ? 1.5 : 0.6,
          ),
        ),
        child: _body(),
      ),
    );
  }

  Widget _body() {
    switch (element.type) {
      case 'line':
        return const Center(child: Divider(height: 1, thickness: 1));
      case 'rectangle':
        return const SizedBox.expand();
      case 'table':
        return _simpleTable();
      case 'qr':
        return _placeholder('QR');
      case 'barcode':
        return _placeholder('BARCODE');
      case 'image':
        return _placeholder('LOGO');
      case 'field':
        return _text(TemplateFieldRegistry.previewValue(element.binding, fallback: element.value));
      default:
        return _text(element.value);
    }
  }

  Widget _text(String text) {
    return Text(
      text,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      textAlign: _align,
      style: TextStyle(
        fontSize: element.style.fontSize,
        fontWeight: element.style.bold ? FontWeight.w700 : FontWeight.w400,
        fontStyle: element.style.italic ? FontStyle.italic : FontStyle.normal,
        color: const Color(0xFF111827),
        height: 1.1,
      ),
    );
  }

  Widget _placeholder(String label) {
    return Center(
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
      ),
    );
  }

  Widget _simpleTable() {
    final columns = element.columns;
    return Column(
      children: [
        Row(
          children: columns
              .map((column) => Expanded(child: Text(column.title, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700))))
              .toList(),
        ),
        const Divider(height: 4),
        const Expanded(child: Center(child: Text('Invoice lines preview', style: TextStyle(fontSize: 8)))),
      ],
    );
  }

  Color get _background {
    return element.type == 'rectangle' ? const Color(0xFFF3F4F6) : Colors.white;
  }

  TextAlign get _align {
    if (element.style.align == 'center') return TextAlign.center;
    if (element.style.align == 'right') return TextAlign.right;
    return TextAlign.left;
  }
}
