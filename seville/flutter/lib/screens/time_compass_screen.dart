import 'package:flutter/material.dart';

import '../constants/time_compass_defaults.dart';
import '../models/compass_layout.dart';
import '../utils/compass_slots.dart';
import '../utils/guide_grid_painter.dart';
import '../utils/layout_guidelines.dart';
import '../utils/time_compass_painter.dart';
import '../widgets/meeple_layout_view.dart';

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
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final mainBounds = _meepleLayoutBounds(size, layout);
        return SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _TimeCompassPainter(layout)),
              Positioned.fromRect(
                rect: mainBounds,
                child: MeepleLayoutView(
                  layout: layout.meepleLayout,
                  fillAvailableBounds: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimeCompassPainter extends CustomPainter {
  const _TimeCompassPainter(this.layout);

  final TimeCompassLayout layout;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = layout.frame.resolve(size);
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
    drawTimeCompass(canvas, size, layout);
    drawCompassSlots(
      canvas,
      size,
      layout,
      mainBounds: _meepleLayoutBounds(size, layout),
    );
  }

  @override
  bool shouldRepaint(_TimeCompassPainter oldDelegate) {
    return oldDelegate.layout != layout;
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
