import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'constants/interface_colors.dart';
import 'constants/typography.dart';
import 'presets/compact_landscape/compact_landscape_layout_config.dart';
import 'presets/lg_ergo/lg_ergo_layout_config.dart';
import 'screens/landscape_xl_layout_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (defaultTargetPlatform == TargetPlatform.android) {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
  await SevilleTypography.ensureLoaded();
  runApp(const ProviderScope(child: SevilleApp()));
}

class SevilleApp extends StatelessWidget {
  const SevilleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seville 7',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        fontFamily: SevilleTypography.fontFamily,
        colorSchemeSeed: const Color(0xFF6750A4),
        scaffoldBackgroundColor: interfaceBackgroundColor,
      ),
      home: LayoutBuilder(
        builder: (context, constraints) {
          final compactAndroidLandscape =
              defaultTargetPlatform == TargetPlatform.android &&
              constraints.maxWidth > constraints.maxHeight &&
              constraints.maxHeight <= 600;
          return LandscapeXlLayoutScreen(
            layout: compactAndroidLandscape
                ? compactLandscapeLayoutConfig
                : lgErgoLayoutConfig,
          );
        },
      ),
    );
  }
}
