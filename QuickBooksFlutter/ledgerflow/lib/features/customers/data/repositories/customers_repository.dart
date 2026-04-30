// customers_repository.dart
// customers_repository.dart

import '../../../../core/api/api_result.dart';
import '../datasources/customers_remote_datasource.dart';
import '../models/customer_model.dart';

class CustomersRepository {
  CustomersRepository(this._datasource);
  final CustomersRemoteDatasource _datasource;

  Future<ApiResult<List<CustomerModel>>> getCustomers({
    String? search,
    bool includeInactive = false,
    int page = 1,
    int pageSize = 25,
  }) =>
      _datasource.getCustomers(
        search: search,
        includeInactive: includeInactive,
        page: page,
        pageSize: pageSize,
      );

  Future<ApiResult<CustomerModel>> getCustomer(String id) =>
      _datasource.getCustomer(id);

  Future<ApiResult<CustomerModel>> createCustomer(
          Map<String, dynamic> body) =>
      _datasource.createCustomer(body);

  Future<ApiResult<CustomerModel>> updateCustomer(
          String id, Map<String, dynamic> body) =>
      _datasource.updateCustomer(id, body);

  Future<ApiResult<CustomerModel>> toggleActive(
          String id, bool isActive) =>
      _datasource.toggleActive(id, isActive);
}