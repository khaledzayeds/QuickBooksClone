// features/dashboard/widgets/dashboard_flowchart.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/router.dart';

class DashboardFlowchart extends StatelessWidget {
  const DashboardFlowchart({super.key});

  static const Size _canvasSize = Size(1040, 560);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: const Color(0xFFECEFF4),
      padding: const EdgeInsets.all(10),
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: _canvasSize.width,
            height: _canvasSize.height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 760,
                  child: Column(
                    children: [
                      _HomePanel(
                        title: l10n.vendors,
                        height: 150,
                        child: _PanelBody(
                          lines: const [
                            _Line(132, 62, 218, 62),
                            _Line(312, 62, 398, 62),
                            _Line(492, 62, 578, 62),
                          ],
                          children: [
                            _node(38, 26, l10n.purchaseOrders, AppRoutes.purchaseOrderNew, PhosphorIconsRegular.clipboardText),
                            _node(218, 26, l10n.receiveInventory, AppRoutes.receiveInventoryNew, PhosphorIconsRegular.package),
                            _node(398, 26, l10n.enterBills, AppRoutes.purchaseBillNew, PhosphorIconsRegular.receipt),
                            _node(578, 26, l10n.payBills, AppRoutes.vendorPaymentNew, PhosphorIconsRegular.money),
                            _small(92, 98, 'Vendor Credits', AppRoutes.vendorCreditNew, PhosphorIconsRegular.arrowUDownLeft),
                            _small(278, 98, 'Purchase Returns', AppRoutes.purchaseReturnNew, PhosphorIconsRegular.arrowCounterClockwise),
                            _small(464, 98, l10n.vendors, AppRoutes.vendors, PhosphorIconsRegular.storefront),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _HomePanel(
                        title: l10n.customers,
                        height: 258,
                        child: _PanelBody(
                          lines: const [
                            _Line(132, 143, 252, 143),
                            _Line(346, 143, 398, 143),
                            _Line(492, 143, 578, 143),
                            _Line(86, 80, 86, 112),
                            _Line(446, 80, 446, 112),
                            _Line(446, 143, 446, 172),
                          ],
                          children: [
                            _node(38, 24, l10n.salesOrders, AppRoutes.salesOrderNew, PhosphorIconsRegular.shoppingCart),
                            _node(38, 106, l10n.estimates, AppRoutes.estimateNew, PhosphorIconsRegular.tag),
                            _node(252, 106, l10n.createInvoices, AppRoutes.invoiceNew, PhosphorIconsRegular.fileText),
                            _node(398, 24, l10n.salesReceipts, AppRoutes.salesReceiptNew, PhosphorIconsRegular.receipt),
                            _node(398, 106, l10n.receivePayments, AppRoutes.paymentNew, PhosphorIconsRegular.creditCard),
                            _node(578, 106, l10n.recordDeposits, AppRoutes.bankingDeposits, PhosphorIconsRegular.arrowDown),
                            _small(74, 198, 'Customer Credits', AppRoutes.customerCreditNew, PhosphorIconsRegular.arrowCounterClockwise),
                            _small(258, 198, 'Sales Returns', AppRoutes.salesReturnNew, PhosphorIconsRegular.arrowBendUpLeft),
                            _small(442, 198, 'Customer Center', AppRoutes.customers, PhosphorIconsRegular.usersThree),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _HomePanel(
                        title: l10n.employees,
                        height: 136,
                        child: _PanelBody(
                          lines: const [_Line(196, 62, 300, 62)],
                          children: [
                            _node(102, 28, l10n.enterTime, AppRoutes.timeTracking, PhosphorIconsRegular.timer),
                            _node(300, 28, l10n.payEmployees, AppRoutes.payroll, PhosphorIconsRegular.identificationBadge),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 270,
                  child: Column(
                    children: [
                      _SidePanel(
                        title: l10n.company,
                        height: 250,
                        items: [
                          _SideAction(l10n.chartOfAccounts, AppRoutes.chartOfAccounts, PhosphorIconsRegular.treeStructure),
                          _SideAction(l10n.itemsAndServices, AppRoutes.items, PhosphorIconsRegular.package),
                          _SideAction(l10n.inventoryAdjustments, AppRoutes.inventoryAdjustmentNew, PhosphorIconsRegular.slidersHorizontal),
                          _SideAction(l10n.journalEntries, AppRoutes.journalEntryNew, PhosphorIconsRegular.notebook),
                          _SideAction(l10n.reports, AppRoutes.reports, PhosphorIconsRegular.presentationChart),
                          _SideAction(l10n.settings, AppRoutes.settings, PhosphorIconsRegular.gearSix),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _SidePanel(
                        title: 'Banking',
                        height: 300,
                        items: [
                          _SideAction('Bank Register', AppRoutes.bankingRegister, PhosphorIconsRegular.bookOpen),
                          _SideAction('Write Checks', AppRoutes.bankingChecks, PhosphorIconsRegular.penNib),
                          _SideAction(l10n.recordDeposits, AppRoutes.bankingDeposits, PhosphorIconsRegular.arrowDown),
                          _SideAction('Bank Transfer', AppRoutes.bankingTransfers, PhosphorIconsRegular.arrowsLeftRight),
                          _SideAction('Reconcile', AppRoutes.bankingReconcile, PhosphorIconsRegular.checks),
                          _SideAction('Transactions', AppRoutes.transactions, PhosphorIconsRegular.listMagnifyingGlass),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _node(double left, double top, String label, String path, IconData icon) {
    return Positioned(
      left: left,
      top: top,
      width: 96,
      height: 66,
      child: _QbNode(label: label, path: path, icon: icon),
    );
  }

  static Widget _small(double left, double top, String label, String path, IconData icon) {
    return Positioned(
      left: left,
      top: top,
      width: 145,
      height: 28,
      child: _SmallNode(label: label, path: path, icon: icon),
    );
  }
}

class _HomePanel extends StatelessWidget {
  const _HomePanel({required this.title, required this.height, required this.child});

  final String title;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFF9AA7B7)),
        borderRadius: BorderRadius.circular(7),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.18),
              border: const Border(bottom: BorderSide(color: Color(0xFF9AA7B7))),
            ),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                color: cs.primary,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _PanelBody extends StatelessWidget {
  const _PanelBody({required this.lines, required this.children});

  final List<_Line> lines;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _LinesPainter(lines: lines, color: const Color(0xFF7B8794)),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _QbNode extends StatelessWidget {
  const _QbNode({required this.label, required this.path, required this.icon});

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
        borderRadius: BorderRadius.circular(6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: cs.primary),
            const SizedBox(height: 5),
            SizedBox(
              width: 94,
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, height: 1.05),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallNode extends StatelessWidget {
  const _SmallNode({required this.label, required this.path, required this.icon});

  final String label;
  final String path;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: () => context.go(path),
      icon: Icon(icon, size: 12),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: cs.onSurface,
        backgroundColor: Colors.white.withValues(alpha: 0.78),
        side: const BorderSide(color: Color(0xFFB5BEC9)),
        padding: const EdgeInsets.symmetric(horizontal: 7),
        textStyle: const TextStyle(fontSize: 9.8, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({required this.title, required this.height, required this.items});

  final String title;
  final double height;
  final List<_SideAction> items;

  @override
  Widget build(BuildContext context) {
    return _HomePanel(
      title: title,
      height: height,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.25,
          children: items.map((item) => _SideButton(action: item)).toList(),
        ),
      ),
    );
  }
}

class _SideAction {
  const _SideAction(this.label, this.path, this.icon);
  final String label;
  final String path;
  final IconData icon;
}

class _SideButton extends StatelessWidget {
  const _SideButton({required this.action});

  final _SideAction action;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.white.withValues(alpha: 0.76),
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: () => context.go(action.path),
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: const Color(0xFFB5BEC9)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, size: 19, color: cs.primary),
              const SizedBox(height: 4),
              Text(
                action.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9.8, height: 1.05, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Line {
  const _Line(this.x1, this.y1, this.x2, this.y2);
  final double x1;
  final double y1;
  final double x2;
  final double y2;
}

class _LinesPainter extends CustomPainter {
  const _LinesPainter({required this.lines, required this.color});

  final List<_Line> lines;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final line in lines) {
      _arrow(canvas, paint, Offset(line.x1, line.y1), Offset(line.x2, line.y2));
    }
  }

  void _arrow(Canvas canvas, Paint paint, Offset start, Offset end) {
    canvas.drawLine(start, end, paint);
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    const arrowSize = 7.0;
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
  bool shouldRepaint(covariant _LinesPainter oldDelegate) {
    return oldDelegate.lines != lines || oldDelegate.color != color;
  }
}
