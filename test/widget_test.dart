import 'package:flutter_test/flutter_test.dart';
import 'package:carelink_kerala/main.dart';
import 'package:carelink_kerala/core/state/app_state_provider.dart';

void main() {
  testWidgets('CareLink Kerala Smoke Test', (WidgetTester tester) async {
    final state = AppStateProvider();
    await tester.pumpWidget(CareLinkKeralaApp(state: state));
    await tester.pumpAndSettle();
    expect(find.text('Staff Portal'), findsOneWidget);
  });
}
