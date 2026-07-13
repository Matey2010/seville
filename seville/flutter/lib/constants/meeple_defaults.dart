import 'dart:ui';

import '../models/meeple_layout.dart';
import 'interface_colors.dart';
import 'layout_axes.dart';

const defaultMeepleAsset = 'assets/time_compass/placeholder_character.svg';
const defaultMeepleAspectRatio = 0.5;
const defaultMeepleHeightFraction = 2 / 3;
const defaultMeepleBodyColor = graphLabelColor;
const defaultMeepleLayoutBackgroundColor = Color(0x228A6D0A);
const defaultMeeplePadding = MeepleLayoutPadding(
  top: 12,
  right: 12,
  bottom: 0,
  left: 12,
);

final defaultMeepleLayout = MeepleLayout.fromAxes(
  axes: CommonRatio.twoDimension.grid1x1,
  config: MeepleLayoutConfig(
    assetPath: defaultMeepleAsset,
    bodyColor: defaultMeepleBodyColor,
    heightFraction: defaultMeepleHeightFraction,
    aspectRatio: defaultMeepleAspectRatio,
    padding: defaultMeeplePadding,
    backgroundColor: defaultMeepleLayoutBackgroundColor,
  ),
);
