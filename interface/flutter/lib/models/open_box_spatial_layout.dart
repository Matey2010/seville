import 'package:flutter/material.dart';

import '../constants/interface_colors.dart';
import 'layout_grid.dart';

class OpenBoxSpatialLayout {
  const OpenBoxSpatialLayout({required this.desktop});

  static const defaults = OpenBoxSpatialLayout(
    desktop: OpenBoxInterfaceLayout.desktop,
  );

  final OpenBoxInterfaceLayout desktop;
}

class OpenBoxInterfaceLayout {
  const OpenBoxInterfaceLayout({
    this.horizontalPadding = 64.0,
    this.topPadding = 40.0,
    this.bottomPadding = 60.0,
    this.sceneBottomRatio = 0.86,
    this.topWallRows = 2,
    this.rightWallRows = 2,
    this.bottomWallRows = 3,
    this.leftWallRows = 2,
    this.bottomWallGrid = DefaultGrid.g36x6,
    this.bottomWallTimeAxisY = 1.0,
    this.bottomWallNodePlacements = OpenBoxNodePlacements.bottomWallDefaults,
    this.guidelineColor = InterfaceColors.guidelineRed,
    this.topWallColor = InterfaceColors.topWall,
    this.rightWallColor = InterfaceColors.rightWall,
    this.bottomWallColor = InterfaceColors.bottomWall,
    this.leftWallColor = InterfaceColors.leftWall,
  });

  static const desktop = OpenBoxInterfaceLayout(
    bottomWallGrid: DefaultGrid.g36x6,
  );

  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;
  final double sceneBottomRatio;
  final int topWallRows;
  final int rightWallRows;
  final int bottomWallRows;
  final int leftWallRows;
  final LayoutGrid bottomWallGrid;
  final double bottomWallTimeAxisY;
  final List<BottomWallNodePlacement> bottomWallNodePlacements;
  final Color guidelineColor;
  final Color topWallColor;
  final Color rightWallColor;
  final Color bottomWallColor;
  final Color leftWallColor;
}

abstract final class OpenBoxNodePlacements {
  static const bottomWallDefaults = [
    BottomWallNodePlacement(
      vaultPath: 'time/concept/now',
      area: LayoutGridArea(column: 17, row: 0, columnSpan: 2),
    ),
  ];
}

class BottomWallNodePlacement {
  const BottomWallNodePlacement({required this.vaultPath, required this.area});

  final String vaultPath;
  final LayoutGridArea area;
}
