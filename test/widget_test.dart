import 'package:flutter_test/flutter_test.dart';
import 'package:tamarin/main.dart';

void main() {
  testWidgets('Tamarin app boots to splash', (WidgetTester tester) async {
    await tester.pumpWidget(const TamarinApp());
    await tester.pump();

    expect(find.text('Tamarin'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 2500));
  });
}
