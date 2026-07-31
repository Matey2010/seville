import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart'
    show Colors, TextPainter, TextSpan, TextStyle;
import 'package:flutter/services.dart';

import '../constants/keymap.dart';
import '../constants/typography.dart';
import '../models/layout/layout.dart';

class SearchHudComponent extends PositionComponent with KeyboardHandler {
  SearchHudComponent({
    required this.searchValue,
    required this.onSearchSubmitted,
    required this.onCancel,
    required this.onRefreshFanData,
    required this.onCopySelectedNodeSlug,
    required this.onSubmit,
    required this.onNodeSelected,
    required this.layout,
    this.results = const [],
  });

  String searchValue;
  ValueChanged<String> onSearchSubmitted;
  VoidCallback onCancel;
  VoidCallback onRefreshFanData;
  VoidCallback onCopySelectedNodeSlug;
  VoidCallback onSubmit;
  ValueChanged<ResolvedVaultNode> onNodeSelected;
  List<ResolvedVaultNode> results;
  SearchLayout layout;

  bool _isOpen = false;
  String _draft = '';
  int _highlightedIndex = -1;

  bool get isOpen => _isOpen;
  bool get showsResults =>
      _isOpen && _draft.trim() == searchValue.trim() && results.isNotEmpty;

  void updateLayout(SearchLayout layout, Rect bounds) {
    this.layout = layout;
    position = Vector2(bounds.left, bounds.top);
    size = Vector2(bounds.width, bounds.height);
  }

  void open(String initialValue) {
    _draft = initialValue;
    _isOpen = true;
    _highlightedIndex = showsResults ? 0 : -1;
  }

  void close() {
    _isOpen = false;
    _highlightedIndex = -1;
  }

  void updateNodeOptions({required List<ResolvedVaultNode> results}) {
    final resultsChanged = !_sameNodes(this.results, results);
    this.results = results;
    if (!showsResults) {
      _highlightedIndex = -1;
    } else if (resultsChanged ||
        _highlightedIndex < 0 ||
        _highlightedIndex >= results.length) {
      _highlightedIndex = 0;
    }
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
        return false;
      }
      if (action == SevilleKeymapAction.submit) {
        if (showsResults && _highlightedIndex >= 0) {
          selectResult(_highlightedIndex);
        } else {
          searchValue = _draft.trim();
          _highlightedIndex = -1;
          results = const [];
          onSearchSubmitted(_draft);
        }
        return false;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _moveHighlight(1);
        return false;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _moveHighlight(-1);
        return false;
      }
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        _draft = _removeLastRune(_draft);
        _highlightedIndex = -1;
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
        _highlightedIndex = -1;
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
    final bounds = _inputBounds;
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
          fontFamily: SevilleTypography.fontFamily,
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

  Rect get _inputBounds {
    final width = size.x.clamp(0, layout.maxWidth).toDouble();
    return Rect.fromLTWH(
      (size.x - width) / 2,
      layout.padding,
      width,
      layout.inputHeight,
    );
  }

  void _moveHighlight(int delta) {
    if (!showsResults) return;
    final resultCount = results.length;
    _highlightedIndex =
        (_highlightedIndex < 0
                ? delta > 0
                      ? 0
                      : resultCount - 1
                : _highlightedIndex + delta)
            .clamp(0, resultCount - 1);
  }

  void selectResult(int index) {
    if (index < 0 || index >= results.length) return;
    final node = results[index];
    if (node.node == null) return;
    close();
    onNodeSelected(node);
  }
}

bool _sameNodes(List<ResolvedVaultNode> left, List<ResolvedVaultNode> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index].node?.slug != right[index].node?.slug) return false;
  }
  return true;
}

String _removeLastRune(String value) {
  if (value.isEmpty) return value;
  final runes = value.runes.toList()..removeLast();
  return String.fromCharCodes(runes);
}
