import '../../models/layout/layout.dart';

final lgErgoWeaponFocusPanelState = _weaponFocusPanelState(90);

final lgErgoOppositeWeaponFocusPanelState = _weaponFocusPanelState(-90);

final lgErgoDarkVintageActionBackground = <LayoutBackground>[
  LayoutBackground.image(
    assetPath: 'assets/wallpapers/dark-vintage-scheme.jpg',
    fit: LayoutBackgroundFit.cover,
    orderPosition: 1,
    opacity: 0.75,
  ),
];

const _lgErgoWeaponAssets = <String>[
  'assets/icons/vector/modular-sword.svg',
  'assets/icons/vector/modular-long-sword.svg',
  'assets/icons/vector/modular-spear.svg',
  'assets/icons/vector/shiv.svg',
  'assets/icons/vector/cursed-sword.svg',
  'assets/icons/vector/world-staff.svg',
];

LayoutState<LayoutConfig> _weaponFocusPanelState(double rotationDegrees) =>
    LayoutState({
      LayoutCondition.panelFocused(): LayoutConfig(
        background: [
          LayoutBackground.random([
            for (final assetPath in _lgErgoWeaponAssets)
              LayoutBackground.svg(
                assetPath: assetPath,
                fit: LayoutBackgroundFit.contain,
                rotationDegrees: rotationDegrees,
              ),
          ]),
        ],
      ),
    });
