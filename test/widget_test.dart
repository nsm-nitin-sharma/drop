import 'package:drop/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Drop app basic smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DropApp());
    expect(find.text('DROP'), findsNothing); // Will be in login widget tree
  });
}
