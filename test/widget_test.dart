import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('App launches and shows bottom nav', (WidgetTester tester) async {
    await tester.pumpWidget(const KinConnectApp());
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Wellness'), findsOneWidget);
    expect(find.text('Safety'), findsOneWidget);
    expect(find.text('Devices'), findsOneWidget);
  });
}
