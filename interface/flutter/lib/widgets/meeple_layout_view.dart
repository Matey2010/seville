import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/meeple_layout.dart';

class MeepleLayoutView extends StatelessWidget {
  const MeepleLayoutView({
    required this.layout,
    this.fillAvailableBounds = false,
    super.key,
  });

  final MeepleLayout layout;
  final bool fillAvailableBounds;

  @override
  Widget build(BuildContext context) {
    final config = layout.config;
    return LayoutBuilder(
      builder: (context, constraints) {
        final layoutHeight = fillAvailableBounds
            ? constraints.maxHeight
            : config.layoutHeightFor(constraints.maxHeight);
        final layoutWidth = fillAvailableBounds
            ? constraints.maxWidth
            : config.layoutWidthFor(constraints.maxHeight);
        return Align(
          alignment: Alignment.bottomCenter,
          child: IgnorePointer(
            child: SizedBox(
              width: layoutWidth,
              height: layoutHeight,
              child: ColoredBox(
                color: config.backgroundColor,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    config.padding.left,
                    config.padding.top,
                    config.padding.right,
                    config.padding.bottom,
                  ),
                  child: SvgPicture.asset(
                    config.assetPath,
                    alignment: Alignment.bottomCenter,
                    fit: BoxFit.contain,
                    colorFilter: ColorFilter.mode(
                      config.bodyColor,
                      BlendMode.srcIn,
                    ),
                    semanticsLabel: 'Meeple',
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
