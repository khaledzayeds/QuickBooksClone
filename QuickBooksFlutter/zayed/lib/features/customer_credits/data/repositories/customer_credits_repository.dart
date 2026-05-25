// customer_credits_repository.dart

import '../../../../core/api/api_result.dart';
import '../datasources/customer_credits_remote_datasource.dart';
import '../models/customer_credit_model.dart';

class CustomerCreditsRepository {
  CustomerCreditsRepository(this._datasource);

  final CustomerCreditsRemoteDatasource _datasource;

  Future<ApiResult<List<CustomerCreditModel>>> getAll({
    String? search,
    String? customerId,
    int? action,
    bool includeVoid = false,
    int page = 1,
    int pageSize = 25,
  }) =>
      _datasource.getAll(
        search: search,
        customerId: customerId,
        action: action,
        includeVoid: includeVoid,
        page: page,
        pageSize: pageSize,
      );

  Future<ApiResult<CustomerCreditModel>> getById(String id) => _datasource.getById(id);

  Future<ApiResult<CustomerCreditModel>> create(CreateCustomerCreditDto dto) => _datasource.create(dto);

  Future<ApiResult<CustomerCreditModel>> post(String id) => _datasource.post(id);
}
