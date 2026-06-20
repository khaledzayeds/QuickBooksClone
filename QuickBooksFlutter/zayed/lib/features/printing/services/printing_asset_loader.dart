// printing_asset_loader.dart

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/widgets.dart' as pw;

import '../../settings/data/models/printing_settings_model.dart';

class PrintingAssetLoader {
  const PrintingAssetLoader();

  Future<pw.ImageProvider?> loadLogo(
    PrintingSettingsModel settings, {
    bool thermalOptimized = false,
  }) async {
    if (!settings.showLogo) return null;
    final path = settings.logoPath?.trim();
    if (path == null || path.isEmpty) return null;

    try {
      final bytes = await _loadLogoBytes(path);
      if (bytes == null || bytes.isEmpty) return null;
      final printableBytes = thermalOptimized
          ? _thermalOptimizedLogo(bytes)
          : _flattenTransparentLogo(bytes);
      if (printableBytes.isEmpty) return null;
      return pw.MemoryImage(printableBytes);
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _loadLogoBytes(String path) async {
    if (path.startsWith('assets/')) {
      final data = await rootBundle.load(path);
      return data.buffer.asUint8List();
    }

    for (final file in _candidateFiles(path)) {
      try {
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      } catch (_) {
        // Try the next candidate.
      }
    }

    return null;
  }

  Iterable<File> _candidateFiles(String path) sync* {
    final raw = File(path);
    yield raw;

    if (!raw.isAbsolute) {
      yield File('${Directory.current.path}${Platform.pathSeparator}$path');
    }

    final exeDir = File(Platform.resolvedExecutable).parent.path;
    yield File('$exeDir${Platform.pathSeparator}$path');
    yield File(
      '$exeDir${Platform.pathSeparator}data${Platform.pathSeparator}flutter_assets${Platform.pathSeparator}$path',
    );
  }

  Uint8List _flattenTransparentLogo(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;

      final oriented = img.bakeOrientation(decoded);
      final canvas = img.Image(
        width: oriented.width,
        height: oriented.height,
        numChannels: 4,
      );
      img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
      img.compositeImage(canvas, oriented);
      return Uint8List.fromList(img.encodePng(canvas));
    } catch (_) {
      return bytes;
    }
  }

  Uint8List _thermalOptimizedLogo(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;

      var image = img.bakeOrientation(decoded);
      if (image.width > 320) {
        image = img.copyResize(image, width: 320);
      }

      final canvas = img.Image(
        width: image.width,
        height: image.height,
        numChannels: 4,
      );
      img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
      img.compositeImage(canvas, image);

      final grayscale = img.grayscale(canvas);
      img.adjustColor(grayscale, contrast: 1.35);
      return Uint8List.fromList(img.encodePng(grayscale));
    } catch (_) {
      return _flattenTransparentLogo(bytes);
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
