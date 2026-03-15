import 'package:flutter_test/flutter_test.dart';
import 'package:musaami/main.dart';

void main() {
  testWidgets('Musaami app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MusaamiApp());
    expect(find.byType(MusaamiApp), findsOneWidget);
  });
}
