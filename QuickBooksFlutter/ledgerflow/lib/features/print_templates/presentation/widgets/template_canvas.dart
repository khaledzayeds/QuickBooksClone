import 'package:flutter/material.dart';

import '../../data/models/print_template_model.dart';
import '../../logic/print_template_controller.dart';
import 'template_element_widget.dart';

class TemplateCanvas extends StatelessWidget {
  const TemplateCanvas({
    super.key,
    required this.controller,
    this.mmToPixel = 3.2,
  });

  final PrintTemplateController controller;
  final double mmToPixel;

  PrintTemplateModel get template => controller.template;

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
                  child: GestureDetector(
                    onPanUpdate: (details) => controller.moveSelectedBy(
                      details.delta.dx / mmToPixel,
                      details.delta.dy / mmToPixel,
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: TemplateElementWidget(
                            element: element,
                            selected: element.id == controller.selectedElementId,
                            onTap: () => controller.selectElement(element.id),
                          ),
                        ),
                        if (element.id == controller.selectedElementId)
                          Positioned(
                            right: -6,
                            bottom: -6,
                            child: GestureDetector(
                              onPanUpdate: (details) => controller.resizeSelectedBy(
                                details.delta.dx / mmToPixel,
                                details.delta.dy / mmToPixel,
                              ),
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
