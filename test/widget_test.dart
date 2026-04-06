import 'package:flutter_test/flutter_test.dart';

import 'package:mechanic_connect/app/mechanic_connect_app.dart';

void main() {
  testWidgets('navigates from splash to login', (WidgetTester tester) async {
    await tester.pumpWidget(const MechanicConnectApp());

    expect(find.text('Mechanic Connect'), findsOneWidget);
    expect(find.text('Welcome Back'), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
