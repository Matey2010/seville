// This is a generated file - do not edit.
//
// Generated from seville/system/v1/system.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class SystemInfo extends $pb.GeneratedMessage {
  factory SystemInfo({
    $fixnum.Int64? nodeCount,
    $fixnum.Int64? nodePropertyCount,
  }) {
    final result = create();
    if (nodeCount != null) result.nodeCount = nodeCount;
    if (nodePropertyCount != null) result.nodePropertyCount = nodePropertyCount;
    return result;
  }

  SystemInfo._();

  factory SystemInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SystemInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SystemInfo',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'seville.system.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'nodeCount', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'nodePropertyCount', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SystemInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SystemInfo copyWith(void Function(SystemInfo) updates) =>
      super.copyWith((message) => updates(message as SystemInfo)) as SystemInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SystemInfo create() => SystemInfo._();
  @$core.override
  SystemInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SystemInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SystemInfo>(create);
  static SystemInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get nodeCount => $_getI64(0);
  @$pb.TagNumber(1)
  set nodeCount($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNodeCount() => $_has(0);
  @$pb.TagNumber(1)
  void clearNodeCount() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get nodePropertyCount => $_getI64(1);
  @$pb.TagNumber(2)
  set nodePropertyCount($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNodePropertyCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearNodePropertyCount() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
