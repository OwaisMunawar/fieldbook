import 'package:fieldbook/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens the inspection notebook', (tester) async {
    app.main();
    await tester.pump();
    expect(find.text('Fieldbook'), findsOneWidget);
  });
}
