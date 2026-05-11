// features/dashboard/widgets/dashboard_flowchart.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/router.dart';

class DashboardFlowchart extends StatelessWidget {
  const DashboardFlowchart({super.key});

  static const Size _canvasSize = Size(1120, 620);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: const Color(0xFFF3F6FA),
          padding: const EdgeInsets.all(12),
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: _canvasSize.width,
                height: _canvasSize.height,
                child: _WorkflowCanvas(l10n: l10n),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WorkflowCanvas extends StatelessWidget {
  const _WorkflowCanvas({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _WorkflowLinesPainter(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.55),
            ),
          ),
        ),
        _mainPanel(
          left: 12,
          top: 10,
          width: 820,
          height: 160,
          title: l10n.vendors,
          child: Stack(
            children: [
              _node(42, 45, l10n.purchaseOrders, AppRoutes.purchaseOrderNew, PhosphorIconsRegular.clipboardText),
              _node(222, 45, l10n.receiveInventory, AppRoutes.receiveInventoryNew, PhosphorIconsRegular.package),
              _node(402, 45, l10n.enterBills, AppRoutes.purchaseBillNew, PhosphorIconsRegular.receipt),
              _node(590, 45, l10n.payBills, AppRoutes.vendorPaymentNew, PhosphorIconsRegular.money),
              _miniNode(52, 118, 'Vendor Credits', AppRoutes.vendorCreditNew, PhosphorIconsRegular.arrowUDownLeft),
              _miniNode(225, 118, 'Purchase Returns', AppRoutes.purchaseReturnNew, PhosphorIconsRegular.arrowCounterClockwise),
              _miniNode(425, 118, 'Vendor Center', AppRoutes.vendors, PhosphorIconsRegular.storefront),
            ],
          ),
        ),
        _mainPanel(
          left: 12,
          top: 184,
          width: 820,
          height: 270,
          title: l10n.customers,
          child: Stack(
            children: [
              _node(42, 28, l10n.estimates, AppRoutes.estimateNew, PhosphorIconsRegular.tag),
              _node(222, 28, l10n.salesOrders, AppRoutes.salesOrderNew, PhosphorIconsRegular.shoppingCart),
              _node(402, 28, l10n.createInvoices, AppRoutes.invoiceNew, PhosphorIconsRegular.fileText),
              _node(582, 28, l10n.receivePayments, AppRoutes.paymentNew, PhosphorIconsRegular.creditCard),
              _node(402, 148, l10n.salesReceipts, AppRoutes.salesReceiptNew, PhosphorIconsRegular.receipt),
              _node(582, 148, l10n.recordDeposits, AppRoutes.bankingDeposits, PhosphorIconsRegular.arrowDown),
              _miniNode(50, 210, 'Customer Credits', AppRoutes.customerCreditNew, PhosphorIconsRegular.arrowCounterClockwise),
              _miniNode(230, 210, 'Sales Returns', AppRoutes.salesReturnNew, PhosphorIconsRegular.arrowBendUpLeft),
              _miniNode(430, 210, 'Customer Center', AppRoutes.customers, PhosphorIconsRegular.usersThree),
            ],
          ),
        ),
        _mainPanel(
          left: 12,
          top: 468,
          width: 820,
          height: 140,
          title: l10n.employees,
          child: Stack(
            children: [
              _node(110, 38, l10n.enterTime, AppRoutes.timeTracking, PhosphorIconsRegular.timer),
              _node(315, 38, l10n.payEmployees, AppRoutes.payroll, PhosphorIconsRegular.identificationBadge),
            ],
          ),
        ),
        _sidePanel(
          left: 846,
          top: 10,
          width: 260,
          height: 250,
          title: l10n.company,
          children: [
            _sideItem(l10n.chartOfAccounts, AppRoutes.chartOfAccounts, PhosphorIconsRegular.treeStructure),
            _sideItem(l10n.itemsAndServices, AppRoutes.items, PhosphorIconsRegular.package),
            _sideItem(l10n.inventoryAdjustments, AppRoutes.inventoryAdjustmentNew, PhosphorIconsRegular.slidersHorizontal),
            _sideItem(l10n.journalEntries, AppRoutes.journalEntryNew, PhosphorIconsRegular.notebook),
            _sideItem(l10n.reports, AppRoutes.reports, PhosphorIconsRegular.presentationChart),
            _sideItem(l10n.settings, AppRoutes.settings, PhosphorIconsRegular.gearSix),
          ],
        ),
        _sidePanel(
          left: 846,
          top: 276,
          width: 260,
          height: 332,
          title: 'Banking',
          children: [
            _sideItem('Bank Register', AppRoutes.bankingRegister, PhosphorIconsRegular.bookOpen),
            _sideItem('Write Checks', AppRoutes.bankingChecks, PhosphorIconsRegular.penNib),
            _sideItem(l10n.recordDeposits, AppRoutes.bankingDeposits, PhosphorIconsRegular.arrowDown),
            _sideItem('Bank Transfer', AppRoutes.bankingTransfers, PhosphorIconsRegular.arrowsLeftRight),
            _sideItem('Reconcile', AppRoutes.bankingReconcile, PhosphorIconsRegular.checks),
            _sideItem('Transactions', AppRoutes.transactions, PhosphorIconsRegular.listMagnifyingGlass),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 180.ms);
  }

  Widget _mainPanel({
    required double left,
    required double top,
    required double width,
    required double height,
    required String title,
    required Widget child,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: _WorkflowPanel(title: title, child: child),
    );
  }

  Widget _sidePanel({
    required double left,
    required double top,
    required double width,
    required double height,
    required String title,
    required List<Widget> children,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: _WorkflowPanel(
        title: title,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _node(double left, double top, String label, String path, IconData icon) {
    return Positioned(
      left: left,
      top: top,
      width: 120,
      height: 72,
      child: _FlowNode(label: label, path: path, icon: icon),
    );
  }

  Widget _miniNode(double left, double top, String label, String path, IconData icon) {
    return Positioned(
      left: left,
      top: top,
      width: 150,
      height: 34,
      child: _MiniFlowNode(label: label, path: path, icon: icon),
    );
  }

  Widget _sideItem(String label, String path, IconData icon) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _SideFlowItem(label: label, path: path, icon: icon),
      ),
    );
  }
}

class _WorkflowPanel extends StatelessWidget {
  const _WorkflowPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: cs.primary.withValues(alpha: 0.14))),
            ),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                color: cs.primary,
                fontSize: 11,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _FlowNode extends StatelessWidget {
  const _FlowNode({required this.label, required this.path, required this.icon});

  final String label;
  final String path;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(path),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: cs.primary),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, height: 1.1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniFlowNode extends StatelessWidget {
  const _MiniFlowNode({required this.label, required this.path, required this.icon});

  final String label;
  final String path;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: () => context.go(path),
      icon: Icon(icon, size: 14),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: cs.onSurface,
        side: BorderSide(color: cs.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        textStyle: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
    );
  }
}

class _SideFlowItem extends StatelessWidget {
  const _SideFlowItem({required this.label, required this.path, required this.icon});

  final String label;
  final String path;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(path),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.34),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.8)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 17, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkflowLinesPainter extends CustomPainter {
  const _WorkflowLinesPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Vendors
    _arrow(canvas, paint, const Offset(176, 91), const Offset(232, 91));
    _arrow(canvas, paint, const Offset(356, 91), const Offset(412, 91));
    _arrow(canvas, paint, const Offset(536, 91), const Offset(600, 91));

    // Customers upper path
    _arrow(canvas, paint, const Offset(176, 248), const Offset(232, 248));
    _arrow(canvas, paint, const Offset(356, 248), const Offset(412, 248));
    _arrow(canvas, paint, const Offset(536, 248), const Offset(592, 248));
    _arrow(canvas, paint, const Offset(706, 248), const Offset(858, 440));

    // Sales receipt to deposits path
    _arrow(canvas, paint, const Offset(536, 368), const Offset(592, 368));
    _arrow(canvas, paint, const Offset(706, 368), const Offset(858, 440));

    // Invoice link to sales receipt vertical relationship
    _polyArrow(canvas, paint, const [Offset(462, 320), Offset(462, 340), Offset(462, 356)]);

    // Employees
    _arrow(canvas, paint, const Offset(254, 530), const Offset(326, 530));
  }

  void _polyArrow(Canvas canvas, Paint paint, List<Offset> points) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
    _drawHead(canvas, paint, points[points.length - 2], points.last);
  }

  void _arrow(Canvas canvas, Paint paint, Offset start, Offset end) {
    canvas.drawLine(start, end, paint);
    _drawHead(canvas, paint, start, end);
  }

  void _drawHead(Canvas canvas, Paint paint, Offset start, Offset end) {
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    const arrowSize = 8.0;
    final p1 = Offset(
      end.dx - arrowSize * math.cos(angle - math.pi / 6),
      end.dy - arrowSize * math.sin(angle - math.pi / 6),
    );
    final p2 = Offset(
      end.dx - arrowSize * math.cos(angle + math.pi / 6),
      end.dy - arrowSize * math.sin(angle + math.pi / 6),
    );
    canvas.drawLine(end, p1, paint);
    canvas.drawLine(end, p2, paint);
  }

  @override
  bool shouldRepaint(covariant _WorkflowLinesPainter oldDelegate) => oldDelegate.color != color;
}
