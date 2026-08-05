import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchState {
  const SearchState({this.value = ''});

  final String value;
}

final searchStateProvider = NotifierProvider<SearchNotifier, SearchState>(
  SearchNotifier.new,
);

class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchState();

  void submit(String value) {
    state = SearchState(value: value.trim());
  }

  void clear() {
    state = const SearchState();
  }
}
