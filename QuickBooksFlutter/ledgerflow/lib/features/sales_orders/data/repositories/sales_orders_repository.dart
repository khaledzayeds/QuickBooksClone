// sales_orders_repository.dart

import '../../../../core/api/api_result.dart';
import '../datasources/sales_orders_remote_datasource.dart';
import '../models/sales_order_model.dart';

class SalesOrdersRepository {
  SalesOrdersRepository(this._datasource);

  final SalesOrdersRemoteDatasource _datasource;

  Future<ApiResult<List<SalesOrderModel>>> getAll({
    String? search,
    String? customerId,
    bool includeClosed = false,
    bool includeCancelled = false,
    int page = 1,
    int pageSize = 25,
  }) =>
      _datasource.getAll(
        search: search,
        customerId: customerId,
        includeClosed: includeClosed,
        includeCancelled: includeCancelled,
        page: page,
        pageSize: pageSize,
      );

  Future<ApiResult<SalesOrderModel>> getById(String id) => _datasource.getById(id);

  Future<ApiResult<SalesOrderModel>> create(CreateSalesOrderDto dto) => _datasource.create(dto);

  Future<ApiResult<SalesOrderModel>> open(String id) => _datasource.open(id);

  Future<ApiResult<SalesOrderModel>> close(String id) => _datasource.close(id);

  Future<ApiResult<SalesOrderModel>> cancel(String id) => _datasource.cancel(id);
}
