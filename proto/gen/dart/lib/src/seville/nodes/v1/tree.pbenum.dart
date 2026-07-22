// This is a generated file - do not edit.
//
// Generated from seville/nodes/v1/tree.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class NodeRelationshipType extends $pb.ProtobufEnum {
  static const NodeRelationshipType NODE_RELATIONSHIP_TYPE_UNSPECIFIED =
      NodeRelationshipType._(
          0, _omitEnumNames ? '' : 'NODE_RELATIONSHIP_TYPE_UNSPECIFIED');
  static const NodeRelationshipType NODE_RELATIONSHIP_TYPE_PART_OF =
      NodeRelationshipType._(
          1, _omitEnumNames ? '' : 'NODE_RELATIONSHIP_TYPE_PART_OF');
  static const NodeRelationshipType NODE_RELATIONSHIP_TYPE_FAMILY =
      NodeRelationshipType._(
          2, _omitEnumNames ? '' : 'NODE_RELATIONSHIP_TYPE_FAMILY');

  static const $core.List<NodeRelationshipType> values = <NodeRelationshipType>[
    NODE_RELATIONSHIP_TYPE_UNSPECIFIED,
    NODE_RELATIONSHIP_TYPE_PART_OF,
    NODE_RELATIONSHIP_TYPE_FAMILY,
  ];

  static final $core.List<NodeRelationshipType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static NodeRelationshipType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const NodeRelationshipType._(super.value, super.name);
}

class NodeParameterType extends $pb.ProtobufEnum {
  static const NodeParameterType NODE_PARAMETER_TYPE_UNSPECIFIED =
      NodeParameterType._(
          0, _omitEnumNames ? '' : 'NODE_PARAMETER_TYPE_UNSPECIFIED');
  static const NodeParameterType NODE_PARAMETER_TYPE_NAME =
      NodeParameterType._(1, _omitEnumNames ? '' : 'NODE_PARAMETER_TYPE_NAME');
  static const NodeParameterType NODE_PARAMETER_TYPE_ID =
      NodeParameterType._(2, _omitEnumNames ? '' : 'NODE_PARAMETER_TYPE_ID');
  static const NodeParameterType NODE_PARAMETER_TYPE_PATH =
      NodeParameterType._(3, _omitEnumNames ? '' : 'NODE_PARAMETER_TYPE_PATH');
  static const NodeParameterType NODE_PARAMETER_TYPE_TITLE =
      NodeParameterType._(4, _omitEnumNames ? '' : 'NODE_PARAMETER_TYPE_TITLE');
  static const NodeParameterType NODE_PARAMETER_TYPE_TAG =
      NodeParameterType._(5, _omitEnumNames ? '' : 'NODE_PARAMETER_TYPE_TAG');
  static const NodeParameterType NODE_PARAMETER_TYPE_LABEL =
      NodeParameterType._(6, _omitEnumNames ? '' : 'NODE_PARAMETER_TYPE_LABEL');
  static const NodeParameterType NODE_PARAMETER_TYPE_SLUG =
      NodeParameterType._(7, _omitEnumNames ? '' : 'NODE_PARAMETER_TYPE_SLUG');

  static const $core.List<NodeParameterType> values = <NodeParameterType>[
    NODE_PARAMETER_TYPE_UNSPECIFIED,
    NODE_PARAMETER_TYPE_NAME,
    NODE_PARAMETER_TYPE_ID,
    NODE_PARAMETER_TYPE_PATH,
    NODE_PARAMETER_TYPE_TITLE,
    NODE_PARAMETER_TYPE_TAG,
    NODE_PARAMETER_TYPE_LABEL,
    NODE_PARAMETER_TYPE_SLUG,
  ];

  static final $core.List<NodeParameterType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static NodeParameterType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const NodeParameterType._(super.value, super.name);
}

class NodeSearchMatchOperator extends $pb.ProtobufEnum {
  static const NodeSearchMatchOperator NODE_SEARCH_MATCH_OPERATOR_UNSPECIFIED =
      NodeSearchMatchOperator._(
          0, _omitEnumNames ? '' : 'NODE_SEARCH_MATCH_OPERATOR_UNSPECIFIED');
  static const NodeSearchMatchOperator NODE_SEARCH_MATCH_OPERATOR_EXACT =
      NodeSearchMatchOperator._(
          1, _omitEnumNames ? '' : 'NODE_SEARCH_MATCH_OPERATOR_EXACT');
  static const NodeSearchMatchOperator
      NODE_SEARCH_MATCH_OPERATOR_REGULAR_EXPRESSION = NodeSearchMatchOperator._(
          2,
          _omitEnumNames
              ? ''
              : 'NODE_SEARCH_MATCH_OPERATOR_REGULAR_EXPRESSION');
  static const NodeSearchMatchOperator NODE_SEARCH_MATCH_OPERATOR_STARTS_WITH =
      NodeSearchMatchOperator._(
          3, _omitEnumNames ? '' : 'NODE_SEARCH_MATCH_OPERATOR_STARTS_WITH');
  static const NodeSearchMatchOperator NODE_SEARCH_MATCH_OPERATOR_ENDS_WITH =
      NodeSearchMatchOperator._(
          4, _omitEnumNames ? '' : 'NODE_SEARCH_MATCH_OPERATOR_ENDS_WITH');
  static const NodeSearchMatchOperator NODE_SEARCH_MATCH_OPERATOR_CONTAINS =
      NodeSearchMatchOperator._(
          5, _omitEnumNames ? '' : 'NODE_SEARCH_MATCH_OPERATOR_CONTAINS');

  static const $core.List<NodeSearchMatchOperator> values =
      <NodeSearchMatchOperator>[
    NODE_SEARCH_MATCH_OPERATOR_UNSPECIFIED,
    NODE_SEARCH_MATCH_OPERATOR_EXACT,
    NODE_SEARCH_MATCH_OPERATOR_REGULAR_EXPRESSION,
    NODE_SEARCH_MATCH_OPERATOR_STARTS_WITH,
    NODE_SEARCH_MATCH_OPERATOR_ENDS_WITH,
    NODE_SEARCH_MATCH_OPERATOR_CONTAINS,
  ];

  static final $core.List<NodeSearchMatchOperator?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static NodeSearchMatchOperator? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const NodeSearchMatchOperator._(super.value, super.name);
}

class NodeSearchMatchMode extends $pb.ProtobufEnum {
  static const NodeSearchMatchMode NODE_SEARCH_MATCH_MODE_UNSPECIFIED =
      NodeSearchMatchMode._(
          0, _omitEnumNames ? '' : 'NODE_SEARCH_MATCH_MODE_UNSPECIFIED');
  static const NodeSearchMatchMode NODE_SEARCH_MATCH_MODE_ANY =
      NodeSearchMatchMode._(
          1, _omitEnumNames ? '' : 'NODE_SEARCH_MATCH_MODE_ANY');
  static const NodeSearchMatchMode NODE_SEARCH_MATCH_MODE_ALL =
      NodeSearchMatchMode._(
          2, _omitEnumNames ? '' : 'NODE_SEARCH_MATCH_MODE_ALL');

  static const $core.List<NodeSearchMatchMode> values = <NodeSearchMatchMode>[
    NODE_SEARCH_MATCH_MODE_UNSPECIFIED,
    NODE_SEARCH_MATCH_MODE_ANY,
    NODE_SEARCH_MATCH_MODE_ALL,
  ];

  static final $core.List<NodeSearchMatchMode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static NodeSearchMatchMode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const NodeSearchMatchMode._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
