import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('Agrilink app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AgrilinkApp());
    expect(find.text('AGRILINK'), findsOneWidget);
  });
}
