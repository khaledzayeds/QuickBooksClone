import 'dart:math';

import '../data/models/item_model.dart';

class ItemBarcodeUtils {
  const ItemBarcodeUtils._();

  static String generateInStoreBarcode(Iterable<ItemModel> items) {
    final random = Random.secure();
    final existing = items
        .map((item) => item.barcode?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toSet();

    for (var attempt = 0; attempt < 50; attempt++) {
      final base = StringBuffer('200');
      for (var i = 0; i < 9; i++) {
        base.write(random.nextInt(10));
      }
      final barcode = withEan13CheckDigit(base.toString());
      if (!existing.contains(barcode)) return barcode;
    }

    final fallbackBase =
        '200${DateTime.now().microsecondsSinceEpoch.toString().padLeft(12, '0').substring(0, 9)}';
    return withEan13CheckDigit(fallbackBase);
  }

  static String withEan13CheckDigit(String first12Digits) {
    final digits = first12Digits.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 12) {
      throw ArgumentError(
        'EAN-13 barcode base must contain exactly 12 digits.',
      );
    }

    var sum = 0;
    for (var i = 0; i < digits.length; i++) {
      final digit = int.parse(digits[i]);
      sum += i.isEven ? digit : digit * 3;
    }
    final checkDigit = (10 - (sum % 10)) % 10;
    return '$digits$checkDigit';
  }

  static bool isInternalInStoreBarcode(String? barcode) {
    final value = barcode?.trim() ?? '';
    return RegExp(r'^2\d{12}$').hasMatch(value);
  }

  static bool hasDuplicateBarcode(
    Iterable<ItemModel> items,
    String barcode, {
    String? excludingItemId,
  }) {
    final normalized = barcode.trim();
    if (normalized.isEmpty) return false;
    return items.any(
      (item) =>
          item.id != excludingItemId && item.barcode?.trim() == normalized,
    );
  }
}
