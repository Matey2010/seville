import 'dart:ui';

import '../../../../models/layout.dart';
import '../../../../models/graph_traverse_type.dart';
import '../../../../models/landscape_xl_layout.dart';
import '../../../../models/table_layout.dart';
import '../../../../models/node_search.dart';
import '../../../interface_colors.dart';
import '../../../paths/default_vault_paths.dart';

final lgErgoLayoutConfig = LandscapeXlLayout(
  initialHighlightedNode: VaultNodeUiComponent(path: DefaultVaultPaths.cortex),
  aliases: ['screen', 'root', 'reality', 'user-space', 'user-reality'],
  attributes: [LayoutAttribute.screen, LayoutAttribute.rectangular],
  backgrounds: [
    LayoutImageBackground(
      assetPath: 'assets/wallpapers/dark-vintage-scheme.jpg',
      fit: LayoutBackgroundFit.cover,
    ),
    LayoutImageBackground(
      assetPath: 'assets/wallpapers/daft-punk-helmet.jpg',
      fit: LayoutBackgroundFit.contain,
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
      backgrounds: [
        LayoutImageBackground(
          assetPath: 'assets/wallpapers/dark-vintage-scheme.jpg',
          fit: LayoutBackgroundFit.cover,
        ),
        LayoutImageBackground(
          assetPath: 'assets/wallpapers/helmet-background.jpg',
          fit: LayoutBackgroundFit.cover,
          opacity: 0.34,
        ),
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
                'refresh-fans': PanelLayout(
                  size: GridAxisVariable(size: LayoutSize.fr(1)),
                  aliases: [
                    'action-button',
                    'refresh-action',
                    'refresh-fan-data',
                  ],
                  fillColor: lgErgoActionButtonColor,
                  borderStyle: lgErgoActionButtonBorderStyle,
                  label: '🔄',
                  labelColor: lgErgoActionButtonLabelColor,
                  labelSize: 18,
                ),
                'search': PanelLayout(
                  size: GridAxisVariable(size: LayoutSize.fr(1)),
                  aliases: [
                    'action-button',
                    'search-action',
                    'open-search-hud',
                  ],
                  fillColor: lgErgoActionButtonColor,
                  borderStyle: lgErgoActionButtonBorderStyle,
                  label: '🔍',
                  labelColor: lgErgoActionButtonLabelColor,
                  labelSize: 18,
                ),
                'add-node': PanelLayout(
                  size: GridAxisVariable(size: LayoutSize.fr(1)),
                  aliases: [
                    'action-button',
                    'add-action',
                    'create-virtual-node',
                  ],
                  fillColor: lgErgoSubmitButtonColor,
                  borderStyle: lgErgoActionButtonBorderStyle,
                  label: 'Add',
                  labelColor: lgErgoActionButtonLabelColor,
                  labelSize: 12,
                ),
                'today': PanelLayout(
                  size: GridAxisVariable(size: LayoutSize.fr(1)),
                  aliases: [
                    'action-button',
                    'today-action',
                    'resolve-today-node',
                  ],
                  fillColor: lgErgoActionButtonColor,
                  borderStyle: lgErgoActionButtonBorderStyle,
                  label: 'Today',
                  labelColor: lgErgoActionButtonLabelColor,
                  labelSize: 12,
                ),
                'confirm': PanelLayout(
                  size: GridAxisVariable(size: LayoutSize.fr(1)),
                  aliases: [
                    'action-button',
                    'confirm-action',
                    'submit-action',
                    'create-first-virtual-node',
                  ],
                  fillColor: lgErgoSubmitButtonColor,
                  borderStyle: lgErgoActionButtonBorderStyle,
                  label: '✅',
                  labelColor: lgErgoActionButtonLabelColor,
                  labelSize: 18,
                ),
                'close-selection': PanelLayout(
                  size: GridAxisVariable(size: LayoutSize.fr(1)),
                  aliases: [
                    'action-button',
                    'close-action',
                    'cancel-interface-action',
                    'clear-selection-action',
                  ],
                  fillColor: lgErgoRejectButtonColor,
                  borderStyle: lgErgoActionButtonBorderStyle,
                  label: '×',
                  labelColor: lgErgoActionButtonLabelColor,
                  labelSize: 18,
                ),
              },
            ),
            'node-actions-row': RowLayout(
              size: GridAxisVariable(size: LayoutSize.px(48)),
              aliases: ['node-actions', 'node-actions-row'],
              layouts: {
                'copy': PanelLayout(
                  size: GridAxisVariable(size: LayoutSize.fr(1)),
                  aliases: [
                    'action-button',
                    'selected-node-action',
                    'copy-action',
                    'copy-selected-node-slug',
                  ],
                  fillColor: lgErgoActionButtonColor,
                  borderStyle: lgErgoActionButtonBorderStyle,
                  label: '📋',
                  labelColor: lgErgoActionButtonLabelColor,
                  labelSize: 18,
                ),
                'share': PanelLayout(
                  size: GridAxisVariable(size: LayoutSize.fr(1)),
                  aliases: [
                    'action-button',
                    'selected-node-action',
                    'share-action',
                  ],
                  fillColor: lgErgoActionButtonColor,
                  borderStyle: lgErgoActionButtonBorderStyle,
                  label: '📤',
                  labelColor: lgErgoActionButtonLabelColor,
                  labelSize: 18,
                ),
              },
            ),
            'search-results': NodeListLayout(
              dataSource: NodeListDataSource.searchResults,
              style: lgErgoCortexNodeBorderStyle,
              layoutDefaults: lgErgoNodeLayoutDefaults,
              aliases: ['search-results', 'query-results', 'node-options'],
              labelColor: lgErgoActionButtonLabelColor,
              size: GridAxisVariable(size: LayoutSize.fr(1)),
            ),
            'virtual-nodes': NodeListLayout(
              dataSource: NodeListDataSource.virtualNodes,
              style: lgErgoCortexNodeBorderStyle,
              layoutDefaults: lgErgoNodeLayoutDefaults,
              size: GridAxisVariable(size: LayoutSize.fr(1)),
              aliases: ['virtual-nodes', 'draft-nodes', 'uncreated-nodes'],
              labelColor: lgErgoActionButtonLabelColor,
            ),
            'direction-pad': ColumnLayout(
              size: GridAxisVariable(size: LayoutSize.px(144)),
              aliases: [
                'direction-pad',
                'node-direction-controls',
                'spatial-navigation',
              ],
              layouts: {
                'top-directions': RowLayout(
                  size: GridAxisVariable(size: LayoutSize.fr(1)),
                  aliases: ['direction-row', 'top-direction-row'],
                  layouts: {
                    'top-left': PanelLayout(
                      size: GridAxisVariable(size: LayoutSize.fr(1)),
                      aliases: [
                        'action-button',
                        'selected-node-action',
                        'direction-action',
                        'direction-top-left',
                      ],
                      fillColor: lgErgoActionButtonColor,
                      borderStyle: lgErgoActionButtonBorderStyle,
                      label: '↖',
                      labelColor: lgErgoActionButtonLabelColor,
                      labelSize: 18,
                    ),
                    'top-center': PanelLayout(
                      size: GridAxisVariable(size: LayoutSize.fr(1)),
                      aliases: [
                        'action-button',
                        'selected-node-action',
                        'direction-action',
                        'direction-top-center',
                      ],
                      fillColor: lgErgoActionButtonColor,
                      borderStyle: lgErgoActionButtonBorderStyle,
                      label: '↑',
                      labelColor: lgErgoActionButtonLabelColor,
                      labelSize: 18,
                    ),
                    'top-right': PanelLayout(
                      size: GridAxisVariable(size: LayoutSize.fr(1)),
                      aliases: [
                        'action-button',
                        'selected-node-action',
                        'direction-action',
                        'direction-top-right',
                      ],
                      fillColor: lgErgoActionButtonColor,
                      borderStyle: lgErgoActionButtonBorderStyle,
                      label: '↗',
                      labelColor: lgErgoActionButtonLabelColor,
                      labelSize: 18,
                    ),
                  },
                ),
                'center-directions': RowLayout(
                  size: GridAxisVariable(size: LayoutSize.fr(1)),
                  aliases: ['direction-row', 'center-direction-row'],
                  layouts: {
                    'center-left': PanelLayout(
                      size: GridAxisVariable(size: LayoutSize.fr(1)),
                      aliases: [
                        'action-button',
                        'selected-node-action',
                        'direction-action',
                        'direction-center-left',
                      ],
                      fillColor: lgErgoActionButtonColor,
                      borderStyle: lgErgoActionButtonBorderStyle,
                      label: '←',
                      labelColor: lgErgoActionButtonLabelColor,
                      labelSize: 18,
                    ),
                    'center': PanelLayout(
                      size: GridAxisVariable(size: LayoutSize.fr(1)),
                      aliases: [
                        'action-button',
                        'selected-node-action',
                        'direction-action',
                        'direction-center',
                      ],
                      fillColor: lgErgoActionButtonColor,
                      borderStyle: lgErgoActionButtonBorderStyle,
                      label: '•',
                      labelColor: lgErgoActionButtonLabelColor,
                      labelSize: 18,
                    ),
                    'center-right': PanelLayout(
                      size: GridAxisVariable(size: LayoutSize.fr(1)),
                      aliases: [
                        'action-button',
                        'selected-node-action',
                        'direction-action',
                        'direction-center-right',
                      ],
                      fillColor: lgErgoActionButtonColor,
                      borderStyle: lgErgoActionButtonBorderStyle,
                      label: '→',
                      labelColor: lgErgoActionButtonLabelColor,
                      labelSize: 18,
                    ),
                  },
                ),
                'bottom-directions': RowLayout(
                  size: GridAxisVariable(size: LayoutSize.fr(1)),
                  aliases: ['direction-row', 'bottom-direction-row'],
                  layouts: {
                    'bottom-left': PanelLayout(
                      size: GridAxisVariable(size: LayoutSize.fr(1)),
                      aliases: [
                        'action-button',
                        'selected-node-action',
                        'direction-action',
                        'direction-bottom-left',
                      ],
                      fillColor: lgErgoActionButtonColor,
                      borderStyle: lgErgoActionButtonBorderStyle,
                      label: '↙',
                      labelColor: lgErgoActionButtonLabelColor,
                      labelSize: 18,
                    ),
                    'bottom-center': PanelLayout(
                      size: GridAxisVariable(size: LayoutSize.fr(1)),
                      aliases: [
                        'action-button',
                        'selected-node-action',
                        'direction-action',
                        'direction-bottom-center',
                      ],
                      fillColor: lgErgoActionButtonColor,
                      borderStyle: lgErgoActionButtonBorderStyle,
                      label: '↓',
                      labelColor: lgErgoActionButtonLabelColor,
                      labelSize: 18,
                    ),
                    'bottom-right': PanelLayout(
                      size: GridAxisVariable(size: LayoutSize.fr(1)),
                      aliases: [
                        'action-button',
                        'selected-node-action',
                        'direction-action',
                        'direction-bottom-right',
                      ],
                      fillColor: lgErgoActionButtonColor,
                      borderStyle: lgErgoActionButtonBorderStyle,
                      label: '↘',
                      labelColor: lgErgoActionButtonLabelColor,
                      labelSize: 18,
                    ),
                  },
                ),
              },
            ),
          },
        ),
      },
    ),
    'info-panel': LayoutPath(
      backgrounds: [
        LayoutImageBackground(
          assetPath: 'assets/wallpapers/daft-punk-suit.jpg',
          fit: LayoutBackgroundFit.contain,
          opacity: 0.34,
        ),
      ],
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
        'info-table': TableLayout(
          aliases: ['info-table', 'table-layout', 'node-info', 'system-info'],
          layoutDefaults: lgErgoNodeLayoutDefaults,
          guideStyle: lgErgoNodeInfoTableStyle,
          cellHighlight: TableCellHighlightConfig(
            rows: true,
            columns: true,
            color: lgErgoNodeInfoCellHighlightColor,
          ),
          includeUnconfiguredFields: true,
          unconfiguredFieldGroupId: 'node',
          fieldBuilder: TableFieldBuilder(
            groups: [
              TableGroup(id: 'node'),
              TableGroup(id: 'system'),
            ],
            fields: [
              TableField(
                key: 'slug',
                label: 'Slug',
                groupId: 'node',
                size: GridAxisVariable(size: LayoutSize.fr(1)),
              ),
              TableField(
                key: 'labels',
                label: 'Labels',
                groupId: 'node',
                size: GridAxisVariable(size: LayoutSize.fr(1)),
              ),
              TableField(
                key: 'classification',
                groupId: 'node',
                size: GridAxisVariable(size: LayoutSize.fr(1)),
              ),
              TableField(
                key: 'version',
                groupId: 'node',
                size: GridAxisVariable(size: LayoutSize.fr(0.5)),
              ),
              TableField(
                key: 'node_count',
                label: 'Nodes',
                groupId: 'system',
                size: GridAxisVariable(size: LayoutSize.fr(1)),
              ),
              TableField(
                key: 'neo4j_labels',
                label: 'Labels',
                groupId: 'system',
                size: GridAxisVariable(size: LayoutSize.fr(1)),
              ),
              TableField(
                key: 'node_property_count',
                label: 'Node properties',
                groupId: 'system',
                size: GridAxisVariable(size: LayoutSize.fr(1)),
              ),
              TableField(
                key: 'go_version',
                label: 'Go version',
                groupId: 'system',
                size: GridAxisVariable(size: LayoutSize.fr(1)),
              ),
              TableField(
                key: 'neo4j_version',
                label: 'Neo4j version',
                groupId: 'system',
                size: GridAxisVariable(size: LayoutSize.fr(1)),
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
      aliases: ['safe-area'],
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
              condition: LayoutCondition.noSelectedNode(),
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
              condition: LayoutCondition.noSelectedNode(),
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
              condition: LayoutCondition.noSelectedNode(),
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
              condition: LayoutCondition.noSelectedNode(),
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
        'top-plane': LayoutPath(
          aliases: ['top-plane', 'control-plane', 'north-plane'],
          points: [
            LayoutDerivativeReference(derivative: 'B'),
            LayoutDerivativeReference(
              layoutPath: ['safe-area'],
              derivative: 'leftPlane.top',
            ),
            LayoutDerivativeReference(
              layoutPath: ['safe-area'],
              derivative: 'rightPlane.top',
            ),
            LayoutDerivativeReference(derivative: 'C'),
          ],
          style: LayoutPathStyle(
            fillColor: lgErgoControlPlaneBandColor,
            strokeStyle: lgErgoPlaneLineStyle,
          ),
          layouts: {
            'cortex-bush': FanLayout(
              aliases: [
                'cortex-tree',
                'fan-layout',
                'cortex-bush',
                'top-node-tree',
                'top-fan',
              ],
              style: lgErgoCortexNodeBorderStyle,
              layoutDefaults: lgErgoNodeLayoutDefaults,
              rootNodeFilter: lgErgoCortexRootNodeFilter,
              traverseBy: GraphTraverseType.partOf,
              nodeFilter: lgErgoCortexBushNodeFilter,
              maxDepth: 3,
              maxSectionCount: 4,
              sectionSizing: FanSectionSizing.directPartsWeighted,
              label: 'cortex',
              labelColor: lgErgoCortexNodeLabelColor,
              labelSize: 10,
              gridStyle: lgErgoFanGridStyle,
              position: LayoutRelativePosition.top,
            ),
          },
        ),
        'bottom-plane': LayoutPath(
          aliases: ['bottom-plane', 'time-plane', 'x-axis-plane'],
          points: [
            LayoutDerivativeReference(derivative: 'A'),
            LayoutDerivativeReference(
              layoutPath: ['safe-area'],
              derivative: 'leftPlane.bottom',
            ),
            LayoutDerivativeReference(
              layoutPath: ['safe-area'],
              derivative: 'rightPlane.bottom',
            ),
            LayoutDerivativeReference(derivative: 'D'),
          ],
          style: LayoutPathStyle(
            fillColor: Color(0x55C59A1A),
            strokeStyle: lgErgoPlaneLineStyle,
          ),
          layouts: {
            'time-fan': FanLayout(
              aliases: [
                'time-tree',
                'fan-layout',
                'time-bush',
                'space-time-fan',
                'space-time-tree',
                'bottom-node-tree',
                'bottom-fan',
                'space-tree',
              ],
              style: lgErgoCortexNodeBorderStyle,
              layoutDefaults: lgErgoNodeLayoutDefaults,
              rootNodeFilter: lgErgoCortexRootNodeFilter,
              traverseBy: GraphTraverseType.partOf,
              nodeFilter: const NodeSearchFilter.reverseOf(
                lgErgoCortexBushNodeFilter,
              ),
              maxDepth: 3,
              maxSectionCount: 4,
              sectionSizing: FanSectionSizing.equal,
              label: 'space-time',
              labelColor: lgErgoCortexNodeLabelColor,
              labelSize: 10,
              gridStyle: lgErgoFanGridStyle,
              position: LayoutRelativePosition.bottom,
            ),
          },
        ),
        'inner-circle-plane': PlaneLayout(
          aliases: ['inner-circle-plane', 'scene-plane', 'circle-plane'],
          visibility: [LayoutCondition.hasActiveNodes()],
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
              attributes: [LayoutAttribute.rectangular],
              shape: LayoutShape.square,
              style: randomBlueprintAesthetics.layoutStyle,
              backgroundColor: Color(0x00000000),
              borderColor: Color(0x00000000),
              resolvedBorderColor: Color(0x00000000),
              borderWidth: 0,
              wrapPadding: 0,
              showGeometryGuides: true,
              layouts: {
                'scene-graph-plane': LayoutPath(
                  aliases: [
                    'scene-graph-plane',
                    'selected-node-plane',
                    'graph-plane',
                  ],
                  points: [
                    LayoutDerivativeReference(
                      layoutPath: [
                        'safe-area',
                        'inner-circle-plane',
                        'wrapped-scene-square',
                      ],
                      derivative: 'A',
                    ),
                    LayoutDerivativeReference(
                      layoutPath: [
                        'safe-area',
                        'inner-circle-plane',
                        'wrapped-scene-square',
                      ],
                      derivative: 'B',
                    ),
                    LayoutDerivativeReference(
                      layoutPath: [
                        'safe-area',
                        'inner-circle-plane',
                        'wrapped-scene-square',
                      ],
                      derivative: 'C',
                    ),
                    LayoutDerivativeReference(
                      layoutPath: [
                        'safe-area',
                        'inner-circle-plane',
                        'wrapped-scene-square',
                      ],
                      derivative: 'D',
                    ),
                  ],
                  layouts: {
                    'scene-graph': GraphLayout(
                      aliases: [
                        'scene-graph',
                        'node-scene',
                        'selected-node-graph',
                        'selected-node-pool',
                        'graph-layout',
                      ],
                      style: lgErgoCortexNodeBorderStyle,
                      layoutDefaults: lgErgoNodeLayoutDefaults,
                      nodeExtentFactor: 0.5,
                      labelColor: lgErgoCortexNodeLabelColor,
                      labelSize: 10,
                      visibility: [
                        LayoutCondition.not(LayoutCondition.noSelectedNode()),
                      ],
                    ),
                  },
                ),
                // 'subject-field-circle': PlaneLayout(
                //   aliases: ['subject-field', 'subject-field-circle'],
                //   shape: LayoutShape.circle,
                //   style: randomBlueprintAesthetics.layoutStyle,
                //   backgroundColor: Color(0x00000000),
                //   borderColor: Color(0x00000000),
                //   resolvedBorderColor: Color(0x00000000),
                //   borderWidth: 0,
                //   wrapPadding: 0,
                //   showGeometryGuides: true,
                //   layouts: {
                //     'subject-core-square': PlaneLayout(
                //       aliases: ['subject-core', 'subject-core-square'],
                //       shape: LayoutShape.square,
                //       style: randomBlueprintAesthetics.layoutStyle,
                //       backgroundColor: Color(0x00000000),
                //       borderColor: Color(0x00000000),
                //       resolvedBorderColor: Color(0x00000000),
                //       borderWidth: 0,
                //       wrapPadding: 0,
                //       showGeometryGuides: true,
                //       layouts: {
                //         'scene-subject': PlaneLayout(
                //           aliases: [
                //             'subject',
                //             'scene-subject',
                //             'project-subject',
                //           ],
                //           shape: LayoutShape.circle,
                //           style: randomBlueprintAesthetics.layoutStyle,
                //           backgroundColor: Color(0xFFFFFBEA),
                //           borderColor: Color(0xAA303030),
                //           resolvedBorderColor: Color(0xAA303030),
                //           borderWidth: 2,
                //           wrapPadding: 0,
                //           showGeometryGuides: true,
                //         ),
                //       },
                //     ),
                //   },
                // ),
              },
            ),
          },
        ),
        'inner-circle': LayoutBorderGuide(
          visibility: [LayoutCondition.hasActiveNodes()],
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

const lgErgoCortexRootNodeFilter = NodeSearchFilter.allOf([
  NodeSearchParameter(
    parameter: NodeParameter.slug,
    value: 'cortex-timeline-calendar-2026-06-fr6h',
    operator: NodeMatchOperator.exact,
  ),
  NodeSearchParameter(
    parameter: NodeParameter.label,
    value: 'Calendar',
    operator: NodeMatchOperator.contains,
  ),
]);

const lgErgoSpaceTimeSectionNodeMatches = <NodeSearchParameter>[
  NodeSearchParameter(
    parameter: NodeParameter.slug,
    value: 'space',
    operator: NodeMatchOperator.contains,
  ),
  NodeSearchParameter(
    parameter: NodeParameter.slug,
    value: 'space-section',
    operator: NodeMatchOperator.contains,
  ),
  NodeSearchParameter(
    parameter: NodeParameter.slug,
    value: 'time',
    operator: NodeMatchOperator.contains,
  ),
  NodeSearchParameter(
    parameter: NodeParameter.slug,
    value: 'time-section',
    operator: NodeMatchOperator.contains,
  ),
];

const lgErgoCortexBushNodeFilter = NodeSearchFilter.anyOf([
  NodeSearchParameter(parameter: NodeParameter.label, value: 'Section'),
], excluding: lgErgoSpaceTimeSectionNodeMatches);

const lgErgoLayoutDefaultPadding = 20.0;
const lgErgoLayoutDefaultGap = 20.0;
const lgErgoLayoutDefaultBorderWidth = 1.2;
const lgErgoLayoutDefaults = LayoutDefaults(
  padding: lgErgoLayoutDefaultPadding,
  gap: lgErgoLayoutDefaultGap,
  borderWidth: lgErgoLayoutDefaultBorderWidth,
  backgrounds: [
    LayoutImageBackground(
      assetPath: 'assets/wallpapers/dark-vintage-scheme.jpg',
      fit: LayoutBackgroundFit.cover,
    ),
  ],
);
const lgErgoNodeBorderWidth = 1.8;
const lgErgoClassificationLabelColors = [
  Color(0xFF3F51B5),
  Color(0xFF2E7D32),
  Color(0xFFC59A1A),
  Color(0xFF8F3E4B),
  Color(0xFF7B4FA3),
  Color(0xFF287A78),
];
const lgErgoClassificationLabelBorderColor = Color(0xFFE8D59F);
const lgErgoClassificationLabelHoleColor = Color(0xFF27251F);
const lgErgoClassificationLabelTextColor = Color(0xFFF5F7FF);
const lgErgoNodeLayoutDefaults = LayoutDefaults(
  borderWidth: lgErgoNodeBorderWidth,
  nodeSlugPrefix: '[[',
  nodeSlugSuffix: ']]',
  classificationLabelColors: lgErgoClassificationLabelColors,
  classificationLabelBorderColor: lgErgoClassificationLabelBorderColor,
  classificationLabelHoleColor: lgErgoClassificationLabelHoleColor,
  classificationLabelTextColor: lgErgoClassificationLabelTextColor,
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

const lgErgoNodeInfoTableStyle = GuideStyle(
  color: Color(0x665F7CFF),
  strokeWidth: 1,
  pattern: GuideLinePattern.solid,
);

const lgErgoNodeInfoCellHighlightColor = Color(0x66374A9B);

const lgErgoCortexNodeBorderStyle = GuideStyle(
  color: Color(0xFFFFF7D6),
  strokeWidth: lgErgoNodeBorderWidth,
  pattern: GuideLinePattern.solid,
);

const lgErgoHighlightedNodeBorderStyle = GuideStyle(
  color: Color(0xFF2196F3),
  strokeWidth: 4,
  pattern: GuideLinePattern.solid,
);

const lgErgoFanGridStyle = GuideStyle(
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
