// sales_receipts_repo.dart

import '../../../../core/api/api_result.dart';
import '../datasources/sales_receipts_api.dart';
import '../models/sales_receipt_contracts.dart';

class SalesReceiptsRepo {
  SalesReceiptsRepo(this._api);
  final SalesReceiptsApi _api;

  Future<ApiResult<List<SalesReceiptModel>>> getAll({
    String? search,
    String? customerId,
    bool includeVoid = false,
    int page = 1,
    int pageSize = 25,
  }) =>
      _api.getAll(
        search: search,
        customerId: customerId,
        includeVoid: includeVoid,
        page: page,
        pageSize: pageSize,
      );

  Future<ApiResult<SalesReceiptModel>> getById(String id) => _api.getById(id);

  Future<ApiResult<SalesReceiptModel>> create(CreateSalesReceiptDto dto) =>
      _api.create(dto);

  Future<ApiResult<SalesReceiptModel>> voidReceipt(String id) =>
      _api.voidReceipt(id);
}
