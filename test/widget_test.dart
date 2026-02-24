import 'package:flutter_test/flutter_test.dart';
import 'package:parking1/main.dart';

void main() {
  testWidgets('App load test', (WidgetTester tester) async {
    // lib/main.dart එකේ තියෙන්නේ MyApp නිසා මෙතනත් ඒ නමම විය යුතුයි
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MyApp), findsOneWidget);
  });
}