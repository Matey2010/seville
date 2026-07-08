import 'package:flutter/material.dart';

import 'constants/interface_colors.dart';
import 'screens/landscape_xl_layout_screen.dart';

void main() {
  runApp(const SevilleApp());
}

class SevilleApp extends StatelessWidget {
  const SevilleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seville',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6750A4),
        scaffoldBackgroundColor: interfaceBackgroundColor,
      ),
      home: const LandscapeXlLayoutScreen(),
    );
  }
}
