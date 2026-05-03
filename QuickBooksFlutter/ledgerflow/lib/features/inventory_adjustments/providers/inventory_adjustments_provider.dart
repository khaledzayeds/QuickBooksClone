// inventory_adjustments_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../data/datasources/inventory_adjustments_remote_datasource.dart';
import '../data/models/inventory_adjustment_model.dart';
import '../data/repositories/inventory_adjustments_repository.dart';

final inventoryAdjustmentsDatasourceProvider = Provider<InventoryAdjustmentsRemoteDatasource>(
  (ref) => InventoryAdjustmentsRemoteDatasource(ApiClient.instance),
);

final inventoryAdjustmentsRepositoryProvider = Provider<InventoryAdjustmentsRepository>(
  (ref) => InventoryAdjustmentsRepository(ref.watch(inventoryAdjustmentsDatasourceProvider)),
);

final inventoryAdjustmentsProvider = AsyncNotifierProvider<InventoryAdjustmentsNotifier, List<InventoryAdjustmentModel>>(
  InventoryAdjustmentsNotifier.new,
);

class InventoryAdjustmentsNotifier extends AsyncNotifier<List<InventoryAdjustmentModel>> {
  String _search = '';
  String? _itemId;
  bool _includeVoid = false;

  @override
  Future<List<InventoryAdjustmentModel>> build() => _fetch();

  Future<List<InventoryAdjustmentModel>> _fetch() async {
    final result = await ref.read(inventoryAdjustmentsRepositoryProvider).getAll(
          search: _search,
          itemId: _itemId,
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

  void setItem(String? value) {
    _itemId = value;
    refresh();
  }

  void setIncludeVoid(bool value) {
    _includeVoid = value;
    refresh();
  }

  Future<ApiResult<InventoryAdjustmentModel>> create(CreateInventoryAdjustmentDto dto) async {
    final result = await ref.read(inventoryAdjustmentsRepositoryProvider).create(dto);
    if (result.isSuccess) refresh();
    return result;
  }
}

final inventoryAdjustmentDetailsProvider = FutureProvider.family<InventoryAdjustmentModel, String>((ref, id) async {
  final result = await ref.read(inventoryAdjustmentsRepositoryProvider).getById(id);
  return result.when(
    success: (data) => data,
    failure: (error) => throw error,
  );
});
