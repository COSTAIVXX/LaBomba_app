import 'dart:convert';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:uuid/uuid.dart';

class ObservabilityService {
  ObservabilityService._();

  static FirebaseAnalytics? analytics;
  static String _currentCorrelationId = const Uuid().v4();
  static final Map<String, Map<String, dynamic>> _metrics =
      <String, Map<String, dynamic>>{};

  static String get currentCorrelationId => _currentCorrelationId;

  static String nextCorrelationId() {
    _currentCorrelationId = const Uuid().v4();
    return _currentCorrelationId;
  }

  static void setCorrelationId(String? correlationId) {
    if (correlationId == null || correlationId.trim().isEmpty) {
      return;
    }
    _currentCorrelationId = correlationId;
  }

  static Map<String, dynamic> sanitizePayload(Map<String, Object?>? payload) {
    final sanitized = <String, dynamic>{};
    if (payload == null) {
      return sanitized;
    }

    for (final entry in payload.entries) {
      final key = entry.key;
      final lowerKey = key.toLowerCase();
      final value = entry.value;

      if (lowerKey.contains('token') ||
          lowerKey.contains('secret') ||
          lowerKey.contains('password') ||
          lowerKey.contains('authorization') ||
          lowerKey.contains('cookie') ||
          lowerKey.contains('email') ||
          lowerKey.contains('phone') ||
          lowerKey.contains('pii')) {
        sanitized[key] = '[REDACTED]';
        continue;
      }

      if (value is Map<String, Object?>) {
        sanitized[key] = sanitizePayload(value);
      } else if (value is Map) {
        sanitized[key] = sanitizePayload(value.cast<String, Object?>());
      } else if (value is List) {
        sanitized[key] = value.map((dynamic item) {
          if (item is Map<String, Object?>) {
            return sanitizePayload(item);
          }
          if (item is Map) {
            return sanitizePayload(item.cast<String, Object?>());
          }
          return item;
        }).toList();
      } else {
        sanitized[key] = value;
      }
    }

    return sanitized;
  }

  static Map<String, Map<String, dynamic>> getMetricsSnapshot() {
    final snapshot = <String, Map<String, dynamic>>{};
    for (final entry in _metrics.entries) {
      snapshot[entry.key] = Map<String, dynamic>.from(entry.value);
    }
    return snapshot;
  }

  static void clearMetrics() {
    _metrics.clear();
  }

  static void recordMetric(
    String name, {
    required String status,
    int? value,
    int? latencyMs,
    String? correlationId,
    Map<String, Object?>? dimensions,
  }) {
    final safeCorrelationId = correlationId ?? _currentCorrelationId;
    final metric = _metrics.putIfAbsent(
      name,
      () => <String, dynamic>{
        'count': 0,
        'success': 0,
        'failure': 0,
        'latencyMs': <int>[],
        'lastUpdatedAt': DateTime.now().toUtc().toIso8601String(),
      },
    );

    metric['count'] = (metric['count'] as int?) ?? 0;
    metric['count'] = metric['count'] + 1;
    if (status == 'success') {
      metric['success'] = (metric['success'] as int?) ?? 0;
      metric['success'] = metric['success'] + 1;
    } else {
      metric['failure'] = (metric['failure'] as int?) ?? 0;
      metric['failure'] = metric['failure'] + 1;
    }

    if (latencyMs != null) {
      final latencies =
          (metric['latencyMs'] as List<int>? ?? <int>[]).toList(growable: true);
      latencies.add(latencyMs);
      metric['latencyMs'] = latencies;
      final avg =
          latencies.reduce((sum, item) => sum + item) / latencies.length;
      metric['averageLatencyMs'] = avg.round();
    }

    metric['lastStatus'] = status;
    metric['lastCorrelationId'] = safeCorrelationId;
    metric['lastUpdatedAt'] = DateTime.now().toUtc().toIso8601String();

    if (value != null) {
      metric['value'] = value;
    }

    if (dimensions != null && dimensions.isNotEmpty) {
      metric['dimensions'] = sanitizePayload(dimensions);
    }
  }

  static Future<T> observeOperation<T>(
    String metricName,
    Future<T> Function() action, {
    String? eventName,
    String? operation,
    String? component,
    String? correlationId,
    Map<String, Object?>? context,
  }) async {
    final effectiveCorrelationId = correlationId ?? _currentCorrelationId;
    final started = DateTime.now();
    final extraContext = context ?? const <String, Object?>{};
    try {
      final result = await action();
      final latencyMs = DateTime.now().difference(started).inMilliseconds;
      final metricDimensions = <String, Object?>{
        'operation': operation ?? metricName,
        'component': component ?? 'app',
      };
      metricDimensions.addAll(extraContext);
      recordMetric(
        metricName,
        status: 'success',
        latencyMs: latencyMs,
        correlationId: effectiveCorrelationId,
        dimensions: metricDimensions,
      );
      final logContext = <String, Object?>{'latencyMs': latencyMs};
      logContext.addAll(extraContext);
      await logStructured(
        eventName ?? metricName,
        operation: operation ?? metricName,
        component: component ?? 'app',
        outcome: 'success',
        severity: 'info',
        context: logContext,
        correlationId: effectiveCorrelationId,
      );
      return result;
    } catch (error, stack) {
      final latencyMs = DateTime.now().difference(started).inMilliseconds;
      final metricDimensions = <String, Object?>{
        'operation': operation ?? metricName,
        'component': component ?? 'app',
        'error': error.toString(),
      };
      metricDimensions.addAll(extraContext);
      recordMetric(
        metricName,
        status: 'failure',
        latencyMs: latencyMs,
        correlationId: effectiveCorrelationId,
        dimensions: metricDimensions,
      );
      final errorContext = <String, Object?>{
        'component': component ?? 'app',
      };
      errorContext.addAll(extraContext);
      await reportError(
        error,
        stack,
        reason: operation ?? metricName,
        correlationId: effectiveCorrelationId,
        context: errorContext,
      );
      final failureContext = <String, Object?>{
        'latencyMs': latencyMs,
        'error': error.toString(),
      };
      failureContext.addAll(extraContext);
      await logStructured(
        eventName ?? metricName,
        operation: operation ?? metricName,
        component: component ?? 'app',
        outcome: 'failure',
        severity: 'error',
        context: failureContext,
        correlationId: effectiveCorrelationId,
      );
      rethrow;
    }
  }

  static Future<void> logStructured(
    String eventName, {
    required String operation,
    required String component,
    required String outcome,
    required String severity,
    required String correlationId,
    Map<String, Object?>? context,
  }) async {
    final payload = <String, Object?>{
      'ts': DateTime.now().toUtc().toIso8601String(),
      'event': eventName,
      'operation': operation,
      'component': component,
      'outcome': outcome,
      'severity': severity,
      'correlationId': correlationId,
      'context': sanitizePayload(context),
    };

    try {
      // keep console logs machine-readable and safe for operational use.
      // The payload is intentionally free of tokens, secrets and user PII.
      print(jsonEncode(payload));
    } catch (_) {}

    try {
      await logEvent(
        'social_observability_event',
        parameters: <String, Object>{
          'event_name': eventName,
          'operation': operation,
          'component': component,
          'outcome': outcome,
          'severity': severity,
          'correlation_id': correlationId,
          'context': jsonEncode(sanitizePayload(context)),
        },
      );
    } catch (_) {}
  }

  /// Initialize Analytics & Crashlytics. Safe to call multiple times.
  static Future<void> init() async {
    analytics = FirebaseAnalytics.instance;

    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    } catch (_) {
      print('Crashlytics collection could not be enabled at init.');
    }
  }

  static Future<void> logEvent(String name,
      {Map<String, Object>? parameters}) async {
    try {
      await analytics?.logEvent(name: name, parameters: parameters);
    } catch (_) {}
  }

  static Future<void> setUserId(String? id) async {
    try {
      await analytics?.setUserId(id: id);
    } catch (_) {}
  }

  static Future<void> reportError(Object error, StackTrace stack,
      {String? reason,
      String? correlationId,
      Map<String, Object?>? context}) async {
    final safeContext = sanitizePayload(context);
    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: reason ?? 'observability_service.reportError',
        information: <Object>[
          'correlation_id: ${correlationId ?? _currentCorrelationId}',
          'context: ${jsonEncode(safeContext)}',
        ],
      );
    } catch (_) {}

    try {
      await logStructured(
        'error.reported',
        operation: reason ?? 'report_error',
        component: 'observability_service',
        outcome: 'failure',
        severity: 'error',
        correlationId: correlationId ?? _currentCorrelationId,
        context: <String, Object?>{
          'error': error.toString(),
          'reason': reason ?? 'report_error',
          ...safeContext,
        },
      );
    } catch (_) {}
  }
}
