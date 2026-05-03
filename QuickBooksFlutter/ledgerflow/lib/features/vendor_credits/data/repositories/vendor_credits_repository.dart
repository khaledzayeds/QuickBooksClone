// vendor_credits_repository.dart

import '../../../../core/api/api_result.dart';
import '../datasources/vendor_credits_remote_datasource.dart';
import '../models/vendor_credit_model.dart';

class VendorCreditsRepository {
  VendorCreditsRepository(this._datasource);

  final VendorCreditsRemoteDatasource _datasource;

  Future<ApiResult<List<VendorCreditModel>>> getAll({
    String? search,
    String? vendorId,
    int? action,
    bool includeVoid = false,
    int page = 1,
    int pageSize = 25,
  }) =>
      _datasource.getAll(
        search: search,
        vendorId: vendorId,
        action: action,
        includeVoid: includeVoid,
        page: page,
        pageSize: pageSize,
      );

  Future<ApiResult<VendorCreditModel>> getById(String id) => _datasource.getById(id);

  Future<ApiResult<VendorCreditModel>> create(CreateVendorCreditDto dto) => _datasource.create(dto);
}
