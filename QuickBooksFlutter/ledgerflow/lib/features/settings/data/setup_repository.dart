import '../../../core/api/api_client.dart';
import 'models/setup_models.dart';

class SetupRepository {
  Future<SetupStatusModel> getStatus() async {
    final response = await ApiClient.instance.get<Map<String, dynamic>>('/api/setup/status');
    return SetupStatusModel.fromJson(response.data ?? const {});
  }

  Future<InitializeCompanyResultModel> initializeCompany(InitializeCompanyPayload payload) async {
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      '/api/setup/initialize-company',
      data: payload.toJson(),
    );
    return InitializeCompanyResultModel.fromJson(response.data ?? const {});
  }
}
