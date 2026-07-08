import '../models/layout.dart';
import '../models/open_box_spatial_layout.dart';
import 'layout_axes.dart';
import 'layout_guides.dart';
import 'timeline/defaults.dart';

final defaultOpenBoxLayout = OpenBoxSpatialLayout.fromAxes(
  axes: [40, 10, 6],
  layouts: const {'scene-grid': sceneGuideGrid},
  subLayouts: {
    OpenBoxSpatialLayout.wallsLayoutId: (
      layout: defaultWallsLayout,
      area: LayoutArea(
        column: 0,
        row: 6,
        columnSpan: 40,
        rowSpan: 10,
        depthSpan: 6,
      ),
    ),
    OpenBoxSpatialLayout.sceneLayoutId: (
      layout: GridLayout.fromAxes(axes: [34, 7]),
      area: LayoutArea(column: 3, row: 1, columnSpan: 34, rowSpan: 7),
    ),
  },
);

final defaultWallsLayout = SceneLayout.fromAxes(
  axes: [40, 10, 6],
  subLayouts: {
    OpenBoxSpatialLayout.topWallLayoutId: (
      layout: GridLayout.fromAxes(
        axes: [40, 4],
        layouts: {'wall-rows': wallRowGuideGrid},
      ),
      area: LayoutArea(
        column: 0,
        row: 0,
        columnSpan: 40,
        rowSpan: 1,
        depthSpan: 6,
      ),
    ),
    OpenBoxSpatialLayout.leftWallLayoutId: (
      layout: GridLayout.fromAxes(
        axes: [7, 2],
        layouts: {'wall-rows': wallRowGuideGrid},
      ),
      area: LayoutArea(
        column: 0,
        row: 0,
        columnSpan: 3,
        rowSpan: 10,
        depthSpan: 6,
      ),
    ),
    OpenBoxSpatialLayout.rightWallLayoutId: (
      layout: GridLayout.fromAxes(
        axes: [7, 2],
        layouts: {'wall-rows': wallRowGuideGrid},
      ),
      area: LayoutArea(
        column: 37,
        row: 0,
        columnSpan: 3,
        rowSpan: 10,
        depthSpan: 6,
      ),
    ),
    OpenBoxSpatialLayout.bottomWallLayoutId: (
      layout: GridLayout.fromAxes(
        axes: CommonRatio.twoDimension.grid36x6,
        subLayouts: {
          OpenBoxSpatialLayout.bottomWallTimelineLayoutId: (
            layout: defaultTimelineLayout,
            area: LayoutArea(column: 0, row: 0, columnSpan: 36, rowSpan: 6),
          ),
        },
      ),
      area: LayoutArea(
        column: 0,
        row: 8,
        columnSpan: 40,
        rowSpan: 2,
        depthSpan: 6,
      ),
    ),
  },
);
