// purchase_returns_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../data/datasources/purchase_returns_remote_datasource.dart';
import '../data/models/purchase_return_model.dart';
import '../data/repositories/purchase_returns_repository.dart';

final purchaseReturnsDatasourceProvider = Provider<PurchaseReturnsRemoteDatasource>(
  (ref) => PurchaseReturnsRemoteDatasource(ApiClient.instance),
);

final purchaseReturnsRepositoryProvider = Provider<PurchaseReturnsRepository>(
  (ref) => PurchaseReturnsRepository(ref.watch(purchaseReturnsDatasourceProvider)),
);

final purchaseReturnsProvider = AsyncNotifierProvider<PurchaseReturnsNotifier, List<PurchaseReturnModel>>(
  PurchaseReturnsNotifier.new,
);

class PurchaseReturnsNotifier extends AsyncNotifier<List<PurchaseReturnModel>> {
  String _search = '';
  String? _purchaseBillId;
  String? _vendorId;
  bool _includeVoid = false;

  @override
  Future<List<PurchaseReturnModel>> build() => _fetch();

  Future<List<PurchaseReturnModel>> _fetch() async {
    final result = await ref.read(purchaseReturnsRepositoryProvider).getAll(
          search: _search,
          purchaseBillId: _purchaseBillId,
          vendorId: _vendorId,
          includeVoid: _includeVoid,
        );
    return result.when(
      success: (data) => data,
      failure: (error) => throw error,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  void setSearch(String value) {
    _search = value;
    refresh();
  }

  void setPurchaseBill(String? value) {
    _purchaseBillId = value;
    refresh();
  }

  void setVendor(String? value) {
    _vendorId = value;
    refresh();
  }

  void setIncludeVoid(bool value) {
    _includeVoid = value;
    refresh();
  }

  Future<ApiResult<PurchaseReturnModel>> create(CreatePurchaseReturnDto dto) async {
    final result = await ref.read(purchaseReturnsRepositoryProvider).create(dto);
    if (result.isSuccess) refresh();
    return result;
  }

  Future<ApiResult<PurchaseReturnModel>> voidReturn(String id) async {
    final result = await ref.read(purchaseReturnsRepositoryProvider).voidReturn(id);
    if (result.isSuccess) refresh();
    return result;
  }
}

final purchaseReturnDetailsProvider = FutureProvider.family<PurchaseReturnModel, String>((ref, id) async {
  final result = await ref.read(purchaseReturnsRepositoryProvider).getById(id);
  return result.when(
    success: (data) => data,
    failure: (error) => throw error,
  );
});
