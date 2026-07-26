import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart' as flame_events;
import 'package:flutter/material.dart'
    show Colors, TextPainter, TextSpan, TextStyle;
import 'package:flutter/services.dart';

import '../constants/keymap.dart';
import '../constants/typography.dart';
import '../models/layout.dart';
import '../models/search_layout.dart';

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
    this.selectedNodeSlugs = const {},
    this.layoutDefaults = const LayoutDefaults(),
  });

  String searchValue;
  ValueChanged<String> onSearchSubmitted;
  VoidCallback onCancel;
  VoidCallback onRefreshFanData;
  VoidCallback onCopySelectedNodeSlug;
  VoidCallback onSubmit;
  ValueChanged<ResolvedVaultNode> onNodeSelected;
  List<ResolvedVaultNode> results;
  Set<String> selectedNodeSlugs;
  LayoutDefaults layoutDefaults;
  SearchLayout layout;

  bool _isOpen = false;
  String _draft = '';
  int _highlightedIndex = -1;
  final List<_SearchNodeOptionComponent> _options = [];

  bool get isOpen => _isOpen;
  bool get _showsResults =>
      _isOpen && _draft.trim() == searchValue.trim() && results.isNotEmpty;

  void updateLayout(SearchLayout layout, Rect bounds) {
    this.layout = layout;
    position = Vector2(bounds.left, bounds.top);
    size = Vector2(bounds.width, bounds.height);
    _layoutOptions();
  }

  void open(String initialValue) {
    _draft = initialValue;
    _isOpen = true;
    _highlightedIndex = _showsResults ? 0 : -1;
    _layoutOptions();
  }

  void close() {
    _isOpen = false;
    _highlightedIndex = -1;
    _layoutOptions();
  }

  void updateNodeOptions({
    required List<ResolvedVaultNode> results,
    required Set<String> selectedNodeSlugs,
    required LayoutDefaults layoutDefaults,
  }) {
    final resultsChanged = !_sameNodes(this.results, results);
    this.results = results;
    this.selectedNodeSlugs = selectedNodeSlugs;
    this.layoutDefaults = layoutDefaults;
    if (resultsChanged) _syncOptions();
    if (!_showsResults) {
      _highlightedIndex = -1;
    } else if (_highlightedIndex < 0 || _highlightedIndex >= results.length) {
      _highlightedIndex = 0;
    }
    _layoutOptions();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _syncOptions();
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
        if (_showsResults && _highlightedIndex >= 0) {
          _selectNode(_highlightedIndex);
        } else {
          searchValue = _draft.trim();
          _highlightedIndex = -1;
          results = const [];
          _syncOptions();
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
        _layoutOptions();
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
        _layoutOptions();
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

  void _syncOptions() {
    for (final option in _options) {
      option.enabled = false;
      option.removeFromParent();
    }
    _options
      ..clear()
      ..addAll([
        for (var index = 0; index < results.length; index += 1)
          _SearchNodeOptionComponent(
            hud: this,
            index: index,
            resolvedNode: results[index],
          ),
      ]);
    addAll(_options);
    _layoutOptions();
  }

  void _layoutOptions() {
    if (_options.isEmpty) return;
    final input = _inputBounds;
    final availableHeight = (size.y - input.bottom - layout.padding).clamp(
      0,
      layout.optionHeight * layout.maxVisibleOptions,
    );
    final visibleCount = (availableHeight / layout.optionHeight).floor().clamp(
      0,
      layout.maxVisibleOptions,
    );
    var visibleStart = 0;
    if (_highlightedIndex >= visibleCount && visibleCount > 0) {
      visibleStart = _highlightedIndex - visibleCount + 1;
    }
    visibleStart = visibleStart.clamp(
      0,
      results.length - visibleCount < 0 ? 0 : results.length - visibleCount,
    );
    for (var index = 0; index < _options.length; index += 1) {
      final option = _options[index];
      final visibleIndex = index - visibleStart;
      option.enabled =
          _showsResults && visibleIndex >= 0 && visibleIndex < visibleCount;
      option
        ..position = Vector2(
          input.left,
          input.bottom +
              layout.inputToOptionsGap +
              visibleIndex * layout.optionHeight,
        )
        ..size = Vector2(input.width, layout.optionHeight)
        ..highlighted = index == _highlightedIndex;
    }
  }

  void _moveHighlight(int delta) {
    if (!_showsResults) return;
    _highlightedIndex =
        (_highlightedIndex < 0
                ? delta > 0
                      ? 0
                      : results.length - 1
                : _highlightedIndex + delta)
            .clamp(0, results.length - 1);
    _layoutOptions();
  }

  void _highlight(int index) {
    if (!_showsResults || index < 0 || index >= results.length) return;
    _highlightedIndex = index;
    _layoutOptions();
  }

  void _selectNode(int index) {
    if (index < 0 || index >= results.length) return;
    final node = results[index];
    if (node.node == null) return;
    close();
    onNodeSelected(node);
  }

  bool _isSelected(ResolvedVaultNode resolvedNode) {
    final slug = resolvedNode.node?.slug.trim() ?? '';
    return slug.isNotEmpty && selectedNodeSlugs.contains(slug);
  }
}

class _SearchNodeOptionComponent extends PositionComponent
    with flame_events.TapCallbacks, flame_events.HoverCallbacks {
  _SearchNodeOptionComponent({
    required this.hud,
    required this.index,
    required this.resolvedNode,
  });

  final SearchHudComponent hud;
  final int index;
  final ResolvedVaultNode resolvedNode;
  bool enabled = false;
  bool highlighted = false;

  @override
  bool containsLocalPoint(Vector2 point) =>
      enabled && super.containsLocalPoint(point);

  @override
  void onTapUp(flame_events.TapUpEvent event) => hud._selectNode(index);

  @override
  void onPointerMove(flame_events.PointerMoveEvent event) {
    hud._highlight(index);
    super.onPointerMove(event);
  }

  @override
  void render(Canvas canvas) {
    if (!enabled || size.x <= 0 || size.y <= 0) return;
    final selected = hud._isSelected(resolvedNode);
    final bounds = Rect.fromLTWH(0, 0, size.x, size.y - 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(6)),
      Paint()
        ..color = selected
            ? const Color(0xEE283593)
            : highlighted
            ? const Color(0xEE232B46)
            : const Color(0xEE141827),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(6)),
      Paint()
        ..color = highlighted || selected
            ? const Color(0xFF3F51B5)
            : const Color(0x553F51B5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlighted ? 2 : 1,
    );

    final slug = resolvedNode.node?.slug.trim() ?? '';
    final label = hud.layoutDefaults.formatNodeSlug(slug);
    final painter = TextPainter(
      text: TextSpan(
        text: selected ? '✓  $label' : label,
        style: TextStyle(
          fontFamily: null,
          color: hud.layoutDefaults.slugColor,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: bounds.width - 28);
    painter.paint(
      canvas,
      Offset(bounds.left + 14, bounds.center.dy - painter.height / 2),
    );
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
