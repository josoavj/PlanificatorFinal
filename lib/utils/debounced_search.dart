/// Debounced Search Helper pour Windows
///
/// Empêche les requêtes excessive lors de la saisie
/// en attendant que l'utilisateur arrête de taper
/// avant de lancer la recherche
library;

import 'dart:async';
import 'package:flutter/material.dart';

typedef SearchCallback<T> = Future<List<T>> Function(String query);

/// Contrôleur de recherche avec debounce intégré
class DebouncedSearchController {
  final SearchCallback onSearch;
  final int debounceMs;
  final VoidCallback onSearchStart;
  final VoidCallback onSearchEnd;

  late TextEditingController textController;
  Timer? _debounceTimer;
  bool _isSearching = false;

  DebouncedSearchController({
    required this.onSearch,
    this.debounceMs = 300,
    required this.onSearchStart,
    required this.onSearchEnd,
  }) {
    textController = TextEditingController();
    textController.addListener(_onTextChanged);
  }

  bool get isSearching => _isSearching;

  void _onTextChanged() {
    _debounceTimer?.cancel();

    final query = textController.text.trim();

    if (query.isEmpty) {
      _isSearching = false;
      onSearchEnd();
      return;
    }

    _debounceTimer = Timer(Duration(milliseconds: debounceMs), () async {
      _isSearching = true;
      onSearchStart();

      try {
        await onSearch(query);
      } finally {
        _isSearching = false;
        onSearchEnd();
      }
    });
  }

  void clear() {
    _debounceTimer?.cancel();
    textController.clear();
  }

  void dispose() {
    _debounceTimer?.cancel();
    textController.dispose();
  }
}

/// Widget réutilisable pour barre de recherche optimisée
class OptimizedSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final bool showClearButton;
  final bool showSearchIcon;
  final int debounceMs;

  const OptimizedSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Rechercher...',
    this.showClearButton = true,
    this.showSearchIcon = true,
    this.debounceMs = 300,
  });

  @override
  State<OptimizedSearchBar> createState() => _OptimizedSearchBarState();
}

class _OptimizedSearchBarState extends State<OptimizedSearchBar> {
  Timer? _debounceTimer;
  bool _isSearching = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged(String value) {
    _debounceTimer?.cancel();

    if (value.isEmpty) {
      setState(() => _isSearching = false);
      widget.onChanged('');
      return;
    }

    setState(() => _isSearching = true);

    _debounceTimer = Timer(Duration(milliseconds: widget.debounceMs), () {
      widget.onChanged(value.trim());
      if (mounted) {
        setState(() => _isSearching = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      onChanged: _onTextChanged,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: widget.showSearchIcon
            ? const Icon(Icons.search, color: Colors.grey)
            : null,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            if (widget.showClearButton && widget.controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  widget.controller.clear();
                  _onTextChanged('');
                },
              ),
          ],
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}

/// Stream utilitaire pour recherche avec debounce
class DebouncedSearchStream<T> {
  final SearchCallback<T> searchFn;
  final int debounceMs;
  late StreamController<List<T>> _controller;
  Timer? _debounceTimer;

  DebouncedSearchStream({required this.searchFn, this.debounceMs = 300}) {
    _controller = StreamController<List<T>>.broadcast();
  }

  Stream<List<T>> search(String query) {
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      _controller.add([]);
      return _controller.stream;
    }

    _debounceTimer = Timer(Duration(milliseconds: debounceMs), () async {
      try {
        final results = await searchFn(query);
        _controller.add(results);
      } catch (e) {
        _controller.addError(e);
      }
    });

    return _controller.stream;
  }

  void dispose() {
    _debounceTimer?.cancel();
    _controller.close();
  }
}
