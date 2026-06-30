import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/interface_colors.dart';
import '../constants/layout_defaults.dart';
import 'layout.dart';

class OpenBoxSpatialLayout {
  const OpenBoxSpatialLayout({
    required this.globalLayout,
    required this.desktop,
  });

  static const defaults = OpenBoxSpatialLayout(
    globalLayout: OpenBoxGlobalLayout.defaults,
    desktop: OpenBoxInterfaceLayout.desktop,
  );

  final OpenBoxGlobalLayout globalLayout;
  final OpenBoxInterfaceLayout desktop;
}

class OpenBoxGlobalLayout {
  const OpenBoxGlobalLayout({
    required this.sceneLayout,
    required this.wallGlues,
  });

  static const defaults = OpenBoxGlobalLayout(
    sceneLayout: DefaultLayout.openBoxScene,
    wallGlues: [
      OpenBoxWallGlue(
        wall: OpenBoxWall.top,
        outerStart: LayoutPoint(
          column: 0,
          row: 0,
          depth: DefaultDimensions.bottomWallDepthTracks,
        ),
        outerEnd: LayoutPoint(
          column: 40,
          row: 0,
          depth: DefaultDimensions.bottomWallDepthTracks,
        ),
        innerStart: LayoutPoint(column: 3, row: 1),
        innerEnd: LayoutPoint(column: 37, row: 1),
      ),
      OpenBoxWallGlue(
        wall: OpenBoxWall.right,
        outerStart: LayoutPoint(
          column: 40,
          row: 0,
          depth: DefaultDimensions.bottomWallDepthTracks,
        ),
        outerEnd: LayoutPoint(
          column: 40,
          row: 10,
          depth: DefaultDimensions.bottomWallDepthTracks,
        ),
        innerStart: LayoutPoint(column: 37, row: 1),
        innerEnd: LayoutPoint(column: 37, row: 8),
      ),
      OpenBoxWallGlue(
        wall: OpenBoxWall.bottom,
        outerStart: LayoutPoint(
          column: 0,
          row: 10,
          depth: DefaultDimensions.bottomWallDepthTracks,
        ),
        outerEnd: LayoutPoint(
          column: 40,
          row: 10,
          depth: DefaultDimensions.bottomWallDepthTracks,
        ),
        innerStart: LayoutPoint(column: 3, row: 8),
        innerEnd: LayoutPoint(column: 37, row: 8),
      ),
      OpenBoxWallGlue(
        wall: OpenBoxWall.left,
        outerStart: LayoutPoint(
          column: 0,
          row: 0,
          depth: DefaultDimensions.bottomWallDepthTracks,
        ),
        outerEnd: LayoutPoint(
          column: 0,
          row: 10,
          depth: DefaultDimensions.bottomWallDepthTracks,
        ),
        innerStart: LayoutPoint(column: 3, row: 1),
        innerEnd: LayoutPoint(column: 3, row: 8),
      ),
    ],
  );

  final SceneLayout sceneLayout;
  final List<OpenBoxWallGlue> wallGlues;

  LayoutDimensions get dimensions => sceneLayout.dimensions;

  LayoutArea get boxBottomArea {
    final innerPoints = [
      for (final glue in wallGlues) ...[glue.innerStart, glue.innerEnd],
    ];
    final left = innerPoints.map((point) => point.column).reduce(math.min);
    final top = innerPoints.map((point) => point.row).reduce(math.min);
    final right = innerPoints.map((point) => point.column).reduce(math.max);
    final bottom = innerPoints.map((point) => point.row).reduce(math.max);
    return LayoutArea(
      column: left.floor(),
      row: top.floor(),
      columnSpan: (right - left).ceil(),
      rowSpan: (bottom - top).ceil(),
    );
  }
}

class OpenBoxInterfaceLayout {
  const OpenBoxInterfaceLayout({
    this.topWallRows = 2,
    this.rightWallRows = 2,
    this.bottomWallRows = 3,
    this.leftWallRows = 2,
    this.bottomWallLayout = DefaultLayout.bottomWallLayout,
    this.bottomWallTimeAxisTrackInset = 1,
    this.bottomWallNodePlacements = OpenBoxNodePlacements.bottomWallDefaults,
    this.guidelineColor = InterfaceColors.guidelineRed,
    this.topWallColor = InterfaceColors.topWall,
    this.rightWallColor = InterfaceColors.rightWall,
    this.bottomWallColor = InterfaceColors.bottomWall,
    this.leftWallColor = InterfaceColors.leftWall,
  });

  static const desktop = OpenBoxInterfaceLayout(
    bottomWallLayout: DefaultLayout.bottomWallLayout,
  );

  final int topWallRows;
  final int rightWallRows;
  final int bottomWallRows;
  final int leftWallRows;
  final GridLayout bottomWallLayout;
  LayoutDimensions get bottomWallDimensions => bottomWallLayout.dimensions;
  final int bottomWallTimeAxisTrackInset;
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
      area: LayoutArea(column: 17, row: 0, columnSpan: 2),
      shape: BottomWallNodeShape.cellSpan,
    ),
  ];
}

class BottomWallNodePlacement {
  const BottomWallNodePlacement({
    required this.vaultPath,
    required this.area,
    this.shape = BottomWallNodeShape.circle,
  });

  final String vaultPath;
  final LayoutArea area;
  final BottomWallNodeShape shape;
}

enum BottomWallNodeShape { circle, cellSpan }

class OpenBoxWallGlue {
  const OpenBoxWallGlue({
    required this.wall,
    required this.outerStart,
    required this.outerEnd,
    required this.innerStart,
    required this.innerEnd,
  });

  final OpenBoxWall wall;
  final LayoutPoint outerStart;
  final LayoutPoint outerEnd;
  final LayoutPoint innerStart;
  final LayoutPoint innerEnd;
}

enum OpenBoxWall { top, right, bottom, left }
