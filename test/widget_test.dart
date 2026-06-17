import 'package:flutter_test/flutter_test.dart';
import 'package:sams/main.dart';

void main() {
  testWidgets('SAMS app shows login page', (WidgetTester tester) async {
    await tester.pumpWidget(const SamsApp());
    await tester.pumpAndSettle();

    expect(find.text('SAMS Login'), findsOneWidget);
    expect(
      find.text('Student Academic Management System'),
      findsOneWidget,
    );
  });
}
