import 'dart:ui';

import '../../models/layout/layout.dart';
import 'lg_ergo_data.dart';

final lgErgoMainMenuFanPlanes = <String, Layout>{
  'top-plane': LayoutPath(
    aliases: ['top-plane', 'control-plane', 'north-plane'],
    state: LayoutState({LayoutCondition.never: LayoutConfig(visible: true)}),
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
        extent: lgErgoMainMenuCurveExtent,
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
          LayoutBackground.image(
            assetPath: 'assets/backgrounds/multifan-pattern.webp',
            rotationDegrees: 180,
            repeat: 10,
            // position: Offset(0.5, 0.30),
            // scale: 1,
          ),
          LayoutBackground.color(Color.fromARGB(172, 0, 0, 0), opacity: 1),
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
        rootNodeFilter: lgErgoFanRootNodeFilter,
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
    state: LayoutState({LayoutCondition.never: LayoutConfig(visible: true)}),
    curves: [
      LayoutPathCurve(
        from: LayoutDerivativeReference(derivative: 'D'),
        through: LayoutDerivativeReference(
          layoutPath: ['safe-area'],
          derivative: 'innerSquare.AD-center',
        ),
        to: LayoutDerivativeReference(derivative: 'A'),
        extent: lgErgoMainMenuCurveExtent,
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
        rootNodeFilter: lgErgoFanRootNodeFilter,
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
};

final lgErgoMainMenuCurveExtent = LayoutSize.fr(
  0,
  state: LayoutState({LayoutCondition.never: LayoutSize.fr(1)}),
  animationDuration: Duration(milliseconds: 420),
);

final lgErgoCortexFanLayout =
    (lgErgoMainMenuFanPlanes['top-plane']! as LayoutPath)
            .children['cortex-bush']!
        as FanLayout;

final lgErgoTimeFanLayout =
    (lgErgoMainMenuFanPlanes['bottom-plane']! as LayoutPath)
            .children['time-fan']!
        as FanLayout;
