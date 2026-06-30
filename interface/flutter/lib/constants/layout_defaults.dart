import '../models/layout.dart';

abstract final class DefaultDimensions {
  static const bottomWallDepthTracks = 6;

  static const w40h10d6 = LayoutDimensions(
    dimensionCount: 3,
    axes: [40, 10, bottomWallDepthTracks],
  );

  static const h9v9 = LayoutDimensions(dimensionCount: 2, axes: [9, 9]);
  static const h36v36 = LayoutDimensions(dimensionCount: 2, axes: [36, 36]);
  static const h32v6 = LayoutDimensions(
    dimensionCount: 2,
    axes: [32, bottomWallDepthTracks],
  );
  static const h36v6 = LayoutDimensions(
    dimensionCount: 2,
    axes: [36, bottomWallDepthTracks],
  );
}

abstract final class DefaultLayout {
  static const bottomWallLayout = GridLayout(
    dimensions: DefaultDimensions.h36v6,
  );

  static const openBoxScene = SceneLayout(
    dimensions: DefaultDimensions.w40h10d6,
    subLayouts: {'bottom-wall': bottomWallLayout},
  );
}
