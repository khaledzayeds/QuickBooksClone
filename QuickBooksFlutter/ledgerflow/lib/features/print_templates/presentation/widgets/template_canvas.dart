import 'package:flutter/material.dart';

import '../../data/models/print_template_model.dart';
import '../../logic/print_template_controller.dart';
import 'template_element_widget.dart';

class TemplateCanvas extends StatefulWidget {
  const TemplateCanvas({
    super.key,
    required this.controller,
    this.mmToPixel = 3.2,
  });

  final PrintTemplateController controller;
  final double mmToPixel;

  @override
  State<TemplateCanvas> createState() => _TemplateCanvasState();
}

class _TemplateCanvasState extends State<TemplateCanvas> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  late double _zoom;

  PrintTemplateModel get template => widget.controller.template;
  double get _mmToPixel => widget.mmToPixel;

  @override
  void initState() {
    super.initState();
    _zoom = _defaultZoomFor(template);
  }

  @override
  void didUpdateWidget(TemplateCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller.template.id != template.id ||
        oldWidget.controller.template.page.widthMm != template.page.widthMm) {
      _zoom = _defaultZoomFor(template);
    }
  }

  double _defaultZoomFor(PrintTemplateModel template) {
    final width = template.page.effectiveWidthMm;
    if (width <= 60) return 2.4;
    if (width <= 90) return 1.8;
    return 0.82;
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageWidth = template.page.effectiveWidthMm * _mmToPixel;
    final pageHeight = template.page.effectiveHeightMm * _mmToPixel;
    final scaledWidth = pageWidth * _zoom;
    final scaledHeight = pageHeight * _zoom;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFFDCE3EA)),
        child: Column(
          children: [
            _CanvasToolbar(
              zoom: _zoom,
              onZoomIn: () => _setZoom(_zoom + .1),
              onZoomOut: () => _setZoom(_zoom - .1),
              onZoomChanged: _setZoom,
              onReset: () => _setZoom(1),
              onFit: () => _fitToWidth(pageWidth),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final viewportWidth = constraints.maxWidth;
                  final viewportHeight = constraints.maxHeight;

                  const horizontalPadding = 72.0;
                  const verticalPadding = 112.0;

                  final contentWidth = (scaledWidth + horizontalPadding).clamp(viewportWidth, double.infinity);
                  final contentHeight = (scaledHeight + verticalPadding).clamp(viewportHeight, double.infinity);

                  return Scrollbar(
                    controller: _verticalController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _verticalController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Scrollbar(
                        controller: _horizontalController,
                        thumbVisibility: true,
                        notificationPredicate: (notification) =>
                            notification.metrics.axis == Axis.horizontal,
                        child: SingleChildScrollView(
                          controller: _horizontalController,
                          scrollDirection: Axis.horizontal,
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            width: contentWidth,
                            height: contentHeight,
                            child: Center(
                              child: SizedBox(
                                width: scaledWidth,
                                height: scaledHeight,
                                child: Transform.scale(
                                  scale: _zoom,
                                  alignment: Alignment.topLeft,
                                  child: SizedBox(
                                    width: pageWidth,
                                    height: pageHeight,
                                    child: _PageSurface(
                                      controller: widget.controller,
                                      pageWidth: pageWidth,
                                      pageHeight: pageHeight,
                                      mmToPixel: _mmToPixel,
                                      zoom: _zoom,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setZoom(double value) {
    setState(() {
      _zoom = value.clamp(.25, 2.5).toDouble();
    });
  }

  void _fitToWidth(double pageWidth) {
    final viewportWidth = context.size?.width ?? pageWidth;
    final available = (viewportWidth - 130).clamp(120, viewportWidth);
    _setZoom(available / pageWidth);
  }
}

class _CanvasToolbar extends StatelessWidget {
  const _CanvasToolbar({
    required this.zoom,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onZoomChanged,
    required this.onReset,
    required this.onFit,
  });

  final double zoom;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final ValueChanged<double> onZoomChanged;
  final VoidCallback onReset;
  final VoidCallback onFit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFC9D3DF))),
      ),
      child: Row(
        children: [
          const Icon(Icons.grid_4x4_outlined, size: 18),
          const SizedBox(width: 8),
          Text(
            'Grid on',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          _ToolIcon(
            tooltip: 'Zoom out',
            icon: Icons.zoom_out,
            onPressed: onZoomOut,
          ),
          SizedBox(
            width: 118,
            child: Slider(
              value: zoom,
              min: .25,
              max: 2.5,
              divisions: 45,
              onChanged: onZoomChanged,
            ),
          ),
          _ToolIcon(
            tooltip: 'Zoom in',
            icon: Icons.zoom_in,
            onPressed: onZoomIn,
          ),
          const SizedBox(width: 8),
          Container(
            width: 72,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFC9D3DF)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${(zoom * 100).round()}%',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(onPressed: onFit, child: const Text('Fit')),
          TextButton(onPressed: onReset, child: const Text('100%')),
        ],
      ),
    );
  }
}

class _ToolIcon extends StatelessWidget {
  const _ToolIcon({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}

class _PageSurface extends StatelessWidget {
  const _PageSurface({
    required this.controller,
    required this.pageWidth,
    required this.pageHeight,
    required this.mmToPixel,
    required this.zoom,
  });

  final PrintTemplateController controller;
  final double pageWidth;
  final double pageHeight;
  final double mmToPixel;
  final double zoom;

  PrintTemplateModel get template => controller.template;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -46,
          left: 0,
          right: 0,
          child: Text(
            template.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Positioned(
          left: -26,
          top: 0,
          width: 22,
          height: pageHeight,
          child: _VerticalRuler(
            lengthMm: template.page.effectiveHeightMm,
            mmToPixel: mmToPixel,
          ),
        ),
        Positioned(
          left: 0,
          top: -24,
          width: pageWidth,
          height: 20,
          child: _HorizontalRuler(
            lengthMm: template.page.effectiveWidthMm,
            mmToPixel: mmToPixel,
          ),
        ),
        Container(
          width: pageWidth,
          height: pageHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
            border: Border.all(color: Colors.black, width: 1.2),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _GridPainter())),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(template.page.marginMm * mmToPixel),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF2563EB),
                        width: .6,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                  ),
                ),
              ),
              for (final element in template.elements)
                Positioned(
                  left: element.x * mmToPixel,
                  top: element.y * mmToPixel,
                  width: element.width * mmToPixel,
                  height: element.height * mmToPixel,
                  child: GestureDetector(
                    onPanStart: (_) => controller.selectElement(element.id),
                    onPanUpdate: (details) => controller.moveSelectedBy(
                      details.delta.dx / (mmToPixel * zoom),
                      details.delta.dy / (mmToPixel * zoom),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: TemplateElementWidget(
                            element: element,
                            selected:
                                element.id == controller.selectedElementId,
                            onTap: () => controller.selectElement(element.id),
                          ),
                        ),
                        if (element.id == controller.selectedElementId)
                          Positioned(
                            right: -6,
                            bottom: -6,
                            child: GestureDetector(
                              onPanStart: (_) =>
                                  controller.selectElement(element.id),
                              onPanUpdate: (details) =>
                                  controller.resizeSelectedBy(
                                    details.delta.dx / (mmToPixel * zoom),
                                    details.delta.dy / (mmToPixel * zoom),
                                  ),
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF229C1B),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
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
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fine = Paint()
      ..color = const Color(0xFFE8EEF5)
      ..strokeWidth = .45;
    final major = Paint()
      ..color = const Color(0xFFC9D3DF)
      ..strokeWidth = .75;

    const spacing = 8.0;
    for (double x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        (x / spacing).round() % 5 == 0 ? major : fine,
      );
    }
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        (y / spacing).round() % 5 == 0 ? major : fine,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}

class _HorizontalRuler extends StatelessWidget {
  const _HorizontalRuler({required this.lengthMm, required this.mmToPixel});

  final double lengthMm;
  final double mmToPixel;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RulerPainter(
        lengthMm: lengthMm,
        mmToPixel: mmToPixel,
        axis: Axis.horizontal,
      ),
    );
  }
}

class _VerticalRuler extends StatelessWidget {
  const _VerticalRuler({required this.lengthMm, required this.mmToPixel});

  final double lengthMm;
  final double mmToPixel;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RulerPainter(
        lengthMm: lengthMm,
        mmToPixel: mmToPixel,
        axis: Axis.vertical,
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  const _RulerPainter({
    required this.lengthMm,
    required this.mmToPixel,
    required this.axis,
  });

  final double lengthMm;
  final double mmToPixel;
  final Axis axis;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = .7;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    for (var mm = 0; mm <= lengthMm; mm += 10) {
      final offset = mm * mmToPixel;
      if (axis == Axis.horizontal) {
        canvas.drawLine(Offset(offset, 0), Offset(offset, 9), paint);
        textPainter.text = TextSpan(
          text: '${mm ~/ 10}',
          style: const TextStyle(fontSize: 8, color: Color(0xFF334155)),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(offset + 2, 8));
      } else {
        canvas.drawLine(Offset(13, offset), Offset(22, offset), paint);
        textPainter.text = TextSpan(
          text: '${mm ~/ 10}',
          style: const TextStyle(fontSize: 8, color: Color(0xFF334155)),
        );
        textPainter.layout();
        canvas.save();
        canvas.translate(0, offset + 12);
        canvas.rotate(-1.5708);
        textPainter.paint(canvas, Offset.zero);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) {
    return oldDelegate.lengthMm != lengthMm ||
        oldDelegate.mmToPixel != mmToPixel ||
        oldDelegate.axis != axis;
  }
}
