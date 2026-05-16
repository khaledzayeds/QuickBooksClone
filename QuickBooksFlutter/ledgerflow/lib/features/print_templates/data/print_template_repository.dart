import '../../../core/api/api_client.dart';
import 'models/print_template_model.dart';

class PrintTemplateRepository {
  const PrintTemplateRepository();

  Future<List<PrintTemplateModel>> list({String? documentType}) async {
    final response = await ApiClient.instance.get<List<dynamic>>(
      '/api/print-templates',
      queryParameters: documentType == null ? null : {'documentType': documentType},
    );

    final data = response.data ?? const [];
    return data
        .whereType<Map>()
        .map((item) => PrintTemplateModel.fromApiJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<PrintTemplateModel> save(PrintTemplateModel template) async {
    final backendId = template.backendId;
    final response = backendId == null || backendId.isEmpty
        ? await ApiClient.instance.post<Map<String, dynamic>>('/api/print-templates', data: template.toApiJson())
        : await ApiClient.instance.put<Map<String, dynamic>>('/api/print-templates/$backendId', data: template.toApiJson());

    return PrintTemplateModel.fromApiJson(response.data ?? const {});
  }

  Future<PrintTemplateModel> clone(String backendId, {String? name}) async {
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      '/api/print-templates/$backendId/clone',
      data: {'name': name},
    );

    return PrintTemplateModel.fromApiJson(response.data ?? const {});
  }

  Future<void> delete(String backendId) async {
    await ApiClient.instance.delete<void>('/api/print-templates/$backendId');
  }
}
