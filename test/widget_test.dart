import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_net/main.dart';

void main() {
  testWidgets('UrbanScore dashboard renders core sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UrbanScoreApp());
    await tester.pumpAndSettle();

    expect(find.text('UrbanScore'), findsWidgets);
    expect(find.text('City map'), findsOneWidget);
    expect(find.text('AI alerts'), findsOneWidget);
    expect(find.text('Alem Riverside'), findsWidgets);
    expect(find.text('Citizen reviews'), findsOneWidget);
  });
}
