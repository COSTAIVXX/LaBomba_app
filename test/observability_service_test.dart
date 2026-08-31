import 'package:flutter_test/flutter_test.dart';
import 'package:labomba_app/services/observability_service.dart';

void main() {
  group('observability service', () {
    test('sanitizes sensitive payload values', () {
      final payload = <String, Object?>{
        'requestId': 'abc-123',
        'token': 'secret-token',
        'nested': <String, Object?>{
          'email': 'user@example.com',
          'safe': 'keep-me',
        },
      };

      final sanitized = ObservabilityService.sanitizePayload(payload);

      expect(sanitized['requestId'], 'abc-123');
      expect(sanitized['token'], '[REDACTED]');
      expect(sanitized['nested']['email'], '[REDACTED]');
      expect(sanitized['nested']['safe'], 'keep-me');
    });

    test('tracks metrics successfully', () {
      ObservabilityService.clearMetrics();

      ObservabilityService.recordMetric(
        'social_feed_load',
        status: 'success',
        latencyMs: 125,
        dimensions: {'component': 'feed'},
      );

      final metrics = ObservabilityService.getMetricsSnapshot();
      expect(metrics.containsKey('social_feed_load'), isTrue);
      expect(metrics['social_feed_load']!['count'], 1);
      expect(metrics['social_feed_load']!['success'], 1);
      expect(metrics['social_feed_load']!['averageLatencyMs'], 125);
    });
  });
}
