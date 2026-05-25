import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../data/datasources/items_remote_datasource.dart';
import '../data/models/item_model.dart';
import '../data/repositories/items_repository.dart';

final itemsDatasourceProvider = Provider<ItemsRemoteDatasource>(
  (ref) => ItemsRemoteDatasource(ApiClient.instance),
);

final itemsRepositoryProvider = Provider<ItemsRepository>(
  (ref) => ItemsRepository(ref.watch(itemsDatasourceProvider)),
);

final itemsProvider = AsyncNotifierProvider<ItemsNotifier, List<ItemModel>>(
  ItemsNotifier.new,
);

class ItemsNotifier extends AsyncNotifier<List<ItemModel>> {
  String _search = '';
  int? _typeFilter;
  bool _includeInactive = false;

  @override
  Future<List<ItemModel>> build() {
    return _fetch();
  }

  Future<List<ItemModel>> _fetch() async {
    final result = await ref
        .read(itemsRepositoryProvider)
        .getItems(
          search: _search,
          itemType: _typeFilter,
          includeInactive: _includeInactive,
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

  void setTypeFilter(int? type) {
    _typeFilter = type;
    refresh();
  }

  void setIncludeInactive(bool value) {
    _includeInactive = value;
    refresh();
  }

  Future<ApiResult<ItemModel>> createItem(Map<String, dynamic> body) async {
    final result = await ref.read(itemsRepositoryProvider).createItem(body);
    if (result.isSuccess) await refresh();
    return result;
  }

  Future<ApiResult<ItemModel>> updateItem(String id, Map<String, dynamic> body) async {
    final result = await ref.read(itemsRepositoryProvider).updateItem(id, body);
    if (result.isSuccess) await refresh();
    return result;
  }

  Future<ApiResult<ItemModel>> toggleActive(String id, bool isActive) async {
    final result = await ref.read(itemsRepositoryProvider).toggleActive(id, isActive);
    if (result.isSuccess) await refresh();
    return result;
  }

  Future<ApiResult<int>> bulkPriceChange({
    required List<String> itemIds,
    required int target,
    required int mode,
    required double value,
  }) async {
    final result = await ref.read(itemsRepositoryProvider).bulkPriceChange(
      itemIds: itemIds,
      target:  target,
      mode:    mode,
      value:   value,
    );
    if (result.isSuccess) await refresh();
    return result;
  }

  Future<ApiResult<String>> exportCsv() =>
      ref.read(itemsRepositoryProvider).exportCsv();


  Future<ApiResult<List<Map<String, dynamic>>>> exportItemsJson() =>
      ref.read(itemsRepositoryProvider).exportItemsJson();
}

final itemDetailProvider = FutureProvider.family<ItemModel, String>((
  ref,
  id,
) async {
  final result = await ref.read(itemsRepositoryProvider).getItem(id);
  return result.when(success: (data) => data, failure: (error) => throw error);
});
