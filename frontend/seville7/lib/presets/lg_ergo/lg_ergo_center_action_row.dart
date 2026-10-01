import 'dart:ui';

import '../../models/layout/layout.dart';
import 'lg_ergo_panel_states.dart';

final lgErgoCenterActionRow = RowLayout(
  slot: 'center-action-row',
  aliases: ['center-action-row', 'confirm-close-row', 'keyboard-action-row'],
  background: lgErgoDarkVintageActionBackground,
  text: LayoutTextConfig(flow: LayoutTextFlow.horizontal()),
  state: LayoutState({
    LayoutCondition.mainMenu(): LayoutConfig(visible: true),
    LayoutCondition.gameplay(): LayoutConfig(visible: true),
  }),
  children: {
    'close-selection': PanelLayout(
      size: LayoutSize.fr(1),
      state: lgErgoWeaponFocusPanelState.merge(
        LayoutState({
          LayoutCondition.gameplay(): LayoutConfig(
            text: LayoutTextConfig(value: LayoutText.value('× Menu | Esc')),
          ),
        }),
      ),
      aliases: [
        'action-button',
        'close-action',
        'cancel-interface-action',
        'clear-selection-action',
      ],
      borderStyle: GuideStyle(
        color: Color(0xCCB7C2FF),
        strokeWidth: 1,
        pattern: GuideLinePattern.solid,
      ),
      text: LayoutTextConfig(value: LayoutText.value('× Close | Esc')),
    ),
    'confirm': PanelLayout(
      size: LayoutSize.fr(1),
      state: lgErgoOppositeWeaponFocusPanelState.merge(
        LayoutState({LayoutCondition.mainMenu(): LayoutConfig(visible: true)}),
      ),
      aliases: [
        'action-button',
        'confirm-action',
        'submit-action',
        'create-first-virtual-node',
      ],
      borderStyle: GuideStyle(
        color: Color(0xCCB7C2FF),
        strokeWidth: 1,
        pattern: GuideLinePattern.solid,
      ),
      text: LayoutTextConfig(value: LayoutText.value('✅ Confirm | Enter')),
    ),
  },
);
