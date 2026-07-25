import 'package:flutter/services.dart';

abstract final class SevilleTypography {
  static const fontFamily = 'Alegreya Sans SC';

  static const _fontAssets = [
    'assets/fonts/alegreya_sans_sc/AlegreyaSansSC-Regular.ttf',
    'assets/fonts/alegreya_sans_sc/AlegreyaSansSC-Medium.ttf',
    'assets/fonts/alegreya_sans_sc/AlegreyaSansSC-Bold.ttf',
    'assets/fonts/alegreya_sans_sc/AlegreyaSansSC-Black.ttf',
  ];

  static Future<void>? _loadFuture;

  /// Registers the bundled family before Flame creates its first TextPainter.
  static Future<void> ensureLoaded() => _loadFuture ??= _load();

  static Future<void> _load() async {
    final loader = FontLoader(fontFamily);
    for (final asset in _fontAssets) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }
}
