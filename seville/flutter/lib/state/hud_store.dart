import 'package:flutter_riverpod/flutter_riverpod.dart';

class HudState {
  const HudState({this.searchEnabled = false, this.searchValue = ''});

  final bool searchEnabled;
  final String searchValue;

  bool get isSearchEnabled => searchEnabled;

  HudState copyWith({bool? searchEnabled, String? searchValue}) => HudState(
    searchEnabled: searchEnabled ?? this.searchEnabled,
    searchValue: searchValue ?? this.searchValue,
  );
}

final hudStateProvider = NotifierProvider<HudNotifier, HudState>(
  HudNotifier.new,
);

class HudNotifier extends Notifier<HudState> {
  @override
  HudState build() => const HudState();

  void showSearch() {
    state = state.copyWith(searchEnabled: true);
  }

  void hideSearch() {
    state = state.copyWith(searchEnabled: false);
  }

  void submitSearch(String value) {
    state = state.copyWith(searchEnabled: false, searchValue: value.trim());
  }
}
