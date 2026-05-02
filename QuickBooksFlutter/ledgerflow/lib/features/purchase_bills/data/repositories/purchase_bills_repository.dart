// purchase_bills_repository.dart

import '../../../../core/api/api_result.dart';
import '../datasources/purchase_bills_remote_datasource.dart';
import '../models/purchase_bill_model.dart';
import '../models/billing_plan_model.dart';
import '../models/create_purchase_bill_dto.dart';

class PurchaseBillsRepository {
  PurchaseBillsRepository(this._datasource);
  final PurchaseBillsRemoteDatasource _datasource;

  Future<ApiResult<List<PurchaseBillModel>>> getBills({
    String? search,
    String? vendorId,
    String? inventoryReceiptId,
    bool includeVoid = false,
    int page = 1,
    int pageSize = 25,
  }) =>
      _datasource.getBills(
        search: search,
        vendorId: vendorId,
        inventoryReceiptId: inventoryReceiptId,
        includeVoid: includeVoid,
        page: page,
        pageSize: pageSize,
      );

  Future<ApiResult<PurchaseBillModel>> getBill(String id) => _datasource.getBill(id);

  Future<ApiResult<BillingPlanModel>> getBillingPlan(String inventoryReceiptId) =>
      _datasource.getBillingPlan(inventoryReceiptId);

  Future<ApiResult<PurchaseBillModel>> createBill(CreatePurchaseBillDto dto) =>
      _datasource.createBill(dto);

  Future<ApiResult<PurchaseBillModel>> voidBill(String id) => _datasource.voidBill(id);
}
