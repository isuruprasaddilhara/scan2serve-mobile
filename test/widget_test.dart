import 'package:flutter_test/flutter_test.dart';
import 'package:scan2serve/main.dart';

void main() {
  testWidgets('Welcome screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const Scan2ServeApp());
    await tester.pumpAndSettle();
    expect(find.text('Welcome!'), findsOneWidget);
  });
}
