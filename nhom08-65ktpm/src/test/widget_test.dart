import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travel_buddy/main.dart';

void main() {
  testWidgets('TravelBuddyApp renders initial auth route', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TravelBuddyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Module auth_and_group'), findsOneWidget);
    expect(find.text('Vào ứng dụng'), findsOneWidget);
  });
}
