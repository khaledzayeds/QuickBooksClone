// vendors_repository.dart
// vendors_repository.dart

import '../../../../core/api/api_result.dart';
import '../datasources/vendors_remote_datasource.dart';
import '../models/vendor_model.dart';

class VendorsRepository {
  VendorsRepository(this._datasource);
  final VendorsRemoteDatasource _datasource;

  Future<ApiResult<List<VendorModel>>> getVendors({
    String? search,
    bool includeInactive = false,
    int page = 1,
    int pageSize = 25,
  }) =>
      _datasource.getVendors(
        search: search,
        includeInactive: includeInactive,
        page: page,
        pageSize: pageSize,
      );

  Future<ApiResult<VendorModel>> getVendor(String id) =>
      _datasource.getVendor(id);

  Future<ApiResult<VendorModel>> createVendor(
          Map<String, dynamic> body) =>
      _datasource.createVendor(body);

  Future<ApiResult<VendorModel>> updateVendor(
          String id, Map<String, dynamic> body) =>
      _datasource.updateVendor(id, body);

  Future<ApiResult<VendorModel>> toggleActive(
          String id, bool isActive) =>
      _datasource.toggleActive(id, isActive);
}