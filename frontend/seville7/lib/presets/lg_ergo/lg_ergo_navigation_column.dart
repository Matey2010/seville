import 'dart:ui';

import '../../constants/typography.dart';
import '../../models/layout/layout.dart';
import 'lg_ergo_panel_states.dart';

final lgErgoNavigationColumn = ColumnLayout(
  state: LayoutState({LayoutCondition.mainMenu(): LayoutConfig(visible: true)}),
  text: LayoutTextConfig(
    fontFamily: SevilleTypography.nodeFontFamily,
    fontSize: 32,
    letterSpacing: 0,
    wordSpacing: 0.5,
    flow: LayoutTextFlow.horizontal(),
  ),
  background: lgErgoDarkVintageActionBackground,
  layoutPadding: 20,
  slot: 'navigation-column',
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
    'navigation-row',
    'browser-navigation',
  ],
  size: LayoutSize.px(48),
  children: {
    'continue': PanelLayout(
      state: lgErgoWeaponFocusPanelState,
      onTap: LayoutTapAction.continueGame(),
      aliases: ['continue-game-action'],
      borderStyle: GuideStyle(
        color: Color(0xFFFFD54F),
        strokeWidth: 1.2,
        pattern: GuideLinePattern.solid,
      ),
      text: LayoutTextConfig(value: LayoutText.value('▶ Continue')),
    ),
    'add-node': PanelLayout(
      state: lgErgoWeaponFocusPanelState,
      onTap: LayoutTapAction.beginNodeCreation(),
      aliases: ['action-button', 'add-action', 'create-virtual-node'],
      borderStyle: (GuideStyle(
        color: Color(0xCCB7C2FF),
        strokeWidth: 1,
        pattern: GuideLinePattern.solid,
      )),
      text: LayoutTextConfig(
        color: Color.fromARGB(255, 133, 255, 33),
        value: LayoutText.value('🏁 New | N'),
      ),
    ),
    'today': PanelLayout(
      state: lgErgoWeaponFocusPanelState,
      onTap: LayoutTapAction.beginNodeCreation(
        labels: ['Event', 'Day', 'Date'],
      ),
      aliases: ['action-button', 'today-action', 'resolve-today-node'],
      borderStyle: (GuideStyle(
        color: Color(0xCCB7C2FF),
        strokeWidth: 1,
        pattern: GuideLinePattern.solid,
      )),
      text: LayoutTextConfig(value: LayoutText.value('📅 Today 3! 3! 3!]')),
    ),
    'settings': PanelLayout(
      state: lgErgoWeaponFocusPanelState,
      aliases: ['header-settings', 'settings-shortcut'],
      borderStyle: GuideStyle(
        color: Color(0xFFFFD54F),
        strokeWidth: 1.2,
        pattern: GuideLinePattern.solid,
      ),
      text: LayoutTextConfig(value: LayoutText.value('⚙️ settings | O')),
    ),
  },
);
