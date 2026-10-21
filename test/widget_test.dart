import 'package:flutter_test/flutter_test.dart';
import 'package:airbridge/main.dart';

void main() {
  testWidgets('AirBridge home screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const AirBridgeApp());

    expect(find.text('AirBridge'), findsOneWidget);
    expect(find.text('Send files'), findsOneWidget);
    expect(find.text('Receive files'), findsOneWidget);
    expect(find.text('Connect with QR'), findsOneWidget);
  });
}