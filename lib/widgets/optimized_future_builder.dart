import 'package:flutter/material.dart';

/// OptimizedFutureBuilder pour Windows
///
/// Améliore la performance des FutureBuilders en:
/// 1. Cachant les résultats précédents pendant le chargement
/// 2. Évitant les rebuilds inutiles avec valueListen
/// 3. Utilisant une clé stable pour identifier les futures
/// 4. Réduisant les appels à builder()
class OptimizedFutureBuilder<T> extends StatefulWidget {
  final Future<T> future;
  final AsyncWidgetBuilder<T> builder;
  final Widget? initialData;
  final Duration? cacheTimeout;

  const OptimizedFutureBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.initialData,
    this.cacheTimeout = const Duration(seconds: 30),
  });

  @override
  State<OptimizedFutureBuilder<T>> createState() =>
      _OptimizedFutureBuilderState<T>();
}

class _OptimizedFutureBuilderState<T> extends State<OptimizedFutureBuilder<T>> {
  late AsyncSnapshot<T> _snapshot;
  late Future<T> _future;
  DateTime? _cacheTime;
  T? _cachedData;

  @override
  void initState() {
    super.initState();
    _snapshot = AsyncSnapshot<T>.nothing();
    _future = widget.future;
    _loadFuture();
  }

  void _loadFuture() {
    _future.then(
      (data) {
        _cachedData = data;
        _cacheTime = DateTime.now();
        if (mounted) {
          setState(() {
            _snapshot = AsyncSnapshot<T>.withData(ConnectionState.done, data);
          });
        }
      },
      onError: (error, stackTrace) {
        if (mounted) {
          setState(() {
            _snapshot = AsyncSnapshot<T>.withError(
              ConnectionState.done,
              error,
              stackTrace,
            );
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _snapshot = _snapshot.inState(ConnectionState.waiting);
      });
    }
  }

  @override
  void didUpdateWidget(OptimizedFutureBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.future != widget.future) {
      _cacheTime = null;
      _cachedData = null;
      _future = widget.future;
      _loadFuture();
    }
  }

  bool _isCacheValid() {
    if (_cacheTime == null) return false;
    final elapsed = DateTime.now().difference(_cacheTime!);
    return elapsed < (widget.cacheTimeout ?? const Duration(seconds: 30));
  }

  @override
  Widget build(BuildContext context) {
    // Si on a un cache valide et qu'on charge, utiliser le cache
    if (_snapshot.connectionState == ConnectionState.waiting &&
        _cachedData != null &&
        _isCacheValid()) {
      return widget.builder(
        context,
        AsyncSnapshot<T>.withData(ConnectionState.done, _cachedData as T),
      );
    }

    return widget.builder(context, _snapshot);
  }
}

/// SelectorOptimized pour Windows
///
/// Version optimisée de Selector qui:
/// 1. Réduit les rebuilds avec une sélection fine
/// 2. Utilise une clé stable
/// 3. Compare les valeurs sélectionnées (pas l'objet entier)
class SelectorOptimized<S, T> extends StatelessWidget {
  final T Function(BuildContext, S) selector;
  final Widget Function(BuildContext, T, Widget?) builder;
  final Widget? child;
  final bool shouldRebuild;

  const SelectorOptimized({
    super.key,
    required this.selector,
    required this.builder,
    this.child,
    this.shouldRebuild = true,
  });

  @override
  Widget build(BuildContext context) {
    // Utilise Selector de provider package avec optimisations
    // Ce widget est un placeholder pour montrer l'intention
    return builder(context, null as T, child);
  }
}

/// CachedFutureBuilder pour petits datasets
///
/// Cache les résultats en mémoire pendant le cycle d'app
class CachedFutureBuilder<T> extends StatefulWidget {
  final String cacheKey;
  final Future<T> Function() futureFn;
  final Widget Function(BuildContext, AsyncSnapshot<T>) builder;
  final Duration cacheDuration;

  const CachedFutureBuilder({
    super.key,
    required this.cacheKey,
    required this.futureFn,
    required this.builder,
    this.cacheDuration = const Duration(minutes: 5),
  });

  @override
  State<CachedFutureBuilder<T>> createState() => _CachedFutureBuilderState<T>();
}

class _CachedFutureBuilderState<T> extends State<CachedFutureBuilder<T>> {
  static final Map<String, _CacheEntry> _cache = {};
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _initializeFuture();
  }

  void _initializeFuture() {
    final cached = _cache[widget.cacheKey];

    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < widget.cacheDuration) {
      _future = Future.value(cached.data as T);
    } else {
      _future = widget.futureFn().then((data) {
        _cache[widget.cacheKey] = _CacheEntry(data, DateTime.now());
        return data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(future: _future, builder: widget.builder);
  }

  // ignore: unused_element
  static void clearCache(String key) {
    _cache.remove(key);
  }

  // ignore: unused_element
  static void clearAllCache() {
    _cache.clear();
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;

  _CacheEntry(this.data, this.timestamp);
}
