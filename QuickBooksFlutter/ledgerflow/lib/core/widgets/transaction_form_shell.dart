// transaction_form_shell.dart
//
// THE one shared wrapper for all 8 transaction form screens:
//   Sales Receipt, Invoice, Sales Order, Estimate,
//   Purchase Order, Purchase Bill, Credit Note, Receive Inventory
//
// Each screen only provides:
//   1. headerFields  — the unique top fields (Customer/Vendor, dates, etc.)
//   2. Business logic callbacks (onSave, onClear, metrics, activities…)
//
// Everything else (AppBar, layout, table, sidebar, totals, F2, keyboard
// shortcuts, post-save dialog) lives HERE — written once.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/transaction_line_table_v2.dart';
import '../../features/transactions/widgets/transaction_context_sidebar.dart';
import '../../features/transactions/widgets/transaction_models.dart';
import '../../features/transactions/widgets/transaction_totals_footer.dart';

export '../../../core/widgets/transaction_line_table_v2.dart'
    show TransactionLineEntry, TransactionLinePriceMode;
export '../widgets/transaction_models.dart'
    show
        TransactionContextMetric,
        TransactionContextActivity,
        TransactionTotalsUiModel,
        TransactionScreenKind;

// ─────────────────────────────────────────────────────────────────────────────
// Config passed by each screen
// ─────────────────────────────────────────────────────────────────────────────

class TransactionFormConfig {
  const TransactionFormConfig({
    required this.kind,
    required this.title,
    required this.breadcrumb,
    required this.emptyPartyTitle,
    required this.emptyPartyMessage,
    this.priceMode = TransactionLinePriceMode.sales,
    this.saveAndCloseLabel = 'Save & Close',
    this.saveAndNewLabel = 'Save & New',
    this.clearLabel = 'Clear',
  });

  final TransactionScreenKind kind;
  final String title; // e.g. "New Sales Receipt"
  final String breadcrumb; // e.g. "Sales / Receipts / New"
  final String emptyPartyTitle;
  final String emptyPartyMessage;
  final TransactionLinePriceMode priceMode;
  final String saveAndCloseLabel;
  final String saveAndNewLabel;
  final String clearLabel;
}

// ─────────────────────────────────────────────────────────────────────────────
// The Shell
// ─────────────────────────────────────────────────────────────────────────────

class TransactionFormShell extends StatefulWidget {
  const TransactionFormShell({
    super.key,
    required this.config,
    required this.lines,
    required this.totals,
    required this.onSaveAndClose,
    required this.onSaveAndNew,
    required this.onClear,
    required this.onBack,
    required this.onLinesChanged,
    required this.headerFields,
    this.partyTitle = '',
    this.partySubtitle,
    this.partyInitials,
    this.metrics = const [],
    this.activities = const [],
    this.warning,
    this.notes,
    this.isSaving = false,
    this.isPartyLoading = false,
    this.onViewAll,
    this.onEditNotes,
    this.onPrint,
  });

  // Config
  final TransactionFormConfig config;

  // Lines (owned by parent state)
  final List<TransactionLineEntry> lines;
  final TransactionTotalsUiModel totals;

  // Callbacks
  final Future<String?> Function()
  onSaveAndClose; // returns doc number or null on error
  final Future<String?> Function() onSaveAndNew;
  final VoidCallback onClear;
  final VoidCallback onBack;
  final VoidCallback onLinesChanged;

  // Header (unique per screen — just pass the Column/Row of fields)
  final Widget headerFields;

  // Sidebar
  final String partyTitle;
  final String? partySubtitle;
  final String? partyInitials;
  final List<TransactionContextMetric> metrics;
  final List<TransactionContextActivity> activities;
  final String? warning;
  final String? notes;
  final bool isPartyLoading;
  final VoidCallback? onViewAll;
  final VoidCallback? onEditNotes;

  // Misc
  final bool isSaving;
  final VoidCallback? onPrint;

  @override
  State<TransactionFormShell> createState() => _TransactionFormShellState();
}

class _TransactionFormShellState extends State<TransactionFormShell> {
  // ── Post-save state ────────────────────────────────────────────────────────
  bool _showSavedBanner = false;
  String? _lastSavedNumber;
  Timer? _bannerTimer;

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  // ── Keyboard shortcuts ─────────────────────────────────────────────────────
  KeyEventResult _handleKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isCtrl =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    // F2 = Save & New
    if (event.logicalKey == LogicalKeyboardKey.f2) {
      _doSaveAndNew();
      return KeyEventResult.handled;
    }
    // F4 = Save & Close  (like most ERP systems)
    if (event.logicalKey == LogicalKeyboardKey.f4) {
      _doSaveAndClose();
      return KeyEventResult.handled;
    }
    // Ctrl+P = Print
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyP) {
      widget.onPrint?.call();
      return KeyEventResult.handled;
    }
    // Escape = back (if no changes — let parent decide)
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onBack();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  // ── Save actions ───────────────────────────────────────────────────────────
  Future<void> _doSaveAndClose() async {
    final num = await widget.onSaveAndClose();
    if (num != null && mounted) _showPostSaveBanner(num, closeAfter: true);
  }

  Future<void> _doSaveAndNew() async {
    final num = await widget.onSaveAndNew();
    if (num != null && mounted) _showPostSaveBanner(num, closeAfter: false);
  }

  void _showPostSaveBanner(String docNumber, {required bool closeAfter}) {
    if (!mounted) return;

    // Show print dialog first
    _showPrintDialog(docNumber, closeAfter: closeAfter);
  }

  void _showPrintDialog(String docNumber, {required bool closeAfter}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PostSaveDialog(
        docNumber: docNumber,
        config: widget.config,
        onPrint: widget.onPrint,
        onNew: () {
          Navigator.of(ctx).pop();
          // parent already reset state via onSaveAndNew
        },
        onClose: () {
          Navigator.of(ctx).pop();
          if (closeAfter) widget.onBack();
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Scaffold(
        backgroundColor: cs.surfaceContainerLowest,
        appBar: _buildAppBar(theme, cs),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final showSidebar = constraints.maxWidth >= 1100;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildMainArea(theme, cs)),
                if (showSidebar) ...[
                  VerticalDivider(width: 1, color: cs.outlineVariant),
                  TransactionContextSidebar(
                    title: widget.partyTitle,
                    subtitle: widget.partySubtitle,
                    initials: widget.partyInitials,
                    emptyTitle: widget.config.emptyPartyTitle,
                    emptyMessage: widget.config.emptyPartyMessage,
                    metrics: widget.metrics,
                    activities: widget.activities,
                    warning: widget.warning,
                    isLoading: widget.isPartyLoading,
                    totals: widget.totals,
                    notes: widget.notes,
                    onViewAll: widget.onViewAll,
                    onEditNotes: widget.onEditNotes,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(ThemeData theme, ColorScheme cs) {
    return AppBar(
      toolbarHeight: 48,
      backgroundColor: cs.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 12,
      title: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back, size: 20),
            tooltip: 'Back (Esc)',
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.config.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                widget.config.breadcrumb,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Print
        if (widget.onPrint != null)
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: widget.onPrint,
            icon: const Icon(Icons.print_outlined, size: 20),
            tooltip: 'Print (Ctrl+P)',
          ),
        const SizedBox(width: 4),

        // Clear
        TextButton.icon(
          onPressed: widget.isSaving ? null : widget.onClear,
          icon: const Icon(Icons.refresh_outlined, size: 16),
          label: Text(widget.config.clearLabel),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(width: 4),

        // Save & New (F2)
        OutlinedButton.icon(
          onPressed: widget.isSaving ? null : _doSaveAndNew,
          icon: const Icon(Icons.add_circle_outline, size: 16),
          label: Text('${widget.config.saveAndNewLabel}  F2'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            side: BorderSide(color: cs.outlineVariant),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Save & Close (F4)
        FilledButton.icon(
          onPressed: widget.isSaving ? null : _doSaveAndClose,
          icon: widget.isSaving
              ? const SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_outlined, size: 16),
          label: Text('${widget.config.saveAndCloseLabel}  F4'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Close X
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: widget.onBack,
          icon: const Icon(Icons.close, size: 20),
          tooltip: 'Close (Esc)',
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: cs.outlineVariant),
      ),
    );
  }

  // ── Main area ──────────────────────────────────────────────────────────────
  Widget _buildMainArea(ThemeData theme, ColorScheme cs) {
    return Column(
      children: [
        // Header fields card (unique per screen)
        Container(
          color: cs.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: widget.headerFields,
        ),
        Divider(height: 1, color: theme.dividerColor),

        // Lines toolbar
        Container(
          color: cs.surfaceContainerLowest,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Row(
            children: [
              Text(
                'Products and services',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '\u2022 Tab through cells  \u2022  Enter / F2 adds a new line',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  widget.lines.add(TransactionLineEntry());
                  widget.onLinesChanged();
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add line'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Line table + totals
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TransactionLineTable(
                    lines: widget.lines,
                    priceMode: widget.config.priceMode,
                    fillWidth: true,
                    compact: true,
                    showAddLineFooter: false,
                    onChanged: widget.onLinesChanged,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  border: Border(top: BorderSide(color: cs.outlineVariant)),
                ),
                child: TransactionTotalsFooter(totals: widget.totals),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Post-Save Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _PostSaveDialog extends StatelessWidget {
  const _PostSaveDialog({
    required this.docNumber,
    required this.config,
    required this.onNew,
    required this.onClose,
    this.onPrint,
  });

  final String docNumber;
  final TransactionFormConfig config;
  final VoidCallback onNew;
  final VoidCallback onClose;
  final VoidCallback? onPrint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 360,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 32,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                '${config.kind.label} Saved!',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),

              // Doc number
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tag, size: 16, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      docNumber,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              if (onPrint != null)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onPrint!();
                    },
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const Text('Print'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              if (onPrint != null) const SizedBox(height: 10),

              Row(
                children: [
                  // New document
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onNew,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('New  F2'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Close
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onClose,
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Close'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
