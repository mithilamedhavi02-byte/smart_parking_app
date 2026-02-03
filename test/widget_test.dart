import 'package:flutter_test/flutter_test.dart';
import 'package:parking1/main.dart';

void main() {
  testWidgets('App load test', (WidgetTester tester) async {
    // දැන් lib/main.dart එකේ නම "SmartParkingApp" නිසා මෙය වැඩ කරනු ඇත
    await tester.pumpWidget(const SmartParkingApp());
    expect(find.byType(SmartParkingApp), findsOneWidget);
  });
}