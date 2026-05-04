// vendor_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../core/api/api_result.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../data/models/vendor_model.dart';
import '../providers/vendors_provider.dart';
import '../widgets/vendor_card.dart';
import '../widgets/vendor_search_bar.dart';

class VendorListScreen extends ConsumerStatefulWidget {
  const VendorListScreen({super.key});

  @override
  ConsumerState<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends ConsumerState<VendorListScreen> {
  bool _includeInactive = false;

  @override
  Widget build(BuildContext context) {
    final vendors = ref.watch(vendorsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Center'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.read(vendorsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
          _VendorActionsMenu(onComingSoon: _showComingSoon),
          AppButton(
            label: 'New Vendor',
            icon: Icons.add_business_outlined,
            onPressed: () => context.go(AppRoutes.vendorNew),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: vendors.when(
        loading: () => const SkeletonList(),
        error: (e, _) => EmptyStateWidget(
          icon: Icons.error_outline,
          message: 'Could not load vendors',
          description: e.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.read(vendorsProvider.notifier).refresh(),
        ),
        data: (list) {
          final active = list.where((v) => v.isActive).length;
          final inactive = list.length - active;
          final openPayable = list.fold<double>(0, (sum, v) => sum + v.balance);
          final vendorCredits = list.fold<double>(0, (sum, v) => sum + v.creditBalance);
          final missingContact = list.where((v) => !v.hasContactInfo).length;
          final owing = list.where((v) => v.balance > 0).length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vendor Center', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(
                      'Manage vendor profiles, payables, credits, and purchase workflow entry points before polishing bills and vendor payments.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _SummaryChip(icon: Icons.store_outlined, label: 'Vendors', value: list.length.toString()),
                        _SummaryChip(icon: Icons.check_circle_outline, label: 'Active', value: active.toString()),
                        _SummaryChip(icon: Icons.block_outlined, label: 'Inactive', value: inactive.toString()),
                        _SummaryChip(icon: Icons.receipt_long_outlined, label: 'Open payable', value: '${openPayable.toStringAsFixed(2)} EGP'),
                        _SummaryChip(icon: Icons.credit_score_outlined, label: 'Vendor credits', value: '${vendorCredits.toStringAsFixed(2)} EGP'),
                        _SummaryChip(icon: Icons.warning_amber_outlined, label: 'No contact', value: missingContact.toString()),
                        _SummaryChip(icon: Icons.payments_outlined, label: 'Payable vendors', value: owing.toString()),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 820;
                    final search = VendorSearchBar(onChanged: (v) => ref.read(vendorsProvider.notifier).setSearch(v));
                    final inactiveSwitch = SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _includeInactive,
                      title: const Text('Include inactive'),
                      onChanged: (v) {
                        setState(() => _includeInactive = v);
                        ref.read(vendorsProvider.notifier).setIncludeInactive(v);
                      },
                    );
                    if (!wide) return Column(children: [search, inactiveSwitch]);
                    return Row(children: [Expanded(child: search), const SizedBox(width: 12), SizedBox(width: 230, child: inactiveSwitch)]);
                  },
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: list.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.store_outlined,
                        message: 'No vendors found',
                        description: 'Create the first vendor or import a vendor list later.',
                        actionLabel: 'New Vendor',
                        onAction: () => context.go(AppRoutes.vendorNew),
                      )
                    : _VendorGroupedList(vendors: list, onToggleActive: _toggleActive),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title is scheduled in the Vendors productivity backlog.')));
  }

  Future<void> _toggleActive(VendorModel vendor) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: vendor.isActive ? 'Make vendor inactive' : 'Make vendor active',
      message: vendor.isActive ? 'Make "${vendor.displayName}" inactive?' : 'Make "${vendor.displayName}" active?',
    );
    if (confirmed != true || !mounted) return;

    final ApiResult<VendorModel> result = await ref.read(vendorsProvider.notifier).toggleActive(vendor.id, !vendor.isActive);

    if (!mounted) return;
    result.when(
      success: (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vendor.isActive ? 'Vendor made inactive' : 'Vendor made active')),
      ),
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      ),
    );
  }
}

class _VendorGroupedList extends StatelessWidget {
  const _VendorGroupedList({required this.vendors, required this.onToggleActive});
  final List<VendorModel> vendors;
  final Future<void> Function(VendorModel vendor) onToggleActive;

  @override
  Widget build(BuildContext context) {
    final payable = vendors.where((v) => v.balance > 0).toList()..sort((a, b) => b.balance.compareTo(a.balance));
    final credit = vendors.where((v) => v.balance <= 0 && v.creditBalance > 0).toList()..sort((a, b) => b.creditBalance.compareTo(a.creditBalance));
    final normal = vendors.where((v) => v.balance <= 0 && v.creditBalance <= 0).toList()..sort((a, b) => a.displayName.compareTo(b.displayName));

    final groups = <_VendorGroup>[
      if (payable.isNotEmpty) _VendorGroup('Open payables', payable, Icons.receipt_long_outlined),
      if (credit.isNotEmpty) _VendorGroup('Vendor credits available', credit, Icons.credit_score_outlined),
      if (normal.isNotEmpty) _VendorGroup('No open payable', normal, Icons.store_outlined),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final total = group.vendors.fold<double>(0, (sum, v) => sum + v.netPayable);
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: ExpansionTile(
            initiallyExpanded: true,
            leading: Icon(group.icon),
            title: Text(group.title, style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text('${group.vendors.length} vendors • ${total.toStringAsFixed(2)} EGP net'),
            children: group.vendors
                .map((vendor) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: VendorCard(
                        vendor: vendor,
                        onTap: () => context.go(AppRoutes.vendorDetails.replaceFirst(':id', vendor.id)),
                        onEdit: () => context.go(AppRoutes.vendorEdit.replaceFirst(':id', vendor.id)),
                        onToggleActive: () => onToggleActive(vendor),
                      ),
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}

class _VendorGroup {
  const _VendorGroup(this.title, this.vendors, this.icon);
  final String title;
  final List<VendorModel> vendors;
  final IconData icon;
}

class _VendorActionsMenu extends StatelessWidget {
  const _VendorActionsMenu({required this.onComingSoon});
  final ValueChanged<String> onComingSoon;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Vendor actions',
      onSelected: onComingSoon,
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'Import Vendors from Excel/CSV', child: _MenuRow(icon: Icons.upload_file_outlined, label: 'Import Vendors from Excel/CSV')),
        PopupMenuItem(value: 'Export Vendors to Excel/CSV', child: _MenuRow(icon: Icons.download_outlined, label: 'Export Vendors to Excel/CSV')),
        PopupMenuItem(value: 'Download Import Template', child: _MenuRow(icon: Icons.description_outlined, label: 'Download Import Template')),
        PopupMenuItem(value: 'Vendor Statement Batch', child: _MenuRow(icon: Icons.summarize_outlined, label: 'Vendor Statement Batch')),
      ],
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Row(children: [Icon(Icons.more_vert), SizedBox(width: 4), Text('Actions')]),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(children: [Icon(icon, size: 18), const SizedBox(width: 10), Text(label)]);
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 18, color: cs.primary), const SizedBox(width: 8), Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w700)), Text(value)]),
    );
  }
}
