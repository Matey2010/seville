import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../components/layout_component_registry.dart';
import '../models/compass_layout.dart';
import '../utils/compass_figure_painter.dart';
import '../utils/compass_slots.dart';
import '../utils/guide_grid_painter.dart';
import '../utils/layout_guidelines.dart';

class CompassScreen extends StatelessWidget {
  const CompassScreen({required this.layout, super.key});

  final CompassLayout layout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: CompassView(layout: layout));
  }
}

class CompassView extends StatefulWidget {
  const CompassView({required this.layout, this.componentRegistry, super.key});

  final CompassLayout layout;
  final LayoutComponentRegistry? componentRegistry;

  @override
  State<CompassView> createState() => _CompassViewState();
}

class _CompassViewState extends State<CompassView> {
  late CompassGame _game = CompassGame(widget.layout, widget.componentRegistry);

  @override
  void didUpdateWidget(CompassView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layout != widget.layout ||
        oldWidget.componentRegistry != widget.componentRegistry) {
      _game = CompassGame(widget.layout, widget.componentRegistry);
    }
  }

  @override
  Widget build(BuildContext context) =>
      GameWidget<CompassGame>(key: ValueKey(_game), game: _game);
}

class CompassGame extends FlameGame {
  CompassGame(this.layout, this.componentRegistry);

  final CompassLayout layout;
  final LayoutComponentRegistry? componentRegistry;

  @override
  Future<void> onLoad() async {
    add(_CompassSurfaceComponent(layout));
    final subLayout = layout.mainSlot.subLayout;
    final content = subLayout == null
        ? null
        : componentRegistry?.build(subLayout);
    if (content != null) {
      content.priority = 10;
      add(content);
    }
    add(_CompassBorderComponent(layout)..priority = 20);
  }

  @override
  Color backgroundColor() => const Color(0x00000000);
}

class _CompassSurfaceComponent extends PositionComponent {
  _CompassSurfaceComponent(this.layout);

  final CompassLayout layout;

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    size = gameSize;
  }

  @override
  void render(Canvas canvas) {
    final viewport = Size(size.x, size.y);
    final frame = layout.frame.resolve(viewport);
    final mainBounds = _mainFigureBounds(layout, frame);
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
    drawCompassSlots(canvas, viewport, layout, mainBounds: mainBounds);
    drawCompassMainFigure(canvas, mainBounds, layout.mainSlot);
  }
}

class _CompassBorderComponent extends PositionComponent {
  _CompassBorderComponent(this.layout);

  final CompassLayout layout;

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    size = gameSize;
    final frame = layout.frame.resolve(Size(size.x, size.y));
    final bounds = _mainFigureBounds(layout, frame);
    final owner = parent;
    if (owner == null) return;
    for (final child in owner.children.whereType<PositionComponent>()) {
      if (child == this || child is _CompassSurfaceComponent) continue;
      child
        ..position = Vector2(bounds.left, bounds.top)
        ..size = Vector2(bounds.width, bounds.height);
    }
  }

  @override
  void render(Canvas canvas) {
    final frame = layout.frame.resolve(Size(size.x, size.y));
    drawCompassMainFigureBorder(
      canvas,
      _mainFigureBounds(layout, frame),
      layout.mainSlot,
    );
  }
}

Rect _mainFigureBounds(CompassLayout layout, Rect frame) {
  final figureConfig = layout.mainSlot.figureConfig;
  final availableSize = layout.mainSlot.availableSizeFraction;
  final size =
      figureConfig?.resolveSize(frame) ??
      Size(
        frame.width * availableSize.width,
        frame.height * availableSize.height,
      );
  return layout.mainSlot.place(size, frame);
}
