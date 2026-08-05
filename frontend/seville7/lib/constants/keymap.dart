import 'package:flutter/services.dart';

enum SevilleKeymapAction {
  showSearch,
  refreshFanData,
  copySelectedNodeSlug,
  submit,
  cancel,
}

SevilleKeymapAction? resolveSevilleKeymapAction(
  KeyEvent event,
  HardwareKeyboard keyboard,
) {
  if (event is! KeyDownEvent) return null;

  if (event.logicalKey == LogicalKeyboardKey.keyF && keyboard.isMetaPressed) {
    return SevilleKeymapAction.showSearch;
  }
  if (event.logicalKey == LogicalKeyboardKey.keyR && keyboard.isMetaPressed) {
    return SevilleKeymapAction.refreshFanData;
  }
  if (event.logicalKey == LogicalKeyboardKey.keyC && keyboard.isMetaPressed) {
    return SevilleKeymapAction.copySelectedNodeSlug;
  }
  if (event.logicalKey == LogicalKeyboardKey.enter ||
      event.logicalKey == LogicalKeyboardKey.numpadEnter) {
    return SevilleKeymapAction.submit;
  }
  if (event.logicalKey == LogicalKeyboardKey.escape) {
    return SevilleKeymapAction.cancel;
  }
  return null;
}
