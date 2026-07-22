import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/hud_store.dart';

class SearchHud extends ConsumerStatefulWidget {
  const SearchHud({super.key});

  @override
  ConsumerState<SearchHud> createState() => _SearchHudState();
}

class _SearchHudState extends ConsumerState<SearchHud> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(hudStateProvider).searchValue,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Material(
          elevation: 8,
          color: const Color(0xEEFFFFFF),
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search',
                      ),
                      onSubmitted: _submit,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _submit(_controller.text),
                    child: const Text('OK'),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: ref.read(hudStateProvider.notifier).hideSearch,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  void _submit(String value) {
    ref.read(hudStateProvider.notifier).submitSearch(value);
  }
}
