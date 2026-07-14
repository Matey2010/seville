import 'dart:ui';

import '../../../../models/layout.dart';
import '../../../../models/landscape_xl_layout.dart';
import '../../../../models/node_property_table.dart';
import '../../../interface_colors.dart';
import '../../../paths/default_vault_paths.dart';

final lgErgoLayoutConfig = LandscapeXlLayout(
  initialHighlightedNode: VaultNodeUiComponent(path: DefaultVaultPaths.cortex),
  aliases: ['screen', 'root', 'reality', 'user-space', 'user-reality'],
  attributes: [LayoutAttribute.screen, LayoutAttribute.rectangular],
  backgrounds: [
    LayoutImageBackground(
      assetPath: 'assets/wallpapers/daft-punk.jpg',
      fit: LayoutBackgroundFit.cover,
      opacity: 0.34,
    ),
    LayoutGuidingBackground(
      guides: [
        LayoutBackgroundGuide(
          start: Offset(0, 0.5),
          end: Offset(1, 0.5),
          style: lgErgoScreenGuidelineStyle,
        ),
        LayoutBackgroundGuide(
          start: Offset(0.5, 0),
          end: Offset(0.5, 1),
          style: lgErgoScreenGuidelineStyle,
        ),
        LayoutBackgroundGuide(
          start: Offset(0, 0),
          end: Offset(1, 1),
          style: lgErgoDiagonalGuidelineStyle,
        ),
        LayoutBackgroundGuide(
          start: Offset(0, 1),
          end: Offset(1, 0),
          style: lgErgoDiagonalGuidelineStyle,
        ),
      ],
    ),
  ],
  layoutDefaults: lgErgoLayoutDefaults,
  derivativeSnapshot: 'screen-edge-centers',
  modes: {
    'scene-flopped': LayoutMode(
      id: 'scene-flopped',
      aliases: ['collapsed-scene', 'folded', 'folded-scene'],
      activeCondition: LayoutCondition.noSelectedNode(),
      derivativeSnapshot: 'screen-edge-centers',
    ),
  },
  derivatives: {
    'screen-edge-centers': LayoutDerivativeSnapshot(
      values: {
        'AD-center': MidpointDerivative(from: 'A', to: 'D'),
        'BC-center': MidpointDerivative(from: 'B', to: 'C'),
      },
    ),
  },
  layouts: {
    'action-panel': LayoutPath(
      aliases: [
        'action-panel',
        'action-pane',
        'action-plane',
        'form-panel',
        'form-pane',
        'form-plane',
        'right-plane',
        'east-plane',
      ],
      points: [
        LayoutDerivativeReference(derivative: 'C'),
        LayoutDerivativeReference(
          layoutPath: ['safe-area'],
          derivative: 'rightPlane.top',
        ),
        LayoutDerivativeReference(
          layoutPath: ['safe-area'],
          derivative: 'rightPlane.bottom',
        ),
        LayoutDerivativeReference(derivative: 'D'),
      ],
      style: LayoutPathStyle(
        fillColor: Color(0x333F51B5),
        strokeStyle: lgErgoSpacePlaneLineStyle,
      ),
      padding: LayoutPathPadding(
        top: lgErgoLayoutDefaultPadding,
        bottom: lgErgoLayoutDefaultPadding,
        left: lgErgoLayoutDefaultPadding,
      ),
      layouts: {
        'action-column': ColumnLayout(
          aliases: ['action-column', 'action-panel-column', 'form-column'],
          layouts: {
            'navigation-row': RowLayout(
              size: GridAxisVariable(size: LayoutSize.px(48)),
              aliases: ['navigation-row', 'browser-navigation'],
              layouts: {
                'back': PanelLayout(
                  size: GridAxisVariable(size: LayoutSize.fr(1)),
                  aliases: ['action-button', 'back-action'],
                  fillColor: lgErgoActionButtonColor,
                  borderStyle: lgErgoActionButtonBorderStyle,
                  label: '‹',
                  labelColor: lgErgoActionButtonLabelColor,
                  labelSize: 18,
                ),
                'forward': PanelLayout(
                  size: GridAxisVariable(size: LayoutSize.fr(1)),
                  aliases: ['action-button', 'forward-action'],
                  fillColor: lgErgoActionButtonColor,
                  borderStyle: lgErgoActionButtonBorderStyle,
                  label: '›',
                  labelColor: lgErgoActionButtonLabelColor,
                  labelSize: 18,
                ),
              },
            ),
            'browser-content': PanelLayout(
              size: GridAxisVariable(size: LayoutSize.fr(1)),
              aliases: ['browser-content', 'web-view', 'change-reference'],
              borderStyle: lgErgoSpacePlaneRimStyle,
              label: 'Browser',
              labelColor: lgErgoActionButtonLabelColor,
            ),
            'action-row': RowLayout(
              size: GridAxisVariable(size: LayoutSize.px(56)),
              aliases: ['actions', 'action-row'],
              layouts: {
                'submit': PanelLayout(
                  size: GridAxisVariable(size: LayoutSize.fr(1)),
                  aliases: ['action-button', 'submit-action'],
                  fillColor: lgErgoSubmitButtonColor,
                  borderStyle: lgErgoActionButtonBorderStyle,
                  label: 'Submit',
                  labelColor: lgErgoActionButtonLabelColor,
                ),
                'reject': PanelLayout(
                  size: GridAxisVariable(size: LayoutSize.fr(1)),
                  aliases: ['action-button', 'reject-action'],
                  fillColor: lgErgoRejectButtonColor,
                  borderStyle: lgErgoActionButtonBorderStyle,
                  label: 'Reject',
                  labelColor: lgErgoActionButtonLabelColor,
                ),
              },
            ),
          },
        ),
      },
    ),
    'top-plane': LayoutPath(
      aliases: ['top-plane', 'control-plane', 'north-plane'],
      points: [
        LayoutDerivativeReference(derivative: 'B'),
        LayoutDerivativeReference(
          layoutPath: ['safe-area'],
          derivative: 'innerSquare.BC-center',
        ),
        LayoutDerivativeReference(derivative: 'C'),
      ],
      style: LayoutPathStyle(
        fillColor: lgErgoControlPlaneBandColor,
        strokeStyle: lgErgoPlaneLineStyle,
      ),
      layouts: {
        'cortex-bush': RadialBushLayout(
          aliases: ['radial-bush', 'node-bush', 'cortex-bush', 'top-node-bush'],
          style: lgErgoCortexNodeBorderStyle,
          label: 'cortex',
          labelColor: lgErgoCortexNodeLabelColor,
          labelSize: 10,
          layoutSize: LayoutExtent.derivativeDistance(
            from: LayoutDerivativeReference(derivative: 'BC-center'),
            to: LayoutDerivativeReference(
              layoutPath: ['safe-area'],
              derivative: 'innerSquare.BC-center',
            ),
          ),
          gridStyle: lgErgoRadialBushGridStyle,
          bushStructure: RadialBushStructure(
            root: RadialBushRoot(
              size: GridAxisVariable(size: LayoutSize.fr(1)),
              node: VaultNodeUiComponent(
                path: DefaultVaultPaths.cortex,
                color: lgErgoCortexNodeColor,
                backgrounds: [
                  ConditionalLayoutBackground(
                    activeCondition: LayoutCondition.nodeHighlighted(),
                    background: LayoutBorderBackground(
                      style: lgErgoHighlightedNodeBorderStyle,
                    ),
                  ),
                ],
              ),
              backgroundExtractor: BackgroundExtractor(
                rootParameter: 'background',
              ),
            ),
            branch: RadialBushBranch(
              size: GridAxisVariable(size: LayoutSize.fr(1)),
              rootParameter: 'components',
            ),
            // leaves: RadialBushElement(
            //   size: GridAxisVariable(size: LayoutSize.fr(1)),
            // ),
            // flowers: RadialBushElement(
            //   size: GridAxisVariable(size: LayoutSize.fr(1)),
            // ),
          ),
          position: LayoutRelativePosition.top,
        ),
      },
    ),
    'info-panel': LayoutPath(
      aliases: [
        'info-panel',
        'info-pane',
        'info-plane',
        'left-plane',
        'west-plane',
      ],
      points: [
        LayoutDerivativeReference(derivative: 'B'),
        LayoutDerivativeReference(
          layoutPath: ['safe-area'],
          derivative: 'leftPlane.top',
        ),
        LayoutDerivativeReference(
          layoutPath: ['safe-area'],
          derivative: 'leftPlane.bottom',
        ),
        LayoutDerivativeReference(derivative: 'A'),
      ],
      pointDerivatives: {'A': 0, 'B': 1, 'C': 2, 'D': 3},
      style: LayoutPathStyle(
        fillColor: lgErgoActionPlaneBandColor,
        strokeStyle: lgErgoSpacePlaneLineStyle,
      ),
      layouts: {
        'base-node-info': NodePropertyTable(
          aliases: ['base-node-info', 'node-info-table'],
          dataSource: NodePropertyTableDataSource.baseNodeInfo,
          guideStyle: lgErgoBaseNodeInfoTableStyle,
          cellHighlight: TableCellHighlightConfig(
            rows: true,
            columns: true,
            color: lgErgoBaseNodeInfoCellHighlightColor,
          ),
          fieldBuilder: TableFieldBuilder(
            groups: {
              TableGroup(id: 'identity', label: 'Public identity'),
              TableGroup(
                id: null,
                ordering: TableFieldOrdering.keyAlphabetical,
              ),
            },
            fields: [
              TableField(
                key: 'id',
                groupId: 'identity',
                size: GridAxisVariable(size: LayoutSize.fr(1)),
              ),
              TableField(
                key: 'aliases',
                groupId: 'identity',
                size: GridAxisVariable(size: LayoutSize.fr(1)),
              ),
              TableField(
                key: 'tags',
                size: GridAxisVariable(size: LayoutSize.fr(1)),
              ),
              TableField(
                key: 'classification',
                size: GridAxisVariable(size: LayoutSize.fr(1)),
              ),
              TableField(
                key: 'version',
                groupId: 'identity',
                size: GridAxisVariable(size: LayoutSize.fr(0.5)),
              ),
            ],
          ),
          columns: [
            MapEntry('key', GridAxisVariable(size: LayoutSize.fr(1))),
            MapEntry('value', GridAxisVariable(size: LayoutSize.fr(3))),
          ],
        ),
      },
    ),
    'bottom-plane': LayoutPath(
      aliases: ['bottom-plane', 'time-plane', 'x-axis-plane'],
      points: [
        LayoutDerivativeReference(derivative: 'A'),
        LayoutDerivativeReference(
          layoutPath: ['safe-area'],
          derivative: 'innerSquare.AD-center',
        ),
        LayoutDerivativeReference(derivative: 'D'),
      ],
      style: LayoutPathStyle(
        fillColor: Color(0x55C59A1A),
        strokeStyle: lgErgoPlaneLineStyle,
      ),
      grid: PerspectiveGridLayout(
        aliases: ['bottom-plane-grid', 'time-grid'],
        guideStyle: lgErgoPlaneDashStyle,
        topStartIndex: 1,
        topEndIndex: 1,
        bottomStartIndex: 0,
        bottomEndIndex: 2,
        rowsConfig: {
          'hour': GridAxisVariable(size: LayoutSize.fr(1)),
          'day': GridAxisVariable(size: LayoutSize.fr(1)),
          'week': GridAxisVariable(size: LayoutSize.fr(1)),
        },
        columnsConfig: {
          'past-padding': GridAxisVariable(
            size: LayoutSize.pt(lgErgoLayoutDefaultPadding),
          ),
          'previous': GridAxisVariable(size: LayoutSize.fr(1)),
          'current': GridAxisVariable(size: LayoutSize.fr(1)),
          'next': GridAxisVariable(size: LayoutSize.fr(1)),
          'future-padding': GridAxisVariable(
            size: LayoutSize.pt(lgErgoLayoutDefaultPadding),
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
      layoutDefaults: lgErgoLayoutDefaults,
      derivativeSnapshot: 'safe-area-manifold',
      derivatives: {
        'safe-area-manifold': LayoutDerivativeSnapshot(
          values: {
            'A': CircleRayIntersectionDerivative(
              circle: LayoutCircleBoundary.inner,
              angleDegrees: 225,
            ),
            'B': CircleRayIntersectionDerivative(
              circle: LayoutCircleBoundary.inner,
              angleDegrees: 135,
            ),
            'C': CircleRayIntersectionDerivative(
              circle: LayoutCircleBoundary.inner,
              angleDegrees: 45,
            ),
            'D': CircleRayIntersectionDerivative(
              circle: LayoutCircleBoundary.inner,
              angleDegrees: 315,
            ),
            'AD-center': MidpointDerivative(from: 'A', to: 'D'),
            'BC-center': MidpointDerivative(from: 'B', to: 'C'),
            'innerCircle.center': CircleCenterDerivative(
              circle: LayoutCircleBoundary.inner,
            ),
            'innerCircle.top': CircleRayIntersectionDerivative(
              circle: LayoutCircleBoundary.inner,
              angleDegrees: 90,
            ),
            'innerCircle.right': CircleRayIntersectionDerivative(
              circle: LayoutCircleBoundary.inner,
              angleDegrees: 0,
            ),
            'innerCircle.bottom': CircleRayIntersectionDerivative(
              circle: LayoutCircleBoundary.inner,
              angleDegrees: 270,
            ),
            'innerCircle.left': CircleRayIntersectionDerivative(
              circle: LayoutCircleBoundary.inner,
              angleDegrees: 180,
            ),
            'innerSquare.A': CircleRayIntersectionDerivative(
              circle: LayoutCircleBoundary.inner,
              angleDegrees: 225,
            ),
            'innerSquare.B': CircleRayIntersectionDerivative(
              circle: LayoutCircleBoundary.inner,
              angleDegrees: 135,
            ),
            'innerSquare.C': CircleRayIntersectionDerivative(
              circle: LayoutCircleBoundary.inner,
              angleDegrees: 45,
            ),
            'innerSquare.D': CircleRayIntersectionDerivative(
              circle: LayoutCircleBoundary.inner,
              angleDegrees: 315,
            ),
            'innerSquare.BC-center': MidpointDerivative(
              from: 'innerSquare.B',
              to: 'innerSquare.C',
            ),
            'innerSquare.AD-center': MidpointDerivative(
              from: 'innerSquare.A',
              to: 'innerSquare.D',
            ),
            'leftPlane.top': ConditionalDerivative(
              condition: LayoutCondition.modeActive('scene-flopped'),
              whenTrue: MidpointDerivative(
                from: 'innerSquare.B',
                to: 'innerSquare.C',
              ),
              whenFalse: CircleRayIntersectionDerivative(
                circle: LayoutCircleBoundary.inner,
                angleDegrees: 135,
              ),
            ),
            'leftPlane.bottom': ConditionalDerivative(
              condition: LayoutCondition.modeActive('scene-flopped'),
              whenTrue: MidpointDerivative(
                from: 'innerSquare.A',
                to: 'innerSquare.D',
              ),
              whenFalse: CircleRayIntersectionDerivative(
                circle: LayoutCircleBoundary.inner,
                angleDegrees: 225,
              ),
            ),
            'rightPlane.top': ConditionalDerivative(
              condition: LayoutCondition.modeActive('scene-flopped'),
              whenTrue: MidpointDerivative(
                from: 'innerSquare.B',
                to: 'innerSquare.C',
              ),
              whenFalse: CircleRayIntersectionDerivative(
                circle: LayoutCircleBoundary.inner,
                angleDegrees: 45,
              ),
            ),
            'rightPlane.bottom': ConditionalDerivative(
              condition: LayoutCondition.modeActive('scene-flopped'),
              whenTrue: MidpointDerivative(
                from: 'innerSquare.A',
                to: 'innerSquare.D',
              ),
              whenFalse: CircleRayIntersectionDerivative(
                circle: LayoutCircleBoundary.inner,
                angleDegrees: 315,
              ),
            ),
          },
        ),
      },
      observables: {
        'square-anchors': LayoutObservable(derivatives: {'A', 'B', 'C', 'D'}),
      },
      layouts: {
        'inner-circle-plane': PlaneLayout(
          aliases: ['inner-circle-plane', 'scene-plane', 'circle-plane'],
          modes: {
            'scene-flopped': LayoutMode(
              id: 'scene-flopped',
              aliases: ['collapsed-scene', 'folded', 'folded-scene'],
              activeCondition: LayoutCondition.modeActive(
                'scene-flopped',
                aliases: ['collapsed-scene', 'folded', 'folded-scene'],
              ),
              visible: false,
            ),
          },
          shape: LayoutShape.circle,
          style: randomBlueprintAesthetics.layoutStyle,
          backgroundColor: Color(0x00000000),
          borderColor: Color(0x00000000),
          resolvedBorderColor: Color(0x00000000),
          borderWidth: 0,
          wrapPadding: 0,
          showGeometryGuides: true,
          layouts: {
            'wrapped-scene-square': PlaneLayout(
              aliases: ['wrapped-scene-square', 'scene-square-plane'],
              shape: LayoutShape.square,
              style: randomBlueprintAesthetics.layoutStyle,
              backgroundColor: Color(0x00000000),
              borderColor: Color(0x00000000),
              resolvedBorderColor: Color(0x00000000),
              borderWidth: 0,
              wrapPadding: 0,
              showGeometryGuides: true,
              layouts: {
                'subject-field-circle': PlaneLayout(
                  aliases: ['subject-field', 'subject-field-circle'],
                  shape: LayoutShape.circle,
                  style: randomBlueprintAesthetics.layoutStyle,
                  backgroundColor: Color(0x00000000),
                  borderColor: Color(0x00000000),
                  resolvedBorderColor: Color(0x00000000),
                  borderWidth: 0,
                  wrapPadding: 0,
                  showGeometryGuides: true,
                  layouts: {
                    'subject-core-square': PlaneLayout(
                      aliases: ['subject-core', 'subject-core-square'],
                      shape: LayoutShape.square,
                      style: randomBlueprintAesthetics.layoutStyle,
                      backgroundColor: Color(0x00000000),
                      borderColor: Color(0x00000000),
                      resolvedBorderColor: Color(0x00000000),
                      borderWidth: 0,
                      wrapPadding: 0,
                      showGeometryGuides: true,
                      layouts: {
                        'scene-subject': PlaneLayout(
                          aliases: [
                            'subject',
                            'scene-subject',
                            'project-subject',
                          ],
                          shape: LayoutShape.circle,
                          style: randomBlueprintAesthetics.layoutStyle,
                          backgroundColor: Color(0xFFFFFBEA),
                          borderColor: Color(0xAA303030),
                          resolvedBorderColor: Color(0xAA303030),
                          borderWidth: 2,
                          wrapPadding: 0,
                          showGeometryGuides: true,
                        ),
                      },
                    ),
                    'scene-graph-preview': GraphPreviewLayout(
                      aliases: [
                        'graph-preview',
                        'knowledge-preview',
                        'future-graph',
                      ],
                      nodeStyle: lgErgoGraphPreviewNodeStyle,
                      edgeStyle: lgErgoGraphPreviewEdgeStyle,
                      fillColor: lgErgoGraphPreviewNodeFillColor,
                      labelColor: lgErgoGraphPreviewLabelColor,
                      nodes: [
                        GraphPreviewNode(
                          id: 'self',
                          position: Offset(0.5, 0.05),
                        ),
                        GraphPreviewNode(
                          id: 'memory',
                          position: Offset(0.34, 0.13),
                        ),
                        GraphPreviewNode(
                          id: 'plan',
                          position: Offset(0.66, 0.13),
                        ),
                        GraphPreviewNode(
                          id: 'idea',
                          position: Offset(0.43, 0.22),
                        ),
                        GraphPreviewNode(
                          id: 'question',
                          position: Offset(0.57, 0.22),
                        ),
                      ],
                      edges: [
                        GraphPreviewEdge(from: 'self', to: 'memory'),
                        GraphPreviewEdge(from: 'self', to: 'plan'),
                        GraphPreviewEdge(from: 'memory', to: 'idea'),
                        GraphPreviewEdge(from: 'plan', to: 'question'),
                        GraphPreviewEdge(from: 'idea', to: 'question'),
                      ],
                    ),
                  },
                ),
              },
            ),
          },
        ),
        'inner-circle': LayoutBorderGuide(
          modes: {
            'scene-flopped': LayoutMode(
              id: 'scene-flopped',
              aliases: ['collapsed-scene', 'folded', 'folded-scene'],
              activeCondition: LayoutCondition.modeActive(
                'scene-flopped',
                aliases: ['collapsed-scene', 'folded', 'folded-scene'],
              ),
              visible: false,
            ),
          },
          shape: LayoutBorderShape.circle,
          reference: LayoutBorderReference.bounds,
          derivativeAnchors: ['innerCircle.center', 'innerCircle.top'],
          labelFontSize: 9,
          anchorRadius: 1.8,
          style: lgErgoSceneInnerCircleStyle,
        ),
        LayoutKey.innerBorder: LayoutBorderGuide(
          shape: LayoutBorderShape.square,
          reference: LayoutBorderReference.bounds,
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

const lgErgoPastColor = Color(0x553F51B5);
const lgErgoNowColor = Color(0xFFDC143C);
const lgErgoFutureColor = Color(0x552E7D32);
const lgErgoSpacePlaneBandColor = Color(0x223F51B5);
const lgErgoControlPlaneBandColor = Color(0x00000000);
const lgErgoActionPlaneBandColor = Color(0x223F51B5);
const lgErgoActionButtonColor = Color(0x553F51B5);
const lgErgoSubmitButtonColor = Color(0x6652A66B);
const lgErgoRejectButtonColor = Color(0x668F3E4B);
const lgErgoActionButtonLabelColor = Color(0xFFF5F7FF);
const lgErgoCortexNodeColor = LayoutColor.fromHex('FFD54F', opacity: 0.9);
const lgErgoCortexNodeLabelColor = Color(0xFF101820);
const lgErgoCurrentTimeBackgroundColor = Color(0x18DC143C);
const lgErgoHourPassedColor = Color(0x33DC143C);
const lgErgoHourLeftColor = Color(0x22DC143C);
const lgErgoDayPassedColor = Color(0x335C6BC0);
const lgErgoDayLeftColor = Color(0x2243A047);

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

const lgErgoActionButtonBorderStyle = GuideStyle(
  color: Color(0xCCB7C2FF),
  strokeWidth: 1,
  pattern: GuideLinePattern.solid,
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

const lgErgoHighlightedNodeBorderStyle = GuideStyle(
  color: Color(0xFF2196F3),
  strokeWidth: 4,
  pattern: GuideLinePattern.solid,
);

const lgErgoRadialBushGridStyle = GuideStyle(
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
