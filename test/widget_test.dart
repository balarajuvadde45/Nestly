import 'package:flutter_test/flutter_test.dart';
import 'package:nestly/main.dart';

void main() {
  testWidgets('Nestly app boots to splash', (WidgetTester tester) async {
    await tester.pumpWidget(const NestlyApp());
    await tester.pump();

    expect(find.text('Nestly'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 2500));
  });
}
