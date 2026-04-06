import 'package:flutter_test/flutter_test.dart';

import 'package:mechanic_connect/main.dart';

void main() {
  testWidgets('renders theme preview screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MechanicConnectApp());

    expect(find.text('Mechanic Connect'), findsOneWidget);
    expect(find.text('Color Tokens'), findsOneWidget);
  });
}
