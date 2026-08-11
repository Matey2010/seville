import 'package:flame/components.dart' hide Matrix4;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/keymap.dart';
import '../models/layout/layout.dart';
import 'layout_component_registry.dart';

class LayoutInputViewState {
  const LayoutInputViewState({
    required this.layout,
    required this.text,
    this.isOpen = false,
    this.draft = '',
    this.input,
    this.owner,
    this.layoutKey,
    this.projectedCorners = const [],
    this.logicalSize = Size.zero,
  });

  final FindLayout layout;
  final LayoutTextConfig text;
  final bool isOpen;
  final String draft;
  final LayoutInputConfig? input;
  final PanelLayout? owner;
  final String? layoutKey;
  final List<Offset> projectedCorners;
  final Size logicalSize;

  bool get isFindInput =>
      input == null || input!.submission is FindNodesLayoutInputSubmission;

  bool get isCreateInput =>
      input?.submission is CreateVirtualNodeLayoutInputSubmission;

  LayoutInputConfig get effectiveInput =>
      input ??
      LayoutInputConfig(
        submission: const LayoutInputSubmission.findNodes(),
        hint: layout.hint,
        backgroundColor: layout.inputBackgroundColor,
        borderStyle: layout.inputBorderStyle,
        borderRadius: layout.inputBorderRadius,
        horizontalPadding: 16,
      );

  bool get hasGeometry =>
      projectedCorners.length == 4 &&
      logicalSize.width > 0 &&
      logicalSize.height > 0;

  LayoutInputViewState copyWith({
    FindLayout? layout,
    LayoutTextConfig? text,
    bool? isOpen,
    String? draft,
    LayoutInputConfig? input,
    PanelLayout? owner,
    String? layoutKey,
    bool clearPanelInput = false,
    List<Offset>? projectedCorners,
    Size? logicalSize,
  }) => LayoutInputViewState(
    layout: layout ?? this.layout,
    text: text ?? this.text,
    isOpen: isOpen ?? this.isOpen,
    draft: draft ?? this.draft,
    input: clearPanelInput ? null : input ?? this.input,
    owner: clearPanelInput ? null : owner ?? this.owner,
    layoutKey: clearPanelInput ? null : layoutKey ?? this.layoutKey,
    projectedCorners: projectedCorners ?? this.projectedCorners,
    logicalSize: logicalSize ?? this.logicalSize,
  );
}

/// Flame-side interaction owner for [FindLayout].
///
/// Its geometry is resolved by the game and shared with [LayoutInputOverlay], so
/// paint, focus, and pointer input all use the configured projected surface.
class LayoutInputComponent extends PositionComponent with KeyboardHandler {
  LayoutInputComponent({
    required FindLayout layout,
    required this.searchValue,
    required this.onSearchSubmitted,
    required this.onCreateVirtualNodeSubmitted,
    required this.onCancel,
    required this.onRefreshFanData,
    required this.onCopySelectedNodeSlug,
    required this.onSubmit,
    required this.onNodeSelected,
    this.results = const [],
  }) : viewState = ValueNotifier(
         LayoutInputViewState(
           layout: layout,
           text: LayoutTextDefaults.config.merge(layout.text),
         ),
       );

  String searchValue;
  ValueChanged<String> onSearchSubmitted;
  void Function(String slug, String layoutKey) onCreateVirtualNodeSubmitted;
  VoidCallback onCancel;
  VoidCallback onRefreshFanData;
  VoidCallback onCopySelectedNodeSlug;
  VoidCallback onSubmit;
  ValueChanged<ResolvedVaultNode> onNodeSelected;
  List<ResolvedVaultNode> results;
  final ValueNotifier<LayoutInputViewState> viewState;

  int _highlightedIndex = -1;
  int _geometryUpdateGeneration = 0;
  LayoutInputViewState? _lastFindPanelState;

  FindLayout get layout => viewState.value.layout;
  bool get isOpen => viewState.value.isOpen;
  bool get isFindOpen => isOpen && viewState.value.isFindInput;
  bool get isCreateOpen => isOpen && viewState.value.isCreateInput;
  String? get activeLayoutKey => isOpen ? viewState.value.layoutKey : null;
  bool get showsResults =>
      isFindOpen &&
      viewState.value.draft.trim() == searchValue.trim() &&
      results.isNotEmpty;

  void updateLayout(
    FindLayout layout,
    LayoutSurface surface,
    LayoutTextConfig text,
  ) {
    final surfaceSize = surface.logicalSize;
    final availableWidth = (surfaceSize.width - layout.padding * 2).clamp(
      0.0,
      double.infinity,
    );
    final inputWidth = availableWidth.clamp(0.0, layout.maxWidth).toDouble();
    final inputHeight = layout.inputHeight.clamp(
      0.0,
      (surfaceSize.height - layout.padding).clamp(0.0, double.infinity),
    );
    if (inputWidth <= 0 || inputHeight <= 0) return;

    final left = (surfaceSize.width - inputWidth) / 2;
    final top = layout.padding;
    Offset project(double x, double y) =>
        surface.project(x / surfaceSize.width, y / surfaceSize.height);

    final logicalSize = Size(inputWidth, inputHeight);
    final projectedCorners = [
      project(left, top),
      project(left + inputWidth, top),
      project(left + inputWidth, top + inputHeight),
      project(left, top + inputHeight),
    ];
    final generation = ++_geometryUpdateGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (generation != _geometryUpdateGeneration) return;
      final current = viewState.value;
      if (current.input != null) return;
      viewState.value = current.copyWith(
        layout: layout,
        text: text,
        logicalSize: logicalSize,
        projectedCorners: projectedCorners,
      );
    });
  }

  void updateConfiguration({
    required String searchValue,
    required List<ResolvedVaultNode> results,
  }) {
    final resultsChanged = !_sameNodes(this.results, results);
    this.searchValue = searchValue;
    this.results = results;
    if (!showsResults) {
      _highlightedIndex = -1;
    } else if (resultsChanged ||
        _highlightedIndex < 0 ||
        _highlightedIndex >= results.length) {
      _highlightedIndex = 0;
    }
  }

  void open(String initialValue) {
    final cached = _lastFindPanelState;
    if (cached != null) {
      viewState.value = cached.copyWith(isOpen: true, draft: initialValue);
      _highlightedIndex = showsResults ? 0 : -1;
      return;
    }
    viewState.value = viewState.value.copyWith(
      isOpen: true,
      draft: initialValue,
      clearPanelInput: true,
    );
    _highlightedIndex = showsResults ? 0 : -1;
  }

  void openPanel({
    required String layoutKey,
    required PanelLayout panel,
    required List<Offset> projectedCorners,
    required String initialValue,
  }) {
    final input = panel.input;
    if (input == null || projectedCorners.length != 4) return;
    final horizontalExtent =
        ((projectedCorners[1] - projectedCorners[0]).distance +
            (projectedCorners[2] - projectedCorners[3]).distance) /
        2;
    final verticalExtent =
        ((projectedCorners[3] - projectedCorners[0]).distance +
            (projectedCorners[2] - projectedCorners[1]).distance) /
        2;
    if (horizontalExtent <= 0 || verticalExtent <= 0) return;
    final text = LayoutTextDefaults.config.merge(panel.text).merge(input.text);
    final next = viewState.value.copyWith(
      isOpen: true,
      draft: initialValue,
      input: input,
      owner: panel,
      layoutKey: layoutKey,
      projectedCorners: List.unmodifiable(projectedCorners),
      logicalSize: Size(horizontalExtent, verticalExtent),
      text: text,
    );
    viewState.value = next;
    if (next.isFindInput) _lastFindPanelState = next.copyWith(isOpen: false);
    _highlightedIndex = showsResults ? 0 : -1;
  }

  void close() {
    viewState.value = viewState.value.copyWith(isOpen: false);
    _highlightedIndex = -1;
  }

  void updateDraft(String value) {
    if (value == viewState.value.draft) return;
    viewState.value = viewState.value.copyWith(draft: value);
    _highlightedIndex = -1;
  }

  void submitDraft() {
    final state = viewState.value;
    final query = state.draft.trim();
    if (state.input?.submission case CreateVirtualNodeLayoutInputSubmission()) {
      final layoutKey = state.layoutKey;
      if (query.isEmpty || layoutKey == null) return;
      onCreateVirtualNodeSubmitted(query, layoutKey);
      close();
      return;
    }
    if (showsResults && _highlightedIndex >= 0) {
      selectResult(_highlightedIndex);
      return;
    }
    searchValue = query;
    results = const [];
    _highlightedIndex = -1;
    onSearchSubmitted(query);
  }

  void moveHighlight(int delta) {
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

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return true;
    final action = resolveSevilleKeymapAction(event, HardwareKeyboard.instance);
    if (action == SevilleKeymapAction.showSearch) {
      open(searchValue);
      return false;
    }
    if (isOpen) return true;

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
}

class LayoutInputOverlay extends StatefulWidget {
  const LayoutInputOverlay({
    required this.component,
    required this.onFocusReleased,
    super.key,
  });

  final LayoutInputComponent component;
  final VoidCallback onFocusReleased;

  @override
  State<LayoutInputOverlay> createState() => _LayoutInputOverlayState();
}

class _LayoutInputOverlayState extends State<LayoutInputOverlay> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _wasOpen = false;
  bool _isSyncingController = false;
  bool _syncScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.component.viewState.value.draft,
    )..addListener(_onTextChanged);
    _focusNode = FocusNode(debugLabel: 'FindLayout input');
    widget.component.viewState.addListener(_scheduleViewStateSync);
    _scheduleViewStateSync();
  }

  @override
  void didUpdateWidget(LayoutInputOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.component == widget.component) return;
    oldWidget.component.viewState.removeListener(_scheduleViewStateSync);
    widget.component.viewState.addListener(_scheduleViewStateSync);
    _scheduleViewStateSync();
  }

  @override
  void dispose() {
    widget.component.viewState.removeListener(_scheduleViewStateSync);
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_isSyncingController) return;
    widget.component.updateDraft(_controller.text);
  }

  void _syncController(String value) {
    if (_controller.text == value) return;
    _isSyncingController = true;
    try {
      _controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    } finally {
      _isSyncingController = false;
    }
  }

  void _scheduleViewStateSync() {
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted) return;
      final state = widget.component.viewState.value;
      _syncController(state.draft);
      if (state.isOpen == _wasOpen) return;
      _wasOpen = state.isOpen;
      if (state.isOpen) {
        _focusNode.requestFocus();
      } else {
        _focusNode.unfocus();
        widget.onFocusReleased();
      }
    });
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.component.close();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      widget.component.moveHighlight(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      widget.component.moveHighlight(-1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LayoutInputViewState>(
      valueListenable: widget.component.viewState,
      builder: (context, state, _) {
        if (!state.isOpen || !state.hasGeometry) {
          return const SizedBox.shrink();
        }
        final input = state.effectiveInput;
        final border = input.borderStyle;
        final text = state.text;
        final matrix = _projectiveTransform(
          state.logicalSize,
          state.projectedCorners,
        );
        return Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.topLeft,
                child: Transform(
                  alignment: Alignment.topLeft,
                  transform: matrix,
                  child: SizedBox.fromSize(
                    size: state.logicalSize,
                    child: Focus(
                      onKeyEvent: _handleKey,
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        autofocus: true,
                        maxLines: 1,
                        textInputAction: state.isFindInput
                            ? TextInputAction.search
                            : TextInputAction.done,
                        onSubmitted: (_) => widget.component.submitDraft(),
                        cursorColor: border.color,
                        style: TextStyle(
                          color: text.resolveColor(input.backgroundColor),
                          fontFamily: text.fontFamily,
                          fontSize: text.fontSize ?? 18,
                          fontWeight: text.fontWeight,
                          fontStyle: text.fontStyle,
                          letterSpacing: text.letterSpacing,
                          wordSpacing: text.wordSpacing,
                          height: text.height,
                          shadows: text.effects,
                          fontFeatures: text.fontFeatures,
                        ),
                        decoration: InputDecoration(
                          hintText: input.hint.resolve(),
                          filled: true,
                          fillColor: input.backgroundColor,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: input.horizontalPadding,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              input.borderRadius,
                            ),
                            borderSide: BorderSide(
                              color: border.color,
                              width: border.strokeWidth,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              input.borderRadius,
                            ),
                            borderSide: BorderSide(
                              color: border.color,
                              width: border.strokeWidth,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              input.borderRadius,
                            ),
                            borderSide: BorderSide(
                              color: border.color,
                              width: border.strokeWidth,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

Matrix4 _projectiveTransform(Size source, List<Offset> corners) {
  final p0 = corners[0];
  final p1 = corners[1];
  final p2 = corners[2];
  final p3 = corners[3];
  final sx = p0.dx - p1.dx + p2.dx - p3.dx;
  final sy = p0.dy - p1.dy + p2.dy - p3.dy;
  final dx1 = p1.dx - p2.dx;
  final dx2 = p3.dx - p2.dx;
  final dy1 = p1.dy - p2.dy;
  final dy2 = p3.dy - p2.dy;
  final denominator = dx1 * dy2 - dx2 * dy1;
  final projective = denominator.abs() > 0.000001;
  final g = projective ? (sx * dy2 - dx2 * sy) / denominator : 0.0;
  final h = projective ? (dx1 * sy - sx * dy1) / denominator : 0.0;

  return Matrix4.identity()
    ..setEntry(0, 0, (p1.dx - p0.dx + g * p1.dx) / source.width)
    ..setEntry(0, 1, (p3.dx - p0.dx + h * p3.dx) / source.height)
    ..setEntry(0, 3, p0.dx)
    ..setEntry(1, 0, (p1.dy - p0.dy + g * p1.dy) / source.width)
    ..setEntry(1, 1, (p3.dy - p0.dy + h * p3.dy) / source.height)
    ..setEntry(1, 3, p0.dy)
    ..setEntry(3, 0, g / source.width)
    ..setEntry(3, 1, h / source.height);
}

bool _sameNodes(List<ResolvedVaultNode> left, List<ResolvedVaultNode> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index].node?.slug != right[index].node?.slug) return false;
  }
  return true;
}
