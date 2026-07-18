import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/meeple_layout.dart';

class MeepleLayoutComponent extends PositionComponent {
  MeepleLayoutComponent({required this.layout});

  final MeepleLayout layout;
  PictureInfo? _pictureInfo;

  @override
  Future<void> onLoad() async {
    _pictureInfo = await vg.loadPicture(
      SvgAssetLoader(layout.config.assetPath),
      null,
    );
  }

  @override
  void onRemove() {
    _pictureInfo?.picture.dispose();
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    final config = layout.config;
    final bounds = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(bounds, Paint()..color = config.backgroundColor);

    final pictureInfo = _pictureInfo;
    if (pictureInfo == null || pictureInfo.size.isEmpty) return;
    final available = Rect.fromLTRB(
      config.padding.left,
      config.padding.top,
      size.x - config.padding.right,
      size.y - config.padding.bottom,
    );
    if (available.isEmpty) return;
    final scale = _min(
      available.width / pictureInfo.size.width,
      available.height / pictureInfo.size.height,
    );
    final drawnSize = pictureInfo.size * scale;
    final destination = Rect.fromLTWH(
      available.center.dx - drawnSize.width / 2,
      available.bottom - drawnSize.height,
      drawnSize.width,
      drawnSize.height,
    );
    canvas
      ..saveLayer(
        destination,
        Paint()
          ..colorFilter = ColorFilter.mode(config.bodyColor, BlendMode.srcIn),
      )
      ..translate(destination.left, destination.top)
      ..scale(scale, scale)
      ..drawPicture(pictureInfo.picture)
      ..restore();
  }
}

double _min(double left, double right) => left < right ? left : right;
