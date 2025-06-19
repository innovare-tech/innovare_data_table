class MemoryManager<T> {
  final int maxCacheSize;
  final Duration itemLifetime;
  final Map<String, CacheEntry<T>> _cache = {};
  final Map<String, DateTime> _accessTimes = {};

  MemoryManager({
    this.maxCacheSize = 1000,
    this.itemLifetime = const Duration(minutes: 10),
  });

  void put(String key, T value) {
    _cleanup();

    _cache[key] = CacheEntry<T>(value: value, timestamp: DateTime.now());
    _accessTimes[key] = DateTime.now();

    if (_cache.length > maxCacheSize) {
      _evictLeastRecentlyUsed();
    }
  }

  T? get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (_isExpired(entry)) {
      remove(key);
      return null;
    }

    _accessTimes[key] = DateTime.now();
    return entry.value;
  }

  void remove(String key) {
    _cache.remove(key);
    _accessTimes.remove(key);
  }

  void clear() {
    _cache.clear();
    _accessTimes.clear();
  }

  bool _isExpired(CacheEntry<T> entry) {
    return DateTime.now().difference(entry.timestamp) > itemLifetime;
  }

  void _cleanup() {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    _cache.forEach((key, entry) {
      if (now.difference(entry.timestamp) > itemLifetime) {
        keysToRemove.add(key);
      }
    });

    for (final key in keysToRemove) {
      remove(key);
    }
  }

  void _evictLeastRecentlyUsed() {
    if (_accessTimes.isEmpty) return;

    final sortedEntries = _accessTimes.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final oldestKey = sortedEntries.first.key;
    remove(oldestKey);
  }

  MemoryStats getStats() {
    return MemoryStats(
      cacheSize: _cache.length,
      maxCacheSize: maxCacheSize,
      usagePercentage: (_cache.length / maxCacheSize) * 100,
    );
  }
}

class CacheEntry<T> {
  final T value;
  final DateTime timestamp;

  const CacheEntry({required this.value, required this.timestamp});
}

class MemoryStats {
  final int cacheSize;
  final int maxCacheSize;
  final double usagePercentage;

  const MemoryStats({
    required this.cacheSize,
    required this.maxCacheSize,
    required this.usagePercentage,
  });

  @override
  String toString() {
    return 'MemoryStats(size: $cacheSize/$maxCacheSize, usage: ${usagePercentage.toStringAsFixed(1)}%)';
  }
}