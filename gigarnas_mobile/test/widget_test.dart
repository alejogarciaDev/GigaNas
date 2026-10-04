import 'package:flutter_test/flutter_test.dart';
import 'package:gigarnas_mobile/main.dart';

void main() {
  testWidgets('GigaNas mobile smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GigaNasApp());
    expect(find.text('GigaNas OS'), findsOneWidget);
  });
}
