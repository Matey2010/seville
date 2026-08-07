import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'constants/interface_colors.dart';
import 'constants/typography.dart';
import 'screens/landscape_xl_layout_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const LandscapeXlLayoutScreen(),
    );
  }
}
