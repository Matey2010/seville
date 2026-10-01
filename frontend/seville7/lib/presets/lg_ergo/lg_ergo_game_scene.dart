import 'dart:ui';

import '../../models/layout/layout.dart';
import 'lg_ergo_create_character_layout.dart';

final lgErgoGameScene = GridLayout(
  slot: 'game-scene',
  aliases: ['game-scene', 'selected-node-scene', 'game-hud'],
  background: [LayoutBackground.color(Color(0x66071324))],
  rowsConfig: {
    'top': LayoutSize.fr(1),
    'center': LayoutSize.fr(1),
    'bottom': LayoutSize.fr(1),
  },
  columnsConfig: {
    'left': LayoutSize.fr(1),
    'center': LayoutSize.fr(3),
    'right': LayoutSize.fr(1),
  },
  slots: {
    'scene-graph': GridSlot(row: 'top', column: 'center', rowSpan: 3),
    'world-scale': GridSlot(row: 'top', column: 'center', rowSpan: 3),
    'possessions': GridSlot(row: 'bottom', column: 'right'),
    'kernel-status': GridSlot(row: 'top', column: 'center', rowSpan: 0.16),
  },
  state: LayoutState({LayoutCondition.gameplay(): LayoutConfig(visible: true)}),
  children: {
    'scene-graph': _lgErgoSceneGraph,
    'world-scale': _lgErgoWorldScale,
    'possessions': _lgErgoPossessionsHud,
    'kernel-status': _lgErgoKernelStatus,
  },
);

const _worldWidthMeters = 500.0;
const _worldHeightMeters = 200.0;
const _characterWidthMeters = 1.0;
const _characterHeightMeters = 2.0;
const _characterPerspectiveScale = 15.0;
const _projectedCharacterWidthMeters =
    _characterWidthMeters * _characterPerspectiveScale;
const _projectedCharacterHeightMeters =
    _characterHeightMeters * _characterPerspectiveScale;
const _horizontalWorldMarginMeters =
    (_worldWidthMeters - _projectedCharacterWidthMeters) / 2;
const _verticalWorldMarginMeters =
    (_worldHeightMeters - _projectedCharacterHeightMeters) / 2;

final _lgErgoWorldScale = GridLayout(
  slot: 'world-scale',
  aliases: ['world-scale', '500m-by-200m-world', 'character-perspective-15x'],
  rowsConfig: {
    'above-character': LayoutSize.fr(_verticalWorldMarginMeters),
    'character': LayoutSize.fr(_projectedCharacterHeightMeters),
    'ground': LayoutSize.fr(_verticalWorldMarginMeters),
  },
  columnsConfig: {
    'left-of-character': LayoutSize.fr(_horizontalWorldMarginMeters),
    'character': LayoutSize.fr(_projectedCharacterWidthMeters),
    'right-of-character': LayoutSize.fr(_horizontalWorldMarginMeters),
  },
  slots: {
    'overhead-debris': GridSlot(
      row: 'above-character',
      column: 'left-of-character',
      columnSpan: 3,
    ),
    'world-character': GridSlot(row: 'character', column: 'character'),
    'ground': GridSlot(
      row: 'ground',
      column: 'left-of-character',
      columnSpan: 3,
    ),
  },
  children: {
    'overhead-debris': _lgErgoOverheadDebris,
    'ground': _lgErgoGround,
    'world-character': lgErgoCharacterBodyLayout(
      slot: 'world-character',
      aliases: [
        'world-character',
        'abstract-character',
        'human-scale',
        'perspective-scale-15x',
      ],
    ),
  },
);

final _lgErgoGround = PanelLayout(
  slot: 'ground',
  aliases: ['world-ground', 'ground-texture'],
  background: [
    LayoutBackground.color(Color(0xDD17110D)),
    LayoutBackground.image(
      assetPath: 'assets/backgrounds/brick-wall.jpg',
      fit: LayoutBackgroundFit.cover,
      repeat: 6,
      opacity: 0.82,
    ),
  ],
  borderStyle: GuideStyle(
    color: Color(0xFFA56A35),
    strokeWidth: 1.4,
    pattern: GuideLinePattern.solid,
  ),
);

final _lgErgoOverheadDebris = PanelLayout(
  slot: 'overhead-debris',
  aliases: ['overhead-debris', 'random-garbage'],
  background: [
    _randomDebrisLayer(rotationDegrees: 90, repeat: 7, opacity: 0.58),
    _randomDebrisLayer(rotationDegrees: -35, repeat: 5, opacity: 0.42),
    _randomDebrisLayer(rotationDegrees: 25, repeat: 3, opacity: 0.30),
  ],
);

LayoutBackground _randomDebrisLayer({
  required double rotationDegrees,
  required int repeat,
  required double opacity,
}) => LayoutBackground.random([
  for (final assetPath in _lgErgoDebrisAssets)
    LayoutBackground.svg(
      assetPath: assetPath,
      fit: LayoutBackgroundFit.contain,
      repeat: repeat,
      rotationDegrees: rotationDegrees,
      opacity: opacity,
    ),
]);

const _lgErgoDebrisAssets = <String>[
  'assets/icons/vector/cursed-sword.svg',
  'assets/icons/vector/modular-long-sword.svg',
  'assets/icons/vector/modular-spear.svg',
  'assets/icons/vector/modular-sword.svg',
  'assets/icons/vector/shiv.svg',
  'assets/icons/vector/world-staff.svg',
  'assets/icons/vector/exclamation.svg',
  'assets/icons/vector/x.svg',
];

final _lgErgoKernelStatus = PanelLayout(
  slot: 'kernel-status',
  aliases: ['gameplay-kernel-status', 'gameplay-systems-status'],
  background: [LayoutBackground.color(Color(0xD9182A24))],
  borderStyle: GuideStyle(
    color: Color(0xFF85FF21),
    strokeWidth: 1.2,
    pattern: GuideLinePattern.solid,
  ),
  text: LayoutTextConfig(
    value: LayoutText.value(
      '◉ GAMEPLAY KERNEL · COLLISION · RPG · MULTIPLAYER',
    ),
    color: Color(0xFF85FF21),
    fontSize: 14,
    flow: LayoutTextFlow.horizontal(),
  ),
);

final _lgErgoSceneGraph = GraphLayout(
  background: [
    LayoutBackground.image(
      assetPath: 'assets/wallpapers/helmet-background.jpg',
      fit: LayoutBackgroundFit.cover,
      opacity: 0.32,
    ),
  ],
  slot: 'scene-graph',
  node: NodeConfig(
    borderStyle: GuideStyle(
      color: Color.fromARGB(104, 135, 17, 208),
      strokeWidth: 1.8,
      pattern: GuideLinePattern.solid,
    ),
  ),
  aliases: [
    'scene-graph',
    'node-scene',
    'selected-node-graph',
    'selected-node-pool',
    'graph-layout',
  ],
  style: GuideStyle(
    color: Color(0xFFFFF7D6),
    strokeWidth: 1.8,
    pattern: GuideLinePattern.solid,
  ),
  layoutBorderWidth: 1.8,
  nodeExtentFactor: 0.5,
  emojiFontSizeFactor: 2,
  emojiSlugGapFactor: 0.5,
);

final _lgErgoPossessionsHud = RowLayout(
  background: [
    LayoutBackground.image(
      assetPath: 'assets/wallpapers/dark-vintage-scheme.jpg',
      fit: LayoutBackgroundFit.cover,
      opacity: 0.50,
      orderPosition: 1,
    ),
  ],
  slot: 'possessions',
  aliases: ['possessions', 'scene-footer', 'possessions-hud'],
  text: LayoutTextConfig(
    flow: LayoutTextFlow.vertical(
      verticalDirection: LayoutTextVerticalDirection.bottomToTop,
    ),
  ),
  children: {
    'perks': PanelLayout(
      aliases: ['bottom-perks', 'perks-shortcut'],
      borderStyle: GuideStyle(
        color: Color(0xFFFFD54F),
        strokeWidth: 1.2,
        pattern: GuideLinePattern.solid,
      ),
      text: LayoutTextConfig(value: LayoutText.value('🥋 Perks | P')),
      state: _lgErgoPossessionPanelState,
    ),
    'map': PanelLayout(
      aliases: ['header-map', 'map-shortcut'],
      borderStyle: GuideStyle(
        color: Color(0xFFFFD54F),
        strokeWidth: 1.2,
        pattern: GuideLinePattern.solid,
      ),
      text: LayoutTextConfig(value: LayoutText.value('🗺️ Map | M')),
      state: _lgErgoPossessionPanelState,
    ),
    'snippets': PanelLayout(
      text: LayoutTextConfig(value: LayoutText.value('🗒️ Snippets | S')),
      state: _lgErgoPossessionPanelState,
    ),
    'achievements': PanelLayout(
      text: LayoutTextConfig(value: LayoutText.value('🏆 Achievements | A')),
      state: _lgErgoPossessionPanelState,
    ),
    'social': PanelLayout(
      text: LayoutTextConfig(
        value: LayoutText.value('👩‍❤️‍👩 Social Graph | G'),
      ),
      state: _lgErgoPossessionPanelState,
    ),
    'quests': PanelLayout(
      text: LayoutTextConfig(value: LayoutText.value('⁉️ Quests | Q')),
      state: _lgErgoPossessionPanelState,
    ),
    'inventory': PanelLayout(
      text: LayoutTextConfig(value: LayoutText.value('🎒 Inventory | I')),
      state: _lgErgoPossessionPanelState,
    ),
    'wallet': PanelLayout(
      aliases: ['huita-blya-koshelyok', 'sevicoin-icon'],
      text: LayoutTextConfig(value: LayoutText.value('🪙 Ballance | B')),
      state: _lgErgoPossessionPanelState,
    ),
    'keyring': PanelLayout(
      aliases: ['huita-blya-koshelyok', 'sevicoin-icon', 'keychain'],
      text: LayoutTextConfig(value: LayoutText.value('🔑 Keychain | K')),
      state: _lgErgoPossessionPanelState,
    ),
    'geneaology': PanelLayout(
      background: [LayoutBackground.color(Color.fromARGB(71, 20, 202, 123))],
      size: LayoutSize.fr(1),
      text: LayoutTextConfig(value: LayoutText.value('G 🌳 genealogy ')),
      state: _lgErgoPossessionPanelState,
    ),
  },
);

final _lgErgoPossessionPanelState = LayoutState<LayoutConfig>({
  LayoutCondition.panelFocused(): LayoutConfig(
    background: [
      LayoutBackground.random([
        LayoutBackground.svg(
          assetPath: 'assets/icons/vector/modular-sword.svg',
          fit: LayoutBackgroundFit.contain,
        ),
        LayoutBackground.svg(
          assetPath: 'assets/icons/vector/modular-long-sword.svg',
          fit: LayoutBackgroundFit.contain,
        ),
        LayoutBackground.svg(
          assetPath: 'assets/icons/vector/modular-spear.svg',
          fit: LayoutBackgroundFit.contain,
        ),
        LayoutBackground.svg(
          assetPath: 'assets/icons/vector/shiv.svg',
          fit: LayoutBackgroundFit.contain,
        ),
        LayoutBackground.svg(
          assetPath: 'assets/icons/vector/cursed-sword.svg',
          fit: LayoutBackgroundFit.contain,
        ),
        LayoutBackground.svg(
          assetPath: 'assets/icons/vector/world-staff.svg',
          fit: LayoutBackgroundFit.contain,
        ),
      ]),
    ],
  ),
});
