import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../models/layout/layout.dart';

/// One renderer-resolved Layout surface shared by paint and interaction.
typedef LayoutSurface = ({
  Size logicalSize,
  Path clipPath,
  Offset Function(double u, double v) project,
});

typedef LayoutComponentBuilder =
    PositionComponent Function(Layout layout, LayoutComponentRegistry registry);

class LayoutComponentRegistry {
  const LayoutComponentRegistry({this.builders = const {}});

  final Map<Type, LayoutComponentBuilder> builders;

  PositionComponent? build(Layout layout) {
    final builder = builders[layout.runtimeType];
    return builder?.call(layout, this);
  }

  LayoutComponentRegistry extended(
    Map<Type, LayoutComponentBuilder> additions,
  ) {
    return LayoutComponentRegistry(builders: {...builders, ...additions});
  }
}
