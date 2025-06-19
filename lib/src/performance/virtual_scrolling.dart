import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class VirtualScrollConfig {
  final double itemHeight;
  final double bufferSize; // Items to render outside viewport
  final bool enableBuffering;
  final int maxCachedItems;
  final bool useEstimatedItemHeight;

  const VirtualScrollConfig({
    this.itemHeight = 52.0,
    this.bufferSize = 5.0,
    this.enableBuffering = true,
    this.maxCachedItems = 1000,
    this.useEstimatedItemHeight = false,
  });
}

class VirtualScrollController extends ChangeNotifier {
  final VirtualScrollConfig config;
  final ScrollController scrollController;

  final Map<int, Widget> _itemCache = {};
  final Map<int, double> _itemHeights = {};

  double _viewportHeight = 0;
  double _scrollOffset = 0;
  int _totalItems = 0;

  int _renderedItems = 0;
  int _cacheHits = 0;
  int _cacheMisses = 0;

  VirtualScrollController({
    required this.config,
    ScrollController? scrollController,
  }) : scrollController = scrollController ?? ScrollController() {
    this.scrollController.addListener(_onScroll);
  }

  int get renderedItems => _renderedItems;
  double get cacheHitRate => _cacheMisses > 0 ? _cacheHits / (_cacheHits + _cacheMisses) : 1.0;
  int get cachedItemsCount => _itemCache.length;

  void _onScroll() {
    _scrollOffset = scrollController.offset;
    notifyListeners();
  }

  void updateViewport(double height) {
    if (_viewportHeight != height) {
      _viewportHeight = height;
      notifyListeners();
    }
  }

  void updateTotalItems(int count) {
    if (_totalItems != count) {
      _totalItems = count;
      _cleanupCache();
      notifyListeners();
    }
  }

  ViewportRange calculateVisibleRange() {
    if (_viewportHeight == 0 || _totalItems == 0) {
      return ViewportRange(start: 0, end: 0);
    }

    final itemHeight = config.itemHeight;
    final bufferItems = config.enableBuffering ? config.bufferSize.ceil() : 0;

    final startIndex = max(0, (_scrollOffset / itemHeight).floor() - bufferItems);
    final visibleCount = (_viewportHeight / itemHeight).ceil();
    final endIndex = min(_totalItems, startIndex + visibleCount + (bufferItems * 2));

    return ViewportRange(start: startIndex, end: endIndex);
  }

  Widget getCachedItem(int index, Widget Function(int) builder) {
    if (_itemCache.containsKey(index)) {
      _cacheHits++;
      return _itemCache[index]!;
    }

    _cacheMisses++;
    final item = builder(index);

    if (_itemCache.length < config.maxCachedItems) {
      _itemCache[index] = item;
    }

    return item;
  }

  void _cleanupCache() {
    if (_itemCache.length > config.maxCachedItems) {
      final keys = _itemCache.keys.toList()..sort();
      final toRemove = keys.take(_itemCache.length - config.maxCachedItems);

      for (final key in toRemove) {
        _itemCache.remove(key);
      }
    }
  }

  void clearCache() {
    _itemCache.clear();
    _itemHeights.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }
}

class ViewportRange {
  final int start;
  final int end;

  const ViewportRange({required this.start, required this.end});

  int get count => end - start;
  bool get isEmpty => count <= 0;

  @override
  String toString() => 'ViewportRange(start: $start, end: $end, count: $count)';
}

class VirtualListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, int index, T item) itemBuilder;
  final VirtualScrollConfig config;
  final VirtualScrollController? controller;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;

  const VirtualListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.config = const VirtualScrollConfig(),
    this.controller,
    this.loadingBuilder,
    this.emptyBuilder,
  });

  @override
  State<VirtualListView<T>> createState() => _VirtualListViewState<T>();
}

class _VirtualListViewState<T> extends State<VirtualListView<T>> {
  late VirtualScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? VirtualScrollController(config: widget.config);
    _controller.updateTotalItems(widget.items.length);
  }

  @override
  void didUpdateWidget(VirtualListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.items.length != widget.items.length) {
      _controller.updateTotalItems(widget.items.length);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return widget.emptyBuilder?.call(context) ??
          const Center(child: Text('Nenhum item encontrado'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _controller.updateViewport(constraints.maxHeight);

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final range = _controller.calculateVisibleRange();

            if (range.isEmpty) {
              return widget.loadingBuilder?.call(context) ??
                  const Center(child: CircularProgressIndicator());
            }

            return _buildVirtualList(range);
          },
        );
      },
    );
  }

  Widget _buildVirtualList(ViewportRange range) {
    final totalHeight = widget.items.length * widget.config.itemHeight;
    final topPadding = range.start * widget.config.itemHeight;
    final bottomPadding = totalHeight - (range.end * widget.config.itemHeight);

    return SingleChildScrollView(
      controller: _controller.scrollController,
      child: Column(
        children: [
          // Top spacer
          if (topPadding > 0)
            SizedBox(height: topPadding),

          // Visible items
          ...List.generate(range.count, (index) {
            final itemIndex = range.start + index;
            final item = widget.items[itemIndex];

            return _controller.getCachedItem(
              itemIndex,
                  (_) => SizedBox(
                height: widget.config.itemHeight,
                child: widget.itemBuilder(context, itemIndex, item),
              ),
            );
          }),

          // Bottom spacer
          if (bottomPadding > 0)
            SizedBox(height: bottomPadding),
        ],
      ),
    );
  }
}