import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart' hide DataTableSource;
import 'package:innovare_data_table/src/data_sources/data_table_models.dart';
import 'package:innovare_data_table/src/data_sources/data_table_source.dart';

enum LoadingState {
  idle,
  loading,
  refreshing,
  backgroundLoading,
  predictiveLoading,
  error,
}

class LoadingConfiguration {
  final bool enablePredictiveLoading;
  final bool enableBackgroundRefresh;
  final bool enableIntelligentCache;
  final Duration backgroundRefreshInterval;
  final Duration cacheMaxAge;
  final int predictivePageCount;
  final double predictiveTriggerThreshold; // 0.0 to 1.0
  final bool showPredictiveIndicator;

  const LoadingConfiguration({
    this.enablePredictiveLoading = true,
    this.enableBackgroundRefresh = true,
    this.enableIntelligentCache = true,
    this.backgroundRefreshInterval = const Duration(minutes: 5),
    this.cacheMaxAge = const Duration(minutes: 10),
    this.predictivePageCount = 2,
    this.predictiveTriggerThreshold = 0.7,
    this.showPredictiveIndicator = true,
  });
}

class CacheEntry<T> {
  final DataTableResult<T> data;
  final DateTime timestamp;
  final DataTableRequest request;
  final bool isStale;

  const CacheEntry({
    required this.data,
    required this.timestamp,
    required this.request,
    this.isStale = false,
  });

  bool isExpired(Duration maxAge) {
    return DateTime.now().difference(timestamp) > maxAge;
  }

  CacheEntry<T> markAsStale() {
    return CacheEntry<T>(
      data: data,
      timestamp: timestamp,
      request: request,
      isStale: true,
    );
  }
}

class SmartLoadingManager<T> extends ChangeNotifier {
  final DataTableSource<T> dataSource;
  final LoadingConfiguration config;

  // Estado interno
  final Map<String, CacheEntry<T>> _cache = {};
  final Map<String, Future<DataTableResult<T>>> _ongoingRequests = {};
  final Set<String> _predictivelyLoaded = {};

  LoadingState _currentState = LoadingState.idle;
  DataTableRequest? _currentRequest;
  DataTableResult<T>? _currentResult;
  String? _error;
  Timer? _backgroundRefreshTimer;
  Timer? _predictiveTimer;

  // Métricas para otimização
  final Map<String, int> _accessCount = {};
  final Map<String, DateTime> _lastAccess = {};

  SmartLoadingManager({
    required this.dataSource,
    this.config = const LoadingConfiguration(),
  }) {
    _setupBackgroundRefresh();
  }

  // Getters
  LoadingState get currentState => _currentState;
  DataTableResult<T>? get currentResult => _currentResult;
  String? get error => _error;
  bool get isLoading => _currentState == LoadingState.loading;
  bool get isRefreshing => _currentState == LoadingState.refreshing;
  bool get isBackgroundLoading => _currentState == LoadingState.backgroundLoading;

  // Estatísticas do cache
  int get cacheSize => _cache.length;
  double get cacheHitRate {
    final total = _accessCount.values.fold<int>(0, (sum, count) => sum + count);
    final hits = _cache.length;
    return total > 0 ? hits / total : 0.0;
  }

  Future<DataTableResult<T>> loadData(DataTableRequest request, {
    bool forceRefresh = false,
    bool silent = false,
  }) async {
    final cacheKey = _generateCacheKey(request);

    // Verificar cache primeiro
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      final entry = _cache[cacheKey]!;

      if (!entry.isExpired(config.cacheMaxAge) && !entry.isStale) {
        _updateAccessMetrics(cacheKey);
        _currentResult = entry.data;
        _currentRequest = request;

        // Trigger predictive loading se necessário
        _schedulePredictiveLoading(request);

        notifyListeners();
        return entry.data;
      }
    }

    // Verificar se já está sendo carregado
    if (_ongoingRequests.containsKey(cacheKey)) {
      return await _ongoingRequests[cacheKey]!;
    }

    // Carregar dados
    return await _performLoad(request, cacheKey, silent);
  }

  Future<DataTableResult<T>> _performLoad(
      DataTableRequest request,
      String cacheKey,
      bool silent,
      ) async {
    if (!silent) {
      _setLoadingState(LoadingState.loading);
    }

    final future = _fetchData(request);
    _ongoingRequests[cacheKey] = future;

    try {
      final result = await future;

      // Atualizar cache
      _cache[cacheKey] = CacheEntry<T>(
        data: result,
        timestamp: DateTime.now(),
        request: request,
      );

      _currentResult = result;
      _currentRequest = request;
      _updateAccessMetrics(cacheKey);

      if (!silent) {
        _setLoadingState(LoadingState.idle);
      }

      // Limpar cache expirado
      _cleanExpiredCache();

      // Agendar loading preditivo
      _schedulePredictiveLoading(request);

      notifyListeners();
      return result;

    } catch (e) {
      _error = e.toString();
      _setLoadingState(LoadingState.error);
      rethrow;
    } finally {
      _ongoingRequests.remove(cacheKey);
    }
  }

  Future<void> refresh({bool silent = false}) async {
    if (_currentRequest == null) return;

    if (!silent) {
      _setLoadingState(LoadingState.refreshing);
    }

    try {
      final result = await _fetchData(_currentRequest!);

      // Invalidar cache relacionado
      _invalidateRelatedCache(_currentRequest!);

      // Atualizar cache
      final cacheKey = _generateCacheKey(_currentRequest!);
      _cache[cacheKey] = CacheEntry<T>(
        data: result,
        timestamp: DateTime.now(),
        request: _currentRequest!,
      );

      _currentResult = result;

      if (!silent) {
        _setLoadingState(LoadingState.idle);
      }

      notifyListeners();

    } catch (e) {
      _error = e.toString();
      _setLoadingState(LoadingState.error);
      rethrow;
    }
  }

  void _schedulePredictiveLoading(DataTableRequest currentRequest) {
    if (!config.enablePredictiveLoading) return;

    _predictiveTimer?.cancel();
    _predictiveTimer = Timer(const Duration(milliseconds: 500), () {
      _performPredictiveLoading(currentRequest);
    });
  }

  Future<void> _performPredictiveLoading(DataTableRequest currentRequest) async {
    _setLoadingState(LoadingState.predictiveLoading);

    try {
      final futures = <Future<void>>[];

      // Próximas páginas
      for (int i = 1; i <= config.predictivePageCount; i++) {
        final nextRequest = currentRequest.copyWith(
          page: currentRequest.page + i,
        );
        final cacheKey = _generateCacheKey(nextRequest);

        if (!_cache.containsKey(cacheKey) && !_predictivelyLoaded.contains(cacheKey)) {
          futures.add(_predictiveLoadPage(nextRequest, cacheKey));
        }
      }

      // Página anterior (se houver)
      if (currentRequest.page > 0) {
        final prevRequest = currentRequest.copyWith(
          page: currentRequest.page - 1,
        );
        final cacheKey = _generateCacheKey(prevRequest);

        if (!_cache.containsKey(cacheKey) && !_predictivelyLoaded.contains(cacheKey)) {
          futures.add(_predictiveLoadPage(prevRequest, cacheKey));
        }
      }

      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }

    } catch (e) {
      // Ignorar erros de loading preditivo
      print('Predictive loading error: $e');
    } finally {
      _setLoadingState(LoadingState.idle);
    }
  }

  Future<void> _predictiveLoadPage(DataTableRequest request, String cacheKey) async {
    try {
      _predictivelyLoaded.add(cacheKey);
      final result = await _fetchData(request);

      _cache[cacheKey] = CacheEntry<T>(
        data: result,
        timestamp: DateTime.now(),
        request: request,
      );

    } catch (e) {
      // Ignorar erros individuais
    }
  }

  void _setupBackgroundRefresh() {
    if (!config.enableBackgroundRefresh) return;

    _backgroundRefreshTimer = Timer.periodic(
      config.backgroundRefreshInterval,
          (_) => _performBackgroundRefresh(),
    );
  }

  Future<void> _performBackgroundRefresh() async {
    if (_currentRequest == null || _currentState == LoadingState.loading) return;

    _setLoadingState(LoadingState.backgroundLoading);

    try {
      // Atualizar página atual em background
      await _fetchData(_currentRequest!);

      // Marcar entradas relacionadas como stale para próximo acesso
      _markStaleEntries(_currentRequest!);

    } catch (e) {
      // Log do erro mas não interromper UX
      print('Background refresh error: $e');
    } finally {
      _setLoadingState(LoadingState.idle);
    }
  }

  Future<DataTableResult<T>> _fetchData(DataTableRequest request) async {
    return await dataSource.fetch(request);
  }

  void _setLoadingState(LoadingState state) {
    if (_currentState != state) {
      _currentState = state;
      notifyListeners();
    }
  }

  String _generateCacheKey(DataTableRequest request) {
    return '${request.page}_${request.pageSize}_${request.searchTerm}_'
        '${request.sorts.map((s) => '${s.field}:${s.ascending}').join(',')}_'
        '${request.filters.map((f) => '${f.field}:${f.value}').join(',')}';
  }

  void _updateAccessMetrics(String cacheKey) {
    _accessCount[cacheKey] = (_accessCount[cacheKey] ?? 0) + 1;
    _lastAccess[cacheKey] = DateTime.now();
  }

  void _cleanExpiredCache() {
    final keysToRemove = <String>[];
    final now = DateTime.now();

    _cache.forEach((key, entry) {
      if (entry.isExpired(config.cacheMaxAge)) {
        keysToRemove.add(key);
      }
    });

    for (final key in keysToRemove) {
      _cache.remove(key);
      _accessCount.remove(key);
      _lastAccess.remove(key);
      _predictivelyLoaded.remove(key);
    }
  }

  void _invalidateRelatedCache(DataTableRequest request) {
    final keysToInvalidate = <String>[];

    _cache.forEach((key, entry) {
      // Invalidar se os filtros/ordenação são os mesmos (páginas relacionadas)
      if (_isSameQuery(entry.request, request)) {
        keysToInvalidate.add(key);
      }
    });

    for (final key in keysToInvalidate) {
      _cache.remove(key);
      _predictivelyLoaded.remove(key);
    }
  }

  void _markStaleEntries(DataTableRequest request) {
    _cache.forEach((key, entry) {
      if (_isSameQuery(entry.request, request)) {
        _cache[key] = entry.markAsStale();
      }
    });
  }

  bool _isSameQuery(DataTableRequest a, DataTableRequest b) {
    return a.searchTerm == b.searchTerm &&
        a.sorts.length == b.sorts.length &&
        a.filters.length == b.filters.length;
  }

  void clearCache() {
    _cache.clear();
    _accessCount.clear();
    _lastAccess.clear();
    _predictivelyLoaded.clear();
    notifyListeners();
  }

  Map<String, dynamic> getMetrics() {
    return {
      'cacheSize': cacheSize,
      'cacheHitRate': cacheHitRate,
      'totalRequests': _accessCount.values.fold<int>(0, (sum, count) => sum + count),
      'currentState': _currentState.toString(),
      'backgroundRefreshEnabled': config.enableBackgroundRefresh,
      'predictiveLoadingEnabled': config.enablePredictiveLoading,
    };
  }

  @override
  void dispose() {
    _backgroundRefreshTimer?.cancel();
    _predictiveTimer?.cancel();
    super.dispose();
  }
}

// =============================================================================
// Smart Loading Indicators
// =============================================================================

class SmartLoadingIndicator extends StatefulWidget {
  final SmartLoadingManager loadingManager;
  final Widget child;
  final bool showPredictiveIndicator;
  final bool showBackgroundIndicator;
  final Color? primaryColor;

  const SmartLoadingIndicator({
    super.key,
    required this.loadingManager,
    required this.child,
    this.showPredictiveIndicator = true,
    this.showBackgroundIndicator = true,
    this.primaryColor,
  });

  @override
  State<SmartLoadingIndicator> createState() => _SmartLoadingIndicatorState();
}

class _SmartLoadingIndicatorState extends State<SmartLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _predictiveController;
  late Animation<double> _backgroundOpacity;
  late Animation<double> _predictiveProgress;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    widget.loadingManager.addListener(_onLoadingStateChanged);
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _predictiveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _backgroundOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    _predictiveProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _predictiveController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    widget.loadingManager.removeListener(_onLoadingStateChanged);
    _backgroundController.dispose();
    _predictiveController.dispose();
    super.dispose();
  }

  void _onLoadingStateChanged() {
    final state = widget.loadingManager.currentState;

    switch (state) {
      case LoadingState.backgroundLoading:
        if (widget.showBackgroundIndicator) {
          _backgroundController.forward();
        }
        break;
      case LoadingState.predictiveLoading:
        if (widget.showPredictiveIndicator) {
          _predictiveController.forward();
        }
        break;
      case LoadingState.idle:
        _backgroundController.reverse();
        _predictiveController.reset();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        // Background loading indicator
        if (widget.showBackgroundIndicator)
          AnimatedBuilder(
            animation: _backgroundOpacity,
            builder: (context, child) {
              return Positioned(
                top: 0,
                right: 16,
                child: Opacity(
                  opacity: _backgroundOpacity.value,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.primaryColor ?? Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Atualizando...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

        // Predictive loading indicator
        if (widget.showPredictiveIndicator)
          AnimatedBuilder(
            animation: _predictiveProgress,
            builder: (context, child) {
              if (_predictiveProgress.value == 0) return const SizedBox.shrink();

              return Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  child: LinearProgressIndicator(
                    value: _predictiveProgress.value,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation(
                      (widget.primaryColor ?? Theme.of(context).primaryColor).withOpacity(0.3),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

// =============================================================================
// Wrapper para ScrollController com Predictive Loading
// =============================================================================

class PredictiveScrollWrapper extends StatefulWidget {
  final Widget child;
  final SmartLoadingManager loadingManager;
  final DataTableRequest currentRequest;
  final double triggerThreshold;

  const PredictiveScrollWrapper({
    super.key,
    required this.child,
    required this.loadingManager,
    required this.currentRequest,
    this.triggerThreshold = 0.8,
  });

  @override
  State<PredictiveScrollWrapper> createState() => _PredictiveScrollWrapperState();
}

class _PredictiveScrollWrapperState extends State<PredictiveScrollWrapper> {
  bool _hasTriggeredPredictive = false;

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final scrollPosition = notification.metrics.pixels;
      final maxScroll = notification.metrics.maxScrollExtent;

      if (maxScroll > 0) {
        final scrollRatio = scrollPosition / maxScroll;

        if (scrollRatio >= widget.triggerThreshold && !_hasTriggeredPredictive) {
          _hasTriggeredPredictive = true;
          _triggerPredictiveLoading();
        } else if (scrollRatio < widget.triggerThreshold) {
          _hasTriggeredPredictive = false;
        }
      }
    }

    return false;
  }

  void _triggerPredictiveLoading() {
    // Simular loading da próxima página
    final nextRequest = widget.currentRequest.copyWith(
      page: widget.currentRequest.page + 1,
    );

    widget.loadingManager.loadData(nextRequest, silent: true).catchError((e) {
      // Ignorar erros de predictive loading
    });
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: widget.child,
    );
  }
}
