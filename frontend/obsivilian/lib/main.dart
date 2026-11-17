import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forge2d/forge2d.dart';

import 'screens/knowledge_workspace.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeForge2D();
  if (defaultTargetPlatform == TargetPlatform.android) {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
  runApp(const ProviderScope(child: ObsivilianApp()));
}

class ObsivilianApp extends StatelessWidget {
  const ObsivilianApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Obsivilian',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF73B5D8),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF101820),
    ),
    home: const KnowledgeWorkspace(),
  );
}
