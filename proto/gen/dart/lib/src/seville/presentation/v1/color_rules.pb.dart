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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'color_rules.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'color_rules.pbenum.dart';

/// Rule order breaks equal-weight ties. Higher weights win.
class NodeColorRule extends $pb.GeneratedMessage {
  factory NodeColorRule({
    $core.String? name,
    $core.bool? enabled,
    $core.int? weight,
    ColorRuleField? field_4,
    ColorRuleOperator? operator,
    $core.String? value,
    $core.String? frontmatterKey,
    $core.String? colorHex,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (enabled != null) result.enabled = enabled;
    if (weight != null) result.weight = weight;
    if (field_4 != null) result.field_4 = field_4;
    if (operator != null) result.operator = operator;
    if (value != null) result.value = value;
    if (frontmatterKey != null) result.frontmatterKey = frontmatterKey;
    if (colorHex != null) result.colorHex = colorHex;
    return result;
  }

  NodeColorRule._();

  factory NodeColorRule.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeColorRule.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeColorRule',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'seville.presentation.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOB(2, _omitFieldNames ? '' : 'enabled')
    ..aI(3, _omitFieldNames ? '' : 'weight')
    ..aE<ColorRuleField>(4, _omitFieldNames ? '' : 'field',
        enumValues: ColorRuleField.values)
    ..aE<ColorRuleOperator>(5, _omitFieldNames ? '' : 'operator',
        enumValues: ColorRuleOperator.values)
    ..aOS(6, _omitFieldNames ? '' : 'value')
    ..aOS(7, _omitFieldNames ? '' : 'frontmatterKey')
    ..aOS(8, _omitFieldNames ? '' : 'colorHex')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeColorRule clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeColorRule copyWith(void Function(NodeColorRule) updates) =>
      super.copyWith((message) => updates(message as NodeColorRule))
          as NodeColorRule;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeColorRule create() => NodeColorRule._();
  @$core.override
  NodeColorRule createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NodeColorRule getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeColorRule>(create);
  static NodeColorRule? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get enabled => $_getBF(1);
  @$pb.TagNumber(2)
  set enabled($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEnabled() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnabled() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get weight => $_getIZ(2);
  @$pb.TagNumber(3)
  set weight($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasWeight() => $_has(2);
  @$pb.TagNumber(3)
  void clearWeight() => $_clearField(3);

  @$pb.TagNumber(4)
  ColorRuleField get field_4 => $_getN(3);
  @$pb.TagNumber(4)
  set field_4(ColorRuleField value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasField_4() => $_has(3);
  @$pb.TagNumber(4)
  void clearField_4() => $_clearField(4);

  @$pb.TagNumber(5)
  ColorRuleOperator get operator => $_getN(4);
  @$pb.TagNumber(5)
  set operator(ColorRuleOperator value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasOperator() => $_has(4);
  @$pb.TagNumber(5)
  void clearOperator() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get value => $_getSZ(5);
  @$pb.TagNumber(6)
  set value($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasValue() => $_has(5);
  @$pb.TagNumber(6)
  void clearValue() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get frontmatterKey => $_getSZ(6);
  @$pb.TagNumber(7)
  set frontmatterKey($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasFrontmatterKey() => $_has(6);
  @$pb.TagNumber(7)
  void clearFrontmatterKey() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get colorHex => $_getSZ(7);
  @$pb.TagNumber(8)
  set colorHex($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasColorHex() => $_has(7);
  @$pb.TagNumber(8)
  void clearColorHex() => $_clearField(8);
}

/// PUT replaces the complete shared ruleset when revision matches the server.
class NodeColorRuleSet extends $pb.GeneratedMessage {
  factory NodeColorRuleSet({
    $fixnum.Int64? revision,
    $core.Iterable<NodeColorRule>? rules,
  }) {
    final result = create();
    if (revision != null) result.revision = revision;
    if (rules != null) result.rules.addAll(rules);
    return result;
  }

  NodeColorRuleSet._();

  factory NodeColorRuleSet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeColorRuleSet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeColorRuleSet',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'seville.presentation.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pPM<NodeColorRule>(2, _omitFieldNames ? '' : 'rules',
        subBuilder: NodeColorRule.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeColorRuleSet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeColorRuleSet copyWith(void Function(NodeColorRuleSet) updates) =>
      super.copyWith((message) => updates(message as NodeColorRuleSet))
          as NodeColorRuleSet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeColorRuleSet create() => NodeColorRuleSet._();
  @$core.override
  NodeColorRuleSet createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NodeColorRuleSet getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeColorRuleSet>(create);
  static NodeColorRuleSet? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get revision => $_getI64(0);
  @$pb.TagNumber(1)
  set revision($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRevision() => $_has(0);
  @$pb.TagNumber(1)
  void clearRevision() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<NodeColorRule> get rules => $_getList(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
