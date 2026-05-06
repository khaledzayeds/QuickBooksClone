// banking_repository.dart

import '../../../../core/api/api_result.dart';
import '../datasources/banking_remote_datasource.dart';
import '../models/banking_models.dart';

class BankingRepository {
  BankingRepository(this._remote);

  final BankingRemoteDatasource _remote;

  Future<ApiResult<List<BankAccountModel>>> getAccounts() => _remote.getAccounts();

  Future<ApiResult<BankRegisterResponseModel>> getRegister(String accountId) => _remote.getRegister(accountId);

  Future<ApiResult<void>> createTransfer(CreateBankTransferDto dto) => _remote.createTransfer(dto);
}
