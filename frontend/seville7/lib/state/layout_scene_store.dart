import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/layout/layout.dart';

final layoutSceneProvider = NotifierProvider<LayoutSceneNotifier, LayoutScene>(
  LayoutSceneNotifier.new,
);

class LayoutSceneNotifier extends Notifier<LayoutScene> {
  @override
  LayoutScene build() => LayoutScene.mainMenu;

  void showGame() => state = LayoutScene.gameplay;

  void showMenu() => state = LayoutScene.mainMenu;
}
