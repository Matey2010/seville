part of 'layout.dart';

/// Renderer-independent typography and contrast policy for a [Layout].
class LayoutTextConfig {
  const LayoutTextConfig({
    this.value,
    this.color,
    this.darkColor,
    this.lightColor,
    this.fontFamily,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.wordSpacing,
    this.height,
    this.flow,
    this.effects,
    this.fontFeatures,
  });

  final LayoutText? value;
  final Color? color;
  final Color? darkColor;
  final Color? lightColor;
  final String? fontFamily;
  final double? fontSize;
  final FontWeight? fontWeight;
  final FontStyle? fontStyle;
  final double? letterSpacing;
  final double? wordSpacing;
  final double? height;
  final LayoutTextFlow? flow;
  final List<Shadow>? effects;
  final List<FontFeature>? fontFeatures;

  Color resolveColor(Color backgroundColor) {
    final dark = darkColor;
    final light = lightColor;
    if (dark != null && light != null) {
      return backgroundColor.computeLuminance() > 0.5 ? dark : light;
    }
    return color ?? dark ?? light ?? LayoutTextDefaults.config.color!;
  }

  LayoutTextConfig merge(LayoutTextConfig overlay) => LayoutTextConfig(
    value: overlay.value ?? value,
    color: overlay.color ?? color,
    darkColor: overlay.darkColor ?? darkColor,
    lightColor: overlay.lightColor ?? lightColor,
    fontFamily: overlay.fontFamily ?? fontFamily,
    fontSize: overlay.fontSize ?? fontSize,
    fontWeight: overlay.fontWeight ?? fontWeight,
    fontStyle: overlay.fontStyle ?? fontStyle,
    letterSpacing: overlay.letterSpacing ?? letterSpacing,
    wordSpacing: overlay.wordSpacing ?? wordSpacing,
    height: overlay.height ?? height,
    flow: overlay.flow ?? flow,
    effects: overlay.effects ?? effects,
    fontFeatures: overlay.fontFeatures ?? fontFeatures,
  );
}

/// Renderer-independent axis and glyph orientation for Layout text.
class LayoutTextFlow {
  const LayoutTextFlow.horizontal()
    : axis = LayoutTextAxis.horizontal,
      verticalDirection = LayoutTextVerticalDirection.topToBottom,
      glyphOrientation = LayoutTextGlyphOrientation.rotated;

  const LayoutTextFlow.vertical({
    this.verticalDirection = LayoutTextVerticalDirection.topToBottom,
    this.glyphOrientation = LayoutTextGlyphOrientation.rotated,
  }) : axis = LayoutTextAxis.vertical;

  final LayoutTextAxis axis;
  final LayoutTextVerticalDirection verticalDirection;
  final LayoutTextGlyphOrientation glyphOrientation;

  bool get isVertical => axis == LayoutTextAxis.vertical;
}

enum LayoutTextAxis {
  horizontal('horizontal'),
  vertical('vertical');

  const LayoutTextAxis(this.serializedValue);

  final String serializedValue;

  static LayoutTextAxis parse(String value) =>
      tryParse(value) ??
      (throw FormatException(
        'Unsupported LayoutTextAxis "$value". '
        'Expected one of: ${values.map((value) => value.serializedValue).join(', ')}.',
        value,
      ));

  static LayoutTextAxis? tryParse(String value) =>
      _tryParseLayoutTextEnum(values, value, (value) => value.serializedValue);
}

enum LayoutTextVerticalDirection {
  topToBottom('top-to-bottom'),
  bottomToTop('bottom-to-top');

  const LayoutTextVerticalDirection(this.serializedValue);

  final String serializedValue;

  static LayoutTextVerticalDirection parse(String value) =>
      tryParse(value) ??
      (throw FormatException(
        'Unsupported LayoutTextVerticalDirection "$value". '
        'Expected one of: ${values.map((value) => value.serializedValue).join(', ')}.',
        value,
      ));

  static LayoutTextVerticalDirection? tryParse(String value) =>
      _tryParseLayoutTextEnum(values, value, (value) => value.serializedValue);
}

enum LayoutTextGlyphOrientation {
  rotated('rotated'),
  upright('upright');

  const LayoutTextGlyphOrientation(this.serializedValue);

  final String serializedValue;

  static LayoutTextGlyphOrientation parse(String value) =>
      tryParse(value) ??
      (throw FormatException(
        'Unsupported LayoutTextGlyphOrientation "$value". '
        'Expected one of: ${values.map((value) => value.serializedValue).join(', ')}.',
        value,
      ));

  static LayoutTextGlyphOrientation? tryParse(String value) =>
      _tryParseLayoutTextEnum(values, value, (value) => value.serializedValue);
}

T? _tryParseLayoutTextEnum<T>(
  Iterable<T> values,
  String source,
  String Function(T value) serializedValue,
) {
  final normalized = _normalizeLayoutTextEnumValue(source);
  for (final value in values) {
    if (_normalizeLayoutTextEnumValue(serializedValue(value)) == normalized) {
      return value;
    }
  }
  return null;
}

String _normalizeLayoutTextEnumValue(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'[-_\s]'), '');

/// Declarative text content resolved independently from its visual style.
class LayoutText {
  const LayoutText.none()
    : _kind = _LayoutTextKind.none,
      _source = '',
      _length = 0,
      _parameters = const {};

  const LayoutText.lorem({required int length})
    : assert(length >= 0),
      _kind = _LayoutTextKind.lorem,
      _source = '',
      _length = length,
      _parameters = const {};

  const LayoutText.value(String value)
    : _kind = _LayoutTextKind.value,
      _source = value,
      _length = 0,
      _parameters = const {};

  const LayoutText.format(String value, LayoutTextFormatParameters parameters)
    : _kind = _LayoutTextKind.format,
      _source = value,
      _length = 0,
      _parameters = parameters;

  const LayoutText.comment(String value)
    : _kind = _LayoutTextKind.comment,
      _source = value,
      _length = 0,
      _parameters = const {};

  static const _loremSentence =
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit.';

  final _LayoutTextKind _kind;
  final String _source;
  final int _length;
  final LayoutTextFormatParameters _parameters;

  /// Null means that this text is explicitly suppressed.
  String? resolve() => switch (_kind) {
    _LayoutTextKind.none => null,
    _LayoutTextKind.lorem => List.filled(_length, _loremSentence).join(' '),
    _LayoutTextKind.value || _LayoutTextKind.comment => _source,
    _LayoutTextKind.format => _format(_source, _parameters),
  };

  static String _format(
    String template,
    LayoutTextFormatParameters parameters,
  ) {
    if (template.isEmpty) return defaultRepresentation(parameters);
    return template.replaceAllMapped(RegExp(r'\{([A-Za-z0-9_.-]+)\}'), (match) {
      final key = match.group(1)!;
      return parameters.containsKey(key)
          ? defaultRepresentation(parameters[key])
          : match.group(0)!;
    });
  }

  /// Canonical plain-text representation shared by every renderer.
  static String defaultRepresentation(Object? value) {
    if (value == null) return '—';
    if (value is LayoutText) return value.resolve() ?? '';
    if (value is VaultNode) {
      final label = value.label?.trim();
      return label == null || label.isEmpty
          ? value.path
          : '$label (${value.path})';
    }
    if (value is Iterable) {
      final formatted = value
          .map(defaultRepresentation)
          .where((item) => item != '—')
          .join(', ');
      return formatted.isEmpty ? '—' : formatted;
    }
    if (value is Map) {
      if (value.isEmpty) return '—';
      return value.entries
          .map(
            (entry) =>
                '${defaultRepresentation(entry.key)}: '
                '${defaultRepresentation(entry.value)}',
          )
          .join(', ');
    }
    final string = value.toString().trim();
    return string.isEmpty ? '—' : string;
  }
}

typedef LayoutTextFormatParameters = Map<String, dynamic>;

enum _LayoutTextKind { none, lorem, value, format, comment }

abstract final class LayoutTextDefaults {
  static const rootFontSize = 12.0;
  static const flow = LayoutTextFlow.horizontal();

  static const config = LayoutTextConfig(
    color: Color(0xFFFFF8E7),
    darkColor: Color(0xFF27251F),
    lightColor: Color(0xFFFFF8E7),
    flow: flow,
  );
}
