import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_net/app.dart';

void main() {
  testWidgets('Dashboard tab renders and map tab is available', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UrbanScoreApp());
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('UrbanScore Dashboard'), findsOneWidget);
    expect(find.text('AI alerts'), findsOneWidget);
  });
}
