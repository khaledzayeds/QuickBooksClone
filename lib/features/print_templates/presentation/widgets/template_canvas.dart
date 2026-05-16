import 'package:flutter/material.dart';

import '../../data/models/print_template_model.dart';
import 'template_element_widget.dart';

class TemplateCanvas extends StatelessWidget {
  const TemplateCanvas({
    super.key,
    required this.template,
    required this.selectedElementId,
    required this.onSelectElement,
    this.mmToPixel = 3.2,
  });

  final PrintTemplateModel template;
  final String? selectedElementId;
  final ValueChanged<String> onSelectElement;
  final double mmToPixel;

  @override
  Widget build(BuildContext context) {
    final pageWidth = template.page.effectiveWidthMm * mmToPixel;
    final pageHeight = template.page.effectiveHeightMm * mmToPixel;

    return InteractiveViewer(
      minScale: 0.35,
      maxScale: 2.5,
      boundaryMargin: const EdgeInsets.all(80),
      child: Center(
        child: Container(
          width: pageWidth,
          height: pageHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 22, offset: Offset(0, 10))],
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _PageGridPainter(mmToPixel: mmToPixel))),
              for (final element in template.elements)
                Positioned(
                  left: element.x * mmToPixel,
                  top: element.y * mmToPixel,
                  width: element.width * mmToPixel,
                  height: element.height * mmToPixel,
                  child: TemplateElementWidget(
                    element: element,
                    selected: element.id == selectedElementId,
                    onTap: () => onSelectElement(element.id),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageGridPainter extends CustomPainter {
  const _PageGridPainter({required this.mmToPixel});

  final double mmToPixel;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF3F4F6)
      ..strokeWidth = 0.5;

    final step = 10 * mmToPixel;
    for (double x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PageGridPainter oldDelegate) => oldDelegate.mmToPixel != mmToPixel;
}
