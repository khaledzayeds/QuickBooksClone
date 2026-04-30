
// runtime_repository.dart

import '../../../../core/api/api_result.dart';
import '../datasources/runtime_remote_datasource.dart';
import '../models/runtime_model.dart';

class RuntimeRepository {
  RuntimeRepository(this._datasource);
  final RuntimeRemoteDatasource _datasource;

  Future<ApiResult<RuntimeModel>> getRuntime() =>
      _datasource.getRuntime();
}