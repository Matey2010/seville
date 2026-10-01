import 'dart:ui';

import '../../constants/typography.dart';
import '../../models/layout/layout.dart';
import 'lg_ergo_create_character_layout.dart';

final lgErgoCreateNodeLayout = GridLayout(
  slot: 'create-layout',
  aliases: ['create-layout', 'node-creation-flow', 'new-node-flow'],
  rowsConfig: {
    'breadcrumbs': LayoutSize.rem(2),
    'screen': LayoutSize.fr(1),
    'actions': LayoutSize.rem(3),
  },
  columnsConfig: {'content': LayoutSize.fr(1)},
  slots: {
    'creation-breadcrumbs': GridSlot(row: 'breadcrumbs', column: 'content'),
    'creation-screen': GridSlot(row: 'screen', column: 'content'),
    'creation-actions': GridSlot(row: 'actions', column: 'content'),
  },
  background: [LayoutBackground.color(Color(0xF2283252))],
  layoutPadding: 12,
  layoutGap: 8,
  layoutBorderWidth: 1.8,
  state: LayoutState({
    LayoutCondition.createOpened(): LayoutConfig(visible: true),
  }),
  children: {
    'choose-kind-breadcrumbs': PanelLayout(
      slot: 'creation-breadcrumbs',
      aliases: ['creation-breadcrumbs'],
      state: LayoutState({
        LayoutCondition.not(
          LayoutCondition.creationNodeHasLabels(lgErgoCreationRootLabels),
        ): LayoutConfig(
          visible: true,
        ),
      }),
      text: LayoutTextConfig(
        value: LayoutText.value('NEW  ›  CHOOSE KIND'),
        color: Color(0xFFFFD54F),
        fontFamily: SevilleTypography.nodeFontFamily,
        fontSize: 15,
      ),
    ),
    for (final label in lgErgoCreationRootLabels)
      '${label.toLowerCase()}-breadcrumbs': PanelLayout(
        slot: 'creation-breadcrumbs',
        aliases: ['creation-breadcrumbs'],
        state: LayoutState({
          LayoutCondition.creationNodeHasLabels([label]): LayoutConfig(
            visible: true,
          ),
        }),
        text: LayoutTextConfig(
          value: LayoutText.value(
            label == 'Character'
                ? 'NEW  ›  CHARACTER  ›  BODY'
                : 'NEW  ›  ${label.toUpperCase()}  ›  1 NAME + LABELS  ›  2 DESCRIPTION',
          ),
          color: Color(0xFFFFD54F),
          fontFamily: SevilleTypography.nodeFontFamily,
          fontSize: 15,
        ),
      ),
    'creation-kind-selection': _creationKindSelection,
    'character-layout': lgErgoCreateCharacterLayout,
    for (final label in _genericCreationLabels)
      '${label.toLowerCase()}-layout': _genericCreationLayout(label),
    'creation-actions': _creationActions,
  },
);

const lgErgoCreationRootLabels = <String>[
  'Character',
  'Project',
  'Universe',
  'Business',
  'Item',
  'Event',
  'Space',
];

const _genericCreationLabels = <String>[
  'Project',
  'Universe',
  'Business',
  'Item',
  'Event',
  'Space',
];

final _creationKindSelection = GridLayout(
  slot: 'creation-screen',
  aliases: ['creation-kind-selection', 'new-node-kind'],
  rowsConfig: {
    'title': LayoutSize.rem(4),
    'first': LayoutSize.fr(1),
    'second': LayoutSize.fr(1),
    'third': LayoutSize.fr(1),
    'fourth': LayoutSize.fr(1),
  },
  columnsConfig: {'left': LayoutSize.fr(1), 'right': LayoutSize.fr(1)},
  slots: {
    'title': GridSlot(row: 'title', column: 'left', columnSpan: 2),
    for (var index = 0; index < lgErgoCreationRootLabels.length; index += 1)
      lgErgoCreationRootLabels[index]: GridSlot(
        row: const [
          'first',
          'first',
          'second',
          'second',
          'third',
          'third',
          'fourth',
        ][index],
        column: index.isEven ? 'left' : 'right',
        columnSpan: index == lgErgoCreationRootLabels.length - 1 ? 2 : 1,
      ),
  },
  layoutGap: 8,
  state: LayoutState({
    LayoutCondition.not(
      LayoutCondition.creationNodeHasLabels(lgErgoCreationRootLabels),
    ): LayoutConfig(
      visible: true,
    ),
  }),
  children: {
    'creation-kind-title': PanelLayout(
      slot: 'title',
      borderStyle: _creationBorder,
      text: LayoutTextConfig(
        value: LayoutText.value('WHAT ARE YOU CREATING?'),
        color: Color(0xFFFFD54F),
        fontFamily: SevilleTypography.nodeFontFamily,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
    ),
    for (final label in lgErgoCreationRootLabels)
      'choose-${label.toLowerCase()}': PanelLayout(
        slot: label,
        aliases: ['creation-kind', 'choose-${label.toLowerCase()}'],
        onTap: LayoutTapAction.selectCreationLabels(
          labels: [label],
          exclusiveWith: lgErgoCreationRootLabels,
        ),
        borderStyle: _creationBorder,
        text: LayoutTextConfig(
          value: LayoutText.value('${_creationEmoji[label]} $label'),
          color: Color(0xFFFFF8E7),
          fontFamily: SevilleTypography.nodeFontFamily,
          fontSize: 24,
        ),
      ),
  },
);

GridLayout _genericCreationLayout(String label) => GridLayout(
  slot: 'creation-screen',
  aliases: ['${label.toLowerCase()}-layout', '${label.toLowerCase()}-creator'],
  rowsConfig: {
    'title': LayoutSize.rem(4),
    'identity': LayoutSize.rem(5),
    'labels': LayoutSize.rem(5),
    'description': LayoutSize.fr(1),
  },
  columnsConfig: {'content': LayoutSize.fr(1)},
  slots: {
    'title': GridSlot(row: 'title', column: 'content'),
    'identity': GridSlot(row: 'identity', column: 'content'),
    'labels': GridSlot(row: 'labels', column: 'content'),
    'description': GridSlot(row: 'description', column: 'content'),
  },
  layoutGap: 8,
  state: LayoutState({
    LayoutCondition.creationNodeHasLabels([label]): LayoutConfig(visible: true),
  }),
  children: {
    '${label.toLowerCase()}-title': PanelLayout(
      slot: 'title',
      borderStyle: _creationBorder,
      text: LayoutTextConfig(
        value: LayoutText.value(
          'CREATE ${label.toUpperCase()}  ${_creationEmoji[label]}',
        ),
        color: Color(0xFFFFD54F),
        fontFamily: SevilleTypography.nodeFontFamily,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
    ),
    '${label.toLowerCase()}-slug-input': PanelLayout(
      slot: 'identity',
      aliases: ['creation-slug-input', '${label.toLowerCase()}-name-input'],
      text: LayoutTextConfig(
        value: LayoutText.value('1 · NAME — CLICK TO EDIT'),
      ),
      input: LayoutInputConfig(
        submission: LayoutInputSubmission.createVirtualNode(),
        hint: LayoutText.value('$label slug'),
        backgroundColor: Color(0xF2283252),
        borderStyle: _creationBorder,
        text: LayoutTextConfig(
          color: Color(0xFF85FF21),
          fontFamily: SevilleTypography.nodeFontFamily,
          fontSize: 18,
        ),
      ),
      borderStyle: _creationBorder,
    ),
    '${label.toLowerCase()}-labels-input': PanelLayout(
      slot: 'labels',
      aliases: ['creation-labels-input'],
      input: LayoutInputConfig(
        submission: LayoutInputSubmission.setCreationLabels(),
        hint: LayoutText.value('Extra labels, separated by commas'),
        backgroundColor: Color(0xF2283252),
        borderStyle: _creationBorder,
        text: LayoutTextConfig(
          color: Color(0xFF85FF21),
          fontFamily: SevilleTypography.nodeFontFamily,
          fontSize: 18,
        ),
      ),
      borderStyle: _creationBorder,
      text: LayoutTextConfig(
        value: LayoutText.value('1 · LABELS — CLICK TO EDIT'),
      ),
    ),
    '${label.toLowerCase()}-description-input': PanelLayout(
      slot: 'description',
      aliases: ['creation-description-input', 'creation-comment-step'],
      input: LayoutInputConfig(
        submission: LayoutInputSubmission.setCreationBody(),
        hint: LayoutText.value(
          'Write Markdown. Use [[slug]] to refer to a Node.',
        ),
        backgroundColor: Color(0xF2283252),
        borderStyle: _creationBorder,
        text: LayoutTextConfig(
          color: Color(0xFFFFF8E7),
          fontFamily: SevilleTypography.fontFamily,
          fontSize: 18,
        ),
      ),
      borderStyle: _creationBorder,
      text: LayoutTextConfig(
        value: LayoutText.value('2 · DESCRIPTION — CLICK TO WRITE MARKDOWN'),
        color: Color(0xFFB7C2FF),
        fontFamily: SevilleTypography.nodeFontFamily,
        fontSize: 18,
      ),
    ),
  },
);

final _creationActions = RowLayout(
  slot: 'creation-actions',
  aliases: ['creation-actions', 'creation-navigation'],
  text: LayoutTextConfig(flow: LayoutTextFlow.horizontal()),
  children: {
    'choose-another-kind': PanelLayout(
      size: LayoutSize.fr(1),
      state: LayoutState({
        LayoutCondition.creationNodeHasLabels(lgErgoCreationRootLabels):
            LayoutConfig(visible: true),
      }),
      aliases: ['action-button', 'creation-back-action'],
      onTap: LayoutTapAction.selectCreationLabels(
        labels: [],
        exclusiveWith: lgErgoCreationRootLabels,
      ),
      borderStyle: _creationBorder,
      text: LayoutTextConfig(value: LayoutText.value('← KINDS')),
    ),
    'cancel-creation': PanelLayout(
      size: LayoutSize.fr(1),
      aliases: ['action-button', 'cancel-interface-action'],
      borderStyle: _creationBorder,
      text: LayoutTextConfig(value: LayoutText.value('✕ CANCEL')),
    ),
    'confirm-creation': PanelLayout(
      size: LayoutSize.fr(1),
      state: LayoutState({
        LayoutCondition.creationNodeHasLabels(lgErgoCreationRootLabels):
            LayoutConfig(visible: true),
      }),
      aliases: ['action-button', 'submit-action', 'create-first-virtual-node'],
      borderStyle: _creationBorder,
      text: LayoutTextConfig(value: LayoutText.value('✓ CREATE')),
    ),
  },
);

const _creationBorder = GuideStyle(
  color: Color(0xCCB7C2FF),
  strokeWidth: 1.2,
  pattern: GuideLinePattern.solid,
);

const _creationEmoji = <String, String>{
  'Character': '🧍',
  'Project': '🧭',
  'Universe': '🌌',
  'Business': '🏢',
  'Item': '⚔️',
  'Event': '📅',
  'Space': '🏕️',
};
