import 'package:flutter/widgets.dart';

import '../models/layout.dart';

typedef LayoutWidgetBuilder =
    Widget Function(
      BuildContext context,
      Layout layout,
      LayoutRendererRegistry registry,
    );

class LayoutRendererRegistry {
  const LayoutRendererRegistry({this.builders = const {}});

  final Map<Type, LayoutWidgetBuilder> builders;

  Widget build(BuildContext context, Layout layout) {
    final builder = builders[layout.runtimeType];
    if (builder == null) return const SizedBox.expand();
    return builder(context, layout, this);
  }

  LayoutRendererRegistry extended(Map<Type, LayoutWidgetBuilder> additions) {
    return LayoutRendererRegistry(builders: {...builders, ...additions});
  }
}
