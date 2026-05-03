// payments_repository.dart

import '../../../../core/api/api_result.dart';
import '../datasources/payments_remote_datasource.dart';
import '../models/payment_model.dart';

class PaymentsRepository {
  PaymentsRepository(this._datasource);

  final PaymentsRemoteDatasource _datasource;

  Future<ApiResult<List<PaymentModel>>> getAll({
    String? search,
    String? customerId,
    String? invoiceId,
    bool includeVoid = false,
    int page = 1,
    int pageSize = 25,
  }) =>
      _datasource.getAll(
        search: search,
        customerId: customerId,
        invoiceId: invoiceId,
        includeVoid: includeVoid,
        page: page,
        pageSize: pageSize,
      );

  Future<ApiResult<PaymentModel>> getById(String id) => _datasource.getById(id);

  Future<ApiResult<PaymentModel>> create(CreatePaymentDto dto) => _datasource.create(dto);

  Future<ApiResult<PaymentModel>> voidPayment(String id) => _datasource.voidPayment(id);
}
