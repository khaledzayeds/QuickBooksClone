// inventory_adjustments_repository.dart

import '../../../../core/api/api_result.dart';
import '../datasources/inventory_adjustments_remote_datasource.dart';
import '../models/inventory_adjustment_model.dart';

class InventoryAdjustmentsRepository {
  InventoryAdjustmentsRepository(this._datasource);

  final InventoryAdjustmentsRemoteDatasource _datasource;

  Future<ApiResult<List<InventoryAdjustmentModel>>> getAll({
    String? search,
    String? itemId,
    bool includeVoid = false,
    int page = 1,
    int pageSize = 25,
  }) =>
      _datasource.getAll(
        search: search,
        itemId: itemId,
        includeVoid: includeVoid,
        page: page,
        pageSize: pageSize,
      );

  Future<ApiResult<InventoryAdjustmentModel>> getById(String id) => _datasource.getById(id);

  Future<ApiResult<InventoryAdjustmentModel>> create(CreateInventoryAdjustmentDto dto) => _datasource.create(dto);
}
