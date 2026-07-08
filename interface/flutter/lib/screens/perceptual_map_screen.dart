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
      body: SizedBox.expand(
        child: CustomPaint(painter: _PerceptualMapPainter(resolvedLayout)),
      ),
    );
  }
}

class _PerceptualMapPainter extends CustomPainter {
  const _PerceptualMapPainter(this.layout);

  final PerceptualMapLayout layout;

  @override
  void paint(Canvas canvas, Size size) {
    drawGuideGrids(
      canvas,
      layout,
      GuideGridProjection(
        topLeft: Offset.zero,
        topRight: Offset(size.width, 0),
        bottomLeft: Offset(0, size.height),
        bottomRight: Offset(size.width, size.height),
      ),
    );
    drawLayoutGuidelines(canvas, size, layout);
    drawPerceptualMapSlots(canvas, size, layout);
  }

  @override
  bool shouldRepaint(_PerceptualMapPainter oldDelegate) {
    return oldDelegate.layout != layout;
  }
}
