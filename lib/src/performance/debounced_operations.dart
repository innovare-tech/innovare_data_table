import 'dart:async';
import 'dart:ui';

class DebouncedOperation {
  final Duration delay;
  Timer? _timer;

  DebouncedOperation({this.delay = const Duration(milliseconds: 300)});

  void run(VoidCallback operation) {
    _timer?.cancel();
    _timer = Timer(delay, operation);
  }

  void runAsync(Future<void> Function() operation) {
    _timer?.cancel();
    _timer = Timer(delay, () async {
      await operation();
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    cancel();
  }
}

class ThrottledOperation {
  final Duration interval;
  DateTime? _lastExecution;

  ThrottledOperation({this.interval = const Duration(milliseconds: 100)});

  bool run(VoidCallback operation) {
    final now = DateTime.now();

    if (_lastExecution == null ||
        now.difference(_lastExecution!) >= interval) {
      _lastExecution = now;
      operation();
      return true;
    }

    return false;
  }

  Future<bool> runAsync(Future<void> Function() operation) async {
    final now = DateTime.now();

    if (_lastExecution == null ||
        now.difference(_lastExecution!) >= interval) {
      _lastExecution = now;
      await operation();
      return true;
    }

    return false;
  }
}

class BatchProcessor<T> {
  final Duration batchDelay;
  final int maxBatchSize;
  final Future<void> Function(List<T> batch) processor;

  final List<T> _pendingItems = [];
  Timer? _batchTimer;

  BatchProcessor({
    this.batchDelay = const Duration(milliseconds: 500),
    this.maxBatchSize = 50,
    required this.processor,
  });

  void add(T item) {
    _pendingItems.add(item);

    if (_pendingItems.length >= maxBatchSize) {
      _processBatch();
    } else {
      _scheduleBatch();
    }
  }

  void addAll(List<T> items) {
    _pendingItems.addAll(items);

    if (_pendingItems.length >= maxBatchSize) {
      _processBatch();
    } else {
      _scheduleBatch();
    }
  }

  void _scheduleBatch() {
    _batchTimer?.cancel();
    _batchTimer = Timer(batchDelay, _processBatch);
  }

  void _processBatch() {
    if (_pendingItems.isEmpty) return;

    final batch = List<T>.from(_pendingItems);
    _pendingItems.clear();
    _batchTimer?.cancel();

    processor(batch).catchError((error) {
      print('Batch processing error: $error');
    });
  }

  void flush() {
    _processBatch();
  }

  void dispose() {
    _batchTimer?.cancel();
    _pendingItems.clear();
  }
}
