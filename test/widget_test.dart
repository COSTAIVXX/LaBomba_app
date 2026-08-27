// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';
import 'package:labomba_app/services/storage_mobile.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:labomba_app/main.dart';
import 'package:labomba_app/providers/client_provider.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    final repository = SecureClientRepository(MobileStorageService());

    await tester.pumpWidget(LaBombaApp(repository: repository));

    expect(find.text('LABOMBA 2027'), findsOneWidget);
  });
}
