// This is a generated file - do not edit.
//
// Generated from seville/node/v2/node.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $0;

import 'node.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'node.pbenum.dart';

class Node extends $pb.GeneratedMessage {
  factory Node({
    $core.String? path,
    $core.String? title,
    $core.String? body,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? frontmatter,
    $0.Timestamp? modifiedAt,
    $core.Iterable<Emoji>? emojis,
    $core.Iterable<$core.String>? labels,
    $core.String? slug,
    $fixnum.Int64? updateCount,
    NodeTemporalSpan? temporalSpan,
  }) {
    final result = create();
    if (path != null) result.path = path;
    if (title != null) result.title = title;
    if (body != null) result.body = body;
    if (frontmatter != null) result.frontmatter.addEntries(frontmatter);
    if (modifiedAt != null) result.modifiedAt = modifiedAt;
    if (emojis != null) result.emojis.addAll(emojis);
    if (labels != null) result.labels.addAll(labels);
    if (slug != null) result.slug = slug;
    if (updateCount != null) result.updateCount = updateCount;
    if (temporalSpan != null) result.temporalSpan = temporalSpan;
    return result;
  }

  Node._();

  factory Node.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Node.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Node',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'seville.node.v2'),
      createEmptyInstance: create)
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..aOS(3, _omitFieldNames ? '' : 'title')
    ..aOS(4, _omitFieldNames ? '' : 'body')
    ..m<$core.String, $core.String>(6, _omitFieldNames ? '' : 'frontmatter',
        entryClassName: 'Node.FrontmatterEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('seville.node.v2'))
    ..aOM<$0.Timestamp>(7, _omitFieldNames ? '' : 'modifiedAt',
        subBuilder: $0.Timestamp.create)
    ..pPM<Emoji>(8, _omitFieldNames ? '' : 'emojis', subBuilder: Emoji.create)
    ..pPS(9, _omitFieldNames ? '' : 'labels')
    ..aOS(10, _omitFieldNames ? '' : 'slug')
    ..a<$fixnum.Int64>(
        11, _omitFieldNames ? '' : 'updateCount', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<NodeTemporalSpan>(12, _omitFieldNames ? '' : 'temporalSpan',
        subBuilder: NodeTemporalSpan.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Node clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Node copyWith(void Function(Node) updates) =>
      super.copyWith((message) => updates(message as Node)) as Node;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Node create() => Node._();
  @$core.override
  Node createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Node getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Node>(create);
  static Node? _defaultInstance;

  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(2)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(3)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(3)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(3)
  void clearTitle() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get body => $_getSZ(2);
  @$pb.TagNumber(4)
  set body($core.String value) => $_setString(2, value);
  @$pb.TagNumber(4)
  $core.bool hasBody() => $_has(2);
  @$pb.TagNumber(4)
  void clearBody() => $_clearField(4);

  @$pb.TagNumber(6)
  $pb.PbMap<$core.String, $core.String> get frontmatter => $_getMap(3);

  @$pb.TagNumber(7)
  $0.Timestamp get modifiedAt => $_getN(4);
  @$pb.TagNumber(7)
  set modifiedAt($0.Timestamp value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasModifiedAt() => $_has(4);
  @$pb.TagNumber(7)
  void clearModifiedAt() => $_clearField(7);
  @$pb.TagNumber(7)
  $0.Timestamp ensureModifiedAt() => $_ensure(4);

  @$pb.TagNumber(8)
  $pb.PbList<Emoji> get emojis => $_getList(5);

  @$pb.TagNumber(9)
  $pb.PbList<$core.String> get labels => $_getList(6);

  @$pb.TagNumber(10)
  $core.String get slug => $_getSZ(7);
  @$pb.TagNumber(10)
  set slug($core.String value) => $_setString(7, value);
  @$pb.TagNumber(10)
  $core.bool hasSlug() => $_has(7);
  @$pb.TagNumber(10)
  void clearSlug() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get updateCount => $_getI64(8);
  @$pb.TagNumber(11)
  set updateCount($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(11)
  $core.bool hasUpdateCount() => $_has(8);
  @$pb.TagNumber(11)
  void clearUpdateCount() => $_clearField(11);

  @$pb.TagNumber(12)
  NodeTemporalSpan get temporalSpan => $_getN(9);
  @$pb.TagNumber(12)
  set temporalSpan(NodeTemporalSpan value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasTemporalSpan() => $_has(9);
  @$pb.TagNumber(12)
  void clearTemporalSpan() => $_clearField(12);
  @$pb.TagNumber(12)
  NodeTemporalSpan ensureTemporalSpan() => $_ensure(9);
}

/// Calendar interval [start_date, end_date_exclusive), stored as native Neo4j DATE values.
class NodeTemporalSpan extends $pb.GeneratedMessage {
  factory NodeTemporalSpan({
    $core.String? startDate,
    $core.String? endDateExclusive,
    TemporalGranularity? granularity,
  }) {
    final result = create();
    if (startDate != null) result.startDate = startDate;
    if (endDateExclusive != null) result.endDateExclusive = endDateExclusive;
    if (granularity != null) result.granularity = granularity;
    return result;
  }

  NodeTemporalSpan._();

  factory NodeTemporalSpan.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeTemporalSpan.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeTemporalSpan',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'seville.node.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'startDate')
    ..aOS(2, _omitFieldNames ? '' : 'endDateExclusive')
    ..aE<TemporalGranularity>(3, _omitFieldNames ? '' : 'granularity',
        enumValues: TemporalGranularity.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeTemporalSpan clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeTemporalSpan copyWith(void Function(NodeTemporalSpan) updates) =>
      super.copyWith((message) => updates(message as NodeTemporalSpan))
          as NodeTemporalSpan;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeTemporalSpan create() => NodeTemporalSpan._();
  @$core.override
  NodeTemporalSpan createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NodeTemporalSpan getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeTemporalSpan>(create);
  static NodeTemporalSpan? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get startDate => $_getSZ(0);
  @$pb.TagNumber(1)
  set startDate($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStartDate() => $_has(0);
  @$pb.TagNumber(1)
  void clearStartDate() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get endDateExclusive => $_getSZ(1);
  @$pb.TagNumber(2)
  set endDateExclusive($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEndDateExclusive() => $_has(1);
  @$pb.TagNumber(2)
  void clearEndDateExclusive() => $_clearField(2);

  @$pb.TagNumber(3)
  TemporalGranularity get granularity => $_getN(2);
  @$pb.TagNumber(3)
  set granularity(TemporalGranularity value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasGranularity() => $_has(2);
  @$pb.TagNumber(3)
  void clearGranularity() => $_clearField(3);
}

class Emoji extends $pb.GeneratedMessage {
  factory Emoji({
    $core.String? id,
    $core.String? character,
    $core.String? title,
    $core.String? codes,
    $core.String? groupName,
    $core.String? subgroup,
    $core.String? category,
    $core.String? source,
    $fixnum.Int64? counter,
    $0.Timestamp? createdAt,
    $0.Timestamp? updatedAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (character != null) result.character = character;
    if (title != null) result.title = title;
    if (codes != null) result.codes = codes;
    if (groupName != null) result.groupName = groupName;
    if (subgroup != null) result.subgroup = subgroup;
    if (category != null) result.category = category;
    if (source != null) result.source = source;
    if (counter != null) result.counter = counter;
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    return result;
  }

  Emoji._();

  factory Emoji.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Emoji.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Emoji',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'seville.node.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'character')
    ..aOS(3, _omitFieldNames ? '' : 'title')
    ..aOS(4, _omitFieldNames ? '' : 'codes')
    ..aOS(5, _omitFieldNames ? '' : 'groupName')
    ..aOS(6, _omitFieldNames ? '' : 'subgroup')
    ..aOS(7, _omitFieldNames ? '' : 'category')
    ..aOS(8, _omitFieldNames ? '' : 'source')
    ..a<$fixnum.Int64>(9, _omitFieldNames ? '' : 'counter', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<$0.Timestamp>(10, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $0.Timestamp.create)
    ..aOM<$0.Timestamp>(11, _omitFieldNames ? '' : 'updatedAt',
        subBuilder: $0.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Emoji clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Emoji copyWith(void Function(Emoji) updates) =>
      super.copyWith((message) => updates(message as Emoji)) as Emoji;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Emoji create() => Emoji._();
  @$core.override
  Emoji createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Emoji getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Emoji>(create);
  static Emoji? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get character => $_getSZ(1);
  @$pb.TagNumber(2)
  set character($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCharacter() => $_has(1);
  @$pb.TagNumber(2)
  void clearCharacter() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get title => $_getSZ(2);
  @$pb.TagNumber(3)
  set title($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTitle() => $_has(2);
  @$pb.TagNumber(3)
  void clearTitle() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get codes => $_getSZ(3);
  @$pb.TagNumber(4)
  set codes($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCodes() => $_has(3);
  @$pb.TagNumber(4)
  void clearCodes() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get groupName => $_getSZ(4);
  @$pb.TagNumber(5)
  set groupName($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasGroupName() => $_has(4);
  @$pb.TagNumber(5)
  void clearGroupName() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get subgroup => $_getSZ(5);
  @$pb.TagNumber(6)
  set subgroup($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSubgroup() => $_has(5);
  @$pb.TagNumber(6)
  void clearSubgroup() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get category => $_getSZ(6);
  @$pb.TagNumber(7)
  set category($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCategory() => $_has(6);
  @$pb.TagNumber(7)
  void clearCategory() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get source => $_getSZ(7);
  @$pb.TagNumber(8)
  set source($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSource() => $_has(7);
  @$pb.TagNumber(8)
  void clearSource() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get counter => $_getI64(8);
  @$pb.TagNumber(9)
  set counter($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasCounter() => $_has(8);
  @$pb.TagNumber(9)
  void clearCounter() => $_clearField(9);

  @$pb.TagNumber(10)
  $0.Timestamp get createdAt => $_getN(9);
  @$pb.TagNumber(10)
  set createdAt($0.Timestamp value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasCreatedAt() => $_has(9);
  @$pb.TagNumber(10)
  void clearCreatedAt() => $_clearField(10);
  @$pb.TagNumber(10)
  $0.Timestamp ensureCreatedAt() => $_ensure(9);

  @$pb.TagNumber(11)
  $0.Timestamp get updatedAt => $_getN(10);
  @$pb.TagNumber(11)
  set updatedAt($0.Timestamp value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasUpdatedAt() => $_has(10);
  @$pb.TagNumber(11)
  void clearUpdatedAt() => $_clearField(11);
  @$pb.TagNumber(11)
  $0.Timestamp ensureUpdatedAt() => $_ensure(10);
}

class NodeConnection extends $pb.GeneratedMessage {
  factory NodeConnection({
    $core.String? sourceNodeSlug,
    $core.String? targetText,
    $core.String? targetNodeSlug,
    $core.String? displayText,
    NodeConnectionKind? kind,
    $core.String? fragment,
  }) {
    final result = create();
    if (sourceNodeSlug != null) result.sourceNodeSlug = sourceNodeSlug;
    if (targetText != null) result.targetText = targetText;
    if (targetNodeSlug != null) result.targetNodeSlug = targetNodeSlug;
    if (displayText != null) result.displayText = displayText;
    if (kind != null) result.kind = kind;
    if (fragment != null) result.fragment = fragment;
    return result;
  }

  NodeConnection._();

  factory NodeConnection.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeConnection.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeConnection',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'seville.node.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sourceNodeSlug')
    ..aOS(2, _omitFieldNames ? '' : 'targetText')
    ..aOS(3, _omitFieldNames ? '' : 'targetNodeSlug')
    ..aOS(4, _omitFieldNames ? '' : 'displayText')
    ..aE<NodeConnectionKind>(5, _omitFieldNames ? '' : 'kind',
        enumValues: NodeConnectionKind.values)
    ..aOS(6, _omitFieldNames ? '' : 'fragment')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeConnection clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeConnection copyWith(void Function(NodeConnection) updates) =>
      super.copyWith((message) => updates(message as NodeConnection))
          as NodeConnection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeConnection create() => NodeConnection._();
  @$core.override
  NodeConnection createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NodeConnection getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeConnection>(create);
  static NodeConnection? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sourceNodeSlug => $_getSZ(0);
  @$pb.TagNumber(1)
  set sourceNodeSlug($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSourceNodeSlug() => $_has(0);
  @$pb.TagNumber(1)
  void clearSourceNodeSlug() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get targetText => $_getSZ(1);
  @$pb.TagNumber(2)
  set targetText($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTargetText() => $_has(1);
  @$pb.TagNumber(2)
  void clearTargetText() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get targetNodeSlug => $_getSZ(2);
  @$pb.TagNumber(3)
  set targetNodeSlug($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTargetNodeSlug() => $_has(2);
  @$pb.TagNumber(3)
  void clearTargetNodeSlug() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get displayText => $_getSZ(3);
  @$pb.TagNumber(4)
  set displayText($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDisplayText() => $_has(3);
  @$pb.TagNumber(4)
  void clearDisplayText() => $_clearField(4);

  @$pb.TagNumber(5)
  NodeConnectionKind get kind => $_getN(4);
  @$pb.TagNumber(5)
  set kind(NodeConnectionKind value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasKind() => $_has(4);
  @$pb.TagNumber(5)
  void clearKind() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get fragment => $_getSZ(5);
  @$pb.TagNumber(6)
  set fragment($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasFragment() => $_has(5);
  @$pb.TagNumber(6)
  void clearFragment() => $_clearField(6);
}

class ApiError extends $pb.GeneratedMessage {
  factory ApiError({
    $core.String? code,
    $core.String? message,
  }) {
    final result = create();
    if (code != null) result.code = code;
    if (message != null) result.message = message;
    return result;
  }

  ApiError._();

  factory ApiError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ApiError.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ApiError',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'seville.node.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'code')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApiError clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApiError copyWith(void Function(ApiError) updates) =>
      super.copyWith((message) => updates(message as ApiError)) as ApiError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApiError create() => ApiError._();
  @$core.override
  ApiError createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ApiError getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApiError>(create);
  static ApiError? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
