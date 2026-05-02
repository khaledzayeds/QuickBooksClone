// json_utils.dart
// Robust JSON parsing utilities to prevent runtime crashes from type mismatches.

class JsonUtils {
  /// Safely converts any dynamic value to a String.
  /// Handles null, int, double, and String.
  static String asString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  /// Safely converts any dynamic value to a nullable String.
  /// Empty strings are normalized to null to simplify optional API fields.
  static String? asNullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  /// Safely converts any dynamic value to a double.
  /// Handles null, int, double, and String.
  static double asDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Safely converts any dynamic value to an int.
  static int asInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Safely converts any dynamic value to a bool.
  static bool asBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) {
      final v = value.toLowerCase();
      if (v == 'true' || v == '1') return true;
      if (v == 'false' || v == '0') return false;
    }
    if (value is num) return value != 0;
    return defaultValue;
  }

  /// Safely converts a list of dynamic values to a typed list using a mapper.
  static List<T> asList<T>(dynamic value, T Function(Map<String, dynamic>) mapper) {
    if (value == null || value is! List) return [];
    return value
        .map((e) => mapper(e as Map<String, dynamic>))
        .toList();
  }
}
