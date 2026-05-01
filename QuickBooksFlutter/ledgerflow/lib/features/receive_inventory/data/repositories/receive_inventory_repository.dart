// receive_inventory_repository.dart

import '../../../../core/api/api_result.dart';
import '../datasources/receive_inventory_remote_datasource.dart';
import '../models/create_receive_inventory_dto.dart';
import '../models/receive_inventory_model.dart';

class ReceiveInventoryRepository {
  ReceiveInventoryRepository(this._remote);
  final ReceiveInventoryRemoteDatasource _remote;

  Future<ApiResult<List<ReceiveInventoryModel>>> getAll({String? purchaseOrderId}) =>
      _remote.getAll(purchaseOrderId: purchaseOrderId);

  Future<ApiResult<ReceiveInventoryModel>> getById(String id) =>
      _remote.getById(id);

  Future<ApiResult<ReceiveInventoryModel>> create(CreateReceiveInventoryDto dto) =>
      _remote.create(dto);
}
