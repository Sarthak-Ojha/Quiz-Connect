// lib/utils/performance_utils.dart

import 'dart:async';
import 'package:flutter/material.dart';

class PerformanceUtils {
  // Cache for expensive operations
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  
  // Cache duration in seconds
  static const int _cacheDuration = 30;
  
  /// Cache data with expiration
  static void cacheData(String key, dynamic data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
  }
  
  /// Get cached data if not expired
  static T? getCachedData<T>(String key) {
    if (!_cache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return null;
    }
    
    final timestamp = _cacheTimestamps[key]!;
    final now = DateTime.now();
    
    if (now.difference(timestamp).inSeconds > _cacheDuration) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      return null;
    }
    
    return _cache[key] as T?;
  }
  
  /// Clear expired cache entries
  static void clearExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp).inSeconds > _cacheDuration) {
        expiredKeys.add(key);
      }
    });
    
    for (final key in expiredKeys) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }
  
  /// Debounce function calls
  static Timer? _debounceTimer;
  
  static void debounce(VoidCallback callback, {Duration delay = const Duration(milliseconds: 300)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }
  
  /// Throttle function calls
  static DateTime? _lastThrottleCall;
  
  static void throttle(VoidCallback callback, {Duration interval = const Duration(milliseconds: 100)}) {
    final now = DateTime.now();
    if (_lastThrottleCall == null || now.difference(_lastThrottleCall!).inMilliseconds >= interval.inMilliseconds) {
      _lastThrottleCall = now;
      callback();
    }
  }
}

/// Optimized FutureBuilder that caches results
class OptimizedFutureBuilder<T> extends StatefulWidget {
  final Future<T> Function() futureBuilder;
  final Widget Function(BuildContext context, AsyncSnapshot<T> snapshot) builder;
  final String cacheKey;
  final Duration cacheDuration;
  
  const OptimizedFutureBuilder({
    super.key,
    required this.futureBuilder,
    required this.builder,
    required this.cacheKey,
    this.cacheDuration = const Duration(seconds: 30),
  });
  
  @override
  State<OptimizedFutureBuilder<T>> createState() => _OptimizedFutureBuilderState<T>();
}

class _OptimizedFutureBuilderState<T> extends State<OptimizedFutureBuilder<T>> {
  late Future<T> _future;
  
  @override
  void initState() {
    super.initState();
    _initializeFuture();
  }
  
  void _initializeFuture() {
    // Check cache first
    final cachedData = PerformanceUtils.getCachedData<T>(widget.cacheKey);
    if (cachedData != null) {
      _future = Future.value(cachedData);
    } else {
      _future = widget.futureBuilder().then((data) {
        PerformanceUtils.cacheData(widget.cacheKey, data);
        return data;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: widget.builder,
    );
  }
}
