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

class LinkKind extends $pb.ProtobufEnum {
  static const LinkKind LINK_KIND_UNSPECIFIED =
      LinkKind._(0, _omitEnumNames ? '' : 'LINK_KIND_UNSPECIFIED');
  static const LinkKind LINK_KIND_WIKI =
      LinkKind._(1, _omitEnumNames ? '' : 'LINK_KIND_WIKI');
  static const LinkKind LINK_KIND_MARKDOWN =
      LinkKind._(2, _omitEnumNames ? '' : 'LINK_KIND_MARKDOWN');
  static const LinkKind LINK_KIND_EMBED =
      LinkKind._(3, _omitEnumNames ? '' : 'LINK_KIND_EMBED');

  static const $core.List<LinkKind> values = <LinkKind>[
    LINK_KIND_UNSPECIFIED,
    LINK_KIND_WIKI,
    LINK_KIND_MARKDOWN,
    LINK_KIND_EMBED,
  ];

  static final $core.List<LinkKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static LinkKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const LinkKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
