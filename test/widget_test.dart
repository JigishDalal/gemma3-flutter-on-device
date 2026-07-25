import 'package:flutter_test/flutter_test.dart';

import 'package:ailocalmodel/main.dart';

void main() {
  testWidgets('shows the expense-only entry point', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AIEdgeGalleryApp());

    expect(find.text('Expense Detector'), findsOneWidget);
    expect(find.text('e.g. Paid ₹450 for lunch'), findsOneWidget);
  });
}
