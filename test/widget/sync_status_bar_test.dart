import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carelink_kerala/core/state/app_state_provider.dart';
import 'package:carelink_kerala/core/widgets/sync_status_bar.dart';

void main() {
  testWidgets('SyncStatusBar renders online status when no pending items', (WidgetTester tester) async {
    final state = AppStateProvider();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SyncStatusBar(state: state),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.textContaining('System Online'), findsOneWidget);
  });
}
