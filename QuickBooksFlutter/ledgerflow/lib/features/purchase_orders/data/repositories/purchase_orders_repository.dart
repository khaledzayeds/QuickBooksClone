import '../../../../core/api/api_result.dart';
import '../datasources/purchase_orders_remote_datasource.dart';
import '../models/purchase_order_model.dart';

class PurchaseOrdersRepository {
  PurchaseOrdersRepository(this._remote);
  final PurchaseOrdersRemoteDatasource _remote;

  Future<ApiResult<List<PurchaseOrderModel>>> getAll({String? status}) =>
      _remote.getAll(status: status);

  Future<ApiResult<PurchaseOrderModel>> getById(String id) =>
      _remote.getById(id);

  Future<ApiResult<PurchaseOrderModel>> create(CreatePurchaseOrderDto dto) =>
      _remote.create(dto);

  Future<ApiResult<PurchaseOrderModel>> openOrder(String id) =>
      _remote.openOrder(id);

  Future<ApiResult<PurchaseOrderModel>> closeOrder(String id) =>
      _remote.closeOrder(id);

  Future<ApiResult<PurchaseOrderModel>> cancelOrder(String id) =>
      _remote.cancelOrder(id);

  Future<ApiResult<void>> delete(String id) => _remote.delete(id);
}