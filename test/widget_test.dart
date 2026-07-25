import 'package:flutter_test/flutter_test.dart';

import 'package:ailocalmodel/main.dart';

void main() {
  testWidgets('App launches with GemmaApp', (WidgetTester tester) async {
    await tester.pumpWidget(const GemmaApp());
    // Basic smoke test: app renders without crashing
    expect(find.byType(GemmaApp), findsOneWidget);
  });
}
