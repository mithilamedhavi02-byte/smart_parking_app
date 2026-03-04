import 'package:flutter_test/flutter_test.dart';
import 'package:parking1/main.dart';

void main() {
  testWidgets('App load test', (WidgetTester tester) async {
    // 1. pumpWidget එකට ParkProApp() ලබා දෙන්න
    await tester.pumpWidget(const ParkProApp());

    // 2. find.byType එකේදීත් ParkProApp පරීක්ෂා කරන්න
    expect(find.byType(ParkProApp), findsOneWidget);
  });
}