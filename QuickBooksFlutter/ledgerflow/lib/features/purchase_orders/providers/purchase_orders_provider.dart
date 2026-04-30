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
  String? _status;
  String? _vendorId;
  bool    _includeClosed    = false;
  bool    _includeCancelled = false;

  @override
  Future<List<PurchaseOrderModel>> build() => _fetch();

  Future<List<PurchaseOrderModel>> _fetch() async {
    final result = await ref
        .read(purchaseOrdersRepoProvider)
        .getAll(status: _status);
    return result.when(
      success: (data) => data,
      failure: (e)    => throw e,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  void setStatus(String? status) {
    _status = status;
    refresh();
  }

  void setVendorId(String? id) {
    _vendorId = id;
    refresh();
  }

  void setIncludeClosed(bool v) {
    _includeClosed = v;
    refresh();
  }

  void setIncludeCancelled(bool v) {
    _includeCancelled = v;
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