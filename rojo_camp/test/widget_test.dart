import 'package:flutter_test/flutter_test.dart';

import 'package:rojo_camp/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RojoCampApp());

    // Verify that the app renders without error.
    expect(find.byType(RojoCampApp), findsOneWidget);
  });
}
