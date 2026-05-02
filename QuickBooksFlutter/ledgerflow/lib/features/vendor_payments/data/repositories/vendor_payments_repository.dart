// vendor_payments_repository.dart

import '../../../../core/api/api_result.dart';
import '../datasources/vendor_payments_remote_datasource.dart';
import '../models/create_vendor_payment_dto.dart';
import '../models/vendor_payment_model.dart';

class VendorPaymentsRepository {
  VendorPaymentsRepository(this._datasource);
  final VendorPaymentsRemoteDatasource _datasource;

  Future<ApiResult<List<VendorPaymentModel>>> getPayments({
    String? search,
    String? vendorId,
    String? purchaseBillId,
    bool includeVoid = false,
    int page = 1,
    int pageSize = 25,
  }) =>
      _datasource.getPayments(
        search: search,
        vendorId: vendorId,
        purchaseBillId: purchaseBillId,
        includeVoid: includeVoid,
        page: page,
        pageSize: pageSize,
      );

  Future<ApiResult<VendorPaymentModel>> createPayment(
    CreateVendorPaymentDto dto,
  ) =>
      _datasource.createPayment(dto);

  Future<ApiResult<VendorPaymentModel>> voidPayment(String id) =>
      _datasource.voidPayment(id);
}
