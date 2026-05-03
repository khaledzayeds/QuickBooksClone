// estimates_repository.dart

import '../../../../core/api/api_result.dart';
import '../datasources/estimates_remote_datasource.dart';
import '../models/estimate_model.dart';

class EstimatesRepository {
  EstimatesRepository(this._datasource);

  final EstimatesRemoteDatasource _datasource;

  Future<ApiResult<List<EstimateModel>>> getAll({
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

  Future<ApiResult<EstimateModel>> getById(String id) => _datasource.getById(id);

  Future<ApiResult<EstimateModel>> create(CreateEstimateDto dto) => _datasource.create(dto);

  Future<ApiResult<EstimateModel>> send(String id) => _datasource.send(id);

  Future<ApiResult<EstimateModel>> accept(String id) => _datasource.accept(id);

  Future<ApiResult<EstimateModel>> decline(String id) => _datasource.decline(id);

  Future<ApiResult<EstimateModel>> cancel(String id) => _datasource.cancel(id);
}
