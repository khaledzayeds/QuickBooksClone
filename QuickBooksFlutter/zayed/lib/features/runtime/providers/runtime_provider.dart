// features/runtime/providers/runtime_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../data/models/runtime_model.dart';


// nullable — مش بيكسر الـ UI لو الـ API وقفت
final runtimeProvider = FutureProvider<RuntimeModel?>((ref) async {
  try {
    final response = await ApiClient.instance
        .get<Map<String, dynamic>>('/api/settings/runtime');
    return RuntimeModel.fromJson(response.data!);
  } on DioException {
    return null;   // ← مش بيرمي error، بيرجع null
  } catch (_) {
    return null;
  }
});