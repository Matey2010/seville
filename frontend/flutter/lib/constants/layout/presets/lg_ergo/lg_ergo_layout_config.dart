import 'dart:ui';

import '../../../../models/layout/layout.dart';
import '../../../interface_colors.dart';
import '../../../typography.dart';

final lgErgoLayoutConfig = LandscapeXlLayout(
  aliases: ['screen', 'root', 'reality', 'user-space', 'user-reality'],
  label: const LabelConfig(
    state: {
      LayoutCondition.always(): LabelConfig(
        style: LabelStyle(
          color: Color(0xFFF5EDD6),
          borderStyle: GuideStyle(
            color: Color(0xFFA87A4C),
            strokeWidth: 1,
            pattern: GuideLinePattern.solid,
          ),
          holeColor: Color(0xFF27251F),
        ),
      ),
      LayoutCondition.isIn(['Science', 'Research', 'Player']): LabelConfig(
        style: LabelStyle(color: Color(0xFF7B4FA3)),
      ),
      LayoutCondition.isIn(['Research', 'Science', 'Player']): LabelConfig(
        style: LabelStyle(color: Color(0xFF7B4FA3)),
      ),
      LayoutCondition.isIn(['Person', 'Human']): LabelConfig(
        style: LabelStyle(color: Color(0xFFE8BEAC)),
      ),
      LayoutCondition.isIn(['Town', 'City']): LabelConfig(
        style: LabelStyle(color: Color(0xFF9E9E9E)),
      ),
      LayoutCondition.equalsTo('Emoji'): LabelConfig(
        style: LabelStyle(color: Color(0xFFFFD54F)),
      ),
      LayoutCondition.equalsTo('Business'): LabelConfig(
        style: LabelStyle(color: Color(0xFFFFD54F)),
      ),
      LayoutCondition.equalsTo('Culture'): LabelConfig(
        style: LabelStyle(color: Color(0xFFE91E63)),
      ),
      LayoutCondition.equalsTo('Security'): LabelConfig(
        style: LabelStyle(color: Color(0xFF1A237E)),
      ),
      LayoutCondition.labelHighlighted(): LabelConfig(
        style: LabelStyle(
          borderStyle: GuideStyle(
            color: Color(0xFFFFD54F),
            strokeWidth: 2,
            pattern: GuideLinePattern.solid,
          ),
        ),
      ),
    },
  ),
  text: const LayoutTextConfig(
    color: Color(0xFFFFF8E7),
    darkColor: Color(0xFF27251F),
    lightColor: Color(0xFFFFF8E7),
    fontFamily: SevilleTypography.fontFamily,
  ),
  node: const NodeConfig(
    style: NodeStyle(
      slugColor: Color(0xFFFFD54F),
      labelColor: Color(0xFFFFF8E7),
      valueColor: Color(0xFFFFF8E7),
      slugPrefix: '[[',
      slugTransform: TextTransform.capitalCap(),
      slugSuffix: ']]',
    ),
    state: {
      LayoutCondition.nodeHighlighted(): NodeConfig(
        style: NodeStyle(
          borderStyle: GuideStyle(
            color: Color(0xFF2196F3),
            strokeWidth: 4,
            pattern: GuideLinePattern.solid,
          ),
        ),
      ),
    },
  ),
  panel: const PanelConfig(
    foldedPanelSize: LayoutSize.twoDimensional(
      primary: LayoutSize.fr(0.33),
      secondary: LayoutSize.fr(0.33),
    ),
  ),
  attributes: [LayoutAttribute.screen, LayoutAttribute.rectangular],

  background: [
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
          style: (GuideStyle(
            color: guidelineRedColor,
            strokeWidth: 1.2,
            pattern: GuideLinePattern.dashed,
            dashLength: 8,
            dashInterval: 6,
          )),
        ),
        LayoutBackgroundGuide(
          start: Offset(0.5, 0),
          end: Offset(0.5, 1),
          style: (GuideStyle(
            color: guidelineRedColor,
            strokeWidth: 1.2,
            pattern: GuideLinePattern.dashed,
            dashLength: 8,
            dashInterval: 6,
          )),
        ),
        LayoutBackgroundGuide(
          start: Offset(0, 0),
          end: Offset(1, 1),
          style: (GuideStyle(
            color: perceptualMapDiagonalColor,
            strokeWidth: 1,
            pattern: GuideLinePattern.dashed,
            dashLength: 7,
            dashInterval: 6,
          )),
        ),
        LayoutBackgroundGuide(
          start: Offset(0, 1),
          end: Offset(1, 0),
          style: (GuideStyle(
            color: perceptualMapDiagonalColor,
            strokeWidth: 1,
            pattern: GuideLinePattern.dashed,
            dashLength: 7,
            dashInterval: 6,
          )),
        ),
      ],
    ),
  ],
  layoutPadding: 20,
  layoutGap: 20,
  layoutBorderWidth: 1.2,
  derivativeSnapshot: 'screen-edge-centers',
  derivatives: {
    'screen-edge-centers': LayoutDerivativeSnapshot(
      values: {
        'AD-center': MidpointDerivative(from: 'A', to: 'D'),
        'BC-center': MidpointDerivative(from: 'B', to: 'C'),
      },
    ),
  },
  children: {
    'safe-area': SafeAreaLayout(
      aliases: ['safe-area'],
      layoutPadding: 20,
      layoutGap: 20,
      layoutBorderWidth: 1.2,
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
      children: {
        'search-layout': SearchLayout(
          aliases: ['search-layout', 'search-overlay', 'search-hud'],
          layoutBorderWidth: 1.8,
          nodeHoverBorderStyle: (GuideStyle(
            color: Color(0xFF2196F3),
            strokeWidth: 4,
            pattern: GuideLinePattern.solid,
          )),
          node: const NodeConfig(
            style: NodeStyle(
              slugPrefix: '[[',
              slugTransform: TextTransform.capitalCap(),
              slugSuffix: ']]',
            ),
          ),
          children: {
            SearchLayout.searchResultsLayoutKey: TableLayout(
              aliases: ['search-results', 'search-results-table'],
              layoutBorderWidth: 1.8,
              nodeHoverBorderStyle: (GuideStyle(
                color: Color(0xFF2196F3),
                strokeWidth: 4,
                pattern: GuideLinePattern.solid,
              )),
              guideStyle: (GuideStyle(
                color: Color(0x665F7CFF),
                strokeWidth: 1,
                pattern: GuideLinePattern.solid,
              )),
              cellHighlight: TableCellHighlightConfig(
                rows: true,
                color: (Color(0x66374A9B)),
              ),
              panelGap: (12.0),
              panelBorderStyle: (GuideStyle(
                color: Color(0xAA5F7CFF),
                strokeWidth: 1.4,
                pattern: GuideLinePattern.solid,
              )),
              tableConfig: TableConfig(
                panels: {
                  'search_results': PanelConfig(
                    size: LayoutSize.fr(1),
                    title: 'Search Results',
                  ),
                },
                rowConfig: TableRowConfig(
                  rows: {
                    'search_results': TableRow(
                      label: 'Results',
                      panelId: 'search_results',
                      size: LayoutSize.fr(1),
                    ),
                  },
                ),
                columnConfig: TableColumnConfig(
                  columns: {
                    'key': TableColumn(size: LayoutSize.fr(1)),
                    'value': TableColumn(size: LayoutSize.fr(3)),
                  },
                ),
              ),
              children: {
                'search_results': NodeListLayout(
                  dataSource: NodeListDataSource.searchResults,
                  style: (GuideStyle(
                    color: Color(0xFFFFF7D6),
                    strokeWidth: (1.8),
                    pattern: GuideLinePattern.solid,
                  )),
                  layoutBorderWidth: 1.8,
                  nodeHoverBorderStyle: (GuideStyle(
                    color: Color(0xFF2196F3),
                    strokeWidth: 4,
                    pattern: GuideLinePattern.solid,
                  )),
                  node: const NodeConfig(
                    style: NodeStyle(
                      slugPrefix: '[[',
                      slugTransform: TextTransform.capitalCap(),
                      slugSuffix: ']]',
                    ),
                  ),
                ),
              },
            ),
          },
        ),
        'top-plane': LayoutPath(
          aliases: ['top-plane', 'control-plane', 'north-plane'],
          points: [
            LayoutDerivativeReference(derivative: 'B'),
            LayoutDerivativeReference(derivative: 'C'),
          ],
          style: LayoutPathStyle(
            fillColor: (Color(0x00000000)),
            strokeStyle: (GuideStyle(
              color: Color(0xAAC59A1A),
              strokeWidth: 1.2,
              pattern: GuideLinePattern.solid,
            )),
          ),
          curves: [
            LayoutPathCurve(
              from: LayoutDerivativeReference(derivative: 'B'),
              through: LayoutDerivativeReference(
                layoutPath: ['safe-area'],
                derivative: 'innerSquare.BC-center',
              ),
              to: LayoutDerivativeReference(derivative: 'C'),
            ),
          ],
          children: {
            'cortex-bush': FanLayout(
              aliases: [
                'cortex-tree',
                'fan-layout',
                'cortex-bush',
                'top-node-tree',
                'top-fan',
              ],
              style: (GuideStyle(
                color: Color(0xFFFFF7D6),
                strokeWidth: (1.8),
                pattern: GuideLinePattern.solid,
              )),
              layoutBorderWidth: 1.8,
              nodeHoverBorderStyle: (GuideStyle(
                color: Color(0xFF2196F3),
                strokeWidth: 4,
                pattern: GuideLinePattern.solid,
              )),
              rootNodeFilter: (NodeSearchFilter.allOf([
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
              ])),
              traverseBy: GraphTraverseType.partOf,
              nodeFilter: (NodeSearchFilter.anyOf(
                [
                  NodeSearchParameter(
                    parameter: NodeParameter.label,
                    value: 'Section',
                  ),
                ],
                excluding: (<NodeSearchParameter>[
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
                ]),
              )),
              maxDepth: 3,
              maxSectionCount: 4,
              sectionSizing: FanSectionSizing.directPartsWeighted,
              caption: 'cortex',
              labelSize: lgErgoNodeFontSize,
              gridStyle: (GuideStyle(
                color: Color(0x88FFD54F),
                strokeWidth: 0.9,
                pattern: GuideLinePattern.dashed,
                dashLength: 5,
                dashInterval: 5,
              )),
              position: LayoutRelativePosition.top,
            ),
          },
        ),
        'bottom-plane': LayoutPath(
          aliases: ['bottom-plane', 'time-plane', 'x-axis-plane'],
          curves: [
                        LayoutPathCurve(
              from: LayoutDerivativeReference(derivative: 'D'),
              through: LayoutDerivativeReference(
                layoutPath: ['safe-area'],
                derivative: 'innerSquare.AD-center',
              ),
              to: LayoutDerivativeReference(derivative: 'A'),
            ),
          ],
          points: [
            LayoutDerivativeReference(derivative: 'A'),
            LayoutDerivativeReference(derivative: 'D'),
          ],
          style: LayoutPathStyle(
            fillColor: Color(0x55C59A1A),
            strokeStyle: (GuideStyle(
              color: Color(0xAAC59A1A),
              strokeWidth: 1.2,
              pattern: GuideLinePattern.solid,
            )),
          ),
          children: {
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
              style: (GuideStyle(
                color: Color(0xFFFFF7D6),
                strokeWidth: (1.8),
                pattern: GuideLinePattern.solid,
              )),
              layoutBorderWidth: 1.8,
              nodeHoverBorderStyle: (GuideStyle(
                color: Color(0xFF2196F3),
                strokeWidth: 4,
                pattern: GuideLinePattern.solid,
              )),
              rootNodeFilter: (NodeSearchFilter.allOf([
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
              ])),
              traverseBy: GraphTraverseType.partOf,
              nodeFilter: const NodeSearchFilter.reverseOf(
                (NodeSearchFilter.anyOf(
                  [
                    NodeSearchParameter(
                      parameter: NodeParameter.label,
                      value: 'Section',
                    ),
                  ],
                  excluding: (<NodeSearchParameter>[
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
                  ]),
                )),
              ),
              maxDepth: 3,
              maxSectionCount: 4,
              sectionSizing: FanSectionSizing.equal,
              caption: 'space-time',
              labelSize: lgErgoNodeFontSize,
              gridStyle: (GuideStyle(
                color: Color(0x88FFD54F),
                strokeWidth: 0.9,
                pattern: GuideLinePattern.dashed,
                dashLength: 5,
                dashInterval: 5,
              )),
              position: LayoutRelativePosition.bottom,
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
          style: (GuideStyle(
            color: Color(0xCC8E44AD),
            strokeWidth: 1.2,
            pattern: GuideLinePattern.dashed,
            dashLength: 6,
            dashInterval: 5,
          )),
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
        'panoramic-scene-plane': LayoutPath(
          aliases: [
            'panoramic-scene-plane',
            'panorama-plane',
            'curved-scene-plane',
          ],
          background: [
            LayoutImageBackground(
              assetPath: 'assets/wallpapers/sims-4-interface.png',
              opacity: 0.78,
              fit: LayoutBackgroundFit.fill,
            ),
          ],
          points: [
            LayoutDerivativeReference(derivative: 'A'),
            LayoutDerivativeReference(derivative: 'B'),
            LayoutDerivativeReference(derivative: 'C'),
            LayoutDerivativeReference(derivative: 'D'),
          ],
          curves: [
            LayoutPathCurve(
              from: LayoutDerivativeReference(derivative: 'B'),
              through: LayoutDerivativeReference(
                layoutPath: ['safe-area'],
                derivative: 'innerSquare.BC-center',
              ),
              to: LayoutDerivativeReference(derivative: 'C'),
            ),
            LayoutPathCurve(
              from: LayoutDerivativeReference(derivative: 'D'),
              through: LayoutDerivativeReference(
                layoutPath: ['safe-area'],
                derivative: 'innerSquare.AD-center',
              ),
              to: LayoutDerivativeReference(derivative: 'A'),
            ),
          ],
          style: LayoutPathStyle(
            fillColor: Color(0x00000000),
            strokeStyle: GuideStyle(
              color: Color(0xAAC59A1A),
              strokeWidth: 1.2,
              pattern: GuideLinePattern.solid,
            ),
          ),
          children: {
            'direction-pad': GridLayout(
              rowsConfig: {
                'top': LayoutSize.fr(1),
                'center': LayoutSize.fr(1),
                'bottom': LayoutSize.fr(1),
              },
              columnsConfig: {
                'left': LayoutSize.fr(1),
                'center': LayoutSize.fr(2),
                'right': LayoutSize.fr(1),
              },
              areas: {
                'info-grid': GridArea(
                  row: 'top',
                  column: 'left',
                  rowSpan: GridSpan.full,
                ),
                'scene-graph': GridArea(
                  row: 'top',
                  column: 'center',
                  rowSpan: GridSpan.full,
                ),
                'action-panel': GridArea(
                  row: 'top',
                  column: 'right',
                  rowSpan: GridSpan.full,
                ),
                'top-left': GridArea(row: 'top', column: 'left'),
                'top-center': GridArea(row: 'top', column: 'center'),
                'top-right': GridArea(row: 'top', column: 'right'),
                'center-left': GridArea(row: 'center', column: 'left'),
                'center': GridArea(row: 'center', column: 'center'),
                'center-right': GridArea(row: 'center', column: 'right'),
                'bottom-left': GridArea(row: 'bottom', column: 'left'),
                'bottom-center': GridArea(row: 'bottom', column: 'center'),
                'bottom-right': GridArea(row: 'bottom', column: 'right'),
              },
              aliases: [
                'panoramic-grid',
                'direction-pad',
                'node-direction-controls',
                'spatial-navigation',
              ],
              children: {
                'action-panel': ColumnLayout(
                  layoutPadding: 20,
                  aliases: [
                    'action-panel',
                    'action-pane',
                    'action-plane',
                    'form-panel',
                    'form-pane',
                    'form-plane',
                    'right-plane',
                    'east-plane',
                    'action-column',
                    'action-panel-column',
                    'form-column',
                  ],
                  children: {
                    'navigation-row': RowLayout(
                      size: LayoutSize.px(48),
                      aliases: ['navigation-row', 'browser-navigation'],
                      children: {
                        'refresh-fans': PanelLayout(
                          size: LayoutSize.fr(1),
                          aliases: [
                            'action-button',
                            'refresh-action',
                            'refresh-fan-data',
                          ],
                          fillColor: (Color(0x553F51B5)),
                          borderStyle: (GuideStyle(
                            color: Color(0xCCB7C2FF),
                            strokeWidth: 1,
                            pattern: GuideLinePattern.solid,
                          )),
                          caption: '🔄',
                          labelColor: ((Color(0xFFFFF8E7))),
                          labelSize: 18,
                        ),
                        'search': PanelLayout(
                          size: LayoutSize.fr(1),
                          aliases: [
                            'action-button',
                            'search-action',
                            'open-search-hud',
                          ],
                          fillColor: (Color(0x553F51B5)),
                          borderStyle: (GuideStyle(
                            color: Color(0xCCB7C2FF),
                            strokeWidth: 1,
                            pattern: GuideLinePattern.solid,
                          )),
                          caption: '🔍',
                          labelColor: ((Color(0xFFFFF8E7))),
                          labelSize: 18,
                        ),
                        'add-node': PanelLayout(
                          size: LayoutSize.fr(1),
                          aliases: [
                            'action-button',
                            'add-action',
                            'create-virtual-node',
                          ],
                          fillColor: (Color(0x6652A66B)),
                          borderStyle: (GuideStyle(
                            color: Color(0xCCB7C2FF),
                            strokeWidth: 1,
                            pattern: GuideLinePattern.solid,
                          )),
                          caption: 'Add',
                          labelColor: ((Color(0xFFFFF8E7))),
                          labelSize: 12,
                        ),
                        'today': PanelLayout(
                          size: LayoutSize.fr(1),
                          aliases: [
                            'action-button',
                            'today-action',
                            'resolve-today-node',
                          ],
                          fillColor: (Color(0x553F51B5)),
                          borderStyle: (GuideStyle(
                            color: Color(0xCCB7C2FF),
                            strokeWidth: 1,
                            pattern: GuideLinePattern.solid,
                          )),
                          caption: 'Today',
                          labelColor: ((Color(0xFFFFF8E7))),
                          labelSize: 12,
                        ),
                        'confirm': PanelLayout(
                          size: LayoutSize.fr(1),
                          aliases: [
                            'action-button',
                            'confirm-action',
                            'submit-action',
                            'create-first-virtual-node',
                          ],
                          fillColor: (Color(0x6652A66B)),
                          borderStyle: (GuideStyle(
                            color: Color(0xCCB7C2FF),
                            strokeWidth: 1,
                            pattern: GuideLinePattern.solid,
                          )),
                          caption: '✅',
                          labelColor: ((Color(0xFFFFF8E7))),
                          labelSize: 18,
                        ),
                        'close-selection': PanelLayout(
                          size: LayoutSize.fr(1),
                          aliases: [
                            'action-button',
                            'close-action',
                            'cancel-interface-action',
                            'clear-selection-action',
                          ],
                          fillColor: (Color(0x668F3E4B)),
                          borderStyle: (GuideStyle(
                            color: Color(0xCCB7C2FF),
                            strokeWidth: 1,
                            pattern: GuideLinePattern.solid,
                          )),
                          caption: '×',
                          labelColor: ((Color(0xFFFFF8E7))),
                          labelSize: 18,
                        ),
                      },
                    ),
                    'node-actions-row': RowLayout(
                      size: LayoutSize.px(48),
                      aliases: ['node-actions', 'node-actions-row'],
                      children: {
                        'copy': PanelLayout(
                          size: LayoutSize.fr(1),
                          aliases: [
                            'action-button',
                            'selected-node-action',
                            'copy-action',
                            'copy-selected-node-slug',
                          ],
                          fillColor: (Color(0x553F51B5)),
                          borderStyle: (GuideStyle(
                            color: Color(0xCCB7C2FF),
                            strokeWidth: 1,
                            pattern: GuideLinePattern.solid,
                          )),
                          caption: '📋',
                          labelColor: ((Color(0xFFFFF8E7))),
                          labelSize: 18,
                        ),
                        'share': PanelLayout(
                          size: LayoutSize.fr(1),
                          aliases: [
                            'action-button',
                            'selected-node-action',
                            'share-action',
                          ],
                          fillColor: (Color(0x553F51B5)),
                          borderStyle: (GuideStyle(
                            color: Color(0xCCB7C2FF),
                            strokeWidth: 1,
                            pattern: GuideLinePattern.solid,
                          )),
                          caption: '📤',
                          labelColor: ((Color(0xFFFFF8E7))),
                          labelSize: 18,
                        ),
                      },
                    ),
                  },
                ),
                'info-grid': TableLayout(
                  aliases: [
                    'info-grid',
                    'info-table',
                    'info-panel',
                    'info-pane',
                    'info-plane',
                    'left-plane',
                    'west-plane',
                    'table-layout',
                    'node-info',
                    'system-info',
                  ],
                  background: [
                    LayoutImageBackground(
                      assetPath: 'assets/wallpapers/daft-punk-suit.jpg',
                      fit: LayoutBackgroundFit.contain,
                      opacity: 0.34,
                    ),
                  ],
                  layoutBorderWidth: 1.8,
                  nodeHoverBorderStyle: GuideStyle(
                    color: Color(0xFF2196F3),
                    strokeWidth: 4,
                    pattern: GuideLinePattern.solid,
                  ),
                  guideStyle: GuideStyle(
                    color: Color(0x665F7CFF),
                    strokeWidth: 1,
                    pattern: GuideLinePattern.solid,
                  ),
                  cellHighlight: TableCellHighlightConfig(
                    rows: true,
                    // columns: true,
                    color: Color(0x66374A9B),
                  ),
                  includeUnconfiguredFields: true,
                  unconfiguredFieldPanelId: 'last_selected_node',
                  panelGap: 12.0,
                  panelBorderStyle: GuideStyle(
                    color: Color(0xAA5F7CFF),
                    strokeWidth: 1.4,
                    pattern: GuideLinePattern.solid,
                  ),
                  tableConfig: TableConfig(
                    panels: {
                      'last_selected_node': PanelConfig(
                        orderPosition: 0,
                        title: 'Last Selected Node',
                        foldable: true,
                      ),
                      'updates': PanelConfig(
                        orderPosition: 2,
                        title: 'Updates',
                        foldable: true,
                      ),
                      'selected_nodes': PanelConfig(
                        orderPosition: 3,
                        title: 'Selected Nodes',
                        foldable: true,
                      ),
                      'me': PanelConfig(
                        orderPosition: 4,
                        title: 'Me',
                        showEmpty: true,
                      ),
                      'settings': PanelConfig(
                        orderPosition: 5,
                        title: 'Settings',
                        showEmpty: true,
                      ),
                      'system': PanelConfig(
                        orderPosition: 6,
                        title: 'System',
                        foldable: true,
                        initiallyFolded: true,
                      ),
                      /* Previous right action-plane implementation, retained here for
                         the next global Panel action migration:
                      'me': PanelLayout(
                        size: LayoutSize.fr(1),
                        aliases: [
                          'action-button',
                          'player-action',
                          'resolve-player-node',
                        ],
                        fillColor: Color(0x553F51B5),
                        borderStyle: GuideStyle(
                          color: Color(0xCCB7C2FF),
                          strokeWidth: 1,
                          pattern: GuideLinePattern.solid,
                        ),
                        caption: 'Me',
                        labelColor: Color(0xFFFFF8E7),
                        labelSize: 12,
                      ),
                      */
                    },
                    rowConfig: TableRowConfig(
                      rows: {
                        'slug': TableRow(
                          orderPosition: 0,
                          label: 'Slug',
                          panelId: 'last_selected_node',
                          size: LayoutSize.fr(1),
                          actions: [TableAction.copyToClipboard()],
                        ),
                        'labels': TableRow(
                          orderPosition: 1,
                          label: 'Labels',
                          panelId: 'last_selected_node',
                          size: LayoutSize.fr(1),
                        ),
                        'classification': TableRow(
                          orderPosition: 2,
                          panelId: 'last_selected_node',
                          size: LayoutSize.fr(1),
                        ),
                        'version': TableRow(
                          orderPosition: 3,
                          panelId: 'last_selected_node',
                          size: LayoutSize.fr(0.5),
                        ),
                        'selected_node_slugs': TableRow(
                          orderPosition: 0,
                          label: 'Slugs',
                          panelId: 'selected_nodes',
                          size: LayoutSize.fr(1),
                        ),
                        'selected_node_labels': TableRow(
                          orderPosition: 1,
                          label: 'Labels',
                          panelId: 'selected_nodes',
                          size: LayoutSize.fr(1),
                        ),
                        'added': TableRow(
                          orderPosition: 0,
                          label: 'Added',
                          panelId: 'updates',
                          includeWhenEmpty: true,
                          size: LayoutSize.fr(1),
                        ),
                        'updated': TableRow(
                          orderPosition: 1,
                          label: 'Updated',
                          panelId: 'updates',
                          includeWhenEmpty: true,
                          size: LayoutSize.fr(1),
                        ),
                        'deleted': TableRow(
                          orderPosition: 2,
                          label: 'Deleted',
                          panelId: 'updates',
                          includeWhenEmpty: true,
                          size: LayoutSize.fr(1),
                        ),
                        'node_count': TableRow(
                          orderPosition: 0,
                          label: 'Nodes',
                          panelId: 'system',
                          size: LayoutSize.fr(1),
                        ),
                        'neo4j_labels': TableRow(
                          orderPosition: 1,
                          label: 'Trending Labels',
                          panelId: 'system',
                          size: LayoutSize.fr(1),
                        ),
                        'node_property_count': TableRow(
                          orderPosition: 2,
                          label: 'Node properties',
                          panelId: 'system',
                          size: LayoutSize.fr(1),
                        ),
                        'go_version': TableRow(
                          orderPosition: 3,
                          label: 'Go version',
                          panelId: 'system',
                          size: LayoutSize.fr(1),
                        ),
                        'neo4j_version': TableRow(
                          orderPosition: 4,
                          label: 'Neo4j version',
                          panelId: 'system',
                          size: LayoutSize.fr(1),
                        ),
                      },
                    ),
                    columnConfig: TableColumnConfig(
                      columns: {
                        'key': TableColumn(size: LayoutSize.fr(1)),
                        'value': TableColumn(size: LayoutSize.fr(3)),
                      },
                    ),
                  ),
                  children: {
                    'added': NodeListLayout(
                      dataSource: NodeListDataSource.virtualNodes,
                      style: GuideStyle(
                        color: Color(0xFFFFF7D6),
                        strokeWidth: 1.8,
                        pattern: GuideLinePattern.solid,
                      ),
                      layoutBorderWidth: 1.8,
                      nodeHoverBorderStyle: GuideStyle(
                        color: Color(0xFF2196F3),
                        strokeWidth: 4,
                        pattern: GuideLinePattern.solid,
                      ),
                      node: const NodeConfig(
                        style: NodeStyle(
                          slugPrefix: '[[',
                          slugTransform: TextTransform.capitalCap(),
                          slugSuffix: ']]',
                        ),
                      ),
                      aliases: [
                        'virtual-nodes',
                        'draft-nodes',
                        'uncreated-nodes',
                      ],
                    ),
                  },
                ),
                'scene-graph': GraphLayout(
                  background: [
                    LayoutImageBackground(
                      assetPath: 'assets/wallpapers/dark-vintage-scheme.jpg',
                      fit: LayoutBackgroundFit.cover,
                      opacity: 0.78,
                    ),
                    LayoutImageBackground(
                      assetPath: 'assets/wallpapers/helmet-background.jpg',
                      fit: LayoutBackgroundFit.cover,
                      opacity: 0.50,
                    ),
                  ],
                  aliases: [
                    'scene-graph',
                    'node-scene',
                    'selected-node-graph',
                    'selected-node-pool',
                    'graph-layout',
                  ],
                  visibility: [LayoutCondition.hasActiveNodes()],
                  style: GuideStyle(
                    color: Color(0xFFFFF7D6),
                    strokeWidth: 1.8,
                    pattern: GuideLinePattern.solid,
                  ),
                  layoutBorderWidth: 1.8,
                  nodeHoverBorderStyle: GuideStyle(
                    color: Color(0xFF2196F3),
                    strokeWidth: 4,
                    pattern: GuideLinePattern.solid,
                  ),
                  nodeExtentFactor: 0.5,
                  labelSize: lgErgoNodeFontSize,
                  emojiFontSizeFactor: 2,
                  emojiSlugGapFactor: 0.5,
                ),
              },
            ),
          },
        ),
      },
    ),
  },
);

const lgErgoNodeFontSize = 10.0;
