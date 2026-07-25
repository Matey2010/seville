import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart'
    show Colors, TextPainter, TextSpan, TextStyle;
import 'package:flutter/services.dart';

import '../constants/keymap.dart';

class SearchHudComponent extends PositionComponent with KeyboardHandler {
  SearchHudComponent({
    required this.searchValue,
    required this.onSearchSubmitted,
    required this.onCancel,
    required this.onRefreshFanData,
    required this.onCopySelectedNodeSlug,
    required this.onSubmit,
  });

  String searchValue;
  ValueChanged<String> onSearchSubmitted;
  VoidCallback onCancel;
  VoidCallback onRefreshFanData;
  VoidCallback onCopySelectedNodeSlug;
  VoidCallback onSubmit;

  double safeTop = 0;
  bool _isOpen = false;
  String _draft = '';

  bool get isOpen => _isOpen;

  void open(String initialValue) {
    _draft = initialValue;
    _isOpen = true;
  }

  void close() {
    _isOpen = false;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return true;

    final action = resolveSevilleKeymapAction(event, HardwareKeyboard.instance);
    if (action == SevilleKeymapAction.showSearch) {
      open(searchValue);
      return false;
    }
    if (_isOpen) {
      if (action == SevilleKeymapAction.cancel) {
        close();
        onCancel();
        return false;
      }
      if (action == SevilleKeymapAction.submit) {
        final submittedValue = _draft;
        close();
        onSearchSubmitted(submittedValue);
        return false;
      }
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        _draft = _removeLastRune(_draft);
        return false;
      }
      final character = event.character;
      if (character != null &&
          character.isNotEmpty &&
          !HardwareKeyboard.instance.isMetaPressed &&
          !HardwareKeyboard.instance.isControlPressed &&
          !HardwareKeyboard.instance.isAltPressed &&
          character.runes.every((rune) => rune >= 0x20 && rune != 0x7F)) {
        _draft += character;
        return false;
      }
      return true;
    }

    switch (action) {
      case SevilleKeymapAction.refreshFanData:
        onRefreshFanData();
        return false;
      case SevilleKeymapAction.copySelectedNodeSlug:
        onCopySelectedNodeSlug();
        return false;
      case SevilleKeymapAction.submit:
        onSubmit();
        return false;
      case SevilleKeymapAction.cancel:
        onCancel();
        return false;
      case SevilleKeymapAction.showSearch:
      case null:
        return true;
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_isOpen || size.x <= 0) return;
    final width = size.x.clamp(0, 520).toDouble();
    final bounds = Rect.fromLTWH((size.x - width) / 2, safeTop + 12, width, 52);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(8)),
      Paint()..color = const Color(0xEEFFFFFF),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(8)),
      Paint()
        ..color = const Color(0xFF3F51B5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final visibleText = _draft.isEmpty ? 'Search' : _draft;
    final painter = TextPainter(
      text: TextSpan(
        text: '$visibleText|',
        style: TextStyle(
          color: _draft.isEmpty ? Colors.black45 : Colors.black87,
          fontSize: 18,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: bounds.width - 32);
    painter.paint(
      canvas,
      Offset(bounds.left + 16, bounds.center.dy - painter.height / 2),
    );
  }
}

String _removeLastRune(String value) {
  if (value.isEmpty) return value;
  final runes = value.runes.toList()..removeLast();
  return String.fromCharCodes(runes);
}
