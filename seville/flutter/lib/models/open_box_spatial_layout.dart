import 'layout.dart';
import 'timeline_grid.dart';

class OpenBoxSpatialLayout extends SceneLayout {
  const OpenBoxSpatialLayout.fromAxes({
    required super.axes,
    super.attributes = const [LayoutAttribute.rectangular],
    super.layouts,
    super.derivatives,
    super.derivativeSnapshot,
    super.observables,
    super.modes,
    super.inputSources,
    super.columnFractions,
    super.rowFractions,
    super.depthFractions,
    required super.subLayouts,
    super.elements,
  }) : super.fromAxes();

  static const wallsLayoutId = 'walls';
  static const topWallLayoutId = 'top-wall';
  static const leftWallLayoutId = 'left-wall';
  static const rightWallLayoutId = 'right-wall';
  static const bottomWallLayoutId = 'bottom-wall';
  static const bottomWallTimelineLayoutId = 'timeline-track';
  static const sceneLayoutId = 'scene';

  SceneLayout get wallsLayout =>
      subLayouts[wallsLayoutId]!.layout as SceneLayout;

  GridLayout get topWallLayout => _wallGridLayout(topWallLayoutId);

  GridLayout get leftWallLayout => _wallGridLayout(leftWallLayoutId);

  GridLayout get rightWallLayout => _wallGridLayout(rightWallLayoutId);

  GridLayout get bottomWallLayout => _wallGridLayout(bottomWallLayoutId);

  TimelineGrid get bottomWallTimelineLayout =>
      bottomWallLayout.subLayouts[bottomWallTimelineLayoutId]!.layout
          as TimelineGrid;

  LayoutArea get bottomWallTimelineArea =>
      bottomWallLayout.subLayouts[bottomWallTimelineLayoutId]!.area;

  GridLayout get sceneSurfaceLayout =>
      subLayouts[sceneLayoutId]!.layout as GridLayout;

  LayoutDimensions get bottomWallDimensions => bottomWallLayout.dimensions;

  LayoutArea get boxBottomArea => subLayouts[sceneLayoutId]!.area;

  ({
    LayoutPoint outerStart,
    LayoutPoint outerEnd,
    LayoutPoint innerStart,
    LayoutPoint innerEnd,
  })
  wallCoordinates(OpenBoxWall wall) {
    final scene = boxBottomArea;
    final wallArea = wallsLayout.subLayouts[_wallLayoutId(wall)]!.area;
    final sceneLeft = scene.column;
    final sceneRight = scene.column + scene.columnSpan;
    final sceneTop = scene.row;
    final sceneBottom = scene.row + scene.rowSpan;
    final innerDepth = wallArea.depth;
    final outerDepth = wallArea.depth + wallArea.depthSpan;

    final coordinates = switch (wall) {
      OpenBoxWall.top => (
        outerStart: LayoutPoint(
          column: wallArea.column,
          row: wallArea.row,
          depth: outerDepth,
        ),
        outerEnd: LayoutPoint(
          column: wallArea.column + wallArea.columnSpan,
          row: wallArea.row,
          depth: outerDepth,
        ),
        innerStart: LayoutPoint(
          column: sceneLeft,
          row: sceneTop,
          depth: innerDepth,
        ),
        innerEnd: LayoutPoint(
          column: sceneRight,
          row: sceneTop,
          depth: innerDepth,
        ),
      ),
      OpenBoxWall.right => (
        outerStart: LayoutPoint(
          column: wallArea.column + wallArea.columnSpan,
          row: wallArea.row,
          depth: outerDepth,
        ),
        outerEnd: LayoutPoint(
          column: wallArea.column + wallArea.columnSpan,
          row: wallArea.row + wallArea.rowSpan,
          depth: outerDepth,
        ),
        innerStart: LayoutPoint(
          column: sceneRight,
          row: sceneTop,
          depth: innerDepth,
        ),
        innerEnd: LayoutPoint(
          column: sceneRight,
          row: sceneBottom,
          depth: innerDepth,
        ),
      ),
      OpenBoxWall.bottom => (
        outerStart: LayoutPoint(
          column: wallArea.column,
          row: wallArea.row + wallArea.rowSpan,
          depth: outerDepth,
        ),
        outerEnd: LayoutPoint(
          column: wallArea.column + wallArea.columnSpan,
          row: wallArea.row + wallArea.rowSpan,
          depth: outerDepth,
        ),
        innerStart: LayoutPoint(
          column: sceneLeft,
          row: sceneBottom,
          depth: innerDepth,
        ),
        innerEnd: LayoutPoint(
          column: sceneRight,
          row: sceneBottom,
          depth: innerDepth,
        ),
      ),
      OpenBoxWall.left => (
        outerStart: LayoutPoint(
          column: wallArea.column,
          row: wallArea.row,
          depth: outerDepth,
        ),
        outerEnd: LayoutPoint(
          column: wallArea.column,
          row: wallArea.row + wallArea.rowSpan,
          depth: outerDepth,
        ),
        innerStart: LayoutPoint(
          column: sceneLeft,
          row: sceneTop,
          depth: innerDepth,
        ),
        innerEnd: LayoutPoint(
          column: sceneLeft,
          row: sceneBottom,
          depth: innerDepth,
        ),
      ),
    };

    return (
      outerStart: _spanToDepth(coordinates.innerStart, coordinates.outerStart),
      outerEnd: _spanToDepth(coordinates.innerEnd, coordinates.outerEnd),
      innerStart: coordinates.innerStart,
      innerEnd: coordinates.innerEnd,
    );
  }

  GridLayout wallLayout(OpenBoxWall wall) {
    return switch (wall) {
      OpenBoxWall.top => topWallLayout,
      OpenBoxWall.right => rightWallLayout,
      OpenBoxWall.bottom => bottomWallLayout,
      OpenBoxWall.left => leftWallLayout,
    };
  }

  String _wallLayoutId(OpenBoxWall wall) {
    return switch (wall) {
      OpenBoxWall.top => topWallLayoutId,
      OpenBoxWall.right => rightWallLayoutId,
      OpenBoxWall.bottom => bottomWallLayoutId,
      OpenBoxWall.left => leftWallLayoutId,
    };
  }

  GridLayout _wallGridLayout(String id) =>
      wallsLayout.subLayouts[id]!.layout as GridLayout;

  LayoutPoint _spanToDepth(LayoutPoint inner, LayoutPoint outer) {
    final depthPosition = dimensions.normalizedAxisPosition(2, outer.depth);
    return LayoutPoint(
      column: inner.column + (outer.column - inner.column) * depthPosition,
      row: inner.row + (outer.row - inner.row) * depthPosition,
      depth: outer.depth,
    );
  }
}

enum OpenBoxWall { top, right, bottom, left }
