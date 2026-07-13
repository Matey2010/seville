import '../models/layout.dart';
import 'interface_colors.dart';

const sceneGuideStyle = GuideStyle(
  color: sceneLayoutDimensionsColor,
  strokeWidth: 0.8,
);

const sceneGuideGrid = GuideGrid(style: sceneGuideStyle);

const sceneIntersectionGuideGrid = GuideGrid(
  style: sceneGuideStyle,
  renderMode: GuideGridRenderMode.intersections,
  intersectionSize: 2,
);

const wallRowGuideGrid = GuideGrid(
  style: GuideStyle(
    color: guidelineRedColor,
    strokeWidth: 1.2,
    pattern: GuideLinePattern.dashed,
  ),
  drawColumns: false,
);

const timelineGuideGrid = GuideGrid(
  style: GuideStyle(
    color: guidelineRedColor,
    strokeWidth: 1.2,
    pattern: GuideLinePattern.dashed,
  ),
);

const timeCompassRadialGuideGrid = GuideGrid(
  geometry: GuideGridGeometry.radial,
  style: GuideStyle(color: timeCompassGridColor, strokeWidth: 1.4),
);

const timeCompassVirtualGuideGrid = GuideGrid(
  geometry: GuideGridGeometry.radialVirtual,
  style: GuideStyle(
    color: timeCompassVirtualGridColor,
    strokeWidth: 1.2,
    pattern: GuideLinePattern.dashed,
    dashLength: 8,
    dashInterval: 6,
  ),
  drawRows: false,
);
