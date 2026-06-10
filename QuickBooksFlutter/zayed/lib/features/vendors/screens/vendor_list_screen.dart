// vendor_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/api/api_result.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../data/models/vendor_model.dart';
import '../providers/vendors_provider.dart';

class VendorListScreen extends ConsumerStatefulWidget {
  const VendorListScreen({super.key});

  @override
  ConsumerState<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends ConsumerState<VendorListScreen> {
  bool _includeInactive = false;
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final vendors = ref.watch(vendorsProvider);
    final cs = Theme.of(context).colorScheme;
    final text = _VendorText.of(context);

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          _CenterToolbar(
            title: text.vendorCenter,
            primaryLabel: text.newVendor,
            primaryIcon: Icons.add_business_outlined,
            onRefresh: () => ref.read(vendorsProvider.notifier).refresh(),
            onPrimary: () => context.go(AppRoutes.vendorNew),
            onAction: _showActionNotice,
          ),
          Expanded(
            child: vendors.when(
              loading: () => const SkeletonList(),
              error: (e, _) => EmptyStateWidget(
                icon: Icons.error_outline,
                message: text.couldNotLoadVendors,
                description: e.toString(),
                actionLabel: text.retry,
                onAction: () => ref.read(vendorsProvider.notifier).refresh(),
              ),
              data: (list) => _buildCenter(context, list),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenter(BuildContext context, List<VendorModel> vendors) {
    final cs = Theme.of(context).colorScheme;
    final text = _VendorText.of(context);
    final active = vendors.where((v) => v.isActive).length;
    final openPayable = vendors.fold<double>(0, (sum, v) => sum + v.balance);
    final credits = vendors.fold<double>(0, (sum, v) => sum + v.creditBalance);
    final missing = vendors.where((v) => !v.hasContactInfo).length;
    final sorted = [...vendors]
      ..sort((a, b) {
        final bucket = _bucket(a).compareTo(_bucket(b));
        return bucket == 0 ? a.displayName.compareTo(b.displayName) : bucket;
      });
    final selected = sorted.isEmpty
        ? null
        : sorted.firstWhere(
            (v) => v.id == _selectedId,
            orElse: () => sorted.first,
          );
    if (selected != null && _selectedId != selected.id) {
      _selectedId = selected.id;
    }

    return Column(
      children: [
        _MetricStrip(
          chips: [
            _MetricChip(
              Icons.store_outlined,
              text.vendors,
              '${vendors.length}',
            ),
            _MetricChip(Icons.check_circle_outline, text.active, '$active'),
            _MetricChip(
              Icons.receipt_long_outlined,
              text.openPayable,
              '${openPayable.toStringAsFixed(2)} EGP',
            ),
            _MetricChip(
              Icons.credit_score_outlined,
              text.credits,
              '${credits.toStringAsFixed(2)} EGP',
            ),
            _MetricChip(
              Icons.warning_amber_outlined,
              text.noContact,
              '$missing',
              warn: missing > 0,
            ),
          ],
        ),
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 330,
                child: _VendorListPane(
                  vendors: sorted,
                  selectedId: selected?.id,
                  includeInactive: _includeInactive,
                  onSearch: (v) =>
                      ref.read(vendorsProvider.notifier).setSearch(v),
                  onIncludeInactive: (v) {
                    setState(() => _includeInactive = v);
                    ref.read(vendorsProvider.notifier).setIncludeInactive(v);
                  },
                  onSelect: (vendor) => setState(() => _selectedId = vendor.id),
                ),
              ),
              VerticalDivider(width: 1, color: cs.outlineVariant),
              Expanded(
                child: selected == null
                    ? EmptyStateWidget(
                        icon: Icons.store_outlined,
                        message: text.noVendorsFound,
                        description: text.createVendorHint,
                        actionLabel: text.newVendor,
                        onAction: () => context.go(AppRoutes.vendorNew),
                      )
                    : _VendorDetailPane(
                        vendor: selected,
                        onEdit: () => context.go(
                          AppRoutes.vendorEdit.replaceFirst(':id', selected.id),
                        ),
                        onOpen: () => context.go(
                          AppRoutes.vendorDetails.replaceFirst(
                            ':id',
                            selected.id,
                          ),
                        ),
                        onToggleActive: () => _toggleActive(selected),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _bucket(VendorModel vendor) {
    if (vendor.balance > 0) return 0;
    if (vendor.creditBalance > 0) return 1;
    return 2;
  }

  void _showActionNotice(String title) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(title)));
  }

  Future<void> _toggleActive(VendorModel vendor) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: vendor.isActive
          ? _VendorText.of(context).makeVendorInactive
          : _VendorText.of(context).makeVendorActive,
      message: vendor.isActive
          ? _VendorText.of(context).confirmVendorInactive(vendor.displayName)
          : _VendorText.of(context).confirmVendorActive(vendor.displayName),
    );
    if (confirmed != true || !mounted) return;

    final ApiResult<VendorModel> result = await ref
        .read(vendorsProvider.notifier)
        .toggleActive(vendor.id, !vendor.isActive);
    if (!mounted) return;
    result.when(
      success: (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            vendor.isActive
                ? _VendorText.of(context).vendorMadeInactive
                : _VendorText.of(context).vendorMadeActive,
          ),
        ),
      ),
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      ),
    );
  }
}

class _VendorListPane extends StatelessWidget {
  const _VendorListPane({
    required this.vendors,
    required this.selectedId,
    required this.includeInactive,
    required this.onSearch,
    required this.onIncludeInactive,
    required this.onSelect,
  });

  final List<VendorModel> vendors;
  final String? selectedId;
  final bool includeInactive;
  final ValueChanged<String> onSearch;
  final ValueChanged<bool> onIncludeInactive;
  final ValueChanged<VendorModel> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = _VendorText.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(bottom: BorderSide(color: cs.outlineVariant)),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 30,
                child: TextField(
                  onChanged: onSearch,
                  decoration: InputDecoration(
                    hintText: text.searchNamePhoneEmail,
                    prefixIcon: const Icon(Icons.search, size: 16),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      text.activeVendors,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(text.inactive, style: const TextStyle(fontSize: 11)),
                  Transform.scale(
                    scale: 0.65,
                    child: Switch(
                      value: includeInactive,
                      onChanged: onIncludeInactive,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          height: 28,
          color: cs.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(flex: 5, child: _Head(text.name)),
              Expanded(flex: 3, child: _Head(text.payable, end: true)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: vendors.length,
            itemBuilder: (context, index) {
              final vendor = vendors[index];
              final selected = vendor.id == selectedId;
              return _VendorListRow(
                vendor: vendor,
                selected: selected,
                onTap: () => onSelect(vendor),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _VendorListRow extends StatelessWidget {
  const _VendorListRow({
    required this.vendor,
    required this.selected,
    required this.onTap,
  });
  final VendorModel vendor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        color: selected ? cs.primary.withValues(alpha: 0.16) : null,
        child: Row(
          children: [
            Icon(
              vendor.balance > 0
                  ? Icons.receipt_long_outlined
                  : Icons.store_outlined,
              size: 15,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 5,
              child: Text(
                vendor.displayName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                vendor.netPayable.toStringAsFixed(2),
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 12,
                  color: vendor.netPayable > 0
                      ? cs.primary
                      : cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VendorDetailPane extends StatelessWidget {
  const _VendorDetailPane({
    required this.vendor,
    required this.onEdit,
    required this.onOpen,
    required this.onToggleActive,
  });

  final VendorModel vendor;
  final VoidCallback onEdit;
  final VoidCallback onOpen;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = _VendorText.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: cs.outlineVariant)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text.vendorInformation,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                tooltip: text.open,
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new_outlined),
              ),
              IconButton(
                tooltip: text.edit,
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(42, 22, 22, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoLine(text.vendorName, vendor.displayName),
                _InfoLine(text.company, vendor.companyName ?? '-'),
                _InfoLine(text.phone, vendor.phone ?? '-'),
                _InfoLine(text.email, vendor.email ?? '-'),
                _InfoLine(text.currency, vendor.currency),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ValueBox(
                      text.openPayable,
                      '${vendor.balance.toStringAsFixed(2)} ${vendor.currency}',
                    ),
                    _ValueBox(
                      text.vendorCredits,
                      '${vendor.creditBalance.toStringAsFixed(2)} ${vendor.currency}',
                    ),
                    _ValueBox(
                      text.netPayable,
                      '${vendor.netPayable.toStringAsFixed(2)} ${vendor.currency}',
                      highlight: vendor.netPayable > 0,
                    ),
                    _ValueBox(
                      text.status,
                      vendor.isActive ? text.active : text.inactive,
                    ),
                  ],
                ),
                const Spacer(),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text(text.editVendor),
                    ),
                    OutlinedButton.icon(
                      onPressed: onToggleActive,
                      icon: const Icon(Icons.toggle_on_outlined, size: 16),
                      label: Text(
                        vendor.isActive ? text.makeInactive : text.makeActive,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.push(
                        AppRoutes.vendorTransactionHistory,
                        extra: {
                          'vendorId': vendor.id,
                          'vendorName': vendor.displayName,
                        },
                      ),
                      icon: const Icon(Icons.receipt_long_outlined, size: 16),
                      label: Text(text.statement),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          flex: 2,
          child: _ActivityTable(
            title: text.transactions,
            rows: [
              _ActivityRow(
                text.openPayable,
                '-',
                '-',
                text.accountsPayable,
                vendor.balance,
              ),
              if (vendor.creditBalance > 0)
                _ActivityRow(
                  text.credit,
                  '-',
                  '-',
                  text.vendorCredits,
                  -vendor.creditBalance,
                ),
            ],
            currency: vendor.currency,
          ),
        ),
      ],
    );
  }
}

class _CenterToolbar extends StatelessWidget {
  const _CenterToolbar({
    required this.title,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onRefresh,
    required this.onPrimary,
    required this.onAction,
  });

  final String title;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onRefresh;
  final VoidCallback onPrimary;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = _VendorText.of(context);
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          IconButton(
            tooltip: text.refresh,
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            tooltip: text.actions,
            icon: const Icon(Icons.more_vert),
            onSelected: onAction,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: text.importVendors,
                child: _MenuRow(
                  icon: Icons.upload_file_outlined,
                  label: text.importVendors,
                ),
              ),
              PopupMenuItem(
                value: text.exportVendors,
                child: _MenuRow(
                  icon: Icons.download_outlined,
                  label: text.exportVendors,
                ),
              ),
              PopupMenuItem(
                value: text.downloadImportTemplate,
                child: _MenuRow(
                  icon: Icons.description_outlined,
                  label: text.downloadImportTemplate,
                ),
              ),
              PopupMenuItem(
                value: text.vendorStatementBatch,
                child: _MenuRow(
                  icon: Icons.summarize_outlined,
                  label: text.vendorStatementBatch,
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          FilledButton.icon(
            onPressed: onPrimary,
            icon: Icon(primaryIcon, size: 17),
            label: Text(primaryLabel),
          ),
        ],
      ),
    );
  }
}

class _MetricStrip extends StatelessWidget {
  const _MetricStrip({required this.chips});
  final List<_MetricChip> chips;
  @override
  Widget build(BuildContext context) => Container(
    height: 46,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemBuilder: (_, i) => chips[i],
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemCount: chips.length,
    ),
  );
}

class _MetricChip extends StatelessWidget {
  const _MetricChip(this.icon, this.label, this.value, {this.warn = false});
  final IconData icon;
  final String label;
  final String value;
  final bool warn;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: warn ? cs.errorContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: warn ? cs.onErrorContainer : cs.primary),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      children: [
        SizedBox(
          width: 125,
          child: Text(
            label,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _ValueBox extends StatelessWidget {
  const _ValueBox(this.label, this.value, {this.highlight = false});
  final String label;
  final String value;
  final bool highlight;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 160,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlight ? cs.primaryContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _ActivityTable extends StatelessWidget {
  const _ActivityTable({
    required this.title,
    required this.rows,
    required this.currency,
  });
  final String title;
  final List<_ActivityRow> rows;
  final String currency;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = _VendorText.of(context);
    return Column(
      children: [
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          color: cs.surfaceContainerHighest,
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(child: _Head(text.type)),
              Expanded(child: _Head(text.num)),
              Expanded(child: _Head(text.date)),
              Expanded(child: _Head(text.account)),
              Expanded(child: _Head(text.amount, end: true)),
            ],
          ),
        ),
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Text(
                    text.noActivityToShow,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (_, i) {
                    final row = rows[i];
                    return Container(
                      height: 30,
                      color: i.isEven
                          ? cs.primaryContainer.withValues(alpha: 0.25)
                          : cs.surfaceContainerLowest,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              row.type,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              row.num,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              row.date,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              row.account,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${row.amount.toStringAsFixed(2)} $currency',
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ActivityRow {
  const _ActivityRow(this.type, this.num, this.date, this.account, this.amount);
  final String type;
  final String num;
  final String date;
  final String account;
  final double amount;
}

class _Head extends StatelessWidget {
  const _Head(this.label, {this.end = false});
  final String label;
  final bool end;
  @override
  Widget build(BuildContext context) => Text(
    label,
    textAlign: end ? TextAlign.end : TextAlign.start,
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
    overflow: TextOverflow.ellipsis,
  );
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [Icon(icon, size: 18), const SizedBox(width: 10), Text(label)],
  );
}

class _VendorText {
  const _VendorText(this.ar);
  final bool ar;

  static _VendorText of(BuildContext context) =>
      _VendorText(Localizations.localeOf(context).languageCode == 'ar');

  String get vendorCenter => ar ? 'مركز الموردين' : 'Vendor Center';
  String get newVendor => ar ? 'مورد جديد' : 'New Vendor';
  String get couldNotLoadVendors =>
      ar ? 'تعذر تحميل الموردين' : 'Could not load vendors';
  String get retry => ar ? 'إعادة المحاولة' : 'Retry';
  String get vendors => ar ? 'الموردون' : 'Vendors';
  String get active => ar ? 'نشط' : 'Active';
  String get inactive => ar ? 'غير نشط' : 'Inactive';
  String get openPayable => ar ? 'المستحق المفتوح' : 'Open payable';
  String get credits => ar ? 'الأرصدة الدائنة' : 'Credits';
  String get noContact => ar ? 'بدون بيانات اتصال' : 'No contact';
  String get noVendorsFound => ar ? 'لا يوجد موردون' : 'No vendors found';
  String get createVendorHint => ar
      ? 'أنشئ موردًا لبدء متابعة المشتريات والمستحقات.'
      : 'Create a vendor to start tracking purchases and payables.';
  String get makeVendorInactive =>
      ar ? 'جعل المورد غير نشط' : 'Make vendor inactive';
  String get makeVendorActive => ar ? 'جعل المورد نشط' : 'Make vendor active';
  String confirmVendorInactive(String name) =>
      ar ? 'جعل "$name" غير نشط؟' : 'Make "$name" inactive?';
  String confirmVendorActive(String name) =>
      ar ? 'جعل "$name" نشط؟' : 'Make "$name" active?';
  String get vendorMadeInactive =>
      ar ? 'تم جعل المورد غير نشط' : 'Vendor made inactive';
  String get vendorMadeActive =>
      ar ? 'تم جعل المورد نشط' : 'Vendor made active';
  String get searchNamePhoneEmail =>
      ar ? 'بحث بالاسم أو الهاتف أو البريد...' : 'Search name, phone, email...';
  String get activeVendors => ar ? 'الموردون النشطون' : 'Active Vendors';
  String get name => ar ? 'الاسم' : 'Name';
  String get payable => ar ? 'المستحق' : 'Payable';
  String get vendorInformation => ar ? 'معلومات المورد' : 'Vendor Information';
  String get open => ar ? 'فتح' : 'Open';
  String get edit => ar ? 'تعديل' : 'Edit';
  String get vendorName => ar ? 'اسم المورد' : 'Vendor Name';
  String get company => ar ? 'الشركة' : 'Company';
  String get phone => ar ? 'الهاتف' : 'Phone';
  String get email => ar ? 'البريد' : 'Email';
  String get currency => ar ? 'العملة' : 'Currency';
  String get vendorCredits => ar ? 'أرصدة المورد' : 'Vendor credits';
  String get netPayable => ar ? 'صافي المستحق' : 'Net payable';
  String get status => ar ? 'الحالة' : 'Status';
  String get editVendor => ar ? 'تعديل المورد' : 'Edit Vendor';
  String get makeInactive => ar ? 'جعله غير نشط' : 'Make Inactive';
  String get makeActive => ar ? 'جعله نشط' : 'Make Active';
  String get statement => ar ? 'كشف حساب' : 'Statement';
  String get transactions => ar ? 'المعاملات' : 'Transactions';
  String get accountsPayable => ar ? 'حسابات دائنة' : 'Accounts Payable';
  String get credit => ar ? 'رصيد دائن' : 'Credit';
  String get refresh => ar ? 'تحديث' : 'Refresh';
  String get actions => ar ? 'إجراءات' : 'Actions';
  String get importVendors =>
      ar ? 'استيراد الموردين من Excel/CSV' : 'Import Vendors from Excel/CSV';
  String get exportVendors =>
      ar ? 'تصدير الموردين إلى Excel/CSV' : 'Export Vendors to Excel/CSV';
  String get downloadImportTemplate =>
      ar ? 'تحميل قالب الاستيراد' : 'Download Import Template';
  String get vendorStatementBatch =>
      ar ? 'طباعة كشوف الموردين دفعة واحدة' : 'Vendor Statement Batch';
  String get type => ar ? 'النوع' : 'Type';
  String get num => ar ? 'الرقم' : 'Num';
  String get date => ar ? 'التاريخ' : 'Date';
  String get account => ar ? 'الحساب' : 'Account';
  String get amount => ar ? 'المبلغ' : 'Amount';
  String get noActivityToShow =>
      ar ? 'لا يوجد نشاط للعرض' : 'No activity to show';
}
