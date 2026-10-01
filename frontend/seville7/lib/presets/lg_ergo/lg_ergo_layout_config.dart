import 'dart:ui';

import '../../constants/interface_colors.dart';
import '../../constants/typography.dart';
import '../../models/layout/layout.dart';
import 'lg_ergo_main_menu_fans.dart';
import 'lg_ergo_panoramic_grid.dart';

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
    text: LayoutTextConfig(
      fontFamily: SevilleTypography.nodeFontFamily,
      fontSize: 10,
    ),
    slugColor: Color(0xFFFFD54F),
    labelColor: Color(0xFFFFF8E7),
    valueColor: Color(0xFFFFF8E7),
    slugPrefix: '[[',
    slugTransform: TextTransform.uppercase(),
    slugSuffix: ']]',
    state: LayoutState({
      LayoutCondition.hasLabelsInCurrentNode(['Science']): NodeConfig(
        background: [
          LayoutBackground.svg(
            assetPath: 'assets/icons/vector/proto-icon.svg',
            fit: LayoutBackgroundFit.contain,
          ),
        ],
      ),
      LayoutCondition.hasLabelsInCurrentNode(['Character']): NodeConfig(
        background: [
          LayoutBackground.svg(
            assetPath: 'assets/icons/vector/body-parts/basic-human.svg',
            fit: LayoutBackgroundFit.contain,
          ),
        ],
      ),
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
        ...lgErgoMainMenuFanPlanes,
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
            LayoutBackground.image(
              assetPath: 'assets/wallpapers/dai-dvi-grivni.jpg',
              fit: LayoutBackgroundFit.cover,
            ),
            // LayoutBackground.random([
            //   // LayoutBackground.color(Color(0xFF7B4FA3), opacity: 0.2),
            //   // LayoutBackground.color(Color(0xFFffffff)),
            // ]),
            // LayoutBackground.conditional(
            //   activeCondition: LayoutCondition.hasActiveNodes(),
            //   background: LayoutBackground.svg(
            //     assetPath: 'assets/icons/vector/hexagon.svg',
            //     fit: LayoutBackgroundFit.contain,
            //     opacity: 0.5,
            //   )
            // ),
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
              extent: lgErgoMainMenuCurveExtent,
            ),
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
          style: LayoutPathStyle(
            fillColor: Color(0x00000000),
            strokeStyle: GuideStyle(
              color: Color(0xAAC59A1A),
              strokeWidth: 1.2,
              pattern: GuideLinePattern.solid,
            ),
          ),
          children: {'direction-pad': lgErgoPanoramicGrid},
        ),
      },
    ),
  },
);
