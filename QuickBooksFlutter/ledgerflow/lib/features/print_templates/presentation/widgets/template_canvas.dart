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
