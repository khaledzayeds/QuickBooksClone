// sales_receipts_repository.dart

import '../../../../core/api/api_result.dart';
import '../datasources/sales_receipts_remote_datasource.dart';
import '../models/sales_receipt_models.dart';

class SalesReceiptsRepository {
  SalesReceiptsRepository(this._datasource);
  final SalesReceiptsRemoteDatasource _datasource;

  Future<ApiResult<List<SalesReceiptModel>>> getAll({
    String? search,
    String? customerId,
    bool includeVoid = false,
    int page = 1,
    int pageSize = 25,
  }) =>
      _datasource.getAll(
        search: search,
        customerId: customerId,
        includeVoid: includeVoid,
        page: page,
        pageSize: pageSize,
      );

  Future<ApiResult<SalesReceiptModel>> getById(String id) =>
      _datasource.getById(id);

  Future<ApiResult<SalesReceiptModel>> create(CreateSalesReceiptDto dto) =>
      _datasource.create(dto);

  Future<ApiResult<SalesReceiptModel>> voidReceipt(String id) =>
      _datasource.voidReceipt(id);
}
