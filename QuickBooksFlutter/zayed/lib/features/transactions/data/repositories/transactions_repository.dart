// transactions_repository.dart

import '../../../../core/api/api_result.dart';
import '../datasources/transactions_remote_datasource.dart';
import '../models/transaction_model.dart';

class TransactionsRepository {
  TransactionsRepository(this._datasource);

  final TransactionsRemoteDatasource _datasource;

  Future<ApiResult<List<TransactionModel>>> getAll({
    String? search,
    String? sourceEntityType,
    String? sourceEntityId,
    bool includeVoided = false,
    int page = 1,
    int pageSize = 50,
  }) => _datasource.getAll(
    search: search,
    sourceEntityType: sourceEntityType,
    sourceEntityId: sourceEntityId,
    includeVoided: includeVoided,
    page: page,
    pageSize: pageSize,
  );

  Future<ApiResult<TransactionModel>> getById(String id) =>
      _datasource.getById(id);
}
