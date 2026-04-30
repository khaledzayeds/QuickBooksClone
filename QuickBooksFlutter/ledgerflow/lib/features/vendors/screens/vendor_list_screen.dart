// vendor_list_screen.dart
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
  ConsumerState<VendorListScreen> createState() =>
      _VendorListScreenState();
}

class _VendorListScreenState extends ConsumerState<VendorListScreen> {
  bool _includeInactive = false;

  @override
  Widget build(BuildContext context) {
    final vendors = ref.watch(vendorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الموردون'),
        actions: [
          AppButton(
            label: 'مورد جديد',
            icon: Icons.add_business_outlined,
            onPressed: () => context.go(AppRoutes.vendorNew),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: VendorSearchBar(
                    onChanged: (v) =>
                        ref.read(vendorsProvider.notifier).setSearch(v),
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _includeInactive,
                      onChanged: (v) {
                        setState(() => _includeInactive = v!);
                        ref
                            .read(vendorsProvider.notifier)
                            .setIncludeInactive(v!);
                      },
                    ),
                    const Text('غير نشط'),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: vendors.when(
              loading: () => const SkeletonList(),
              error: (e, _) => EmptyStateWidget(
                icon: Icons.error_outline,
                message: 'تعذر تحميل الموردين',
                description: e.toString(),
                actionLabel: 'إعادة المحاولة',
                onAction: () =>
                    ref.read(vendorsProvider.notifier).refresh(),
              ),
              data: (list) => list.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.store_outlined,
                      message: 'لا يوجد موردون',
                      description: 'ابدأ بإضافة مورد جديد',
                      actionLabel: 'مورد جديد',
                      onAction: () => context.go(AppRoutes.vendorNew),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, i) => VendorCard(
                        vendor: list[i],
                        onTap: () => context.go(
                          AppRoutes.vendorDetails
                              .replaceFirst(':id', list[i].id),
                        ),
                        onEdit: () => context.go(
                          AppRoutes.vendorEdit
                              .replaceFirst(':id', list[i].id),
                        ),
                        onToggleActive: () => _toggleActive(list[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(VendorModel vendor) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: vendor.isActive ? 'تعطيل المورد' : 'تفعيل المورد',
      message: vendor.isActive
          ? 'هل تريد تعطيل "${vendor.displayName}"؟'
          : 'هل تريد تفعيل "${vendor.displayName}"؟',
    );
    if (!confirmed! || !mounted) return;

    final ApiResult<VendorModel> result = await ref
        .read(vendorsProvider.notifier)
        .toggleActive(vendor.id, !vendor.isActive);

    if (!mounted) return;
    result.when(
      success: (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              vendor.isActive ? 'تم تعطيل المورد' : 'تم تفعيل المورد'),
        ),
      ),
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      ),
    );
  }
}