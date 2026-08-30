import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class ObservabilityService {
  ObservabilityService._();

  static FirebaseAnalytics? analytics;

  /// Initialize Analytics & Crashlytics. Safe to call multiple times.
  static Future<void> init() async {
    analytics = FirebaseAnalytics.instance;

    // Enable crashlytics collection if not already configured (respecting platform defaults)
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    } catch (_) {
      if (kDebugMode)
        debugPrint('Crashlytics collection could not be enabled at init.');
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
      // Also set Crashlytics user identifier for cross-correlation
      await FirebaseCrashlytics.instance.setUserIdentifier(id ?? '');
    } catch (_) {}
  }

  /// Record a non-fatal error with Crashlytics (object + stacktrace)
  static Future<void> reportError(Object error, StackTrace stack,
      {String? reason}) async {
    try {
      await FirebaseCrashlytics.instance
          .recordError(error, stack, reason: reason);
    } catch (_) {}
  }

  /// Record Flutter framework errors (FlutterErrorDetails) into Crashlytics
  static Future<void> recordFlutterError(FlutterErrorDetails details) async {
    try {
      // Forward to Crashlytics
      await FirebaseCrashlytics.instance.recordFlutterError(details);
    } catch (_) {
      if (kDebugMode)
        debugPrint('Failed to record flutter error to Crashlytics');
    }
  }
}
