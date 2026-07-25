import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../constants/perceptual_map_defaults.dart';
import '../models/perceptual_map_layout.dart';
import '../utils/guide_grid_painter.dart';
import '../utils/layout_guidelines.dart';
import '../utils/perceptual_map_slots.dart';

class PerceptualMapScreen extends StatelessWidget {
  const PerceptualMapScreen({this.layout, super.key});

  final PerceptualMapLayout? layout;

  @override
  Widget build(BuildContext context) {
    final resolvedLayout = layout ?? defaultPerceptualMapLayout;
    return Scaffold(
      body: GameWidget<PerceptualMapGame>(
        game: PerceptualMapGame(resolvedLayout),
      ),
    );
  }
}

class PerceptualMapGame extends FlameGame {
  PerceptualMapGame(this.layout);

  final PerceptualMapLayout layout;

  @override
  Future<void> onLoad() async {
    add(_PerceptualMapComponent(layout));
  }

  @override
  Color backgroundColor() => const Color(0x00000000);
}

class _PerceptualMapComponent extends PositionComponent {
  _PerceptualMapComponent(this.layout);

  final PerceptualMapLayout layout;

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    size = gameSize;
  }

  @override
  void render(Canvas canvas) {
    final viewport = Size(size.x, size.y);
    drawGuideGrids(
      canvas,
      layout,
      GuideGridProjection(
        topLeft: Offset.zero,
        topRight: Offset(viewport.width, 0),
        bottomLeft: Offset(0, viewport.height),
        bottomRight: Offset(viewport.width, viewport.height),
      ),
    );
    drawLayoutGuidelines(canvas, viewport, layout);
    drawPerceptualMapSlots(canvas, viewport, layout);
  }
}
