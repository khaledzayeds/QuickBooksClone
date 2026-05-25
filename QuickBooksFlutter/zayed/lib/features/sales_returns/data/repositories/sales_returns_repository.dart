// sales_returns_repository.dart

import '../../../../core/api/api_result.dart';
import '../datasources/sales_returns_remote_datasource.dart';
import '../models/sales_return_model.dart';

class SalesReturnsRepository {
  SalesReturnsRepository(this._datasource);

  final SalesReturnsRemoteDatasource _datasource;

  Future<ApiResult<List<SalesReturnModel>>> getAll({
    String? search,
    String? invoiceId,
    String? customerId,
    bool includeVoid = false,
    int page = 1,
    int pageSize = 25,
  }) =>
      _datasource.getAll(
        search: search,
        invoiceId: invoiceId,
        customerId: customerId,
        includeVoid: includeVoid,
        page: page,
        pageSize: pageSize,
      );

  Future<ApiResult<SalesReturnModel>> getById(String id) => _datasource.getById(id);

  Future<ApiResult<SalesReturnModel>> create(CreateSalesReturnDto dto) => _datasource.create(dto);

  Future<ApiResult<SalesReturnModel>> post(String id) => _datasource.post(id);

  Future<ApiResult<SalesReturnModel>> voidReturn(String id) => _datasource.voidReturn(id);
}
