class PerformanceMonitor {
  static final Map<String, PerformanceMetrics> _metrics = {};
  static final Map<String, DateTime> _operationStarts = {};

  static void startOperation(String operationName) {
    _operationStarts[operationName] = DateTime.now();
  }

  static void endOperation(String operationName, {Map<String, dynamic>? metadata}) {
    final start = _operationStarts.remove(operationName);
    if (start == null) return;

    final duration = DateTime.now().difference(start);

    if (!_metrics.containsKey(operationName)) {
      _metrics[operationName] = PerformanceMetrics(operationName);
    }

    _metrics[operationName]!.addMeasurement(duration, metadata);
  }

  static T measureOperation<T>(String operationName, T Function() operation) {
    startOperation(operationName);
    try {
      final result = operation();
      endOperation(operationName);
      return result;
    } catch (e) {
      endOperation(operationName, metadata: {'error': e.toString()});
      rethrow;
    }
  }

  static Future<T> measureAsyncOperation<T>(
      String operationName,
      Future<T> Function() operation,
      ) async {
    startOperation(operationName);
    try {
      final result = await operation();
      endOperation(operationName);
      return result;
    } catch (e) {
      endOperation(operationName, metadata: {'error': e.toString()});
      rethrow;
    }
  }

  static PerformanceMetrics? getMetrics(String operationName) {
    return _metrics[operationName];
  }

  static Map<String, PerformanceMetrics> getAllMetrics() {
    return Map.unmodifiable(_metrics);
  }

  static void clearMetrics([String? operationName]) {
    if (operationName != null) {
      _metrics.remove(operationName);
    } else {
      _metrics.clear();
    }
  }

  static String generateReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== Performance Report ===');
    buffer.writeln('Generated at: ${DateTime.now()}');
    buffer.writeln();

    _metrics.forEach((name, metrics) {
      buffer.writeln('Operation: $name');
      buffer.writeln('  Total calls: ${metrics.totalCalls}');
      buffer.writeln('  Average duration: ${metrics.averageDuration.inMilliseconds}ms');
      buffer.writeln('  Min duration: ${metrics.minDuration.inMilliseconds}ms');
      buffer.writeln('  Max duration: ${metrics.maxDuration.inMilliseconds}ms');
      buffer.writeln('  Error count: ${metrics.errorCount}');
      buffer.writeln();
    });

    return buffer.toString();
  }
}

class PerformanceMetrics {
  final String operationName;
  final List<Duration> _durations = [];
  final List<Map<String, dynamic>> _metadata = [];

  int _errorCount = 0;

  PerformanceMetrics(this.operationName);

  void addMeasurement(Duration duration, [Map<String, dynamic>? metadata]) {
    _durations.add(duration);
    _metadata.add(metadata ?? {});

    if (metadata?['error'] != null) {
      _errorCount++;
    }
  }

  int get totalCalls => _durations.length;
  int get errorCount => _errorCount;

  Duration get totalDuration => _durations.fold(
    Duration.zero,
        (sum, duration) => sum + duration,
  );

  Duration get averageDuration => _durations.isNotEmpty
      ? Duration(microseconds: totalDuration.inMicroseconds ~/ _durations.length)
      : Duration.zero;

  Duration get minDuration => _durations.isNotEmpty
      ? _durations.reduce((a, b) => a < b ? a : b)
      : Duration.zero;

  Duration get maxDuration => _durations.isNotEmpty
      ? _durations.reduce((a, b) => a > b ? a : b)
      : Duration.zero;

  double get successRate => totalCalls > 0
      ? ((totalCalls - errorCount) / totalCalls) * 100
      : 100.0;
}
