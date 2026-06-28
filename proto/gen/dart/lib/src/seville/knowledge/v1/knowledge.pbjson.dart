// This is a generated file - do not edit.
//
// Generated from seville/knowledge/v1/knowledge.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use linkKindDescriptor instead')
const LinkKind$json = {
  '1': 'LinkKind',
  '2': [
    {'1': 'LINK_KIND_UNSPECIFIED', '2': 0},
    {'1': 'LINK_KIND_WIKI', '2': 1},
    {'1': 'LINK_KIND_MARKDOWN', '2': 2},
    {'1': 'LINK_KIND_EMBED', '2': 3},
  ],
};

/// Descriptor for `LinkKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List linkKindDescriptor = $convert.base64Decode(
    'CghMaW5rS2luZBIZChVMSU5LX0tJTkRfVU5TUEVDSUZJRUQQABISCg5MSU5LX0tJTkRfV0lLSR'
    'ABEhYKEkxJTktfS0lORF9NQVJLRE9XThACEhMKD0xJTktfS0lORF9FTUJFRBAD');

@$core.Deprecated('Use knowledgeSnapshotDescriptor instead')
const KnowledgeSnapshot$json = {
  '1': 'KnowledgeSnapshot',
  '2': [
    {'1': 'revision', '3': 1, '4': 1, '5': 9, '10': 'revision'},
    {
      '1': 'generated_at',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'generatedAt'
    },
    {
      '1': 'notes',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.seville.knowledge.v1.Note',
      '10': 'notes'
    },
    {
      '1': 'links',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.seville.knowledge.v1.Link',
      '10': 'links'
    },
    {
      '1': 'warnings',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.seville.knowledge.v1.ScanWarning',
      '10': 'warnings'
    },
  ],
};

/// Descriptor for `KnowledgeSnapshot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List knowledgeSnapshotDescriptor = $convert.base64Decode(
    'ChFLbm93bGVkZ2VTbmFwc2hvdBIaCghyZXZpc2lvbhgBIAEoCVIIcmV2aXNpb24SPQoMZ2VuZX'
    'JhdGVkX2F0GAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFILZ2VuZXJhdGVkQXQS'
    'MAoFbm90ZXMYAyADKAsyGi5zZXZpbGxlLmtub3dsZWRnZS52MS5Ob3RlUgVub3RlcxIwCgVsaW'
    '5rcxgEIAMoCzIaLnNldmlsbGUua25vd2xlZGdlLnYxLkxpbmtSBWxpbmtzEj0KCHdhcm5pbmdz'
    'GAUgAygLMiEuc2V2aWxsZS5rbm93bGVkZ2UudjEuU2Nhbldhcm5pbmdSCHdhcm5pbmdz');

@$core.Deprecated('Use noteDescriptor instead')
const Note$json = {
  '1': 'Note',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
    {'1': 'title', '3': 3, '4': 1, '5': 9, '10': 'title'},
    {'1': 'body', '3': 4, '4': 1, '5': 9, '10': 'body'},
    {'1': 'tags', '3': 5, '4': 3, '5': 9, '10': 'tags'},
    {
      '1': 'frontmatter',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.seville.knowledge.v1.Note.FrontmatterEntry',
      '10': 'frontmatter'
    },
    {
      '1': 'modified_at',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'modifiedAt'
    },
  ],
  '3': [Note_FrontmatterEntry$json],
};

@$core.Deprecated('Use noteDescriptor instead')
const Note_FrontmatterEntry$json = {
  '1': 'FrontmatterEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `Note`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List noteDescriptor = $convert.base64Decode(
    'CgROb3RlEg4KAmlkGAEgASgJUgJpZBISCgRwYXRoGAIgASgJUgRwYXRoEhQKBXRpdGxlGAMgAS'
    'gJUgV0aXRsZRISCgRib2R5GAQgASgJUgRib2R5EhIKBHRhZ3MYBSADKAlSBHRhZ3MSTQoLZnJv'
    'bnRtYXR0ZXIYBiADKAsyKy5zZXZpbGxlLmtub3dsZWRnZS52MS5Ob3RlLkZyb250bWF0dGVyRW'
    '50cnlSC2Zyb250bWF0dGVyEjsKC21vZGlmaWVkX2F0GAcgASgLMhouZ29vZ2xlLnByb3RvYnVm'
    'LlRpbWVzdGFtcFIKbW9kaWZpZWRBdBo+ChBGcm9udG1hdHRlckVudHJ5EhAKA2tleRgBIAEoCV'
    'IDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAE=');

@$core.Deprecated('Use linkDescriptor instead')
const Link$json = {
  '1': 'Link',
  '2': [
    {'1': 'source_note_id', '3': 1, '4': 1, '5': 9, '10': 'sourceNoteId'},
    {'1': 'target_text', '3': 2, '4': 1, '5': 9, '10': 'targetText'},
    {
      '1': 'resolved_target_id',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'resolvedTargetId',
      '17': true
    },
    {
      '1': 'display_text',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'displayText',
      '17': true
    },
    {
      '1': 'kind',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.seville.knowledge.v1.LinkKind',
      '10': 'kind'
    },
    {
      '1': 'fragment',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'fragment',
      '17': true
    },
  ],
  '8': [
    {'1': '_resolved_target_id'},
    {'1': '_display_text'},
    {'1': '_fragment'},
  ],
};

/// Descriptor for `Link`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List linkDescriptor = $convert.base64Decode(
    'CgRMaW5rEiQKDnNvdXJjZV9ub3RlX2lkGAEgASgJUgxzb3VyY2VOb3RlSWQSHwoLdGFyZ2V0X3'
    'RleHQYAiABKAlSCnRhcmdldFRleHQSMQoScmVzb2x2ZWRfdGFyZ2V0X2lkGAMgASgJSABSEHJl'
    'c29sdmVkVGFyZ2V0SWSIAQESJgoMZGlzcGxheV90ZXh0GAQgASgJSAFSC2Rpc3BsYXlUZXh0iA'
    'EBEjIKBGtpbmQYBSABKA4yHi5zZXZpbGxlLmtub3dsZWRnZS52MS5MaW5rS2luZFIEa2luZBIf'
    'CghmcmFnbWVudBgGIAEoCUgCUghmcmFnbWVudIgBAUIVChNfcmVzb2x2ZWRfdGFyZ2V0X2lkQg'
    '8KDV9kaXNwbGF5X3RleHRCCwoJX2ZyYWdtZW50');

@$core.Deprecated('Use scanWarningDescriptor instead')
const ScanWarning$json = {
  '1': 'ScanWarning',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ScanWarning`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List scanWarningDescriptor = $convert.base64Decode(
    'CgtTY2FuV2FybmluZxISCgRwYXRoGAEgASgJUgRwYXRoEhgKB21lc3NhZ2UYAiABKAlSB21lc3'
    'NhZ2U=');

@$core.Deprecated('Use scanStatusDescriptor instead')
const ScanStatus$json = {
  '1': 'ScanStatus',
  '2': [
    {'1': 'revision', '3': 1, '4': 1, '5': 9, '10': 'revision'},
    {
      '1': 'scanned_at',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'scannedAt'
    },
    {'1': 'note_count', '3': 3, '4': 1, '5': 13, '10': 'noteCount'},
    {'1': 'link_count', '3': 4, '4': 1, '5': 13, '10': 'linkCount'},
    {'1': 'warning_count', '3': 5, '4': 1, '5': 13, '10': 'warningCount'},
  ],
};

/// Descriptor for `ScanStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List scanStatusDescriptor = $convert.base64Decode(
    'CgpTY2FuU3RhdHVzEhoKCHJldmlzaW9uGAEgASgJUghyZXZpc2lvbhI5CgpzY2FubmVkX2F0GA'
    'IgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJc2Nhbm5lZEF0Eh0KCm5vdGVfY291'
    'bnQYAyABKA1SCW5vdGVDb3VudBIdCgpsaW5rX2NvdW50GAQgASgNUglsaW5rQ291bnQSIwoNd2'
    'FybmluZ19jb3VudBgFIAEoDVIMd2FybmluZ0NvdW50');

@$core.Deprecated('Use apiErrorDescriptor instead')
const ApiError$json = {
  '1': 'ApiError',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 9, '10': 'code'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ApiError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List apiErrorDescriptor = $convert.base64Decode(
    'CghBcGlFcnJvchISCgRjb2RlGAEgASgJUgRjb2RlEhgKB21lc3NhZ2UYAiABKAlSB21lc3NhZ2'
    'U=');
