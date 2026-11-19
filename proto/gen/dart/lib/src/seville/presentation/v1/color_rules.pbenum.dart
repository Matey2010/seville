// This is a generated file - do not edit.
//
// Generated from seville/presentation/v1/color_rules.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ColorRuleField extends $pb.ProtobufEnum {
  static const ColorRuleField COLOR_RULE_FIELD_UNSPECIFIED =
      ColorRuleField._(0, _omitEnumNames ? '' : 'COLOR_RULE_FIELD_UNSPECIFIED');
  static const ColorRuleField COLOR_RULE_FIELD_LABEL =
      ColorRuleField._(2, _omitEnumNames ? '' : 'COLOR_RULE_FIELD_LABEL');
  static const ColorRuleField COLOR_RULE_FIELD_SLUG =
      ColorRuleField._(4, _omitEnumNames ? '' : 'COLOR_RULE_FIELD_SLUG');
  static const ColorRuleField COLOR_RULE_FIELD_TITLE =
      ColorRuleField._(5, _omitEnumNames ? '' : 'COLOR_RULE_FIELD_TITLE');
  static const ColorRuleField COLOR_RULE_FIELD_FRONTMATTER =
      ColorRuleField._(6, _omitEnumNames ? '' : 'COLOR_RULE_FIELD_FRONTMATTER');

  static const $core.List<ColorRuleField> values = <ColorRuleField>[
    COLOR_RULE_FIELD_UNSPECIFIED,
    COLOR_RULE_FIELD_LABEL,
    COLOR_RULE_FIELD_SLUG,
    COLOR_RULE_FIELD_TITLE,
    COLOR_RULE_FIELD_FRONTMATTER,
  ];

  static final $core.List<ColorRuleField?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static ColorRuleField? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ColorRuleField._(super.value, super.name);
}

class ColorRuleOperator extends $pb.ProtobufEnum {
  static const ColorRuleOperator COLOR_RULE_OPERATOR_UNSPECIFIED =
      ColorRuleOperator._(
          0, _omitEnumNames ? '' : 'COLOR_RULE_OPERATOR_UNSPECIFIED');
  static const ColorRuleOperator COLOR_RULE_OPERATOR_EXACT =
      ColorRuleOperator._(1, _omitEnumNames ? '' : 'COLOR_RULE_OPERATOR_EXACT');
  static const ColorRuleOperator COLOR_RULE_OPERATOR_CONTAINS =
      ColorRuleOperator._(
          2, _omitEnumNames ? '' : 'COLOR_RULE_OPERATOR_CONTAINS');
  static const ColorRuleOperator COLOR_RULE_OPERATOR_STARTS_WITH =
      ColorRuleOperator._(
          3, _omitEnumNames ? '' : 'COLOR_RULE_OPERATOR_STARTS_WITH');

  static const $core.List<ColorRuleOperator> values = <ColorRuleOperator>[
    COLOR_RULE_OPERATOR_UNSPECIFIED,
    COLOR_RULE_OPERATOR_EXACT,
    COLOR_RULE_OPERATOR_CONTAINS,
    COLOR_RULE_OPERATOR_STARTS_WITH,
  ];

  static final $core.List<ColorRuleOperator?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static ColorRuleOperator? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ColorRuleOperator._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
