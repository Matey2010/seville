import 'dart:ui';

import 'package:flutter/material.dart' hide TableRow;
import 'package:seville_proto/seville_proto.dart' show Emoji, Node;

import '../../../../models/layout/layout.dart';
import '../../../interface_colors.dart';
import '../../../typography.dart';

final lgErgoLayoutConfig = LandscapeXlLayout(
  aliases: ['screen', 'root', 'reality', 'user-space', 'user-reality'],
  label: const LabelConfig(
    state: LayoutState({
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
    }),
  ),
  text: const LayoutTextConfig(
    color: Color(0xFFFFF8E7),
    darkColor: Color(0xFF27251F),
    lightColor: Color(0xFFFFF8E7),
    fontFamily: SevilleTypography.fontFamily,
    fontSize: LayoutTextDefaults.rootFontSize,
  ),
  node: const NodeConfig(
    text: LayoutTextConfig(fontSize: 10),
    slugColor: Color(0xFFFFD54F),
    labelColor: Color(0xFFFFF8E7),
    valueColor: Color(0xFFFFF8E7),
    slugPrefix: '[[',
    slugTransform: TextTransform.capitalCap(),
    slugSuffix: ']]',
    state: LayoutState({
      LayoutCondition.nodeHighlighted(): NodeConfig(
        borderStyle: GuideStyle(
          color: Color(0xFF2196F3),
          strokeWidth: 4,
          pattern: GuideLinePattern.solid,
        ),
      ),
    }),
  ),
  panel: const PanelConfig(
    foldedPanelSize: LayoutSize.twoDimensional(
      primary: LayoutSize.fr(0.33),
      secondary: LayoutSize.fr(0.33),
    ),
  ),
  attributes: [LayoutAttribute.screen, LayoutAttribute.rectangular],

  background: [
    LayoutBackground.guides(
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
              background: [
                LayoutBackground.color(Color(0x00000000)),
                LayoutBackground.image(
                  assetPath: 'assets/backgrounds/chinese-fan.png',
                  fit: LayoutBackgroundFit.fill,
                  rotationDegrees: 180,
                  // position: Offset(0.5, 0.30),
                  // scale: 1,
                ),
              ],
              node: const NodeConfig(
                borderStyle: GuideStyle(
                  color: Color(0xFFFFF7D6),
                  strokeWidth: 1.8,
                  pattern: GuideLinePattern.solid,
                ),
                state: LayoutState({
                  LayoutCondition.nodeHighlighted(): NodeConfig(
                    borderStyle: GuideStyle(
                      color: Color(0xFF2196F3),
                      strokeWidth: 4,
                      pattern: GuideLinePattern.solid,
                    ),
                  ),
                }),
              ),
              layoutBorderWidth: 1.8,
              rootNodeFilter: _lgErgoFanRootNodeFilter,
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
              background: [
                LayoutBackground.image(
                  assetPath: 'assets/backgrounds/brick-wall.jpg',
                  fit: LayoutBackgroundFit.fill,
                  position: Offset(0.5, 0.38),
                  scale: 1,
                  opacity: 1,
                ),
              ],
              node: const NodeConfig(
                borderStyle: GuideStyle(
                  color: Color(0xFFFFF7D6),
                  strokeWidth: 1.8,
                  pattern: GuideLinePattern.solid,
                ),
                state: LayoutState({
                  LayoutCondition.nodeHighlighted(): NodeConfig(
                    borderStyle: GuideStyle(
                      color: Color(0xFF2196F3),
                      strokeWidth: 4,
                      pattern: GuideLinePattern.solid,
                    ),
                  ),
                }),
              ),
              layoutBorderWidth: 1.8,
              rootNodeFilter: _lgErgoFanRootNodeFilter,
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
          state: LayoutState({
            LayoutCondition.hasActiveNodes(): LayoutConfig(visible: true),
          }),
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
            LayoutBackground.random([
              // LayoutBackground.color(Color(0xFF22D54F)),
              LayoutBackground.color(Color(0xFF000000)),
              LayoutBackground.color(Color(0xFFffffff)),
            ]),
            LayoutBackground.conditional(
              activeCondition: LayoutCondition.hasActiveNodes(),
              background: LayoutBackground.color(Color(0xFF0000FF)),
            ),
            LayoutBackground.image(
              assetPath: 'assets/wallpapers/sims-4-interface.png',
              opacity: 0.78,
              fit: LayoutBackgroundFit.fill,
              orderPosition: 1,
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
              aliases: [
                'panoramic-grid',
                'panoramic-layout',
                'direction-pad',
                'node-direction-controls',
                'spatial-navigation',
                'panorama',
              ],
              rowsConfig: {
                'header': LayoutDefaultSize.panoramicHeader,
                'top': LayoutSize.fr(1),
                'center': LayoutSize.fr(1),
                'bottom': LayoutSize.fr(1),
                'bottom-ribbon': LayoutDefaultSize.panoramicFooter,
                'teletext-ribbon': LayoutDefaultSize.panoramicFooter,
              },
              columnsConfig: {
                'left-ribbon': LayoutDefaultSize.crossAxisRibbonWidth,
                'status': LayoutSize.fr(0.5),
                'family-tree': LayoutSize.fr(0.5),
                'center': LayoutSize.fr(3),
                'right': LayoutSize.fr(0.75),
              },
              slots: {
                'geneaology': GridSlot(
                  row: 'bottom-ribbon',
                  column: 'family-tree',
                  rowSpan: 2,
                ),
                'info': GridSlot(
                  row: 'top',
                  column: 'status',
                  aliases: ['info-grid'],
                  columnSpan: 2,
                  rowSpan: 3,
                ),
                'left-ribbon': GridSlot(
                  row: 'header',
                  column: 'left-ribbon',
                  rowSpan: GridSpan.full,
                ),
                'logo': GridSlot(row: 'header', column: 'left-ribbon'),
                'header': GridSlot(
                  row: 'header',
                  column: 'left-ribbon',
                  columnSpan: GridSpan.full,
                ),
                'search-layout': GridSlot(
                  row: 'top',
                  column: 'status',
                  columnSpan: 2,
                  rowSpan: 3,
                ),
                'scene-graph': GridSlot(
                  row: 'top',
                  column: 'center',
                  rowSpan: 3,
                ),
                'action-panel': GridSlot(
                  row: 'top',
                  column: 'right',
                  rowSpan: 3,
                ),
                'top-left': GridSlot(row: 'top', column: 'left'),
                'top-center': GridSlot(row: 'top', column: 'center'),
                'top-right': GridSlot(row: 'top', column: 'right'),
                'center-left': GridSlot(row: 'center', column: 'left'),
                'center': GridSlot(row: 'center', column: 'center'),
                'center-right': GridSlot(row: 'center', column: 'right'),
                'bottom-left': GridSlot(row: 'bottom', column: 'left'),
                'bottom-center': GridSlot(row: 'bottom', column: 'center'),
                'bottom-right': GridSlot(row: 'bottom', column: 'right'),
                'footer': GridSlot(
                  row: 'bottom-ribbon',
                  column: 'left-ribbon',
                  columnSpan: GridSpan.full,
                ),
                'possessions': GridSlot(
                  row: 'bottom',
                  column: 'right',
                  columnSpan: 1,
                  rowSpan: 3,
                ), 
                'status': GridSlot(row: 'teletext-ribbon', column: 'status'),
                'teletext': GridSlot(
                  row: 'teletext-ribbon',
                  column: 'center',
                  columnSpan: 1,
                ),
              },
              children: {
                'left-ribbon': GridLayout(
                  slot: 'left-ribbon',
                  rowsConfig: {
                    'logo': LayoutDefaultSize.panoramicHeader,
                    'content': LayoutSize.fr(1),
                  },
                  columnsConfig: {'ribbon': LayoutSize.fr(1)},
                  slots: {
                    'content': GridSlot(row: 'content', column: 'ribbon'),
                  },
                  aliases: [
                    'left-ribbon',
                    'panoramic-left-ribbon',
                    'scene-left-ribbon',
                  ],
                  text: LayoutTextConfig(
                    color: Color(0xFFFFD54F),
                    fontSize: 10,
                  ),
                  background: [LayoutBackground.color(Color(0xCC283252))],
                  children: {
                    'content': ColumnLayout(
                      slot: 'content',
                      aliases: ['left-ribbon-content'],
                      children: {
                        'folder': PanelLayout(
                          aliases: ['left-ribbon-folder'],
                          borderStyle: GuideStyle(
                            color: Color(0xFFFFD54F),
                            strokeWidth: 1.2,
                            pattern: GuideLinePattern.solid,
                          ),
                          text: LayoutTextConfig(value: LayoutText.value('📁')),
                        ),
                        'bookmarks': PanelLayout(
                          aliases: ['left-ribbon-bookmarks'],
                          borderStyle: GuideStyle(
                            color: Color(0xFFFFD54F),
                            strokeWidth: 1.2,
                            pattern: GuideLinePattern.solid,
                          ),
                          text: LayoutTextConfig(value: LayoutText.value('🔖')),
                        ),
                        'action-queue': PanelLayout(
                          aliases: ['left-ribbon-action-queue'],
                          borderStyle: GuideStyle(
                            color: Color(0xFFFFD54F),
                            strokeWidth: 1.2,
                            pattern: GuideLinePattern.solid,
                          ),
                          text: LayoutTextConfig(
                            value: LayoutText.value('📋n'),
                          ),
                        ),
                        'avatar-pro': NodeLayout(
                          slot: 'logo',
                          node: const NodeConfig(
                            content: NodeContent.emoji(),
                            text: LayoutTextConfig(
                              value: LayoutText.none(),
                              fontSize: 24,
                            ),
                          ),
                          background: [
                            LayoutBackground.image(
                              assetPath: 'assets/logo/elder-brain.png',
                              fit: LayoutBackgroundFit.fill,
                              // position: Offset(0.5, 0.30),
                              // scale: 1.5,
                            ),
                          ],
                          filter: _lgErgoFanRootNodeFilter,
                          storedNode: Node(
                            slug: _lgErgoFanRootSlug,
                            path: _lgErgoFanRootSlug,
                            title: 'Brain Control',
                            labels: ['Calendar'],
                            emojis: [Emoji(character: '🧠', title: 'Brain')],
                          ),
                          aliases: [
                            'logo',
                            'panoramic-logo',
                            'scene-logo',
                            'brain-control',
                            'cortex-control',
                          ],
                        ),
                        'avatar': PanelLayout(
                          size: LayoutDefaultSize.crossAxisRibbonWidth,
                          aliases: [
                            'jarvis',
                            'footer-spacer-start',
                            'left-ribbon-footer-intersection',
                          ],
                          text: LayoutTextConfig(
                            value: LayoutText.value('🦹🏼‍♂️'),
                            fontSize: 18,
                          ),
                        ),
                      },
                    ),
                  },
                ),
                'logo': NodeLayout(
                  slot: 'logo',
                  node: const NodeConfig(
                    borderStyle: GuideStyle(
                      color: Color(0xFFFFF7D6),
                      strokeWidth: 4,
                      pattern: GuideLinePattern.solid,
                    ),
                    content: NodeContent.emoji(),
                    text: LayoutTextConfig(
                      value: LayoutText.none(),
                      fontSize: 24,
                    ),
                  ),
                  background: [
                    LayoutBackground.image(
                      assetPath: 'assets/logo/elder-brain.png',
                      fit: LayoutBackgroundFit.fill,
                      // position: Offset(0.5, 0.30),
                      // scale: 1.5,
                    ),
                  ],
                  filter: _lgErgoFanRootNodeFilter,
                  storedNode: Node(
                    slug: _lgErgoFanRootSlug,
                    path: _lgErgoFanRootSlug,
                    title: 'Brain Control',
                    labels: ['Calendar'],
                    emojis: [Emoji(character: '🧠', title: 'Brain')],
                  ),
                  aliases: [
                    'logo',
                    'panoramic-logo',
                    'scene-logo',
                    'brain-control',
                    'cortex-control',
                  ],
                ),
                'header': RowLayout(
                  slot: 'header',
                  crossAxisAlignment: LayoutCrossAxisAlignment.stretch(),
                  aliases: [
                    'header',
                    'panoramic-header',
                    'scene-header',
                    'header-content',
                    'header-lorem',
                    'top-ribbon',
                  ],
                  text: LayoutTextConfig(
                    color: Color(0xFFFFD54F),
                    fontSize: 12,
                  ),
                  background: [
                    LayoutBackground.color(Color(0x44283252)),
                    LayoutBackground.image(
                      assetPath: 'assets/wallpapers/dark-vintage-scheme.jpg',
                      fit: LayoutBackgroundFit.cover,
                      opacity: 0.39,
                      orderPosition: 1,
                    ),
                  ],
                  children: {
                    'spacer': PanelLayout(
                      aliases: ['header-spacer', 'spacer-shortcut'],
                      size: LayoutDefaultSize.crossAxisRibbonWidth,
                      text: LayoutTextConfig(value: LayoutText.none()),
                    ),
                    'find': PanelLayout(
                      aliases: ['header-search', 'search-shortcut'],
                      onTap: LayoutTapAction.searchOpenned(),
                      borderStyle: GuideStyle(
                        color: Color(0xFFFFD54F),
                        strokeWidth: 1.2,
                        pattern: GuideLinePattern.solid,
                      ),
                      text: LayoutTextConfig(
                        value: LayoutText.value('F 🔎 find'),
                      ),
                    ),
                    'labels': PanelLayout(
                      aliases: ['header-labels', 'labels-shortcut'],
                      borderStyle: GuideStyle(
                        color: Color(0xFFFFD54F),
                        strokeWidth: 1.2,
                        pattern: GuideLinePattern.solid,
                      ),
                      text: LayoutTextConfig(
                        value: LayoutText.value('🏷️ labels'),
                      ),
                    ),
                    'lorem': PanelLayout(
                      size: LayoutSize.fr(3),
                      aliases: [
                        'center-ribbon',
                        'panoramic-center-ribbon',
                        'scene-center-header',
                      ],
                      state: LayoutState({
                        LayoutCondition.hasActiveNodes(): LayoutConfig(
                          text: LayoutTextConfig(
                            value: LayoutText.lorem(length: 1),
                          ),
                        ),
                      }),
                      text: LayoutTextConfig(
                        color: Color.fromARGB(255, 255, 97, 79),
                        value: LayoutText.value('Choose your NODEs, Player!'),
                      ),
                    ),

                    'bookmarks': PanelLayout(
                      aliases: ['header-bookmarks', 'bookmarks-shortcut'],
                      borderStyle: GuideStyle(
                        color: Color(0xFFFFD54F),
                        strokeWidth: 1.2,
                        pattern: GuideLinePattern.solid,
                      ),
                      text: LayoutTextConfig(
                        value: LayoutText.value('🔖 bookmarks'),
                      ),
                    ),
                    'degeneracy-panel': RowLayout(
                      size: LayoutSize.fr(2),
                      children: {
                        'pov': PanelLayout(
                          aliases: ['header-view-change', 'view-change-shortcut'],
                          borderStyle: GuideStyle(
                            color: Color(0xFFFFD54F),
                            strokeWidth: 1.2,
                            pattern: GuideLinePattern.solid,
                          ),
                          text: LayoutTextConfig(
                            value: LayoutText.value('🎥 pov | p')),
                        ),
                        'map': PanelLayout(
                          aliases: ['header-map', 'map-shortcut'],
                          borderStyle: GuideStyle(
                            color: Color(0xFFFFD54F),
                            strokeWidth: 1.2,
                            pattern: GuideLinePattern.solid,
                          ),
                          text: LayoutTextConfig(
                            value: LayoutText.value('🗺️ map | m')),
                        ),
                        'settings': PanelLayout(
                          aliases: ['header-settings', 'settings-shortcut'],
                          borderStyle: GuideStyle(
                            color: Color(0xFFFFD54F),
                            strokeWidth: 1.2,
                            pattern: GuideLinePattern.solid,
                          ),
                          text: LayoutTextConfig(
                            value: LayoutText.value('⚙️ settings | Esc')),
                        ),
                      }
                    )
                  },
                ),
                'action-panel': ColumnLayout(
                  slot: 'action-panel',
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
                          borderStyle: (GuideStyle(
                            color: Color(0xCCB7C2FF),
                            strokeWidth: 1,
                            pattern: GuideLinePattern.solid,
                          )),
                          text: LayoutTextConfig(
                            value: LayoutText.value('🔄'),
                            color: Color(0xFFFFF8E7),
                            fontSize: 18,
                          ),
                        ),
                        'add-node': PanelLayout(
                          size: LayoutSize.fr(1),
                          aliases: [
                            'action-button',
                            'add-action',
                            'create-virtual-node',
                          ],
                          borderStyle: (GuideStyle(
                            color: Color(0xCCB7C2FF),
                            strokeWidth: 1,
                            pattern: GuideLinePattern.solid,
                          )),
                          text: LayoutTextConfig(
                            value: LayoutText.value('Add'),
                            color: Color(0xFFFFF8E7),
                            fontSize: 12,
                          ),
                        ),
                        'today': PanelLayout(
                          size: LayoutSize.fr(1),
                          aliases: [
                            'action-button',
                            'today-action',
                            'resolve-today-node',
                          ],
                          borderStyle: (GuideStyle(
                            color: Color(0xCCB7C2FF),
                            strokeWidth: 1,
                            pattern: GuideLinePattern.solid,
                          )),
                          text: LayoutTextConfig(
                            value: LayoutText.value('Today'),
                            color: Color(0xFFFFF8E7),
                            fontSize: 12,
                          ),
                        ),
                        'confirm': PanelLayout(
                          size: LayoutSize.fr(1),
                          aliases: [
                            'action-button',
                            'confirm-action',
                            'submit-action',
                            'create-first-virtual-node',
                          ],
                          borderStyle: (GuideStyle(
                            color: Color(0xCCB7C2FF),
                            strokeWidth: 1,
                            pattern: GuideLinePattern.solid,
                          )),
                          text: LayoutTextConfig(
                            value: LayoutText.value('✅'),
                            color: Color(0xFFFFF8E7),
                            fontSize: 18,
                          ),
                        ),
                        'close-selection': PanelLayout(
                          size: LayoutSize.fr(1),
                          aliases: [
                            'action-button',
                            'close-action',
                            'cancel-interface-action',
                            'clear-selection-action',
                          ],
                          borderStyle: (GuideStyle(
                            color: Color(0xCCB7C2FF),
                            strokeWidth: 1,
                            pattern: GuideLinePattern.solid,
                          )),
                          text: LayoutTextConfig(
                            value: LayoutText.value('×'),
                            color: Color(0xFFFFF8E7),
                            fontSize: 18,
                          ),
                        ),
                      },
                    ),
                  },
                ),
                'info-grid': TableLayout(
                  slot: 'info',
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
                    LayoutBackground.image(
                      assetPath: 'assets/wallpapers/daft-punk-suit.jpg',
                      fit: LayoutBackgroundFit.contain,
                      opacity: 0.34,
                    ),
                  ],
                  layoutBorderWidth: 1.8,
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
                      'system': PanelConfig(
                        orderPosition: 6,
                        title: 'System',
                        foldable: true,
                        initiallyFolded: true,
                      ),
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
                      node: const NodeConfig(
                        slugPrefix: '[[',
                        slugTransform: TextTransform.capitalCap(),
                        slugSuffix: ']]',
                      ),
                      aliases: [
                        'virtual-nodes',
                        'draft-nodes',
                        'uncreated-nodes',
                      ],
                    ),
                  },
                ),
                'search-layout': SearchLayout(
                  slot: 'search-layout',
                  aliases: ['search-layout', 'search-hud'],
                  background: [LayoutBackground.color(Color(0xF2283252))],
                  layoutBorderWidth: 1.8,
                  state: LayoutState({
                    LayoutCondition.searchOpenned(): LayoutConfig(
                      visible: true,
                    ),
                  }),
                  children: {
                    SearchLayout.searchResultsLayoutKey: ColumnLayout(
                      slot: SearchLayout.searchResultsLayoutKey,
                      aliases: ['search-results', 'search-results-column'],
                      children: {
                        'search_results': NodeListLayout(
                          dataSource: NodeListDataSource.searchResults,
                          style: GuideStyle(
                            color: Color(0xFFFFF7D6),
                            strokeWidth: 1.8,
                            pattern: GuideLinePattern.solid,
                          ),
                          layoutBorderWidth: 1.8,
                          node: const NodeConfig(
                            slugPrefix: '[[',
                            slugTransform: TextTransform.capitalCap(),
                            slugSuffix: ']]',
                          ),
                        ),
                      },
                    ),
                  },
                ),
                'scene-graph': GraphLayout(
                  slot: 'scene-graph',
                  background: [
                    LayoutBackground.image(
                      assetPath: 'assets/wallpapers/helmet-background.jpg',
                      fit: LayoutBackgroundFit.cover,
                      opacity: 0.12,
                    ),
                  ],
                  aliases: [
                    'scene-graph',
                    'node-scene',
                    'selected-node-graph',
                    'selected-node-pool',
                    'graph-layout',
                  ],
                  state: LayoutState({
                    LayoutCondition.hasActiveNodes(): LayoutConfig(
                      visible: true,
                    ),
                  }),
                  style: GuideStyle(
                    color: Color(0xFFFFF7D6),
                    strokeWidth: 1.8,
                    pattern: GuideLinePattern.solid,
                  ),
                  layoutBorderWidth: 1.8,
                  nodeExtentFactor: 0.5,
                  emojiFontSizeFactor: 2,
                  emojiSlugGapFactor: 0.5,
                ),
                'possessions': ColumnLayout(
                  slot: 'possessions',
                  // crossAxisAlignment: LayoutCrossAxisAlignment.bottom(),
                  aliases: ['possessions', 'panoramic-footer', 'scene-footer'],
                  children: {
                    'wallet': PanelLayout(
                      // size: LayoutSize.fr(1),
                      aliases: ['huita-blya-koshelyok', 'sevicoin-icon'],
                      text: LayoutTextConfig(
                        // TODO: Fix hardcoded wallet value to be dynamic based on user data
                        value: LayoutText.value('🪙 0,000.000,000'),
                      ),
                    ),
                    'keyring': PanelLayout(
                      // size: LayoutSize.fr(1),
                      aliases: ['huita-blya-koshelyok', 'sevicoin-icon'],
                      text: LayoutTextConfig(
                        // TODO: Fix hardcoded wallet value to be dynamic based on user data
                        value: LayoutText.value('K 🔑 Keychain'),
                      ),
                    ),
                    // 'bookmarks': PanelLayout(
                    //   aliases: ['bottom-bookmarks', 'bookmarks-shortcut'],
                    //   borderStyle: GuideStyle(
                    //     color: Color(0xFFFFD54F),
                    //     strokeWidth: 1.2,
                    //     pattern: GuideLinePattern.solid,
                    //   ),
                    //   text: LayoutTextConfig(
                    //     value: LayoutText.value('B 🔖 bookmarks'),
                    //   ),
                    // ),
                    // 'social': PanelLayout(
                    //   size: LayoutSize.fr(0.33),
                    //   aliases: [],
                    //   text: LayoutTextConfig(
                    //     value: LayoutText.value('👩‍❤️‍👩 social graph'),
                    //   ),
                    // ),
                    // 'quests': PanelLayout(
                    //   size: LayoutSize.fr(0.33),
                    //   aliases: [],
                    //   text: LayoutTextConfig(value: LayoutText.value('Q ⁉️')),
                    // ),
                    'inventory': PanelLayout(
                      size: LayoutSize.fr(0.25),
                      aliases: [],
                      text: LayoutTextConfig(value: LayoutText.value('I 🎒')),
                    ),
                  },
                ),
                'teletext': PanelLayout(
                  slot: 'teletext',
                  aliases: [
                    'bottom-ribbon',
                    'panoramic-bottom-ribbon',
                    'scene-ribbon',
                    'teletext-ribbon',
                    'poloska-teletexta',
                    'teletext-bottom',
                  ],
                  text: LayoutTextConfig(
                    value: LayoutText.value(
                      'teletext | 🌌 | ☀️ | 🌎 | 🇪🇸 | BCN | 2026 | ⛱️ Jun - Jul - Aug | XX | XX:XX | ↕️ 2REM',
                    ),
                    color: Color(0xFF21FFF3),
                    fontSize: 12,
                  ),
                  borderStyle: GuideStyle(
                    color: Color(0xFFFFD54F),
                    strokeWidth: 1.2,
                    pattern: GuideLinePattern.solid,
                  ),
                  background: [
                    // LayoutBackground.color(Color(0xCC283252)),
                    LayoutBackground.image(
                      assetPath: 'assets/wallpapers/dark-vintage-scheme.jpg',
                      fit: LayoutBackgroundFit.cover,
                      orderPosition: 1,
                    ),
                  ],
                ),
                'geneaology': PanelLayout(
                  background: [
                    LayoutBackground.color(Color.fromARGB(255, 20, 202, 123)),
                  ],
                  slot: 'geneaology',
                  size: LayoutSize.fr(1),
                  aliases: [],
                  text: LayoutTextConfig(
                    value: LayoutText.value('G 🌳 genealogy '),
                  ),
                ),
                'status-button': PanelLayout(
                  slot: 'status',
                  aliases: [],
                  background: [
                    LayoutBackground.color(Color.fromARGB(255, 198, 145, 79)),
                  ],
                  text: LayoutTextConfig(
                    value: LayoutText.value("S 🤤 Hungry "),
                  ),
                ),
              },
            ),
          },
        ),
      },
    ),
  },
);

const _lgErgoFanRootSlug = 'cortex-timeline-calendar-2026-06-fr6h';

const _lgErgoFanRootNodeFilter = NodeSearchFilter.allOf([
  NodeSearchParameter(
    parameter: NodeParameter.slug,
    value: _lgErgoFanRootSlug,
    operator: NodeMatchOperator.exact,
  ),
  NodeSearchParameter(
    parameter: NodeParameter.label,
    value: 'Calendar',
    operator: NodeMatchOperator.contains,
  ),
]);
