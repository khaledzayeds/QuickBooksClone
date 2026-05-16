// items_repository.dart

import '../../../../core/api/api_result.dart';
import '../datasources/items_remote_datasource.dart';
import '../models/item_model.dart';

class ItemsRepository {
  ItemsRepository(this._datasource);
  final ItemsRemoteDatasource _datasource;

  Future<ApiResult<List<ItemModel>>> getItems({
    String? search,
    int?    itemType,
    bool    includeInactive = false,
    int     page            = 1,
    int     pageSize        = 100,
  }) =>
      _datasource.getItems(
        search:          search,
        itemType:        itemType,
        includeInactive: includeInactive,
        page:            page,
        pageSize:        pageSize,
      );

  Future<ApiResult<ItemModel>> getItem(String id) =>
      _datasource.getItem(id);

  Future<ApiResult<ItemModel>> createItem(Map<String, dynamic> body) =>
      _datasource.createItem(body);

  Future<ApiResult<ItemModel>> updateItem(String id, Map<String, dynamic> body) =>
      _datasource.updateItem(id, body);

  Future<ApiResult<ItemModel>> toggleActive(String id, bool isActive) =>
      _datasource.toggleActive(id, isActive);

  Future<ApiResult<int>> bulkPriceChange({
    required List<String> itemIds,
    required int target,
    required int mode,
    required double value,
  }) =>
      _datasource.bulkPriceChange(
        itemIds: itemIds,
        target:  target,
        mode:    mode,
        value:   value,
      );

  Future<ApiResult<String>> exportCsv() => _datasource.exportCsv();


  Future<ApiResult<List<Map<String, dynamic>>>> exportItemsJson() =>
      _datasource.exportItemsJson();
}