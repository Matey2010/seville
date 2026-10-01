import 'dart:ui';

import '../../constants/typography.dart';
import '../../models/layout/layout.dart';
import '../lg_ergo/lg_ergo_create_character_layout.dart';
import '../lg_ergo/lg_ergo_create_node_layout.dart';
import '../lg_ergo/lg_ergo_layout_config.dart';

/// A phone-sized landscape composition using the shared Layout renderer.
final compactLandscapeLayoutConfig = LandscapeXlLayout(
  aliases: ['screen', 'compact-landscape', 'android-phone'],
  label: lgErgoLayoutConfig.label,
  text: lgErgoLayoutConfig.text,
  node: lgErgoLayoutConfig.node,
  panel: lgErgoLayoutConfig.panel,
  attributes: const [LayoutAttribute.screen, LayoutAttribute.rectangular],
  background: const [LayoutBackground.color(Color(0xFF0A1524))],
  children: {
    'safe-area': SafeAreaLayout(
      aliases: ['safe-area'],
      layoutPadding: 6,
      children: {
        'scene-plane': LayoutPath(
          aliases: ['compact-scene-plane'],
          points: const [
            LayoutDerivativeReference(derivative: 'A'),
            LayoutDerivativeReference(derivative: 'B'),
            LayoutDerivativeReference(derivative: 'C'),
            LayoutDerivativeReference(derivative: 'D'),
          ],
          background: [
            LayoutBackground.image(
              assetPath: 'assets/wallpapers/dai-dvi-grivni.jpg',
              fit: LayoutBackgroundFit.cover,
              opacity: 0.38,
            ),
          ],
          children: {'screen-grid': _compactScreenGrid},
        ),
      },
    ),
  },
);

final _compactScreenGrid = GridLayout(
  rowsConfig: {
    'header': const LayoutSize.px(38),
    'content': const LayoutSize.fr(1),
    'actions': const LayoutSize.px(52),
  },
  columnsConfig: {'content': const LayoutSize.fr(1)},
  slots: {
    'header': const GridSlot(row: 'header', column: 'content'),
    'menu': const GridSlot(row: 'content', column: 'content'),
    'find-layout': const GridSlot(row: 'content', column: 'content'),
    'create-layout': const GridSlot(row: 'content', column: 'content'),
    'game-scene': const GridSlot(row: 'content', column: 'content'),
    'actions': const GridSlot(row: 'actions', column: 'content'),
  },
  layoutGap: 5,
  children: {
    'header': PanelLayout(
      slot: 'header',
      background: const [LayoutBackground.color(Color(0xDD152838))],
      text: const LayoutTextConfig(
        value: LayoutText.value('SEVILLE 7  ·  LANDSCAPE'),
        fontFamily: SevilleTypography.nodeFontFamily,
        fontSize: 17,
        color: Color(0xFFFFD54F),
        flow: LayoutTextFlow.horizontal(),
      ),
    ),
    'menu': _compactMenu,
    'find-layout': FindLayout(
      slot: 'find-layout',
      aliases: ['find-layout', 'node-finder'],
      background: const [LayoutBackground.color(Color(0xF2283252))],
      text: const LayoutTextConfig(fontSize: 16),
      state: const LayoutState({
        LayoutCondition.findOpened(): LayoutConfig(visible: true),
      }),
    ),
    'create-layout': lgErgoCreateNodeLayout,
    'game-scene': _compactGameScene,
    'actions': RowLayout(
      slot: 'actions',
      text: const LayoutTextConfig(flow: LayoutTextFlow.horizontal()),
      children: {
        'close': PanelLayout(
          aliases: const [
            'action-button',
            'cancel-interface-action',
            'close-action',
          ],
          background: const [LayoutBackground.color(Color(0xEE152838))],
          borderStyle: const GuideStyle(
            color: Color(0xFFFFD54F),
            strokeWidth: 1.4,
          ),
          text: const LayoutTextConfig(
            value: LayoutText.value('‹ BACK / MENU'),
            fontSize: 18,
            flow: LayoutTextFlow.horizontal(),
          ),
        ),
      },
    ),
  },
);

final _compactMenu = ColumnLayout(
  slot: 'menu',
  aliases: const ['navigation-column', 'compact-menu'],
  layoutGap: 6,
  text: const LayoutTextConfig(
    fontFamily: SevilleTypography.nodeFontFamily,
    fontSize: 22,
    flow: LayoutTextFlow.horizontal(),
  ),
  state: const LayoutState({
    LayoutCondition.mainMenu(): LayoutConfig(visible: true),
    LayoutCondition.findOpened(): LayoutConfig(visible: false),
  }),
  children: {
    'continue': _compactMenuButton(
      '▶ CONTINUE',
      LayoutTapAction.continueGame(),
    ),
    'new': _compactMenuButton(
      '＋ NEW NODE',
      LayoutTapAction.beginNodeCreation(),
    ),
    'find': _compactMenuButton('⌕ FIND NODES', LayoutTapAction.findOpened()),
    'today': _compactMenuButton(
      '▣ TODAY',
      LayoutTapAction.beginNodeCreation(labels: ['Event', 'Day', 'Date']),
      aliases: const ['resolve-today-node'],
    ),
  },
);

PanelLayout _compactMenuButton(
  String caption,
  LayoutTapAction action, {
  List<String> aliases = const [],
}) => PanelLayout(
  onTap: action,
  aliases: aliases,
  background: const [LayoutBackground.color(Color(0xE31B2A3C))],
  borderStyle: const GuideStyle(color: Color(0xFFB8A04E), strokeWidth: 1.3),
  text: LayoutTextConfig(value: LayoutText.value(caption)),
);

final _compactGameScene = GridLayout(
  slot: 'game-scene',
  aliases: const ['game-scene', 'mobile-world'],
  background: [
    LayoutBackground.image(
      assetPath: 'assets/wallpapers/helmet-background.jpg',
      fit: LayoutBackgroundFit.cover,
      opacity: 0.46,
    ),
  ],
  rowsConfig: {
    'status': const LayoutSize.px(32),
    'sky': const LayoutSize.fr(1),
    'character': const LayoutSize.fr(5),
    'ground': const LayoutSize.fr(1),
  },
  columnsConfig: {
    'left': const LayoutSize.fr(1),
    'character': const LayoutSize.fr(2),
    'right': const LayoutSize.fr(1),
  },
  slots: {
    'status': const GridSlot(row: 'status', column: 'left', columnSpan: 3),
    'character': const GridSlot(row: 'character', column: 'character'),
    'ground': const GridSlot(row: 'ground', column: 'left', columnSpan: 3),
    'selected-nodes': const GridSlot(row: 'sky', column: 'right', rowSpan: 2),
  },
  state: const LayoutState({
    LayoutCondition.gameplay(): LayoutConfig(visible: true),
  }),
  children: {
    'status': PanelLayout(
      slot: 'status',
      background: const [LayoutBackground.color(Color(0xD9182A24))],
      text: const LayoutTextConfig(
        value: LayoutText.value('◉ COLLISION · RPG · MULTIPLAYER'),
        color: Color(0xFF85FF21),
        fontSize: 12,
        flow: LayoutTextFlow.horizontal(),
      ),
    ),
    'character': lgErgoCharacterBodyLayout(slot: 'character'),
    'ground': PanelLayout(
      slot: 'ground',
      background: [
        LayoutBackground.image(
          assetPath: 'assets/backgrounds/brick-wall.jpg',
          fit: LayoutBackgroundFit.cover,
          opacity: 0.82,
        ),
      ],
    ),
    'selected-nodes': GraphLayout(
      slot: 'selected-nodes',
      aliases: const ['scene-graph', 'selected-node-pool'],
      style: const GuideStyle(color: Color(0xFFFFD54F), strokeWidth: 1.4),
      nodeExtentFactor: 0.72,
    ),
  },
);
