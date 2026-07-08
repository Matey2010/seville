import 'package:flutter/material.dart';

import '../models/compass_layout.dart';
import '../utils/compass_figure_painter.dart';
import '../utils/compass_slots.dart';
import '../utils/guide_grid_painter.dart';
import '../utils/layout_guidelines.dart';
import '../widgets/layout_renderer_registry.dart';

class CompassScreen extends StatelessWidget {
  const CompassScreen({required this.layout, super.key});

  final CompassLayout layout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: CompassView(layout: layout));
  }
}

class CompassView extends StatelessWidget {
  const CompassView({required this.layout, this.rendererRegistry, super.key});

  final CompassLayout layout;
  final LayoutRendererRegistry? rendererRegistry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final frame = layout.frame.resolve(constraints.biggest);
        final mainBounds = _mainFigureBounds(layout, frame);
        final subLayout = layout.mainSlot.subLayout;
        Widget? mainContent;
        if (subLayout != null && rendererRegistry != null) {
          mainContent = rendererRegistry!.build(context, subLayout);
          if (layout.mainSlot.figure != CompassMainFigure.layout) {
            mainContent = ClipPath(
              clipper: CompassFigureClipper(layout.mainSlot.figure),
              child: mainContent,
            );
          }
        }
        return SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _CompassPainter(layout)),
              if (mainContent != null)
                Positioned.fromRect(rect: mainBounds, child: mainContent),
              CustomPaint(painter: _CompassFigureBorderPainter(layout)),
            ],
          ),
        );
      },
    );
  }
}

class _CompassFigureBorderPainter extends CustomPainter {
  const _CompassFigureBorderPainter(this.layout);

  final CompassLayout layout;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = layout.frame.resolve(size);
    drawCompassMainFigureBorder(
      canvas,
      _mainFigureBounds(layout, frame),
      layout.mainSlot,
    );
  }

  @override
  bool shouldRepaint(_CompassFigureBorderPainter oldDelegate) {
    return oldDelegate.layout != layout;
  }
}

class _CompassPainter extends CustomPainter {
  const _CompassPainter(this.layout);

  final CompassLayout layout;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = layout.frame.resolve(size);
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
    drawCompassSlots(canvas, size, layout, mainBounds: mainBounds);
    drawCompassMainFigure(canvas, mainBounds, layout.mainSlot);
  }

  @override
  bool shouldRepaint(_CompassPainter oldDelegate) {
    return oldDelegate.layout != layout;
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
