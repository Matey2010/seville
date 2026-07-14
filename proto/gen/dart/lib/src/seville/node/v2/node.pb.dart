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

import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $0;

import 'node.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'node.pbenum.dart';

class NodeSnapshot extends $pb.GeneratedMessage {
  factory NodeSnapshot({
    $core.String? revision,
    $0.Timestamp? generatedAt,
    $core.Iterable<Node>? nodes,
    $core.Iterable<NodeConnection>? connections,
    $core.Iterable<ImportWarning>? warnings,
  }) {
    final result = create();
    if (revision != null) result.revision = revision;
    if (generatedAt != null) result.generatedAt = generatedAt;
    if (nodes != null) result.nodes.addAll(nodes);
    if (connections != null) result.connections.addAll(connections);
    if (warnings != null) result.warnings.addAll(warnings);
    return result;
  }

  NodeSnapshot._();

  factory NodeSnapshot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeSnapshot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeSnapshot',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'seville.node.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'revision')
    ..aOM<$0.Timestamp>(2, _omitFieldNames ? '' : 'generatedAt',
        subBuilder: $0.Timestamp.create)
    ..pPM<Node>(3, _omitFieldNames ? '' : 'nodes', subBuilder: Node.create)
    ..pPM<NodeConnection>(4, _omitFieldNames ? '' : 'connections',
        subBuilder: NodeConnection.create)
    ..pPM<ImportWarning>(5, _omitFieldNames ? '' : 'warnings',
        subBuilder: ImportWarning.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeSnapshot clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeSnapshot copyWith(void Function(NodeSnapshot) updates) =>
      super.copyWith((message) => updates(message as NodeSnapshot))
          as NodeSnapshot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeSnapshot create() => NodeSnapshot._();
  @$core.override
  NodeSnapshot createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NodeSnapshot getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeSnapshot>(create);
  static NodeSnapshot? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get revision => $_getSZ(0);
  @$pb.TagNumber(1)
  set revision($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRevision() => $_has(0);
  @$pb.TagNumber(1)
  void clearRevision() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.Timestamp get generatedAt => $_getN(1);
  @$pb.TagNumber(2)
  set generatedAt($0.Timestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasGeneratedAt() => $_has(1);
  @$pb.TagNumber(2)
  void clearGeneratedAt() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Timestamp ensureGeneratedAt() => $_ensure(1);

  @$pb.TagNumber(3)
  $pb.PbList<Node> get nodes => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<NodeConnection> get connections => $_getList(3);

  @$pb.TagNumber(5)
  $pb.PbList<ImportWarning> get warnings => $_getList(4);
}

class Node extends $pb.GeneratedMessage {
  factory Node({
    $core.String? id,
    $core.String? path,
    $core.String? title,
    $core.String? body,
    $core.Iterable<$core.String>? tags,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? frontmatter,
    $0.Timestamp? modifiedAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (path != null) result.path = path;
    if (title != null) result.title = title;
    if (body != null) result.body = body;
    if (tags != null) result.tags.addAll(tags);
    if (frontmatter != null) result.frontmatter.addEntries(frontmatter);
    if (modifiedAt != null) result.modifiedAt = modifiedAt;
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
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..aOS(3, _omitFieldNames ? '' : 'title')
    ..aOS(4, _omitFieldNames ? '' : 'body')
    ..pPS(5, _omitFieldNames ? '' : 'tags')
    ..m<$core.String, $core.String>(6, _omitFieldNames ? '' : 'frontmatter',
        entryClassName: 'Node.FrontmatterEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('seville.node.v2'))
    ..aOM<$0.Timestamp>(7, _omitFieldNames ? '' : 'modifiedAt',
        subBuilder: $0.Timestamp.create)
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

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get title => $_getSZ(2);
  @$pb.TagNumber(3)
  set title($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTitle() => $_has(2);
  @$pb.TagNumber(3)
  void clearTitle() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get body => $_getSZ(3);
  @$pb.TagNumber(4)
  set body($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBody() => $_has(3);
  @$pb.TagNumber(4)
  void clearBody() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get tags => $_getList(4);

  @$pb.TagNumber(6)
  $pb.PbMap<$core.String, $core.String> get frontmatter => $_getMap(5);

  @$pb.TagNumber(7)
  $0.Timestamp get modifiedAt => $_getN(6);
  @$pb.TagNumber(7)
  set modifiedAt($0.Timestamp value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasModifiedAt() => $_has(6);
  @$pb.TagNumber(7)
  void clearModifiedAt() => $_clearField(7);
  @$pb.TagNumber(7)
  $0.Timestamp ensureModifiedAt() => $_ensure(6);
}

class NodeConnection extends $pb.GeneratedMessage {
  factory NodeConnection({
    $core.String? sourceNodeId,
    $core.String? targetText,
    $core.String? targetNodeId,
    $core.String? displayText,
    NodeConnectionKind? kind,
    $core.String? fragment,
  }) {
    final result = create();
    if (sourceNodeId != null) result.sourceNodeId = sourceNodeId;
    if (targetText != null) result.targetText = targetText;
    if (targetNodeId != null) result.targetNodeId = targetNodeId;
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
    ..aOS(1, _omitFieldNames ? '' : 'sourceNodeId')
    ..aOS(2, _omitFieldNames ? '' : 'targetText')
    ..aOS(3, _omitFieldNames ? '' : 'targetNodeId')
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
  $core.String get sourceNodeId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sourceNodeId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSourceNodeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSourceNodeId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get targetText => $_getSZ(1);
  @$pb.TagNumber(2)
  set targetText($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTargetText() => $_has(1);
  @$pb.TagNumber(2)
  void clearTargetText() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get targetNodeId => $_getSZ(2);
  @$pb.TagNumber(3)
  set targetNodeId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTargetNodeId() => $_has(2);
  @$pb.TagNumber(3)
  void clearTargetNodeId() => $_clearField(3);

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

class ImportWarning extends $pb.GeneratedMessage {
  factory ImportWarning({
    $core.String? path,
    $core.String? message,
  }) {
    final result = create();
    if (path != null) result.path = path;
    if (message != null) result.message = message;
    return result;
  }

  ImportWarning._();

  factory ImportWarning.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ImportWarning.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ImportWarning',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'seville.node.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImportWarning clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImportWarning copyWith(void Function(ImportWarning) updates) =>
      super.copyWith((message) => updates(message as ImportWarning))
          as ImportWarning;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ImportWarning create() => ImportWarning._();
  @$core.override
  ImportWarning createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ImportWarning getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ImportWarning>(create);
  static ImportWarning? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

class ImportStatus extends $pb.GeneratedMessage {
  factory ImportStatus({
    $core.String? revision,
    $0.Timestamp? importedAt,
    $core.int? nodeCount,
    $core.int? connectionCount,
    $core.int? warningCount,
  }) {
    final result = create();
    if (revision != null) result.revision = revision;
    if (importedAt != null) result.importedAt = importedAt;
    if (nodeCount != null) result.nodeCount = nodeCount;
    if (connectionCount != null) result.connectionCount = connectionCount;
    if (warningCount != null) result.warningCount = warningCount;
    return result;
  }

  ImportStatus._();

  factory ImportStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ImportStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ImportStatus',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'seville.node.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'revision')
    ..aOM<$0.Timestamp>(2, _omitFieldNames ? '' : 'importedAt',
        subBuilder: $0.Timestamp.create)
    ..aI(3, _omitFieldNames ? '' : 'nodeCount', fieldType: $pb.PbFieldType.OU3)
    ..aI(4, _omitFieldNames ? '' : 'connectionCount',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(5, _omitFieldNames ? '' : 'warningCount',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImportStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImportStatus copyWith(void Function(ImportStatus) updates) =>
      super.copyWith((message) => updates(message as ImportStatus))
          as ImportStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ImportStatus create() => ImportStatus._();
  @$core.override
  ImportStatus createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ImportStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ImportStatus>(create);
  static ImportStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get revision => $_getSZ(0);
  @$pb.TagNumber(1)
  set revision($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRevision() => $_has(0);
  @$pb.TagNumber(1)
  void clearRevision() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.Timestamp get importedAt => $_getN(1);
  @$pb.TagNumber(2)
  set importedAt($0.Timestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasImportedAt() => $_has(1);
  @$pb.TagNumber(2)
  void clearImportedAt() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Timestamp ensureImportedAt() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.int get nodeCount => $_getIZ(2);
  @$pb.TagNumber(3)
  set nodeCount($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNodeCount() => $_has(2);
  @$pb.TagNumber(3)
  void clearNodeCount() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get connectionCount => $_getIZ(3);
  @$pb.TagNumber(4)
  set connectionCount($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasConnectionCount() => $_has(3);
  @$pb.TagNumber(4)
  void clearConnectionCount() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get warningCount => $_getIZ(4);
  @$pb.TagNumber(5)
  set warningCount($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasWarningCount() => $_has(4);
  @$pb.TagNumber(5)
  void clearWarningCount() => $_clearField(5);
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
