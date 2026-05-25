// invoices_repository.dart

import '../../../../core/api/api_result.dart';
import '../datasources/invoices_remote_datasource.dart';
import '../models/invoice_model.dart';

class InvoicesRepository {
  InvoicesRepository(this._datasource);

  final InvoicesRemoteDatasource _datasource;

  Future<ApiResult<List<InvoiceModel>>> getInvoices({
    String? search,
    String? customerId,
    bool includeVoid = false,
    int page = 1,
    int pageSize = 25,
  }) =>
      _datasource.getInvoices(
        search: search,
        customerId: customerId,
        includeVoid: includeVoid,
        page: page,
        pageSize: pageSize,
      );

  Future<ApiResult<InvoiceModel>> getInvoice(String id) => _datasource.getInvoice(id);

  Future<ApiResult<InvoiceModel>> createInvoice(Map<String, dynamic> body) => _datasource.createInvoice(body);

  Future<ApiResult<InvoiceModel>> postInvoice(String id) => _datasource.postInvoice(id);

  Future<ApiResult<InvoiceModel>> voidInvoice(String id) => _datasource.voidInvoice(id);
}
