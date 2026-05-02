// invoices_repo.dart

import '../../../../core/api/api_result.dart';
import '../datasources/invoices_api.dart';
import '../models/invoice_contracts.dart';

class InvoicesRepo {
  InvoicesRepo(this._api);
  final InvoicesApi _api;

  Future<ApiResult<List<InvoiceModel>>> getAll({
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

  Future<ApiResult<InvoiceModel>> getById(String id) => _api.getById(id);

  Future<ApiResult<InvoiceModel>> create(CreateInvoiceDto dto) => _api.create(dto);

  Future<ApiResult<InvoiceModel>> postInvoice(String id) => _api.postInvoice(id);

  Future<ApiResult<void>> markSent(String id) => _api.markSent(id);

  Future<ApiResult<InvoiceModel>> voidInvoice(String id) => _api.voidInvoice(id);
}
