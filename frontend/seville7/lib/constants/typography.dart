import 'package:flutter/services.dart';

import '../generated/fonts/sevifont.dart';

abstract final class SevilleTypography {
  static const fontFamily = 'Alegreya Sans SC';
  static const nodeFontFamily = Sevifont.fontFamily;

  static const _fontAssets = [
    'assets/fonts/alegreya_sans_sc/AlegreyaSansSC-Regular.ttf',
    'assets/fonts/alegreya_sans_sc/AlegreyaSansSC-Medium.ttf',
    'assets/fonts/alegreya_sans_sc/AlegreyaSansSC-Bold.ttf',
    'assets/fonts/alegreya_sans_sc/AlegreyaSansSC-Black.ttf',
  ];
  static const _nodeFontAsset = 'assets/fonts/sevifont/Sevifont.ttf';

  static Future<void>? _loadFuture;

  /// Registers the bundled family before Flame creates its first TextPainter.
  static Future<void> ensureLoaded() => _loadFuture ??= _load();

  static Future<void> _load() async {
    final loader = FontLoader(fontFamily);
    for (final asset in _fontAssets) {
      loader.addFont(rootBundle.load(asset));
    }
    final nodeLoader = FontLoader(nodeFontFamily)
      ..addFont(rootBundle.load(_nodeFontAsset));
    await Future.wait([loader.load(), nodeLoader.load()]);
  }
}
