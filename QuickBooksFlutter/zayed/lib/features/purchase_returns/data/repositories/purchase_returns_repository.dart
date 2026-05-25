// purchase_returns_repository.dart

import '../../../../core/api/api_result.dart';
import '../datasources/purchase_returns_remote_datasource.dart';
import '../models/purchase_return_model.dart';

class PurchaseReturnsRepository {
  PurchaseReturnsRepository(this._datasource);

  final PurchaseReturnsRemoteDatasource _datasource;

  Future<ApiResult<List<PurchaseReturnModel>>> getAll({
    String? search,
    String? purchaseBillId,
    String? vendorId,
    bool includeVoid = false,
    int page = 1,
    int pageSize = 25,
  }) =>
      _datasource.getAll(
        search: search,
        purchaseBillId: purchaseBillId,
        vendorId: vendorId,
        includeVoid: includeVoid,
        page: page,
        pageSize: pageSize,
      );

  Future<ApiResult<PurchaseReturnModel>> getById(String id) => _datasource.getById(id);

  Future<ApiResult<PurchaseReturnModel>> create(CreatePurchaseReturnDto dto) => _datasource.create(dto);

  Future<ApiResult<PurchaseReturnModel>> voidReturn(String id) => _datasource.voidReturn(id);
}
