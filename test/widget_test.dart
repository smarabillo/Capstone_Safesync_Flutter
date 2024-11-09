import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safesync/pages/home.dart';
import 'package:safesync/pages/splashscreen.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byType(SafeSyncDashboard), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
