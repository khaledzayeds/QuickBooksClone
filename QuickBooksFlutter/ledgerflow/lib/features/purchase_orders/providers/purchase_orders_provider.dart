// purchase_orders_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/purchase_orders_remote_datasource.dart';
import '../data/repositories/purchase_orders_repository.dart';
import '../data/models/purchase_order_model.dart';

// ─── Dependencies ─────────────────────────────────────────────────────
final _poDatasourceProvider = Provider<PurchaseOrdersRemoteDatasource>(
    (_) => PurchaseOrdersRemoteDatasource());

final purchaseOrdersRepoProvider = Provider<PurchaseOrdersRepository>(
    (ref) => PurchaseOrdersRepository(ref.read(_poDatasourceProvider)));

// ─── List Notifier ────────────────────────────────────────────────────
final purchaseOrdersProvider =
    AsyncNotifierProvider<PurchaseOrdersNotifier, List<PurchaseOrderModel>>(
        PurchaseOrdersNotifier.new);

class PurchaseOrdersNotifier
    extends AsyncNotifier<List<PurchaseOrderModel>> {
  
  /// Which filter tab is active
  PurchaseOrderStatus? _statusFilter;
  String? _vendorId;

  @override
  Future<List<PurchaseOrderModel>> build() => _fetch();

  Future<List<PurchaseOrderModel>> _fetch() async {
    // Backend uses includeClosed / includeCancelled booleans, not a status string.
    // We translate our local filter to those booleans.
    bool includeClosed    = false;
    bool includeCancelled = false;

    if (_statusFilter == null) {
      // "الكل" — show everything
      includeClosed    = true;
      includeCancelled = true;
    } else if (_statusFilter == PurchaseOrderStatus.closed) {
      includeClosed = true;
    } else if (_statusFilter == PurchaseOrderStatus.cancelled) {
      includeCancelled = true;
    }

    final result = await ref.read(purchaseOrdersRepoProvider).getAll(
      vendorId: _vendorId,
      includeClosed: includeClosed,
      includeCancelled: includeCancelled,
    );

    final all = result.when(
      success: (data) => data,
      failure: (e) => throw e,
    );

    // Client-side filter for Draft / Open since the API includes both by default
    if (_statusFilter != null &&
        _statusFilter != PurchaseOrderStatus.closed &&
        _statusFilter != PurchaseOrderStatus.cancelled) {
      return all.where((o) => o.status == _statusFilter).toList();
    }
    // For closed/cancelled — the API already filtered, but also do client filter
    // to be safe (API may include drafts/open alongside)
    if (_statusFilter == PurchaseOrderStatus.closed) {
      return all.where((o) => o.status == PurchaseOrderStatus.closed).toList();
    }
    if (_statusFilter == PurchaseOrderStatus.cancelled) {
      return all.where((o) => o.status == PurchaseOrderStatus.cancelled).toList();
    }
    return all;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  void setStatusFilter(PurchaseOrderStatus? status) {
    _statusFilter = status;
    refresh();
  }

  void setVendorId(String? id) {
    _vendorId = id;
    refresh();
  }
}

// ─── Single PO ────────────────────────────────────────────────────────
final purchaseOrderProvider =
    FutureProvider.family<PurchaseOrderModel, String>((ref, id) async {
  final result =
      await ref.read(purchaseOrdersRepoProvider).getById(id);
  return result.when(
    success: (data) => data,
    failure: (e)    => throw e,
  );
});

// ─── Open POs (for Receive Inventory form) ─────────────────────────────
final openPurchaseOrdersProvider =
    FutureProvider<List<PurchaseOrderModel>>((ref) async {
  final result = await ref
      .read(purchaseOrdersRepoProvider)
      .getAll();
  return result.when(
    success: (data) =>
        data.where((o) => o.status == PurchaseOrderStatus.open).toList(),
    failure: (e) => throw e,
  );
});