import '../../models/layout/layout.dart';

const lgErgoFanRootSlug = 'cortex-timeline-calendar-2026-06-fr6h';

const lgErgoFanRootNodeFilter = NodeSearchFilter.allOf([
  NodeSearchParameter(
    parameter: NodeParameter.slug,
    value: lgErgoFanRootSlug,
    operator: NodeMatchOperator.exact,
  ),
  NodeSearchParameter(
    parameter: NodeParameter.label,
    value: 'Calendar',
    operator: NodeMatchOperator.contains,
  ),
]);
