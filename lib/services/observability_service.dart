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
      // ignore: avoid_print
      print('Crashlytics collection could not be enabled at init.');
    }
  }

  static Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      await analytics?.logEvent(name: name, parameters: parameters);
    } catch (_) {}
  }

  static Future<void> setUserId(String? id) async {
    try {
      await analytics?.setUserId(id: id);
    } catch (_) {}
  }

  static Future<void> reportError(Object error, StackTrace stack, {String? reason}) async {
    try {
      await FirebaseCrashlytics.instance.recordError(error, stack, reason: reason);
    } catch (_) {}
  }
}
