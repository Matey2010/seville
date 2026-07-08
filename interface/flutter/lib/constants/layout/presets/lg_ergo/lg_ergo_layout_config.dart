import 'dart:ui';

import '../../../../models/layout.dart';
import '../../../../models/landscape_xl_layout.dart';
import '../../../interface_colors.dart';
import '../../../paths/default_vault_paths.dart';

const lgErgoLayoutConfig = LandscapeXlLayout(
  aliases: ['screen', 'root', 'reality', 'user-space', 'user-reality'],
  attributes: [LayoutAttribute.screen, LayoutAttribute.rectangular],
  layoutDefaults: lgErgoLayoutDefaults,
  derivativeSnapshot: 'screen-edge-centers',
  derivatives: {
    'screen-edge-centers': LayoutDerivativeSnapshot(
      values: {
        'AD-center': MidpointDerivative(from: 'A', to: 'D'),
        'BC-center': MidpointDerivative(from: 'B', to: 'C'),
      },
    ),
  },
  layouts: {
    'please-stand-by-background': LayoutBackgroundElement(
      assetPath: 'assets/please-stand-by.png',
      orderPosition: 0,
      fit: LayoutBackgroundFit.cover,
      opacity: lgErgoBackgroundOpacity,
    ),
    'horizontal-guide': Guideline(
      start: Offset(0, 0.5),
      end: Offset(1, 0.5),
      style: lgErgoScreenGuidelineStyle,
    ),
    'vertical-guide': Guideline(
      start: Offset(0.5, 0),
      end: Offset(0.5, 1),
      style: lgErgoScreenGuidelineStyle,
    ),
    'descending-diagonal-guide': Guideline(
      start: Offset(0, 0),
      end: Offset(1, 1),
      style: lgErgoDiagonalGuidelineStyle,
    ),
    // 'ascending-diagonal-guide': Guideline(
    //   start: Offset(0, 1),
    //   end: Offset(1, 0),
    //   style: lgErgoDiagonalGuidelineStyle,
    // ),
    'left-plane': LayoutPath(
      aliases: ['left-plane', 'space-plane', 'y-axis-plane'],
      points: [
        LayoutDerivativeReference(derivative: 'B'),
        LayoutDerivativeReference(layoutPath: ['safe-area'], derivative: 'B'),
        LayoutDerivativeReference(layoutPath: ['safe-area'], derivative: 'A'),
        LayoutDerivativeReference(derivative: 'A'),
      ],
      style: LayoutPathStyle(
        fillColor: Color(0x333F51B5),
        strokeStyle: lgErgoSpacePlaneLineStyle,
      ),
      padding: lgErgoLayoutDefaultPadding,
      grid: PerspectiveGridLayout(
        aliases: ['left-plane-grid', 'space-grid', 'y-axis-grid'],
        guideStyle: lgErgoSpacePlaneDashStyle,
        rowsConfig: {
          'space-01': GridAxisVariable(size: GridTrackSize.fr(1)),
          'space-02': GridAxisVariable(size: GridTrackSize.fr(1)),
          'space-03': GridAxisVariable(size: GridTrackSize.fr(1)),
          'space-04': GridAxisVariable(size: GridTrackSize.fr(1)),
          'space-05': GridAxisVariable(size: GridTrackSize.fr(1)),
          'space-06': GridAxisVariable(size: GridTrackSize.fr(1)),
          'space-07': GridAxisVariable(size: GridTrackSize.fr(1)),
          'space-08': GridAxisVariable(size: GridTrackSize.fr(1)),
          'space-09': GridAxisVariable(size: GridTrackSize.fr(1)),
          'space-10': GridAxisVariable(size: GridTrackSize.fr(1)),
          'space-11': GridAxisVariable(size: GridTrackSize.fr(1)),
          'space-12': GridAxisVariable(size: GridTrackSize.fr(1)),
        },
        columnsConfig: {
          'scene-height': GridAxisVariable(size: GridTrackSize.fr(1)),
        },
        areas: {
          'outer-rim': PerspectiveGridArea(
            row: 'space-01',
            column: 'scene-height',
            rowSpan: GridSpan.full,
            columnSpan: GridSpan.full,
            aliases: ['outer-rim', 'with-padding-rim'],
            borderStyle: lgErgoSpacePlaneRimStyle,
          ),
          'inner-rim': PerspectiveGridArea(
            row: 'space-01',
            column: 'scene-height',
            rowOffset: 0.5,
            columnOffset: 0.08,
            rowSpan: 11,
            columnSpan: 0.84,
            aliases: ['inner-rim', 'without-padding-rim'],
            borderStyle: lgErgoSpacePlaneRimStyle,
          ),
          'space-band': PerspectiveGridArea(
            row: 'space-01',
            column: 'scene-height',
            rowSpan: 12,
            aliases: ['space-band', 'x-axis-band'],
            fillColor: lgErgoSpacePlaneBandColor,
          ),
        },
      ),
    ),
    'top-plane': RadialTreeLayout(
      aliases: [
        'radial-tree',
        'node-tree',
        'cortex-tree',
        'top-node-tree',
        'top-plane',
        'control-plane',
        'north-plane',
      ],
      node: VaultNode(
        path: DefaultVaultPaths.cortex,
        color: lgErgoCortexNodeColor,
      ),
      style: lgErgoCortexNodeBorderStyle,
      label: 'cortex',
      labelColor: lgErgoCortexNodeLabelColor,
      labelSize: 10,
      layoutSize: LayoutSize.derivativeDistance(
        from: LayoutDerivativeReference(derivative: 'BC-center'),
        to: LayoutDerivativeReference(
          layoutPath: ['safe-area'],
          derivative: 'scene-BC-center',
        ),
      ),
      gridStyle: lgErgoRadialTreeGridStyle,
      rowsConfig: {
        'root-band': GridAxisVariable(size: GridTrackSize.fr(0.9)),
        'branch-band': GridAxisVariable(size: GridTrackSize.fr(1)),
        'leaf-band': GridAxisVariable(size: GridTrackSize.fr(1)),
      },
      columnsConfig: {
        'left-branch': GridAxisVariable(size: GridTrackSize.fr(1)),
        'center-branch': GridAxisVariable(size: GridTrackSize.fr(1)),
        'right-branch': GridAxisVariable(size: GridTrackSize.fr(1)),
      },
      areas: {
        'cortex-root-zone': RadialTreeArea(
          row: 'root-band',
          column: 'center-branch',
          aliases: ['root-zone', 'cortex-root-zone'],
          fillColor: Color(0x18FFD54F),
          borderStyle: lgErgoRadialTreeGridStyle,
          label: 'root',
        ),
        'left-branch-zone': RadialTreeArea(
          row: 'branch-band',
          column: 'left-branch',
          aliases: ['left-branch-zone'],
          borderStyle: lgErgoRadialTreeGridStyle,
          label: 'left',
        ),
        'center-branch-zone': RadialTreeArea(
          row: 'branch-band',
          column: 'center-branch',
          aliases: ['center-branch-zone'],
          borderStyle: lgErgoRadialTreeGridStyle,
          label: 'center',
          segments: {
            'center-leaf-a': RadialTreeArea(
              row: 'branch-band',
              column: 'center-branch',
              columnSpan: 0.5,
              aliases: ['center-leaf-a'],
              label: 'a',
            ),
            'center-leaf-b': RadialTreeArea(
              row: 'branch-band',
              column: 'center-branch',
              columnOffset: 0.5,
              columnSpan: 0.5,
              aliases: ['center-leaf-b'],
              label: 'b',
            ),
          },
        ),
        'right-branch-zone': RadialTreeArea(
          row: 'branch-band',
          column: 'right-branch',
          aliases: ['right-branch-zone'],
          borderStyle: lgErgoRadialTreeGridStyle,
          label: 'right',
        ),
        'leaf-row-zone': RadialTreeArea(
          row: 'leaf-band',
          column: 'left-branch',
          columnSpan: GridSpan.full,
          aliases: ['leaf-row-zone'],
          borderStyle: lgErgoRadialTreeGridStyle,
          label: 'sub-segments',
        ),
      },
      position: LayoutRelativePosition.top,
    ),
    'right-plane': LayoutPath(
      aliases: ['right-plane', 'action-plane', 'east-plane'],
      points: [
        LayoutDerivativeReference(derivative: 'C'),
        LayoutDerivativeReference(layoutPath: ['safe-area'], derivative: 'C'),
        LayoutDerivativeReference(layoutPath: ['safe-area'], derivative: 'D'),
        LayoutDerivativeReference(derivative: 'D'),
      ],
      pointDerivatives: {'A': 0, 'B': 1, 'C': 2, 'D': 3},
      style: LayoutPathStyle(
        fillColor: lgErgoActionPlaneBandColor,
        strokeStyle: lgErgoSpacePlaneLineStyle,
      ),
      layouts: {
        'base-node-info': TableLayout(
          aliases: ['base-node-info', 'node-info-table'],
          dataSource: TableLayoutDataSource.baseNodeInfo,
          guideStyle: lgErgoBaseNodeInfoTableStyle,
          cellHighlight: TableCellHighlightConfig(
            rows: true,
            columns: true,
            color: lgErgoBaseNodeInfoCellHighlightColor,
          ),
          rows: [
            MapEntry('id', GridAxisVariable(size: GridTrackSize.fr(1))),
            MapEntry('version', GridAxisVariable(size: GridTrackSize.fr(1))),
            MapEntry('aliases', GridAxisVariable(size: GridTrackSize.fr(1))),
            MapEntry('tags', GridAxisVariable(size: GridTrackSize.fr(1))),
            MapEntry(
              'classification',
              GridAxisVariable(size: GridTrackSize.fr(1)),
            ),
          ],
          columns: [
            MapEntry('key', GridAxisVariable(size: GridTrackSize.fr(1))),
            MapEntry('value', GridAxisVariable(size: GridTrackSize.fr(3))),
          ],
        ),
      },
    ),
    'bottom-plane': LayoutPath(
      aliases: ['bottom-plane', 'time-plane', 'x-axis-plane'],
      points: [
        LayoutDerivativeReference(derivative: 'A'),
        LayoutDerivativeReference(layoutPath: ['safe-area'], derivative: 'A'),
        LayoutDerivativeReference(layoutPath: ['safe-area'], derivative: 'D'),
        LayoutDerivativeReference(derivative: 'D'),
      ],
      style: LayoutPathStyle(
        fillColor: Color(0x55C59A1A),
        strokeStyle: lgErgoPlaneLineStyle,
      ),
      grid: PerspectiveGridLayout(
        aliases: ['bottom-plane-grid', 'time-grid'],
        guideStyle: lgErgoPlaneDashStyle,
        rowsConfig: {
          'hour': GridAxisVariable(size: GridTrackSize.fr(1)),
          'day': GridAxisVariable(size: GridTrackSize.fr(1)),
          'week': GridAxisVariable(size: GridTrackSize.fr(1)),
        },
        columnsConfig: {
          'past-padding': GridAxisVariable(
            size: GridTrackSize.pt(lgErgoLayoutDefaultPadding),
          ),
          'previous': GridAxisVariable(size: GridTrackSize.fr(1)),
          'current': GridAxisVariable(size: GridTrackSize.fr(1)),
          'next': GridAxisVariable(size: GridTrackSize.fr(1)),
          'future-padding': GridAxisVariable(
            size: GridTrackSize.pt(lgErgoLayoutDefaultPadding),
          ),
        },
        areas: {
          'previous-hour': PerspectiveGridArea(
            row: 'hour',
            column: 'previous',
            aliases: ['previous-hour'],
            label: 'previous hour',
          ),
          'current-hour': PerspectiveGridArea(
            row: 'hour',
            column: 'current',
            aliases: ['current-hour', 'now-hour'],
            fillColor: lgErgoCurrentTimeBackgroundColor,
            label: 'now',
          ),
          'next-hour': PerspectiveGridArea(
            row: 'hour',
            column: 'next',
            aliases: ['next-hour'],
            label: 'next hour',
          ),
          'previous-day': PerspectiveGridArea(
            row: 'day',
            column: 'previous',
            aliases: ['previous-day', 'yesterday'],
            label: 'yesterday',
          ),
          'current-day': PerspectiveGridArea(
            row: 'day',
            column: 'current',
            aliases: ['current-day', 'today'],
            defaultPath: DefaultTimelineVaultPaths.today,
            fillColor: lgErgoCurrentTimeBackgroundColor,
            label: 'today',
          ),
          'next-day': PerspectiveGridArea(
            row: 'day',
            column: 'next',
            aliases: ['next-day', 'tomorrow'],
            label: 'tomorrow',
          ),
          'last-week': PerspectiveGridArea(
            row: 'week',
            column: 'previous',
            aliases: ['previous-week', 'last-week'],
            label: 'last week',
          ),
          'current-week': PerspectiveGridArea(
            row: 'week',
            column: 'current',
            aliases: ['current-week', 'this-week'],
            fillColor: lgErgoCurrentTimeBackgroundColor,
            label: 'this week',
          ),
          'next-week': PerspectiveGridArea(
            row: 'week',
            column: 'next',
            aliases: ['next-week'],
            label: 'next week',
          ),
        },
      ),
    ),
    'now-ray': RayLayout(
      start: LayoutDerivativeReference(derivative: 'AD-center'),
      towards: LayoutDerivativeReference(
        layoutPath: ['safe-area'],
        derivative: 'AD-center',
      ),
      style: lgErgoNowRayStyle,
    ),
    'ray-a': RayLayout(
      start: LayoutDerivativeReference(
        layoutPath: ['safe-area'],
        derivative: 'A',
      ),
      towards: LayoutDerivativeReference(derivative: 'A'),
      style: lgErgoPlaneConnectionLineStyle,
    ),
    'ray-b': RayLayout(
      start: LayoutDerivativeReference(
        layoutPath: ['safe-area'],
        derivative: 'B',
      ),
      towards: LayoutDerivativeReference(derivative: 'B'),
      style: lgErgoRayStyle,
    ),
    'ray-c': RayLayout(
      start: LayoutDerivativeReference(
        layoutPath: ['safe-area'],
        derivative: 'C',
      ),
      towards: LayoutDerivativeReference(derivative: 'C'),
      style: lgErgoRayStyle,
    ),
    'ray-d': RayLayout(
      start: LayoutDerivativeReference(
        layoutPath: ['safe-area'],
        derivative: 'D',
      ),
      towards: LayoutDerivativeReference(derivative: 'D'),
      style: lgErgoPlaneConnectionLineStyle,
    ),
    'scene-ascending-diagonal-guide': RayLayout(
      start: LayoutDerivativeReference(
        layoutPath: ['safe-area'],
        derivative: 'A',
      ),
      towards: LayoutDerivativeReference(
        layoutPath: ['safe-area'],
        derivative: 'C',
      ),
      showArrow: false,
      style: lgErgoSceneDiagonalStyle,
    ),
    'safe-area': SafeAreaLayout(
      aliases: ['safe-area', 'scene-container'],
      attributes: [
        LayoutAttribute.safeArea,
        LayoutAttribute.rectangular,
        LayoutAttribute.circular,
      ],
      layoutDefaults: lgErgoLayoutDefaults,
      innerCircle: LayoutCircle(
        radiusFraction: lgErgoSceneInnerCircleRadiusFraction,
      ),
      outerCircle: LayoutCircle(
        radiusFraction: lgErgoSceneOuterCircleRadiusFraction,
      ),
      derivativeSnapshot: 'square-on-outer-circle',
      derivatives: {
        'square-on-outer-circle': LayoutDerivativeSnapshot(
          values: {
            'A': CircleRayIntersectionDerivative(
              circle: LayoutCircleBoundary.outer,
              angleDegrees: 135,
            ),
            'B': CircleRayIntersectionDerivative(
              circle: LayoutCircleBoundary.outer,
              angleDegrees: 225,
            ),
            'C': CircleRayIntersectionDerivative(
              circle: LayoutCircleBoundary.outer,
              angleDegrees: 315,
            ),
            'D': CircleRayIntersectionDerivative(
              circle: LayoutCircleBoundary.outer,
              angleDegrees: 45,
            ),
            'AD-center': MidpointDerivative(from: 'A', to: 'D'),
            'BC-center': MidpointDerivative(from: 'B', to: 'C'),
            'scene-BC-center': MidpointDerivative(from: 'B', to: 'C'),
          },
        ),
      },
      observables: {
        'square-anchors': LayoutObservable(derivatives: {'A', 'B', 'C', 'D'}),
      },
      layouts: {
        'scene-stickman': StickmanLayout(
          aliases: ['stickman', 'person', 'human-scale'],
          heightCm: 200,
          rangeStart: -0.1,
          rangeEnd: 1.1,
          style: lgErgoStickmanStyle,
        ),
        'scene-graph-preview': GraphPreviewLayout(
          aliases: ['graph-preview', 'knowledge-preview', 'future-graph'],
          nodeStyle: lgErgoGraphPreviewNodeStyle,
          edgeStyle: lgErgoGraphPreviewEdgeStyle,
          fillColor: lgErgoGraphPreviewNodeFillColor,
          labelColor: lgErgoGraphPreviewLabelColor,
          nodes: [
            GraphPreviewNode(id: 'self', position: Offset(0.5, 0.05)),
            GraphPreviewNode(id: 'memory', position: Offset(0.34, 0.13)),
            GraphPreviewNode(id: 'plan', position: Offset(0.66, 0.13)),
            GraphPreviewNode(id: 'idea', position: Offset(0.43, 0.22)),
            GraphPreviewNode(id: 'question', position: Offset(0.57, 0.22)),
          ],
          edges: [
            GraphPreviewEdge(from: 'self', to: 'memory'),
            GraphPreviewEdge(from: 'self', to: 'plan'),
            GraphPreviewEdge(from: 'memory', to: 'idea'),
            GraphPreviewEdge(from: 'plan', to: 'question'),
            GraphPreviewEdge(from: 'idea', to: 'question'),
          ],
        ),
        'outer-circle': CirleLayout(
          boundary: LayoutCircleBoundary.outer,
          style: GuideStyle(
            color: perceptualMapSlotColor,
            strokeWidth: 1.2,
            pattern: GuideLinePattern.dashed,
          ),
        ),
        'inner-circle': CirleLayout(
          boundary: LayoutCircleBoundary.inner,
          style: lgErgoSceneInnerCircleStyle,
        ),
        'padding-inner-border': LayoutBorderGuide(
          shape: LayoutBorderShape.square,
          reference: LayoutBorderReference.innerCircle,
          showAnchorDirections: true,
          style: lgErgoScenePaddingInnerBorderStyle,
        ),
        'scene-square': LayoutBorderGuide(
          shape: LayoutBorderShape.square,
          reference: LayoutBorderReference.outerCircle,
          useLayoutDefaults: true,
          style: lgErgoSceneSquareStyle,
        ),
        LayoutKey.innerBorder: LayoutBorderGuide(
          shape: LayoutBorderShape.square,
          reference: LayoutBorderReference.outerCircle,
          derivativeAnchors: ['A', 'B', 'C', 'D'],
          showAnchorDirections: true,
          style: GuideStyle(
            color: Color.fromARGB(153, 13, 136, 58),
            strokeWidth: 1,
            pattern: GuideLinePattern.dashed,
            dashLength: 5,
            dashInterval: 7,
          ),
        ),
      },
    ),
  },
);

const lgErgoLayoutDefaultPadding = 20.0;
const lgErgoLayoutDefaultGap = 20.0;
const lgErgoLayoutDefaultBorderWidth = 1.2;
const lgErgoLayoutDefaults = LayoutDefaults(
  padding: lgErgoLayoutDefaultPadding,
  gap: lgErgoLayoutDefaultGap,
  borderWidth: lgErgoLayoutDefaultBorderWidth,
);

const lgErgoBackgroundOpacity = 0.34;
const lgErgoPastColor = Color(0x553F51B5);
const lgErgoNowColor = Color(0xFFDC143C);
const lgErgoFutureColor = Color(0x552E7D32);
const lgErgoSpacePlaneBandColor = Color(0x223F51B5);
const lgErgoControlPlaneBandColor = Color(0x223F51B5);
const lgErgoActionPlaneBandColor = Color(0x223F51B5);
const lgErgoCortexNodeColor = LayoutColor.fromHex('FFD54F', opacity: 0.9);
const lgErgoCortexNodeLabelColor = Color(0xFF101820);
const lgErgoCurrentTimeBackgroundColor = Color(0x18DC143C);
const lgErgoHourPassedColor = Color(0x33DC143C);
const lgErgoHourLeftColor = Color(0x22DC143C);
const lgErgoDayPassedColor = Color(0x335C6BC0);
const lgErgoDayLeftColor = Color(0x2243A047);
const lgErgoSceneOuterCircleRadiusFraction = 0.5;
const lgErgoSceneInnerCircleRadiusFraction = 0.3535533905932738;

const lgErgoPlaneLineStyle = GuideStyle(
  color: Color(0xAAC59A1A),
  strokeWidth: 1.2,
  pattern: GuideLinePattern.solid,
);

const lgErgoPlaneConnectionLineStyle = GuideStyle(
  color: Color(0xCCC59A1A),
  strokeWidth: 1.2,
  pattern: GuideLinePattern.solid,
);

const lgErgoPlaneDashStyle = GuideStyle(
  color: Color(0xCCC59A1A),
  strokeWidth: 1,
  pattern: GuideLinePattern.dashed,
  dashLength: 6,
  dashInterval: 5,
);

const lgErgoSpacePlaneLineStyle = GuideStyle(
  color: Color(0xAA3F51B5),
  strokeWidth: lgErgoLayoutDefaultBorderWidth,
  pattern: GuideLinePattern.solid,
);

const lgErgoSpacePlaneDashStyle = GuideStyle(
  color: Color(0xAA3F51B5),
  strokeWidth: 1,
  pattern: GuideLinePattern.dashed,
  dashLength: 6,
  dashInterval: 5,
);

const lgErgoSpacePlaneRimStyle = GuideStyle(
  color: Color(0xCC3F51B5),
  strokeWidth: 1,
  pattern: GuideLinePattern.dashed,
  dashLength: 5,
  dashInterval: 7,
);

const lgErgoBaseNodeInfoTableStyle = GuideStyle(
  color: Color(0x665F7CFF),
  strokeWidth: 1,
  pattern: GuideLinePattern.solid,
);

const lgErgoBaseNodeInfoCellHighlightColor = Color(0x66374A9B);

const lgErgoCortexNodeBorderStyle = GuideStyle(
  color: Color(0xFFFFF7D6),
  strokeWidth: 1.8,
  pattern: GuideLinePattern.solid,
);

const lgErgoRadialTreeGridStyle = GuideStyle(
  color: Color(0x88FFD54F),
  strokeWidth: 0.9,
  pattern: GuideLinePattern.dashed,
  dashLength: 5,
  dashInterval: 5,
);

const lgErgoNowRayStyle = GuideStyle(
  color: lgErgoNowColor,
  strokeWidth: 2,
  pattern: GuideLinePattern.solid,
);

const lgErgoBcCenterArrowStyle = GuideStyle(
  color: perceptualMapDiagonalColor,
  strokeWidth: 2,
  pattern: GuideLinePattern.solid,
);

const lgErgoRayStyle = GuideStyle(
  color: perceptualMapDiagonalColor,
  strokeWidth: 1,
  pattern: GuideLinePattern.dashed,
  dashLength: 7,
  dashInterval: 6,
);

const lgErgoSceneInnerCircleStyle = GuideStyle(
  color: Color(0xCC8E44AD),
  strokeWidth: 1.2,
  pattern: GuideLinePattern.dashed,
  dashLength: 6,
  dashInterval: 5,
);

const lgErgoScenePaddingInnerBorderStyle = GuideStyle(
  color: Color(0xCC8E44AD),
  strokeWidth: 1,
  pattern: GuideLinePattern.dashed,
  dashLength: 5,
  dashInterval: 7,
);

const lgErgoSceneSquareStyle = GuideStyle(
  color: Color(0xAA8E44AD),
  strokeWidth: 1,
  pattern: GuideLinePattern.dashed,
  dashLength: 5,
  dashInterval: 7,
);

const lgErgoStickmanStyle = GuideStyle(
  color: Color(0xDD101820),
  strokeWidth: 3,
  pattern: GuideLinePattern.solid,
  strokeCap: StrokeCap.round,
);

const lgErgoGraphPreviewNodeFillColor = Color(0xBBFFF7D6);
const lgErgoGraphPreviewLabelColor = Color(0xFF101820);

const lgErgoGraphPreviewNodeStyle = GuideStyle(
  color: Color(0xDDC59A1A),
  strokeWidth: 1.6,
  pattern: GuideLinePattern.solid,
);

const lgErgoGraphPreviewEdgeStyle = GuideStyle(
  color: Color(0x99C59A1A),
  strokeWidth: 1,
  pattern: GuideLinePattern.dashed,
  dashLength: 4,
  dashInterval: 4,
);

const lgErgoSceneDiagonalStyle = GuideStyle(
  color: Color(0xCC8E44AD),
  strokeWidth: 1,
  pattern: GuideLinePattern.dashed,
  dashLength: 6,
  dashInterval: 5,
);

const lgErgoDiagonalGuidelineStyle = GuideStyle(
  color: perceptualMapDiagonalColor,
  strokeWidth: 1,
  pattern: GuideLinePattern.dashed,
  dashLength: 7,
  dashInterval: 6,
);

const lgErgoScreenGuidelineStyle = GuideStyle(
  color: guidelineRedColor,
  strokeWidth: 1.2,
  pattern: GuideLinePattern.dashed,
  dashLength: 8,
  dashInterval: 6,
);
