// printing_asset_loader.dart

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../settings/data/models/printing_settings_model.dart';

class PrintingAssetLoader {
  const PrintingAssetLoader();

  Future<pw.ImageProvider?> loadLogo(PrintingSettingsModel settings) async {
    if (!settings.showLogo) return null;
    final path = settings.logoPath?.trim();
    if (path == null || path.isEmpty) return null;

    try {
      Uint8List bytes;
      if (path.startsWith('assets/')) {
        final data = await rootBundle.load(path);
        bytes = data.buffer.asUint8List();
      } else {
        final file = File(path);
        if (!await file.exists()) return null;
        bytes = await file.readAsBytes();
      }
      if (bytes.isEmpty) return null;
      return pw.MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  Future<pw.Font?> loadArabicFont(PrintingSettingsModel settings) async {
    if (!settings.useArabicFonts) return null;

    const candidates = <String>[
      'assets/fonts/Cairo-Regular.ttf',
      'assets/fonts/Cairo-Bold.ttf',
      'assets/fonts/NotoNaskhArabic-Regular.ttf',
      'assets/fonts/NotoSansArabic-Regular.ttf',
    ];

    for (final path in candidates) {
      try {
        final data = await rootBundle.load(path);
        return pw.Font.ttf(data);
      } catch (_) {
        // Try next candidate.
      }
    }

    return null;
  }
}
