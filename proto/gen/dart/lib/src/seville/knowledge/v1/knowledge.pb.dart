// This is a generated file - do not edit.
//
// Generated from seville/knowledge/v1/knowledge.proto.

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

import 'knowledge.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'knowledge.pbenum.dart';

class KnowledgeSnapshot extends $pb.GeneratedMessage {
  factory KnowledgeSnapshot({
    $core.String? revision,
    $0.Timestamp? generatedAt,
    $core.Iterable<Note>? notes,
    $core.Iterable<Link>? links,
    $core.Iterable<ScanWarning>? warnings,
  }) {
    final result = create();
    if (revision != null) result.revision = revision;
    if (generatedAt != null) result.generatedAt = generatedAt;
    if (notes != null) result.notes.addAll(notes);
    if (links != null) result.links.addAll(links);
    if (warnings != null) result.warnings.addAll(warnings);
    return result;
  }

  KnowledgeSnapshot._();

  factory KnowledgeSnapshot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory KnowledgeSnapshot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'KnowledgeSnapshot',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'seville.knowledge.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'revision')
    ..aOM<$0.Timestamp>(2, _omitFieldNames ? '' : 'generatedAt',
        subBuilder: $0.Timestamp.create)
    ..pPM<Note>(3, _omitFieldNames ? '' : 'notes', subBuilder: Note.create)
    ..pPM<Link>(4, _omitFieldNames ? '' : 'links', subBuilder: Link.create)
    ..pPM<ScanWarning>(5, _omitFieldNames ? '' : 'warnings',
        subBuilder: ScanWarning.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KnowledgeSnapshot clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KnowledgeSnapshot copyWith(void Function(KnowledgeSnapshot) updates) =>
      super.copyWith((message) => updates(message as KnowledgeSnapshot))
          as KnowledgeSnapshot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static KnowledgeSnapshot create() => KnowledgeSnapshot._();
  @$core.override
  KnowledgeSnapshot createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static KnowledgeSnapshot getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<KnowledgeSnapshot>(create);
  static KnowledgeSnapshot? _defaultInstance;

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
  $pb.PbList<Note> get notes => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<Link> get links => $_getList(3);

  @$pb.TagNumber(5)
  $pb.PbList<ScanWarning> get warnings => $_getList(4);
}

class Note extends $pb.GeneratedMessage {
  factory Note({
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

  Note._();

  factory Note.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Note.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Note',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'seville.knowledge.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..aOS(3, _omitFieldNames ? '' : 'title')
    ..aOS(4, _omitFieldNames ? '' : 'body')
    ..pPS(5, _omitFieldNames ? '' : 'tags')
    ..m<$core.String, $core.String>(6, _omitFieldNames ? '' : 'frontmatter',
        entryClassName: 'Note.FrontmatterEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('seville.knowledge.v1'))
    ..aOM<$0.Timestamp>(7, _omitFieldNames ? '' : 'modifiedAt',
        subBuilder: $0.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Note clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Note copyWith(void Function(Note) updates) =>
      super.copyWith((message) => updates(message as Note)) as Note;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Note create() => Note._();
  @$core.override
  Note createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Note getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Note>(create);
  static Note? _defaultInstance;

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

class Link extends $pb.GeneratedMessage {
  factory Link({
    $core.String? sourceNoteId,
    $core.String? targetText,
    $core.String? resolvedTargetId,
    $core.String? displayText,
    LinkKind? kind,
    $core.String? fragment,
  }) {
    final result = create();
    if (sourceNoteId != null) result.sourceNoteId = sourceNoteId;
    if (targetText != null) result.targetText = targetText;
    if (resolvedTargetId != null) result.resolvedTargetId = resolvedTargetId;
    if (displayText != null) result.displayText = displayText;
    if (kind != null) result.kind = kind;
    if (fragment != null) result.fragment = fragment;
    return result;
  }

  Link._();

  factory Link.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Link.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Link',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'seville.knowledge.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sourceNoteId')
    ..aOS(2, _omitFieldNames ? '' : 'targetText')
    ..aOS(3, _omitFieldNames ? '' : 'resolvedTargetId')
    ..aOS(4, _omitFieldNames ? '' : 'displayText')
    ..aE<LinkKind>(5, _omitFieldNames ? '' : 'kind',
        enumValues: LinkKind.values)
    ..aOS(6, _omitFieldNames ? '' : 'fragment')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Link clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Link copyWith(void Function(Link) updates) =>
      super.copyWith((message) => updates(message as Link)) as Link;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Link create() => Link._();
  @$core.override
  Link createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Link getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Link>(create);
  static Link? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sourceNoteId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sourceNoteId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSourceNoteId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSourceNoteId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get targetText => $_getSZ(1);
  @$pb.TagNumber(2)
  set targetText($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTargetText() => $_has(1);
  @$pb.TagNumber(2)
  void clearTargetText() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get resolvedTargetId => $_getSZ(2);
  @$pb.TagNumber(3)
  set resolvedTargetId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasResolvedTargetId() => $_has(2);
  @$pb.TagNumber(3)
  void clearResolvedTargetId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get displayText => $_getSZ(3);
  @$pb.TagNumber(4)
  set displayText($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDisplayText() => $_has(3);
  @$pb.TagNumber(4)
  void clearDisplayText() => $_clearField(4);

  @$pb.TagNumber(5)
  LinkKind get kind => $_getN(4);
  @$pb.TagNumber(5)
  set kind(LinkKind value) => $_setField(5, value);
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

class ScanWarning extends $pb.GeneratedMessage {
  factory ScanWarning({
    $core.String? path,
    $core.String? message,
  }) {
    final result = create();
    if (path != null) result.path = path;
    if (message != null) result.message = message;
    return result;
  }

  ScanWarning._();

  factory ScanWarning.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ScanWarning.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ScanWarning',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'seville.knowledge.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScanWarning clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScanWarning copyWith(void Function(ScanWarning) updates) =>
      super.copyWith((message) => updates(message as ScanWarning))
          as ScanWarning;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ScanWarning create() => ScanWarning._();
  @$core.override
  ScanWarning createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ScanWarning getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ScanWarning>(create);
  static ScanWarning? _defaultInstance;

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

class ScanStatus extends $pb.GeneratedMessage {
  factory ScanStatus({
    $core.String? revision,
    $0.Timestamp? scannedAt,
    $core.int? noteCount,
    $core.int? linkCount,
    $core.int? warningCount,
  }) {
    final result = create();
    if (revision != null) result.revision = revision;
    if (scannedAt != null) result.scannedAt = scannedAt;
    if (noteCount != null) result.noteCount = noteCount;
    if (linkCount != null) result.linkCount = linkCount;
    if (warningCount != null) result.warningCount = warningCount;
    return result;
  }

  ScanStatus._();

  factory ScanStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ScanStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ScanStatus',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'seville.knowledge.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'revision')
    ..aOM<$0.Timestamp>(2, _omitFieldNames ? '' : 'scannedAt',
        subBuilder: $0.Timestamp.create)
    ..aI(3, _omitFieldNames ? '' : 'noteCount', fieldType: $pb.PbFieldType.OU3)
    ..aI(4, _omitFieldNames ? '' : 'linkCount', fieldType: $pb.PbFieldType.OU3)
    ..aI(5, _omitFieldNames ? '' : 'warningCount',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScanStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScanStatus copyWith(void Function(ScanStatus) updates) =>
      super.copyWith((message) => updates(message as ScanStatus)) as ScanStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ScanStatus create() => ScanStatus._();
  @$core.override
  ScanStatus createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ScanStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ScanStatus>(create);
  static ScanStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get revision => $_getSZ(0);
  @$pb.TagNumber(1)
  set revision($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRevision() => $_has(0);
  @$pb.TagNumber(1)
  void clearRevision() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.Timestamp get scannedAt => $_getN(1);
  @$pb.TagNumber(2)
  set scannedAt($0.Timestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasScannedAt() => $_has(1);
  @$pb.TagNumber(2)
  void clearScannedAt() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Timestamp ensureScannedAt() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.int get noteCount => $_getIZ(2);
  @$pb.TagNumber(3)
  set noteCount($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNoteCount() => $_has(2);
  @$pb.TagNumber(3)
  void clearNoteCount() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get linkCount => $_getIZ(3);
  @$pb.TagNumber(4)
  set linkCount($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLinkCount() => $_has(3);
  @$pb.TagNumber(4)
  void clearLinkCount() => $_clearField(4);

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
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'seville.knowledge.v1'),
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
