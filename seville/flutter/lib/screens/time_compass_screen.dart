import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../components/meeple_layout_component.dart';
import '../constants/time_compass_defaults.dart';
import '../models/compass_layout.dart';
import '../utils/compass_slots.dart';
import '../utils/guide_grid_painter.dart';
import '../utils/layout_guidelines.dart';
import '../utils/time_compass_painter.dart';

class TimeCompassScreen extends StatelessWidget {
  const TimeCompassScreen({this.layout, super.key});

  final TimeCompassLayout? layout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TimeCompassView(layout: layout ?? defaultTimeCompassLayout),
    );
  }
}

class TimeCompassView extends StatelessWidget {
  const TimeCompassView({required this.layout, super.key});

  final TimeCompassLayout layout;

  @override
  Widget build(BuildContext context) =>
      GameWidget<TimeCompassGame>(game: TimeCompassGame(layout));
}

class TimeCompassGame extends FlameGame {
  TimeCompassGame(this.layout);

  final TimeCompassLayout layout;

  @override
  Future<void> onLoad() async {
    add(_TimeCompassComponent(layout));
    add(_TimeCompassMeepleComponent(layout)..priority = 10);
  }

  @override
  Color backgroundColor() => const Color(0x00000000);
}

class _TimeCompassComponent extends PositionComponent {
  _TimeCompassComponent(this.layout);

  final TimeCompassLayout layout;

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    size = gameSize;
  }

  @override
  void render(Canvas canvas) {
    final viewport = Size(size.x, size.y);
    final frame = layout.frame.resolve(viewport);
    drawGuideGrids(
      canvas,
      layout,
      GuideGridProjection(
        topLeft: frame.topLeft,
        topRight: frame.topRight,
        bottomLeft: frame.bottomLeft,
        bottomRight: frame.bottomRight,
      ),
    );
    canvas
      ..save()
      ..clipRect(frame)
      ..translate(frame.left, frame.top);
    drawLayoutGuidelines(canvas, frame.size, layout);
    canvas.restore();
    drawTimeCompass(canvas, viewport, layout);
    drawCompassSlots(
      canvas,
      viewport,
      layout,
      mainBounds: _meepleLayoutBounds(viewport, layout),
    );
  }
}

class _TimeCompassMeepleComponent extends PositionComponent {
  _TimeCompassMeepleComponent(this.layout);

  final TimeCompassLayout layout;
  late final MeepleLayoutComponent meeple = MeepleLayoutComponent(
    layout: layout.meepleLayout,
  );

  @override
  Future<void> onLoad() async {
    add(meeple);
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    size = gameSize;
    final bounds = _meepleLayoutBounds(Size(size.x, size.y), layout);
    meeple
      ..position = Vector2(bounds.left, bounds.top)
      ..size = Vector2(bounds.width, bounds.height);
  }
}

Rect _meepleLayoutBounds(Size size, TimeCompassLayout layout) {
  final frame = layout.frame.resolve(size);
  final mainSlot = layout.mainSlot;
  final availableHeight = frame.height * mainSlot.availableSizeFraction.height;
  final config = layout.meepleLayout.config;
  final height = config.layoutHeightFor(availableHeight);
  final width = config.layoutWidthFor(availableHeight);
  return mainSlot.place(Size(width, height), frame);
}
